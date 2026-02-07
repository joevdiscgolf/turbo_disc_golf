import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'package:turbo_disc_golf/services/putt_practice/putt_detection_service.dart';

/// Callback for frame processing results
typedef FrameProcessingCallback = void Function(List<DetectionResult> detections);

/// Service for processing camera frames and running object detection
class FrameProcessorService {
  final PuttDetectionService _detectionService;

  /// Target frame rate for processing (frames per second)
  final int targetFps;

  /// Whether processing is currently active
  bool _isProcessing = false;

  /// Timestamp of last processed frame
  DateTime? _lastProcessedTime;

  /// Minimum interval between processed frames
  late final Duration _minInterval;

  /// Stream controller for detection results
  final StreamController<List<DetectionResult>> _detectionsController =
      StreamController<List<DetectionResult>>.broadcast();

  /// Stream of detection results
  Stream<List<DetectionResult>> get detectionsStream => _detectionsController.stream;

  FrameProcessorService({
    required PuttDetectionService detectionService,
    this.targetFps = 15,
  }) : _detectionService = detectionService {
    _minInterval = Duration(milliseconds: (1000 / targetFps).round());
  }

  /// Start processing frames
  void start() {
    _isProcessing = true;
  }

  /// Stop processing frames
  void stop() {
    _isProcessing = false;
  }

  /// Process a camera frame
  /// Returns true if the frame was processed, false if skipped
  Future<bool> processFrame(CameraImage image) async {
    if (!_isProcessing) return false;

    // Rate limiting
    final DateTime now = DateTime.now();
    if (_lastProcessedTime != null &&
        now.difference(_lastProcessedTime!) < _minInterval) {
      return false;
    }
    _lastProcessedTime = now;

    try {
      // Convert camera image to bytes
      final Uint8List imageBytes = _convertCameraImage(image);

      // Run detection
      final List<DetectionResult> detections = await _detectionService.detect(
        imageBytes,
        image.width,
        image.height,
      );

      // Emit results
      if (!_detectionsController.isClosed) {
        _detectionsController.add(detections);
      }

      return true;
    } catch (e) {
      debugPrint('[FrameProcessorService] Frame processing error: $e');
      return false;
    }
  }

  /// Convert CameraImage to Uint8List
  Uint8List _convertCameraImage(CameraImage image) {
    // For YUV420 format, we primarily use the Y plane (luminance)
    // This gives us grayscale data which is sufficient for object detection
    final Plane yPlane = image.planes[0];
    return yPlane.bytes;
  }

  /// Convert CameraImage to RGB bytes (for color-dependent detection)
  /// ignore: unused_element - will be used for color-based disc detection
  Uint8List _convertCameraImageToRgb(CameraImage image) {
    // YUV420 to RGB conversion
    final int width = image.width;
    final int height = image.height;
    final Uint8List rgbBytes = Uint8List(width * height * 3);

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final int yRowStride = yPlane.bytesPerRow;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

    int rgbIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final int yValue = yPlane.bytes[yIndex];
        final int uValue = uPlane.bytes[uvIndex];
        final int vValue = vPlane.bytes[uvIndex];

        // YUV to RGB conversion
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .round()
            .clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        rgbBytes[rgbIndex++] = r;
        rgbBytes[rgbIndex++] = g;
        rgbBytes[rgbIndex++] = b;
      }
    }

    return rgbBytes;
  }

  /// Get frame dimensions from camera image
  static (int width, int height) getFrameDimensions(CameraImage image) {
    return (image.width, image.height);
  }

  /// Dispose resources
  void dispose() {
    _isProcessing = false;
    _detectionsController.close();
  }
}
