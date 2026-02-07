import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:turbo_disc_golf/services/putt_practice/detection_isolate.dart';

/// YOLOv8 COCO model configuration constants
class YOLOv8Config {
  /// Frisbee class index in COCO dataset (class 29)
  static const int frisbeeClassIndex = 29;

  /// Total number of classes in COCO dataset
  static const int numClasses = 80;

  /// Number of predictions for 320x320 input (grid cells from 3 scales)
  static const int numPredictions = 2100;

  /// Output channels: 4 bbox coords + 80 class scores
  static const int outputChannels = 84;

  /// IoU threshold for Non-Maximum Suppression
  static const double nmsIouThreshold = 0.45;

  /// Maximum detections to return after NMS
  static const int maxDetections = 10;

  /// COCO class labels (subset relevant for disc detection)
  static const Map<int, String> relevantClasses = {
    29: 'frisbee', // We use this for disc detection
    0: 'person',
  };
}

/// Result of object detection on a single frame
class DetectionResult {
  /// Class label of the detected object
  final String label;

  /// Bounding box in normalized coordinates (0-1)
  final Rect boundingBox;

  /// Confidence score (0-1)
  final double confidence;

  DetectionResult({
    required this.label,
    required this.boundingBox,
    required this.confidence,
  });
}

/// Service for detecting baskets and discs using TensorFlow Lite
class PuttDetectionService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isInitialized = false;
  bool _isYOLOv8 = false;

  /// Isolate manager for background ML inference
  final DetectionIsolateManager _isolateManager = DetectionIsolateManager();

  /// Whether to use isolate-based detection (better performance)
  bool _useIsolate = false;

  /// Model input dimensions
  static const int inputWidth = 320;
  static const int inputHeight = 320;

  /// Detection confidence threshold - increased to reduce false positives
  static const double confidenceThreshold = 0.40;

  /// Class labels for the custom model
  static const List<String> defaultLabels = [
    'basket',
    'flying_disc',
    'disc_in_chains',
    'disc_on_ground',
  ];

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Whether YOLOv8 COCO model is being used
  bool get isUsingYOLOv8 => _isYOLOv8;

  /// Initialize the TFLite model
  Future<void> initialize({String? modelPath, bool useIsolate = true}) async {
    if (_isInitialized) return;

    try {
      // Try isolate-based detection first (better performance)
      if (useIsolate && modelPath == null) {
        debugPrint('[PuttDetectionService] Attempting isolate-based initialization...');
        final bool isolateSuccess = await _isolateManager.initialize();
        if (isolateSuccess) {
          _useIsolate = true;
          _isYOLOv8 = true;
          _isInitialized = true;
          debugPrint('[PuttDetectionService] Initialized with ISOLATE (non-blocking ML)');
          return;
        }
        debugPrint('[PuttDetectionService] Isolate init failed, falling back to main thread');
      }

      // Fall back to main-thread detection
      if (modelPath == null) {
        try {
          _interpreter = await Interpreter.fromAsset('assets/ml/yolov8n_coco.tflite');
          _isYOLOv8 = true;
          debugPrint('[PuttDetectionService] Loaded model: assets/ml/yolov8n_coco.tflite');

          // Log input/output tensor info
          final List<dynamic> inputTensors = _interpreter!.getInputTensors();
          final List<dynamic> outputTensors = _interpreter!.getOutputTensors();
          debugPrint('[PuttDetectionService] Input tensors: ${inputTensors.length}');
          for (int i = 0; i < inputTensors.length; i++) {
            debugPrint('  Input $i: shape=${inputTensors[i].shape}, type=${inputTensors[i].type}');
          }
          debugPrint('[PuttDetectionService] Output tensors: ${outputTensors.length}');
          for (int i = 0; i < outputTensors.length; i++) {
            debugPrint('  Output $i: shape=${outputTensors[i].shape}, type=${outputTensors[i].type}');
          }
        } catch (e) {
          debugPrint('[PuttDetectionService] YOLOv8 model not found, trying custom model');
          // Fall back to custom model
          try {
            _interpreter = await Interpreter.fromAsset('assets/ml/putt_detection.tflite');
            _labels = defaultLabels;
            _isYOLOv8 = false;
            debugPrint('[PuttDetectionService] Loaded model: assets/ml/putt_detection.tflite');
          } catch (e2) {
            debugPrint('[PuttDetectionService] Custom model not found, using placeholder detection');
            _interpreter = null;
            _labels = defaultLabels;
            _isYOLOv8 = false;
          }
        }
      } else {
        // Load specified model
        _interpreter = await Interpreter.fromAsset(modelPath);
        _labels = defaultLabels;
        _isYOLOv8 = modelPath.contains('yolov8');
        debugPrint('[PuttDetectionService] Loaded custom model: $modelPath');
      }

      _isInitialized = true;
      debugPrint('[PuttDetectionService] Initialized (YOLOv8: $_isYOLOv8, useIsolate: $_useIsolate)');
    } catch (e) {
      debugPrint('[PuttDetectionService] Failed to initialize: $e');
      rethrow;
    }
  }

  // Frame counter for debug logging
  int _frameCount = 0;

  /// Run object detection on an image
  /// Returns list of detected objects with bounding boxes
  Future<List<DetectionResult>> detect(Uint8List imageBytes, int width, int height) async {
    _frameCount++;

    // Return empty list if not initialized (graceful degradation)
    if (!_isInitialized) {
      if (_frameCount % 30 == 0) {
        debugPrint('[PuttDetectionService] Frame $_frameCount: Not initialized');
      }
      return [];
    }

    try {
      // Use isolate-based detection if available (non-blocking)
      if (_useIsolate) {
        if (_frameCount % 30 == 0) {
          debugPrint('[PuttDetectionService] Frame $_frameCount: Using ISOLATE detection');
        }

        final List<IsolateDetectionResult> isolateResults =
            await _isolateManager.detect(imageBytes, width, height);

        // Convert to DetectionResult format
        return isolateResults.map((IsolateDetectionResult r) => DetectionResult(
          label: r.label,
          boundingBox: r.boundingBox,
          confidence: r.confidence,
        )).toList();
      }

      // Fall back to main-thread detection
      if (_frameCount % 30 == 0) {
        debugPrint('[PuttDetectionService] Frame $_frameCount: Using MAIN THREAD detection (no isolate)');
      }

      if (_interpreter == null) {
        return [];
      }

      // Preprocess image
      final Float32List input = _preprocessImage(imageBytes, width, height);

      if (_isYOLOv8) {
        return _runYOLOv8Inference(input);
      } else {
        return _runCustomModelInference(input);
      }
    } catch (e) {
      debugPrint('[PuttDetectionService] Detection failed: $e');
      return [];
    }
  }

  // Pre-allocated buffers for performance
  List<List<List<List<double>>>>? _inputBuffer;
  List<List<List<double>>>? _outputBuffer;

  /// Run inference with YOLOv8 COCO model
  List<DetectionResult> _runYOLOv8Inference(Float32List flatInput) {
    // Pre-allocate input buffer once (reuse across frames)
    _inputBuffer ??= List.generate(
      1,
      (_) => List.generate(
        inputHeight,
        (_) => List.generate(
          inputWidth,
          (_) => List.filled(3, 0.0),
        ),
      ),
    );

    // Pre-allocate output buffer once
    _outputBuffer ??= List.generate(
      1,
      (_) => List.generate(
        YOLOv8Config.outputChannels,
        (_) => List.filled(YOLOv8Config.numPredictions, 0.0),
      ),
    );

    // Copy flat input into pre-allocated 4D buffer
    for (int y = 0; y < inputHeight; y++) {
      for (int x = 0; x < inputWidth; x++) {
        final int baseIdx = (y * inputWidth + x) * 3;
        _inputBuffer![0][y][x][0] = flatInput[baseIdx];
        _inputBuffer![0][y][x][1] = flatInput[baseIdx + 1];
        _inputBuffer![0][y][x][2] = flatInput[baseIdx + 2];
      }
    }

    // Run inference
    _interpreter!.run(_inputBuffer!, _outputBuffer!);

    // Parse YOLOv8 output and apply NMS
    final List<DetectionResult> results = _parseYOLOv8Detections(_outputBuffer![0]);

    // Debug logging every 30 frames
    if (_frameCount % 30 == 0) {
      debugPrint('[PuttDetectionService] Frame $_frameCount: ${results.length} detections');
      for (final DetectionResult r in results) {
        final Rect b = r.boundingBox;
        debugPrint('  - ${r.label}: conf=${r.confidence.toStringAsFixed(3)} '
            'LTRB=(${b.left.toStringAsFixed(3)}, ${b.top.toStringAsFixed(3)}, '
            '${b.right.toStringAsFixed(3)}, ${b.bottom.toStringAsFixed(3)})');
      }
    }

    return results;
  }

  /// Run inference with custom model
  List<DetectionResult> _runCustomModelInference(Float32List input) {
    // Custom model output: [1, 100, 8]
    final List<List<List<double>>> output = List.generate(
      1,
      (_) => List.generate(100, (_) => List.filled(8, 0.0)),
    );

    // Run inference
    _interpreter!.run(input.buffer.asFloat32List(), output);

    // Parse results
    return _parseCustomDetections(output[0]);
  }

  /// Parse YOLOv8 output tensor into detection results
  /// Output format: [84, 2100] where rows are channels and columns are predictions
  List<DetectionResult> _parseYOLOv8Detections(List<List<double>> output) {
    final List<DetectionResult> candidates = [];

    // Track max frisbee score for debugging
    double maxFrisbeeScore = 0.0;
    double maxAnyScore = 0.0;
    int maxAnyClass = 0;

    // Iterate over predictions (columns)
    for (int predIdx = 0; predIdx < YOLOv8Config.numPredictions; predIdx++) {
      // Find class with maximum score
      double maxClassScore = 0.0;
      int bestClassIdx = 0;

      for (int classIdx = 0; classIdx < YOLOv8Config.numClasses; classIdx++) {
        final double score = output[4 + classIdx][predIdx];
        if (score > maxClassScore) {
          maxClassScore = score;
          bestClassIdx = classIdx;
        }
      }

      // Track frisbee class score specifically
      final double frisbeeScore = output[4 + YOLOv8Config.frisbeeClassIndex][predIdx];
      if (frisbeeScore > maxFrisbeeScore) {
        maxFrisbeeScore = frisbeeScore;
      }

      // Track overall max
      if (maxClassScore > maxAnyScore) {
        maxAnyScore = maxClassScore;
        maxAnyClass = bestClassIdx;
      }

      // In YOLOv8, class score IS the confidence (no separate objectness)
      if (maxClassScore < confidenceThreshold) continue;

      // Extract bounding box values (already normalized 0-1 from TFLite export)
      final double xCenter = output[0][predIdx];
      final double yCenter = output[1][predIdx];
      final double bboxWidth = output[2][predIdx];
      final double bboxHeight = output[3][predIdx];

      // Debug first high-confidence detection
      if (candidates.isEmpty && _frameCount % 30 == 0) {
        debugPrint('[PuttDetectionService] Bbox: center=($xCenter, $yCenter), size=($bboxWidth x $bboxHeight)');
      }

      // Convert to Rect
      final Rect boundingBox = Rect.fromCenter(
        center: Offset(xCenter, yCenter),
        width: bboxWidth,
        height: bboxHeight,
      );

      // Map class index to label
      String label;
      if (bestClassIdx == YOLOv8Config.frisbeeClassIndex) {
        label = 'flying_disc'; // Map frisbee to our internal label
      } else {
        label = YOLOv8Config.relevantClasses[bestClassIdx] ?? 'unknown';
      }

      candidates.add(DetectionResult(
        label: label,
        boundingBox: boundingBox,
        confidence: maxClassScore,
      ));
    }

    // Debug logging every 30 frames - show max scores even if no detections
    if (_frameCount % 30 == 0) {
      final String maxClassName = YOLOv8Config.relevantClasses[maxAnyClass] ?? 'class_$maxAnyClass';
      debugPrint('[PuttDetectionService] Frame $_frameCount scores: '
          'maxFrisbee=${maxFrisbeeScore.toStringAsFixed(4)}, '
          'maxAny=${maxAnyScore.toStringAsFixed(4)} ($maxClassName), '
          'candidates=${candidates.length}');
    }

    // Apply Non-Maximum Suppression
    return _applyNMS(candidates);
  }

  /// Apply Non-Maximum Suppression to filter overlapping detections
  List<DetectionResult> _applyNMS(List<DetectionResult> detections) {
    if (detections.isEmpty) return [];

    // Sort by confidence (descending)
    detections.sort((DetectionResult a, DetectionResult b) => b.confidence.compareTo(a.confidence));

    final List<DetectionResult> results = [];
    final List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      if (results.length >= YOLOv8Config.maxDetections) break;

      results.add(detections[i]);

      // Suppress overlapping boxes
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        final double iou = _calculateIoU(
          detections[i].boundingBox,
          detections[j].boundingBox,
        );

        if (iou > YOLOv8Config.nmsIouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return results;
  }

  /// Calculate Intersection over Union (IoU) between two bounding boxes
  double _calculateIoU(Rect boxA, Rect boxB) {
    // Calculate intersection
    final double intersectLeft = boxA.left > boxB.left ? boxA.left : boxB.left;
    final double intersectTop = boxA.top > boxB.top ? boxA.top : boxB.top;
    final double intersectRight = boxA.right < boxB.right ? boxA.right : boxB.right;
    final double intersectBottom = boxA.bottom < boxB.bottom ? boxA.bottom : boxB.bottom;

    if (intersectRight <= intersectLeft || intersectBottom <= intersectTop) {
      return 0.0;
    }

    final double intersectionArea = (intersectRight - intersectLeft) * (intersectBottom - intersectTop);

    // Calculate union
    final double boxAArea = boxA.width * boxA.height;
    final double boxBArea = boxB.width * boxB.height;
    final double unionArea = boxAArea + boxBArea - intersectionArea;

    if (unionArea <= 0) return 0.0;

    return intersectionArea / unionArea;
  }

  /// Parse custom model output into detection results
  List<DetectionResult> _parseCustomDetections(List<List<double>> output) {
    final List<DetectionResult> results = [];

    for (final List<double> detection in output) {
      // Check if this is a valid detection
      final double objectness = detection[4];
      if (objectness < confidenceThreshold) continue;

      // Get class with highest confidence
      int bestClass = 0;
      double bestClassConf = 0.0;
      for (int c = 0; c < _labels!.length; c++) {
        final double classConf = detection[5 + c];
        if (classConf > bestClassConf) {
          bestClassConf = classConf;
          bestClass = c;
        }
      }

      final double confidence = objectness * bestClassConf;
      if (confidence < confidenceThreshold) continue;

      // Parse bounding box (x_center, y_center, width, height)
      final double xCenter = detection[0];
      final double yCenter = detection[1];
      final double bboxWidth = detection[2];
      final double bboxHeight = detection[3];

      final Rect boundingBox = Rect.fromCenter(
        center: Offset(xCenter, yCenter),
        width: bboxWidth,
        height: bboxHeight,
      );

      results.add(DetectionResult(
        label: _labels![bestClass],
        boundingBox: boundingBox,
        confidence: confidence,
      ));
    }

    return results;
  }

  /// Detect basket in the frame
  Future<DetectionResult?> detectBasket(Uint8List imageBytes, int width, int height) async {
    final List<DetectionResult> results = await detect(imageBytes, width, height);

    // Find basket detection with highest confidence
    DetectionResult? bestBasket;
    for (final DetectionResult result in results) {
      if (result.label == 'basket') {
        if (bestBasket == null || result.confidence > bestBasket.confidence) {
          bestBasket = result;
        }
      }
    }

    return bestBasket;
  }

  /// Detect flying disc in the frame
  Future<DetectionResult?> detectFlyingDisc(Uint8List imageBytes, int width, int height) async {
    final List<DetectionResult> results = await detect(imageBytes, width, height);

    // Find flying disc detection with highest confidence
    DetectionResult? bestDisc;
    for (final DetectionResult result in results) {
      if (result.label == 'flying_disc') {
        if (bestDisc == null || result.confidence > bestDisc.confidence) {
          bestDisc = result;
        }
      }
    }

    return bestDisc;
  }

  /// Detect disc in chains (made putt indicator)
  Future<DetectionResult?> detectDiscInChains(Uint8List imageBytes, int width, int height) async {
    final List<DetectionResult> results = await detect(imageBytes, width, height);

    for (final DetectionResult result in results) {
      if (result.label == 'disc_in_chains') {
        return result;
      }
    }

    return null;
  }

  /// Preprocess image for model input
  Float32List _preprocessImage(Uint8List imageBytes, int width, int height) {
    // Convert to RGB float32 tensor normalized to [0, 1]
    // Resize to inputWidth x inputHeight
    final Float32List input = Float32List(1 * inputHeight * inputWidth * 3);

    // Scale factors for resizing
    final double scaleX = width / inputWidth;
    final double scaleY = height / inputHeight;

    int inputIndex = 0;
    for (int y = 0; y < inputHeight; y++) {
      for (int x = 0; x < inputWidth; x++) {
        // Map to original image coordinates
        final int srcX = (x * scaleX).floor().clamp(0, width - 1);
        final int srcY = (y * scaleY).floor().clamp(0, height - 1);

        // Assuming YUV420 format, get Y component only for grayscale
        // Full color conversion would require UV planes
        final int yIndex = srcY * width + srcX;
        if (yIndex < imageBytes.length) {
          final int yValue = imageBytes[yIndex];
          final double normalized = yValue / 255.0;

          // RGB channels (grayscale for now)
          input[inputIndex++] = normalized; // R
          input[inputIndex++] = normalized; // G
          input[inputIndex++] = normalized; // B
        } else {
          input[inputIndex++] = 0.0;
          input[inputIndex++] = 0.0;
          input[inputIndex++] = 0.0;
        }
      }
    }

    return input;
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (_useIsolate) {
      await _isolateManager.dispose();
    }
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _isYOLOv8 = false;
    _useIsolate = false;
  }
}
