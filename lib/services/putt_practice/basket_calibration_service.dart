import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/basket_calibration.dart';
import 'package:turbo_disc_golf/services/putt_practice/putt_detection_service.dart';

/// Service for calibrating basket detection
class BasketCalibrationService {
  // ignore: unused_field - will be used for auto-detection
  final PuttDetectionService _detectionService;

  /// Number of consecutive detections required for stable calibration
  static const int requiredConsecutiveDetections = 5;

  /// Maximum deviation allowed between consecutive detections (normalized)
  static const double maxDeviation = 0.05;

  /// Minimum confidence for a valid detection
  static const double minConfidence = 0.6;

  /// Recent basket detections for stability check
  final List<BasketCalibration> _recentDetections = [];

  /// Stream controller for calibration updates
  final StreamController<BasketCalibration?> _calibrationController =
      StreamController<BasketCalibration?>.broadcast();

  /// Stream of calibration updates
  Stream<BasketCalibration?> get calibrationStream => _calibrationController.stream;

  /// Current stable calibration (null if not yet stable)
  BasketCalibration? _stableCalibration;

  /// Whether calibration is currently active
  bool _isCalibrating = false;

  BasketCalibrationService({
    required PuttDetectionService detectionService,
  }) : _detectionService = detectionService;

  /// Start calibration process
  void startCalibration() {
    _isCalibrating = true;
    _recentDetections.clear();
    _stableCalibration = null;
    debugPrint('[BasketCalibrationService] Calibration started');
  }

  /// Stop calibration process
  void stopCalibration() {
    _isCalibrating = false;
    debugPrint('[BasketCalibrationService] Calibration stopped');
  }

  /// Process a detection result and update calibration state
  Future<BasketCalibration?> processDetection(
    DetectionResult? basketDetection,
    double frameWidth,
  ) async {
    if (!_isCalibrating) return _stableCalibration;

    if (basketDetection == null || basketDetection.confidence < minConfidence) {
      // No valid detection - clear recent detections if too many misses
      if (_recentDetections.length > 2) {
        _recentDetections.clear();
      }
      _emitCalibration(null);
      return null;
    }

    // Create calibration from detection
    final BasketCalibration newCalibration = BasketCalibration.fromDetection(
      left: basketDetection.boundingBox.left,
      top: basketDetection.boundingBox.top,
      right: basketDetection.boundingBox.right,
      bottom: basketDetection.boundingBox.bottom,
      frameWidth: frameWidth,
      confidence: basketDetection.confidence,
    );

    // Check stability
    if (_isStableDetection(newCalibration)) {
      _recentDetections.add(newCalibration);

      if (_recentDetections.length >= requiredConsecutiveDetections) {
        // Calculate average calibration from recent detections
        _stableCalibration = _averageCalibrations(_recentDetections);
        _isCalibrating = false;
        debugPrint(
          '[BasketCalibrationService] Stable calibration achieved: '
          'center=(${_stableCalibration!.centerX.toStringAsFixed(3)}, ${_stableCalibration!.centerY.toStringAsFixed(3)})',
        );
      }
    } else {
      // Detection deviated too much - reset
      _recentDetections.clear();
      _recentDetections.add(newCalibration);
    }

    _emitCalibration(newCalibration);
    return _stableCalibration ?? newCalibration;
  }

  /// Check if new detection is stable compared to recent detections
  bool _isStableDetection(BasketCalibration newCalibration) {
    if (_recentDetections.isEmpty) return true;

    final BasketCalibration last = _recentDetections.last;

    // Check center position deviation
    final double centerXDiff = (newCalibration.centerX - last.centerX).abs();
    final double centerYDiff = (newCalibration.centerY - last.centerY).abs();

    // Check size deviation
    final double widthDiff = (newCalibration.width - last.width).abs();
    final double heightDiff = (newCalibration.height - last.height).abs();

    return centerXDiff < maxDeviation &&
        centerYDiff < maxDeviation &&
        widthDiff < maxDeviation &&
        heightDiff < maxDeviation;
  }

  /// Calculate average calibration from a list of detections
  BasketCalibration _averageCalibrations(List<BasketCalibration> calibrations) {
    if (calibrations.isEmpty) {
      throw StateError('Cannot average empty calibrations list');
    }

    double sumLeft = 0, sumTop = 0, sumRight = 0, sumBottom = 0;
    double sumCenterX = 0, sumCenterY = 0;
    double sumWidthPixels = 0, sumPixelsPerInch = 0;
    double sumConfidence = 0;

    for (final BasketCalibration cal in calibrations) {
      sumLeft += cal.left;
      sumTop += cal.top;
      sumRight += cal.right;
      sumBottom += cal.bottom;
      sumCenterX += cal.centerX;
      sumCenterY += cal.centerY;
      sumWidthPixels += cal.basketWidthPixels;
      sumPixelsPerInch += cal.pixelsPerInch;
      sumConfidence += cal.confidence;
    }

    final int n = calibrations.length;
    return BasketCalibration(
      left: sumLeft / n,
      top: sumTop / n,
      right: sumRight / n,
      bottom: sumBottom / n,
      centerX: sumCenterX / n,
      centerY: sumCenterY / n,
      basketWidthPixels: sumWidthPixels / n,
      pixelsPerInch: sumPixelsPerInch / n,
      confidence: sumConfidence / n,
      userConfirmed: false,
      calibratedAt: DateTime.now(),
    );
  }

  /// Manually set calibration from user-drawn bounding box
  BasketCalibration manualCalibration({
    required double left,
    required double top,
    required double right,
    required double bottom,
    required double frameWidth,
  }) {
    _stableCalibration = BasketCalibration.fromDetection(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      frameWidth: frameWidth,
      confidence: 1.0, // Manual = full confidence
    );

    _isCalibrating = false;
    _emitCalibration(_stableCalibration);

    debugPrint(
      '[BasketCalibrationService] Manual calibration set: '
      'center=(${_stableCalibration!.centerX.toStringAsFixed(3)}, ${_stableCalibration!.centerY.toStringAsFixed(3)})',
    );

    return _stableCalibration!;
  }

  /// Confirm current calibration
  BasketCalibration? confirmCalibration() {
    if (_stableCalibration != null) {
      _stableCalibration = _stableCalibration!.confirm();
      _emitCalibration(_stableCalibration);
    }
    return _stableCalibration;
  }

  /// Get current stable calibration
  BasketCalibration? get currentCalibration => _stableCalibration;

  /// Whether we have a stable calibration
  bool get hasStableCalibration => _stableCalibration != null;

  /// Whether calibration is in progress
  bool get isCalibrating => _isCalibrating;

  /// Emit calibration update
  void _emitCalibration(BasketCalibration? calibration) {
    if (!_calibrationController.isClosed) {
      _calibrationController.add(calibration);
    }
  }

  /// Reset calibration
  void reset() {
    _recentDetections.clear();
    _stableCalibration = null;
    _isCalibrating = false;
    _emitCalibration(null);
  }

  /// Dispose resources
  void dispose() {
    _calibrationController.close();
  }
}
