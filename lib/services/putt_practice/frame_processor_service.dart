import 'dart:async';
import 'dart:io';

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
      final Uint8List? imageBytes = _convertCameraImage(image);
      if (imageBytes == null) {
        return false;
      }

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

  /// Convert CameraImage to Uint8List (grayscale)
  /// Handles both YUV420 (Android) and BGRA8888 (iOS) formats
  Uint8List? _convertCameraImage(CameraImage image) {
    try {
      if (image.planes.isEmpty) {
        debugPrint('[FrameProcessorService] No image planes available');
        return null;
      }

      if (Platform.isIOS) {
        // iOS uses BGRA8888 format - extract grayscale from BGRA data
        return _convertBgraToGrayscale(image);
      } else {
        // Android uses YUV420 format - use Y plane directly (luminance)
        final Plane yPlane = image.planes[0];
        return yPlane.bytes;
      }
    } catch (e) {
      debugPrint('[FrameProcessorService] Error converting camera image: $e');
      return null;
    }
  }

  /// Convert BGRA8888 image to grayscale bytes
  Uint8List? _convertBgraToGrayscale(CameraImage image) {
    try {
      final Plane plane = image.planes[0];
      final int width = image.width;
      final int height = image.height;

      if (width <= 0 || height <= 0) {
        debugPrint('[FrameProcessorService] Invalid image dimensions: ${width}x$height');
        return null;
      }

      final Uint8List grayscale = Uint8List(width * height);
      final Uint8List bgraBytes = plane.bytes;
      final int bytesPerRow = plane.bytesPerRow;

      int grayscaleIndex = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          // BGRA format: each pixel is 4 bytes (B, G, R, A)
          final int pixelIndex = y * bytesPerRow + x * 4;
          if (pixelIndex + 2 < bgraBytes.length) {
            final int b = bgraBytes[pixelIndex];
            final int g = bgraBytes[pixelIndex + 1];
            final int r = bgraBytes[pixelIndex + 2];
            // Standard grayscale conversion: 0.299*R + 0.587*G + 0.114*B
            grayscale[grayscaleIndex] =
                ((0.299 * r) + (0.587 * g) + (0.114 * b)).round().clamp(0, 255);
          }
          grayscaleIndex++;
        }
      }
      return grayscale;
    } catch (e) {
      debugPrint('[FrameProcessorService] Error converting BGRA to grayscale: $e');
      return null;
    }
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
