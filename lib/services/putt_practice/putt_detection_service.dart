import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

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

  /// Model input dimensions
  static const int inputWidth = 320;
  static const int inputHeight = 320;

  /// Detection confidence threshold
  static const double confidenceThreshold = 0.5;

  /// Class labels for the model
  static const List<String> defaultLabels = [
    'basket',
    'flying_disc',
    'disc_in_chains',
    'disc_on_ground',
  ];

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the TFLite model
  Future<void> initialize({String? modelPath}) async {
    if (_isInitialized) return;

    try {
      // Try to load custom model, fall back to COCO-trained model
      final String path = modelPath ?? 'assets/ml/putt_detection.tflite';

      try {
        _interpreter = await Interpreter.fromAsset(path);
        _labels = defaultLabels;
        debugPrint('[PuttDetectionService] Loaded custom model: $path');
      } catch (e) {
        // If custom model not found, we'll use placeholder detection
        // until a model is trained and added
        debugPrint('[PuttDetectionService] Custom model not found, using placeholder detection');
        _interpreter = null;
        _labels = defaultLabels;
      }

      _isInitialized = true;
      debugPrint('[PuttDetectionService] Initialized');
    } catch (e) {
      debugPrint('[PuttDetectionService] Failed to initialize: $e');
      rethrow;
    }
  }

  /// Run object detection on an image
  /// Returns list of detected objects with bounding boxes
  Future<List<DetectionResult>> detect(Uint8List imageBytes, int width, int height) async {
    if (!_isInitialized) {
      throw StateError('PuttDetectionService not initialized');
    }

    // If no interpreter (model not loaded), return empty list
    // This allows the app to run without a trained model during development
    if (_interpreter == null) {
      return _placeholderDetection();
    }

    try {
      // Preprocess image
      final Float32List input = _preprocessImage(imageBytes, width, height);

      // Prepare output tensors
      // YOLOv8 outputs: [1, num_detections, 85] where 85 = 4 (bbox) + 1 (obj conf) + 80 (class confs)
      // For our custom model: [1, num_detections, 8] where 8 = 4 (bbox) + 4 (class confs)
      final List<List<List<double>>> output = List.generate(
        1,
        (_) => List.generate(100, (_) => List.filled(8, 0.0)),
      );

      // Run inference
      _interpreter!.run(input.buffer.asFloat32List(), output);

      // Parse results
      return _parseDetections(output[0]);
    } catch (e) {
      debugPrint('[PuttDetectionService] Detection failed: $e');
      return [];
    }
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

  /// Parse model output into detection results
  List<DetectionResult> _parseDetections(List<List<double>> output) {
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

  /// Placeholder detection for development without a trained model
  List<DetectionResult> _placeholderDetection() {
    // Return empty list - no detections without a model
    // In real usage, the calibration flow will handle this gracefully
    return [];
  }

  /// Clean up resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
