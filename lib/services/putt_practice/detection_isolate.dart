import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Message types for isolate communication
enum DetectionMessageType {
  initialize,
  detect,
  dispose,
}

/// Message sent to the detection isolate
class DetectionRequest {
  final DetectionMessageType type;
  final Uint8List? imageBytes;
  final int? width;
  final int? height;
  final SendPort? replyPort;
  final Uint8List? modelBytes; // Model loaded in main isolate, passed here

  DetectionRequest({
    required this.type,
    this.imageBytes,
    this.width,
    this.height,
    this.replyPort,
    this.modelBytes,
  });
}

/// Response from the detection isolate
class DetectionResponse {
  final bool success;
  final List<IsolateDetectionResult>? detections;
  final String? error;

  DetectionResponse({
    required this.success,
    this.detections,
    this.error,
  });
}

/// Detection result that can be passed between isolates
class IsolateDetectionResult {
  final String label;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double confidence;

  IsolateDetectionResult({
    required this.label,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.confidence,
  });

  Rect get boundingBox => Rect.fromLTRB(left, top, right, bottom);
}

/// YOLOv8 configuration (duplicated here since isolates can't share classes easily)
class _YOLOv8Config {
  static const int frisbeeClassIndex = 29;
  static const int numClasses = 80;
  static const int numPredictions = 2100;
  static const int outputChannels = 84;
  static const double nmsIouThreshold = 0.45;
  static const int maxDetections = 10;
  /// Confidence threshold - increased from 0.25 to reduce false positives
  static const double confidenceThreshold = 0.40;
  static const int inputWidth = 320;
  static const int inputHeight = 320;
}

/// Isolate entry point - runs detection in background
void detectionIsolateEntry(SendPort mainSendPort) {
  final ReceivePort isolateReceivePort = ReceivePort();
  mainSendPort.send(isolateReceivePort.sendPort);

  Interpreter? interpreter;
  List<List<List<List<double>>>>? inputBuffer;
  List<List<List<double>>>? outputBuffer;
  int frameCount = 0;

  isolateReceivePort.listen((dynamic message) async {
    if (message is! DetectionRequest) return;

    final DetectionRequest request = message;
    final SendPort? replyPort = request.replyPort;

    switch (request.type) {
      case DetectionMessageType.initialize:
        try {
          // Model bytes are loaded in main isolate and passed here
          if (request.modelBytes == null) {
            replyPort?.send(DetectionResponse(
              success: false,
              error: 'No model bytes provided',
            ));
            return;
          }

          debugPrint('[DetectionIsolate] Creating interpreter from ${request.modelBytes!.length} bytes');

          // Use fromBuffer instead of fromAsset - no Flutter bindings needed!
          interpreter = Interpreter.fromBuffer(request.modelBytes!);

          // Pre-allocate buffers
          inputBuffer = List.generate(
            1,
            (_) => List.generate(
              _YOLOv8Config.inputHeight,
              (_) => List.generate(
                _YOLOv8Config.inputWidth,
                (_) => List.filled(3, 0.0),
              ),
            ),
          );

          outputBuffer = List.generate(
            1,
            (_) => List.generate(
              _YOLOv8Config.outputChannels,
              (_) => List.filled(_YOLOv8Config.numPredictions, 0.0),
            ),
          );

          replyPort?.send(DetectionResponse(success: true));
        } catch (e) {
          replyPort?.send(DetectionResponse(
            success: false,
            error: 'Failed to initialize: $e',
          ));
        }
        break;

      case DetectionMessageType.detect:
        if (interpreter == null || inputBuffer == null || outputBuffer == null) {
          replyPort?.send(DetectionResponse(
            success: false,
            error: 'Not initialized',
          ));
          return;
        }

        try {
          frameCount++;
          final Stopwatch totalWatch = Stopwatch()..start();

          final Uint8List imageBytes = request.imageBytes!;
          final int width = request.width!;
          final int height = request.height!;

          // Preprocess image
          final Stopwatch preprocessWatch = Stopwatch()..start();
          final Float32List input = _preprocessImage(
            imageBytes,
            width,
            height,
            _YOLOv8Config.inputWidth,
            _YOLOv8Config.inputHeight,
          );

          // Copy to 4D buffer
          for (int y = 0; y < _YOLOv8Config.inputHeight; y++) {
            for (int x = 0; x < _YOLOv8Config.inputWidth; x++) {
              final int baseIdx = (y * _YOLOv8Config.inputWidth + x) * 3;
              inputBuffer![0][y][x][0] = input[baseIdx];
              inputBuffer![0][y][x][1] = input[baseIdx + 1];
              inputBuffer![0][y][x][2] = input[baseIdx + 2];
            }
          }
          preprocessWatch.stop();

          // Run inference
          final Stopwatch inferenceWatch = Stopwatch()..start();
          interpreter!.run(inputBuffer!, outputBuffer!);
          inferenceWatch.stop();

          // Parse detections
          final Stopwatch parseWatch = Stopwatch()..start();
          final List<IsolateDetectionResult> detections =
              _parseYOLOv8Detections(outputBuffer![0], frameCount);
          parseWatch.stop();

          totalWatch.stop();

          // Log timing every 30 frames
          if (frameCount % 30 == 0) {
            debugPrint('[DetectionIsolate] Frame $frameCount timing: '
                'preprocess=${preprocessWatch.elapsedMilliseconds}ms, '
                'inference=${inferenceWatch.elapsedMilliseconds}ms, '
                'parse=${parseWatch.elapsedMilliseconds}ms, '
                'total=${totalWatch.elapsedMilliseconds}ms');
          }

          replyPort?.send(DetectionResponse(
            success: true,
            detections: detections,
          ));
        } catch (e) {
          replyPort?.send(DetectionResponse(
            success: false,
            error: 'Detection failed: $e',
          ));
        }
        break;

      case DetectionMessageType.dispose:
        interpreter?.close();
        interpreter = null;
        inputBuffer = null;
        outputBuffer = null;
        replyPort?.send(DetectionResponse(success: true));
        isolateReceivePort.close();
        break;
    }
  });
}

/// Preprocess image for model input
Float32List _preprocessImage(
  Uint8List imageBytes,
  int width,
  int height,
  int inputWidth,
  int inputHeight,
) {
  final Float32List input = Float32List(inputHeight * inputWidth * 3);

  final double scaleX = width / inputWidth;
  final double scaleY = height / inputHeight;

  int inputIndex = 0;
  for (int y = 0; y < inputHeight; y++) {
    for (int x = 0; x < inputWidth; x++) {
      final int srcX = (x * scaleX).floor().clamp(0, width - 1);
      final int srcY = (y * scaleY).floor().clamp(0, height - 1);

      final int yIndex = srcY * width + srcX;
      if (yIndex < imageBytes.length) {
        final int yValue = imageBytes[yIndex];
        final double normalized = yValue / 255.0;

        input[inputIndex++] = normalized;
        input[inputIndex++] = normalized;
        input[inputIndex++] = normalized;
      } else {
        input[inputIndex++] = 0.0;
        input[inputIndex++] = 0.0;
        input[inputIndex++] = 0.0;
      }
    }
  }

  return input;
}

/// Parse YOLOv8 output tensor into detection results
List<IsolateDetectionResult> _parseYOLOv8Detections(
  List<List<double>> output,
  int frameCount,
) {
  final List<IsolateDetectionResult> candidates = [];

  double maxFrisbeeScore = 0.0;

  for (int predIdx = 0; predIdx < _YOLOv8Config.numPredictions; predIdx++) {
    double maxClassScore = 0.0;
    int bestClassIdx = 0;

    for (int classIdx = 0; classIdx < _YOLOv8Config.numClasses; classIdx++) {
      final double score = output[4 + classIdx][predIdx];
      if (score > maxClassScore) {
        maxClassScore = score;
        bestClassIdx = classIdx;
      }
    }

    final double frisbeeScore = output[4 + _YOLOv8Config.frisbeeClassIndex][predIdx];
    if (frisbeeScore > maxFrisbeeScore) {
      maxFrisbeeScore = frisbeeScore;
    }

    if (maxClassScore < _YOLOv8Config.confidenceThreshold) continue;

    final double xCenter = output[0][predIdx];
    final double yCenter = output[1][predIdx];
    final double bboxWidth = output[2][predIdx];
    final double bboxHeight = output[3][predIdx];

    final double left = xCenter - bboxWidth / 2;
    final double top = yCenter - bboxHeight / 2;
    final double right = xCenter + bboxWidth / 2;
    final double bottom = yCenter + bboxHeight / 2;

    String label;
    if (bestClassIdx == _YOLOv8Config.frisbeeClassIndex) {
      label = 'flying_disc';
    } else if (bestClassIdx == 0) {
      label = 'person';
    } else {
      label = 'class_$bestClassIdx';
    }

    candidates.add(IsolateDetectionResult(
      label: label,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      confidence: maxClassScore,
    ));
  }

  // Apply NMS
  return _applyNMS(candidates);
}

/// Apply Non-Maximum Suppression
List<IsolateDetectionResult> _applyNMS(List<IsolateDetectionResult> detections) {
  if (detections.isEmpty) return [];

  detections.sort((IsolateDetectionResult a, IsolateDetectionResult b) =>
      b.confidence.compareTo(a.confidence));

  final List<IsolateDetectionResult> results = [];
  final List<bool> suppressed = List.filled(detections.length, false);

  for (int i = 0; i < detections.length; i++) {
    if (suppressed[i]) continue;
    if (results.length >= _YOLOv8Config.maxDetections) break;

    results.add(detections[i]);

    for (int j = i + 1; j < detections.length; j++) {
      if (suppressed[j]) continue;

      final double iou = _calculateIoU(
        detections[i].boundingBox,
        detections[j].boundingBox,
      );

      if (iou > _YOLOv8Config.nmsIouThreshold) {
        suppressed[j] = true;
      }
    }
  }

  return results;
}

/// Calculate IoU between two boxes
double _calculateIoU(Rect boxA, Rect boxB) {
  final double intersectLeft = boxA.left > boxB.left ? boxA.left : boxB.left;
  final double intersectTop = boxA.top > boxB.top ? boxA.top : boxB.top;
  final double intersectRight = boxA.right < boxB.right ? boxA.right : boxB.right;
  final double intersectBottom = boxA.bottom < boxB.bottom ? boxA.bottom : boxB.bottom;

  if (intersectRight <= intersectLeft || intersectBottom <= intersectTop) {
    return 0.0;
  }

  final double intersectionArea =
      (intersectRight - intersectLeft) * (intersectBottom - intersectTop);
  final double boxAArea = boxA.width * boxA.height;
  final double boxBArea = boxB.width * boxB.height;
  final double unionArea = boxAArea + boxBArea - intersectionArea;

  if (unionArea <= 0) return 0.0;
  return intersectionArea / unionArea;
}

/// Manager for the detection isolate - used from main isolate
class DetectionIsolateManager {
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isDisposed = false;

  /// Whether a detection is currently in progress (prevents queueing)
  bool _isDetecting = false;

  /// Whether the isolate is ready for detection
  bool get isInitialized => _isInitialized && !_isDisposed;

  /// Spawn and initialize the detection isolate
  Future<bool> initialize() async {
    if (_isInitialized || _isInitializing) return _isInitialized;
    _isInitializing = true;

    try {
      // Load model bytes in main isolate (has access to asset bundle)
      debugPrint('[DetectionIsolateManager] Loading model bytes from assets...');
      final ByteData modelData = await rootBundle.load('assets/ml/yolov8n_coco.tflite');
      final Uint8List modelBytes = modelData.buffer.asUint8List();
      debugPrint('[DetectionIsolateManager] Model loaded: ${modelBytes.length} bytes');

      debugPrint('[DetectionIsolateManager] Spawning isolate...');

      final ReceivePort mainReceivePort = ReceivePort();

      _isolate = await Isolate.spawn(
        detectionIsolateEntry,
        mainReceivePort.sendPort,
      );

      // Get the isolate's send port
      final Completer<SendPort> sendPortCompleter = Completer<SendPort>();
      mainReceivePort.listen((dynamic message) {
        if (message is SendPort && !sendPortCompleter.isCompleted) {
          sendPortCompleter.complete(message);
        }
      });

      _isolateSendPort = await sendPortCompleter.future;
      debugPrint('[DetectionIsolateManager] Got isolate SendPort, initializing interpreter...');

      // Initialize the interpreter in the isolate - pass model bytes!
      final ReceivePort initReplyPort = ReceivePort();
      _isolateSendPort!.send(DetectionRequest(
        type: DetectionMessageType.initialize,
        replyPort: initReplyPort.sendPort,
        modelBytes: modelBytes,
      ));

      final DetectionResponse initResponse =
          await initReplyPort.first as DetectionResponse;
      initReplyPort.close();

      if (!initResponse.success) {
        debugPrint('[DetectionIsolateManager] Init failed: ${initResponse.error}');
        _isInitializing = false;
        return false;
      }

      _isInitialized = true;
      _isInitializing = false;
      debugPrint('[DetectionIsolateManager] Isolate initialized successfully');
      return true;
    } catch (e) {
      debugPrint('[DetectionIsolateManager] Failed to spawn isolate: $e');
      _isInitializing = false;
      return false;
    }
  }

  int _detectCallCount = 0;

  /// Run detection on an image
  /// Returns empty list if isolate is busy (prevents request queueing)
  Future<List<IsolateDetectionResult>> detect(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    // Skip if disposed
    if (_isDisposed) {
      return [];
    }

    // Skip if not initialized
    if (!_isInitialized || _isolateSendPort == null) {
      return [];
    }

    // Skip if already detecting - prevents request queue buildup
    if (_isDetecting) {
      return [];
    }

    _isDetecting = true;
    _detectCallCount++;
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final ReceivePort replyPort = ReceivePort();

      _isolateSendPort!.send(DetectionRequest(
        type: DetectionMessageType.detect,
        imageBytes: imageBytes,
        width: width,
        height: height,
        replyPort: replyPort.sendPort,
      ));

      final DetectionResponse response = await replyPort.first as DetectionResponse;
      replyPort.close();

      stopwatch.stop();
      _isDetecting = false;

      // Don't log if disposed
      if (_isDisposed) {
        return [];
      }

      // Log timing every 30 calls
      if (_detectCallCount % 30 == 0) {
        debugPrint('[DetectionIsolateManager] Isolate round-trip: ${stopwatch.elapsedMilliseconds}ms (call #$_detectCallCount)');
      }

      if (!response.success) {
        debugPrint('[DetectionIsolateManager] Detection failed: ${response.error}');
        return [];
      }

      return response.detections ?? [];
    } catch (e) {
      _isDetecting = false;
      if (!_isDisposed) {
        debugPrint('[DetectionIsolateManager] Detection error: $e');
      }
      return [];
    }
  }

  /// Dispose the isolate
  Future<void> dispose() async {
    debugPrint('[DetectionIsolateManager] Disposing isolate...');

    // Mark as disposed first to stop any new requests
    _isDisposed = true;
    _isInitialized = false;

    // Kill the isolate immediately - don't wait for graceful shutdown
    // This prevents queued requests from continuing to process
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isolateSendPort = null;

    debugPrint('[DetectionIsolateManager] Isolate disposed');
  }
}
