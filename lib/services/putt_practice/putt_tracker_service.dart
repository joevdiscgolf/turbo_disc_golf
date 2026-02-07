import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/basket_calibration.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/detected_putt_attempt.dart';
import 'package:turbo_disc_golf/services/putt_practice/putt_detection_service.dart';
import 'package:turbo_disc_golf/services/putt_practice/frame_processor_service.dart';

/// States for the putt tracking state machine
enum PuttTrackingState {
  /// Waiting for a disc to appear
  idle,

  /// Disc detected and moving toward basket
  discInFlight,

  /// Putt was made (disc entered basket zone)
  made,

  /// Putt was missed (disc exited frame or landed outside basket)
  missed,
}

/// Tracked position of the disc
class _DiscPosition {
  final double x;
  final double y;
  final DateTime timestamp;
  final double confidence;

  _DiscPosition({
    required this.x,
    required this.y,
    required this.timestamp,
    required this.confidence,
  });
}

/// Service for tracking putt attempts using a state machine
class PuttTrackerService {
  final PuttDetectionService _detectionService = PuttDetectionService();
  late final FrameProcessorService _frameProcessor;

  /// Current tracking state
  PuttTrackingState _state = PuttTrackingState.idle;

  /// Basket calibration
  BasketCalibration? _calibration;

  /// Recent disc positions for trajectory analysis
  final List<_DiscPosition> _discPositions = [];

  /// Maximum positions to track
  static const int maxPositionHistory = 10;

  /// Minimum frames to track before determining result
  static const int minFramesForResult = 3;

  /// Time threshold for disc in chains detection (milliseconds)
  static const int madeDetectionThresholdMs = 500;

  /// Distance threshold for "in basket" detection (normalized units)
  static const double basketProximityThreshold = 0.15;

  /// Timestamp when disc was last detected near basket
  DateTime? _discNearBasketTime;

  /// Last detected disc position (for miss position recording)
  _DiscPosition? _lastDiscPosition;

  /// Stream controller for putt detections
  final StreamController<DetectedPuttAttempt> _puttController =
      StreamController<DetectedPuttAttempt>.broadcast();

  /// Stream of detected putt attempts
  Stream<DetectedPuttAttempt> get puttStream => _puttController.stream;

  /// Current tracking state
  PuttTrackingState get state => _state;

  /// Frame counter for current tracking session
  int _frameCount = 0;

  PuttTrackerService() {
    _frameProcessor = FrameProcessorService(
      detectionService: _detectionService,
      targetFps: 15,
    );
  }

  /// Initialize the tracker
  Future<void> initialize() async {
    await _detectionService.initialize();
    debugPrint('[PuttTrackerService] Initialized');
  }

  /// Set the basket calibration
  void setCalibration(BasketCalibration calibration) {
    _calibration = calibration;
    debugPrint(
      '[PuttTrackerService] Calibration set: '
      'center=(${calibration.centerX.toStringAsFixed(3)}, ${calibration.centerY.toStringAsFixed(3)})',
    );
  }

  /// Process a camera frame
  Future<void> processFrame(CameraImage image) async {
    if (_calibration == null) {
      debugPrint('[PuttTrackerService] Cannot process frame - no calibration');
      return;
    }

    _frameCount++;

    // Convert image to bytes
    final Plane yPlane = image.planes[0];
    final List<DetectionResult> detections = await _detectionService.detect(
      yPlane.bytes,
      image.width,
      image.height,
    );

    // Find disc detection
    final DetectionResult? discDetection = _findDiscDetection(detections);

    // Find disc in chains detection (indicates made putt)
    final DetectionResult? discInChains = _findDiscInChainsDetection(detections);

    // Update state machine
    _updateState(
      discDetection: discDetection,
      discInChains: discInChains,
    );
  }

  /// Find disc detection from results
  DetectionResult? _findDiscDetection(List<DetectionResult> detections) {
    for (final DetectionResult detection in detections) {
      if (detection.label == 'flying_disc') {
        return detection;
      }
    }
    return null;
  }

  /// Find disc in chains detection from results
  DetectionResult? _findDiscInChainsDetection(List<DetectionResult> detections) {
    for (final DetectionResult detection in detections) {
      if (detection.label == 'disc_in_chains') {
        return detection;
      }
    }
    return null;
  }

  /// Update the state machine based on detections
  void _updateState({
    DetectionResult? discDetection,
    DetectionResult? discInChains,
  }) {
    final DateTime now = DateTime.now();

    switch (_state) {
      case PuttTrackingState.idle:
        if (discDetection != null) {
          // Disc detected - start tracking
          _state = PuttTrackingState.discInFlight;
          _discPositions.clear();
          _addDiscPosition(discDetection, now);
          debugPrint('[PuttTrackerService] State: IDLE -> DISC_IN_FLIGHT');
        }
        break;

      case PuttTrackingState.discInFlight:
        if (discInChains != null) {
          // Disc detected in chains - putt made!
          _recordPutt(made: true, position: discInChains.boundingBox.center);
          _state = PuttTrackingState.made;
          debugPrint('[PuttTrackerService] State: DISC_IN_FLIGHT -> MADE');
          _resetToIdle();
        } else if (discDetection != null) {
          // Disc still visible - update position
          _addDiscPosition(discDetection, now);

          // Check if disc is near basket
          final double distToBasket = _calculateDistanceToBasket(
            discDetection.boundingBox.center,
          );

          if (distToBasket < basketProximityThreshold) {
            // Disc near basket - start timer
            _discNearBasketTime ??= now;

            // If disc has been near basket for threshold duration, count as made
            if (now.difference(_discNearBasketTime!).inMilliseconds >
                madeDetectionThresholdMs) {
              _recordPutt(made: true, position: discDetection.boundingBox.center);
              _state = PuttTrackingState.made;
              debugPrint('[PuttTrackerService] State: DISC_IN_FLIGHT -> MADE (proximity)');
              _resetToIdle();
            }
          } else {
            _discNearBasketTime = null;
          }
        } else {
          // Disc no longer visible
          if (_discPositions.length >= minFramesForResult) {
            // We have enough data - determine if it was a miss
            _recordPutt(made: false, position: _getLastDiscPosition());
            _state = PuttTrackingState.missed;
            debugPrint('[PuttTrackerService] State: DISC_IN_FLIGHT -> MISSED');
          }
          _resetToIdle();
        }
        break;

      case PuttTrackingState.made:
      case PuttTrackingState.missed:
        // Transitional states - reset handled by _resetToIdle
        break;
    }
  }

  /// Add a disc position to the history
  void _addDiscPosition(DetectionResult detection, DateTime timestamp) {
    final Offset center = detection.boundingBox.center;
    _lastDiscPosition = _DiscPosition(
      x: center.dx,
      y: center.dy,
      timestamp: timestamp,
      confidence: detection.confidence,
    );
    _discPositions.add(_lastDiscPosition!);

    // Trim history
    if (_discPositions.length > maxPositionHistory) {
      _discPositions.removeAt(0);
    }
  }

  /// Get the last known disc position
  Offset _getLastDiscPosition() {
    if (_lastDiscPosition != null) {
      return Offset(_lastDiscPosition!.x, _lastDiscPosition!.y);
    }
    if (_discPositions.isNotEmpty) {
      final _DiscPosition last = _discPositions.last;
      return Offset(last.x, last.y);
    }
    return Offset.zero;
  }

  /// Calculate distance from disc to basket center (normalized units)
  double _calculateDistanceToBasket(Offset discPosition) {
    if (_calibration == null) return double.infinity;

    final double dx = discPosition.dx - _calibration!.centerX;
    final double dy = discPosition.dy - _calibration!.centerY;
    return (dx * dx + dy * dy);
  }

  /// Record a putt attempt
  void _recordPutt({required bool made, required Offset position}) {
    if (_calibration == null) return;

    // Convert position to relative coordinates
    final (double relX, double relY) = _calibration!.pixelToRelative(
      position.dx,
      position.dy,
    );

    // Clamp to reasonable range
    final double clampedX = relX.clamp(-2.0, 2.0);
    final double clampedY = relY.clamp(-2.0, 2.0);

    // Calculate average confidence from tracked positions
    final double avgConfidence = _discPositions.isEmpty
        ? 0.5
        : _discPositions.map((p) => p.confidence).reduce((a, b) => a + b) /
            _discPositions.length;

    final DetectedPuttAttempt attempt = DetectedPuttAttempt(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      made: made,
      relativeX: made ? 0.0 : clampedX,
      relativeY: made ? 0.0 : clampedY,
      confidence: avgConfidence,
      frameNumber: _frameCount,
    );

    debugPrint(
      '[PuttTrackerService] Putt recorded: ${made ? "MADE" : "MISSED"} '
      'at (${attempt.relativeX.toStringAsFixed(2)}, ${attempt.relativeY.toStringAsFixed(2)}) '
      'confidence: ${avgConfidence.toStringAsFixed(2)}',
    );

    if (!_puttController.isClosed) {
      _puttController.add(attempt);
    }
  }

  /// Reset to idle state
  void _resetToIdle() {
    // Small delay before returning to idle to prevent immediate re-detection
    Future.delayed(const Duration(milliseconds: 500), () {
      _state = PuttTrackingState.idle;
      _discPositions.clear();
      _discNearBasketTime = null;
      _lastDiscPosition = null;
    });
  }

  /// Start tracking
  void start() {
    _frameProcessor.start();
    debugPrint('[PuttTrackerService] Tracking started');
  }

  /// Stop tracking
  void stop() {
    _frameProcessor.stop();
    debugPrint('[PuttTrackerService] Tracking stopped');
  }

  /// Reset tracker state
  void reset() {
    _state = PuttTrackingState.idle;
    _discPositions.clear();
    _discNearBasketTime = null;
    _lastDiscPosition = null;
    _frameCount = 0;
  }

  /// Dispose resources
  void dispose() {
    _frameProcessor.dispose();
    _detectionService.dispose();
    _puttController.close();
  }
}
