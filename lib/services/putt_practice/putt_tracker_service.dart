import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/basket_calibration.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/detected_putt_attempt.dart';
import 'package:turbo_disc_golf/services/putt_practice/motion_detection_service.dart';
import 'package:turbo_disc_golf/services/putt_practice/putt_detection_service.dart';
import 'package:turbo_disc_golf/services/putt_practice/frame_processor_service.dart';
import 'package:turbo_disc_golf/utils/constants/putting_constants.dart';

/// States for the hybrid putt tracking state machine
///
/// This uses exit-based detection for misses and disappearance-based
/// detection for makes, which works better with typical camera angles
/// where the basket bucket is often occluded.
enum PuttTrackingState {
  /// Waiting for a valid putt attempt to begin
  idle,

  /// Disc detected and validated as a real putt attempt
  /// (originated outside basket, moving toward basket)
  discInFlight,

  /// Disc has entered the basket zone - watching for exit or disappearance
  basketInteraction,

  /// Post-resolution cooldown to prevent double-counting
  cooldown,
}

/// Tracked position of the disc with velocity data
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

  /// Calculate velocity from this position to another (pixels per second)
  Offset velocityTo(_DiscPosition other) {
    final Duration dt = other.timestamp.difference(timestamp);
    if (dt.inMilliseconds == 0) return Offset.zero;

    final double seconds = dt.inMilliseconds / 1000.0;
    return Offset((other.x - x) / seconds, (other.y - y) / seconds);
  }
}

/// Service for tracking putt attempts using a hybrid detection approach
///
/// Key insight: The basket bucket is often NOT visible from typical camera
/// angles (phone on tripod, slightly below basket level). Instead of trying
/// to detect disc entry into the bucket, we focus on:
///
/// 1. MAKE detection: Disc enters basket zone and DISAPPEARS (no visible exit)
/// 2. MISS detection: Disc enters basket zone and EXITS visibly (upward or lateral)
///
/// This hybrid approach works with what we CAN see (exits) rather than
/// what we often CAN'T see (bucket entry).
class PuttTrackerService {
  final PuttDetectionService _detectionService = PuttDetectionService();
  final MotionDetectionService _motionDetectionService =
      MotionDetectionService();
  late final FrameProcessorService _frameProcessor;

  /// Current tracking state
  PuttTrackingState _state = PuttTrackingState.idle;

  /// Basket calibration
  BasketCalibration? _calibration;

  /// Recent disc positions for trajectory analysis
  final List<_DiscPosition> _discPositions = [];

  /// Maximum positions to track for trajectory
  static const int maxPositionHistory = 15;

  /// Minimum frames to validate a putt attempt
  static const int minFramesForAttempt = 3;

  /// Minimum velocity toward basket to count as attempt (normalized units/sec)
  static const double minVelocityThreshold = 0.3;

  /// Time threshold for disappearance-based make detection (milliseconds)
  /// If disc vanishes in basket zone for this long without exit, it's a make
  static const int makeDisappearanceThresholdMs = 600;

  /// Cooldown duration after putt resolution (milliseconds)
  static const int cooldownDurationMs = 1500;

  /// Expanded basket zone for interaction detection (normalized units)
  /// Slightly larger than calibrated bounds to catch near-misses
  static const double basketZoneExpansion = 0.05;

  /// Threshold for detecting lateral exit velocity
  static const double lateralExitThreshold = 0.4;

  /// When disc last entered basket zone
  DateTime? _basketEntryTime;

  /// Frames since disc was last visible
  int _framesSinceVisible = 0;

  /// Cooldown end time
  DateTime? _cooldownEndTime;

  /// Stream controller for putt detections
  final StreamController<DetectedPuttAttempt> _puttController =
      StreamController<DetectedPuttAttempt>.broadcast();

  /// Stream controller for motion debug boxes
  final StreamController<List<Rect>> _motionDebugController =
      StreamController<List<Rect>>.broadcast();

  /// Stream of detected putt attempts
  Stream<DetectedPuttAttempt> get puttStream => _puttController.stream;

  /// Stream of motion boxes for debug overlay
  Stream<List<Rect>> get motionDebugStream => _motionDebugController.stream;

  /// Current tracking state
  PuttTrackingState get state => _state;

  /// Frame counter for current tracking session
  int _frameCount = 0;

  /// Rate limiting for frame processing
  DateTime? _lastProcessedTime;
  static const int _targetFps = 15; // Higher FPS now that ML runs on isolate
  static final Duration _minFrameInterval = Duration(
    milliseconds: (1000 / _targetFps).round(),
  );

  /// FPS tracking for diagnostics
  int _fpsFrameCount = 0;
  DateTime? _fpsStartTime;
  double _lastReportedFps = 0;
  final List<int> _frameTimes = []; // Track individual frame processing times

  /// Whether the service has been disposed
  bool _isDisposed = false;

  /// Last detected disc bounding box (for persistence)
  Rect? _lastDiscBox;
  DateTime? _lastDiscDetectionTime;

  /// How long to keep showing the last detection box (milliseconds)
  static const int _detectionPersistenceMs = 500;

  PuttTrackerService() {
    _frameProcessor = FrameProcessorService(
      detectionService: _detectionService,
      targetFps: _targetFps,
    );
  }

  /// Initialize the tracker
  Future<void> initialize() async {
    if (useMLDiscDetection) {
      await _detectionService.initialize();
      debugPrint('[PuttTrackerService] Initialized with ML detection');
    } else {
      debugPrint('[PuttTrackerService] Initialized with motion detection');
    }
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
    // Skip if disposed
    if (_isDisposed) {
      return;
    }

    if (_calibration == null) {
      return;
    }

    // Rate limiting - skip frames to maintain target fps
    final DateTime now = DateTime.now();
    if (_lastProcessedTime != null &&
        now.difference(_lastProcessedTime!) < _minFrameInterval) {
      return;
    }
    _lastProcessedTime = now;

    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      _frameCount++;
      _fpsFrameCount++;

      // Initialize FPS tracking
      _fpsStartTime ??= now;

      // Convert image to bytes based on platform
      final Stopwatch extractWatch = Stopwatch()..start();
      final Uint8List? imageBytes = _extractImageBytes(image);
      extractWatch.stop();

      if (imageBytes == null) {
        return;
      }

      final int extractMs = extractWatch.elapsedMilliseconds;

      if (useMLDiscDetection) {
        // Use ML-based detection
        final Stopwatch mlWatch = Stopwatch()..start();
        await _processWithMLDetection(imageBytes, image.width, image.height);
        mlWatch.stop();

        stopwatch.stop();
        _frameTimes.add(stopwatch.elapsedMilliseconds);

        // Keep only last 30 frame times
        while (_frameTimes.length > 30) {
          _frameTimes.removeAt(0);
        }

        // Log FPS every second
        final int elapsedMs = now.difference(_fpsStartTime!).inMilliseconds;
        if (elapsedMs >= 1000) {
          _lastReportedFps = _fpsFrameCount * 1000.0 / elapsedMs;
          final double avgFrameTime = _frameTimes.isEmpty
              ? 0
              : _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;

          debugPrint('[PuttTrackerService] ===== FPS REPORT =====');
          debugPrint(
            '[PuttTrackerService] Actual FPS: ${_lastReportedFps.toStringAsFixed(1)}',
          );
          debugPrint('[PuttTrackerService] Target FPS: $_targetFps');
          debugPrint(
            '[PuttTrackerService] Avg frame time: ${avgFrameTime.toStringAsFixed(1)}ms',
          );
          debugPrint(
            '[PuttTrackerService] Last frame: extract=${extractMs}ms, ML=${mlWatch.elapsedMilliseconds}ms, total=${stopwatch.elapsedMilliseconds}ms',
          );
          debugPrint(
            '[PuttTrackerService] Frames processed: $_fpsFrameCount in ${elapsedMs}ms',
          );
          debugPrint('[PuttTrackerService] =====================');

          _fpsFrameCount = 0;
          _fpsStartTime = now;
        }
      } else {
        // Use motion-based detection
        _processWithMotionDetection(imageBytes, image.width, image.height);
      }
    } catch (e) {
      debugPrint('[PuttTrackerService] Error processing frame: $e');
    }
  }

  /// Process frame using ML-based disc detection
  Future<void> _processWithMLDetection(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    // Log every 30 frames to confirm processing
    if (_frameCount % 30 == 0) {
      debugPrint(
        '[PuttTrackerService] Processing frame $_frameCount (ML mode, ${width}x$height)',
      );
    }

    final List<DetectionResult> detections = await _detectionService.detect(
      imageBytes,
      width,
      height,
    );

    // Find the single highest-confidence disc detection
    final DetectionResult? discDetection = _findBestDiscDetection(detections);

    // Update bounding box with persistence
    final DateTime now = DateTime.now();
    if (discDetection != null) {
      // New detection - update the stored box
      _lastDiscBox = discDetection.boundingBox;
      _lastDiscDetectionTime = now;
    }

    // Emit detection box for debug overlay (with persistence)
    if (!_motionDebugController.isClosed) {
      Rect? boxToShow;

      if (_lastDiscBox != null && _lastDiscDetectionTime != null) {
        final int msSinceDetection = now.difference(_lastDiscDetectionTime!).inMilliseconds;
        if (msSinceDetection < _detectionPersistenceMs) {
          boxToShow = _lastDiscBox;
        } else {
          // Detection expired - clear it
          _lastDiscBox = null;
          _lastDiscDetectionTime = null;
        }
      }

      _motionDebugController.add(boxToShow != null ? [boxToShow] : []);
    }

    // Update state machine
    _updateState(discDetection: discDetection);
  }

  /// Process frame using motion-based detection
  void _processWithMotionDetection(
    Uint8List imageBytes,
    int width,
    int height,
  ) {
    // Get motion boxes
    final List<Rect> motionBoxes = _motionDetectionService.detectMotion(
      imageBytes,
      width,
      height,
    );

    // Emit motion boxes for debug overlay
    if (!_motionDebugController.isClosed) {
      _motionDebugController.add(motionBoxes);
    }

    // Find the primary moving object (largest or fastest)
    final Rect? primaryMotion = _findPrimaryMotion(motionBoxes);

    // Convert motion box to detection result format for state machine
    DetectionResult? detection;
    if (primaryMotion != null) {
      detection = DetectionResult(
        label: 'motion',
        confidence: 0.8, // Default confidence for motion detection
        boundingBox: primaryMotion,
      );
    }

    // Update state machine
    _updateState(discDetection: detection);
  }

  /// Find the primary motion (largest box, assumed to be the disc)
  Rect? _findPrimaryMotion(List<Rect> motionBoxes) {
    if (motionBoxes.isEmpty) return null;

    // Return the largest motion box (already sorted by area in the service)
    return motionBoxes.first;
  }

  /// Extract image bytes based on platform format
  Uint8List? _extractImageBytes(CameraImage image) {
    try {
      if (image.planes.isEmpty) {
        return null;
      }

      if (Platform.isIOS) {
        // iOS uses BGRA8888 format - convert to grayscale
        return _convertBgraToGrayscale(image);
      } else {
        // Android uses YUV420 format - use Y plane directly
        return image.planes[0].bytes;
      }
    } catch (e) {
      debugPrint('[PuttTrackerService] Error extracting image bytes: $e');
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
        return null;
      }

      final Uint8List grayscale = Uint8List(width * height);
      final Uint8List bgraBytes = plane.bytes;
      final int bytesPerRow = plane.bytesPerRow;

      int grayscaleIndex = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int pixelIndex = y * bytesPerRow + x * 4;
          if (pixelIndex + 2 < bgraBytes.length) {
            final int b = bgraBytes[pixelIndex];
            final int g = bgraBytes[pixelIndex + 1];
            final int r = bgraBytes[pixelIndex + 2];
            grayscale[grayscaleIndex] =
                ((0.299 * r) + (0.587 * g) + (0.114 * b)).round().clamp(0, 255);
          }
          grayscaleIndex++;
        }
      }
      return grayscale;
    } catch (e) {
      debugPrint('[PuttTrackerService] Error converting BGRA to grayscale: $e');
      return null;
    }
  }

  /// Find disc detection from results
  /// Find the single highest-confidence disc detection
  DetectionResult? _findBestDiscDetection(List<DetectionResult> detections) {
    DetectionResult? bestDisc;

    for (final DetectionResult detection in detections) {
      if (detection.label == 'flying_disc' ||
          detection.label == 'disc' ||
          detection.label == 'motion') {
        if (bestDisc == null || detection.confidence > bestDisc.confidence) {
          bestDisc = detection;
        }
      }
    }

    return bestDisc;
  }

  /// Update the state machine based on detections
  void _updateState({DetectionResult? discDetection}) {
    final DateTime now = DateTime.now();

    switch (_state) {
      case PuttTrackingState.idle:
        _handleIdleState(discDetection, now);
        break;

      case PuttTrackingState.discInFlight:
        _handleDiscInFlightState(discDetection, now);
        break;

      case PuttTrackingState.basketInteraction:
        _handleBasketInteractionState(discDetection, now);
        break;

      case PuttTrackingState.cooldown:
        _handleCooldownState(now);
        break;
    }
  }

  /// Handle IDLE state - waiting for valid putt attempt
  void _handleIdleState(DetectionResult? discDetection, DateTime now) {
    if (discDetection == null) {
      _discPositions.clear();
      return;
    }

    final Offset center = discDetection.boundingBox.center;
    final _DiscPosition position = _DiscPosition(
      x: center.dx,
      y: center.dy,
      timestamp: now,
      confidence: discDetection.confidence,
    );

    // Check if disc originated OUTSIDE the basket zone
    if (_isInBasketZone(center)) {
      // Disc is in basket zone - could be retrieval, ignore
      _discPositions.clear();
      return;
    }

    _discPositions.add(position);
    _trimPositionHistory();

    // Need minimum frames to validate trajectory
    if (_discPositions.length < minFramesForAttempt) {
      return;
    }

    // Check if disc is moving toward basket
    if (_isValidPuttAttempt()) {
      _state = PuttTrackingState.discInFlight;
      _framesSinceVisible = 0;
      debugPrint(
        '[PuttTrackerService] State: IDLE -> DISC_IN_FLIGHT (valid attempt)',
      );
    }
  }

  /// Handle DISC_IN_FLIGHT state - tracking valid attempt toward basket
  void _handleDiscInFlightState(DetectionResult? discDetection, DateTime now) {
    if (discDetection != null) {
      final Offset center = discDetection.boundingBox.center;
      final _DiscPosition position = _DiscPosition(
        x: center.dx,
        y: center.dy,
        timestamp: now,
        confidence: discDetection.confidence,
      );

      _discPositions.add(position);
      _trimPositionHistory();
      _framesSinceVisible = 0;

      // Check if disc has entered basket zone
      if (_isInBasketZone(center)) {
        _state = PuttTrackingState.basketInteraction;
        _basketEntryTime = now;
        debugPrint(
          '[PuttTrackerService] State: DISC_IN_FLIGHT -> BASKET_INTERACTION',
        );
      }
    } else {
      // Disc not visible
      _framesSinceVisible++;

      // If disc disappears before reaching basket, attempt is abandoned
      if (_framesSinceVisible > 10) {
        debugPrint(
          '[PuttTrackerService] Attempt abandoned (disc lost before basket)',
        );
        _resetToIdle();
      }
    }
  }

  /// Handle BASKET_INTERACTION state - watching for exit or disappearance
  void _handleBasketInteractionState(
    DetectionResult? discDetection,
    DateTime now,
  ) {
    if (discDetection != null) {
      final Offset center = discDetection.boundingBox.center;
      final _DiscPosition position = _DiscPosition(
        x: center.dx,
        y: center.dy,
        timestamp: now,
        confidence: discDetection.confidence,
      );

      _discPositions.add(position);
      _trimPositionHistory();
      _framesSinceVisible = 0;

      // Check for visible EXIT from basket zone
      if (!_isInBasketZone(center)) {
        // Disc exited basket zone - this is a MISS
        // Could be lateral deflection off chains or spit-out back toward thrower
        final (double relX, double relY) = _calculateExitDirection(position);
        _recordPutt(made: false, relativeX: relX, relativeY: relY);
        _enterCooldown(now);
        debugPrint(
          '[PuttTrackerService] State: BASKET_INTERACTION -> COOLDOWN (MISS - visible exit)',
        );
        return;
      }
    } else {
      // Disc not visible while in basket zone
      _framesSinceVisible++;

      // Check for disappearance-based MAKE
      if (_basketEntryTime != null) {
        final int msInBasket = now.difference(_basketEntryTime!).inMilliseconds;
        if (msInBasket >= makeDisappearanceThresholdMs &&
            _framesSinceVisible >= 3) {
          // Disc disappeared in basket zone without visible exit = MAKE
          _recordPutt(made: true, relativeX: 0, relativeY: 0);
          _enterCooldown(now);
          debugPrint(
            '[PuttTrackerService] State: BASKET_INTERACTION -> COOLDOWN (MAKE - disappeared)',
          );
          return;
        }
      }

      // Extended invisibility without confirmed make - could be occlusion
      if (_framesSinceVisible > 20) {
        // Assume make if disc was last seen in basket zone and vanished
        _recordPutt(made: true, relativeX: 0, relativeY: 0);
        _enterCooldown(now);
        debugPrint(
          '[PuttTrackerService] State: BASKET_INTERACTION -> COOLDOWN (MAKE - extended disappearance)',
        );
      }
    }
  }

  /// Handle COOLDOWN state - prevent double-counting
  void _handleCooldownState(DateTime now) {
    if (_cooldownEndTime != null && now.isAfter(_cooldownEndTime!)) {
      _state = PuttTrackingState.idle;
      _cooldownEndTime = null;
      debugPrint('[PuttTrackerService] State: COOLDOWN -> IDLE');
    }
  }

  /// Check if position is within expanded basket zone
  bool _isInBasketZone(Offset position) {
    if (_calibration == null) return false;

    final double left = _calibration!.left - basketZoneExpansion;
    final double right = _calibration!.right + basketZoneExpansion;
    final double top = _calibration!.top - basketZoneExpansion;
    final double bottom = _calibration!.bottom + basketZoneExpansion;

    return position.dx >= left &&
        position.dx <= right &&
        position.dy >= top &&
        position.dy <= bottom;
  }

  /// Validate that current trajectory is a real putt attempt
  bool _isValidPuttAttempt() {
    if (_discPositions.length < minFramesForAttempt) return false;
    if (_calibration == null) return false;

    // Calculate average velocity over recent positions
    final _DiscPosition first =
        _discPositions[_discPositions.length - minFramesForAttempt];
    final _DiscPosition last = _discPositions.last;
    final Offset velocity = first.velocityTo(last);

    // Check if moving toward basket (basket is typically in upper half of frame)
    final double basketCenterX = _calibration!.centerX;
    final double basketCenterY = _calibration!.centerY;

    final double dx = basketCenterX - last.x;
    final double dy = basketCenterY - last.y;

    // Velocity should be in direction of basket
    final bool movingTowardX =
        (dx > 0 && velocity.dx > 0) ||
        (dx < 0 && velocity.dx < 0) ||
        dx.abs() < 0.1;
    final bool movingTowardY =
        (dy > 0 && velocity.dy > 0) ||
        (dy < 0 && velocity.dy < 0) ||
        dy.abs() < 0.1;

    // Check minimum velocity
    final double speed =
        (velocity.dx * velocity.dx + velocity.dy * velocity.dy);
    final bool hasMinVelocity =
        speed > minVelocityThreshold * minVelocityThreshold;

    return (movingTowardX || movingTowardY) && hasMinVelocity;
  }

  /// Calculate exit direction for miss position recording
  (double, double) _calculateExitDirection(_DiscPosition exitPosition) {
    if (_calibration == null) return (0, 0);

    // Get position relative to basket center
    final (double relX, double relY) = _calibration!.pixelToRelative(
      exitPosition.x,
      exitPosition.y,
    );

    return (relX.clamp(-1.5, 1.5), relY.clamp(-1.5, 1.5));
  }

  /// Record a putt attempt
  void _recordPutt({
    required bool made,
    required double relativeX,
    required double relativeY,
  }) {
    // Calculate average confidence from tracked positions
    final double avgConfidence = _discPositions.isEmpty
        ? 0.5
        : _discPositions.map((p) => p.confidence).reduce((a, b) => a + b) /
              _discPositions.length;

    final DetectedPuttAttempt attempt = DetectedPuttAttempt(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      made: made,
      relativeX: relativeX,
      relativeY: relativeY,
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

  /// Enter cooldown state
  void _enterCooldown(DateTime now) {
    _state = PuttTrackingState.cooldown;
    _cooldownEndTime = now.add(
      const Duration(milliseconds: cooldownDurationMs),
    );
    _discPositions.clear();
    _basketEntryTime = null;
    _framesSinceVisible = 0;
  }

  /// Reset to idle state
  void _resetToIdle() {
    _state = PuttTrackingState.idle;
    _discPositions.clear();
    _basketEntryTime = null;
    _framesSinceVisible = 0;
  }

  /// Trim position history to max size
  void _trimPositionHistory() {
    while (_discPositions.length > maxPositionHistory) {
      _discPositions.removeAt(0);
    }
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
    _basketEntryTime = null;
    _cooldownEndTime = null;
    _framesSinceVisible = 0;
    _frameCount = 0;
    _motionDetectionService.reset();
  }

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('[PuttTrackerService] Disposing...');
    _isDisposed = true;
    _frameProcessor.dispose();
    await _detectionService.dispose();
    _motionDetectionService.dispose();
    _puttController.close();
    _motionDebugController.close();
    debugPrint('[PuttTrackerService] Disposed');
  }
}
