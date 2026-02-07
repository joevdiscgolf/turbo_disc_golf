import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/basket_calibration.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/detected_putt_attempt.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/putt_practice_session.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_putt_practice_data_loader.dart';
import 'package:turbo_disc_golf/services/putt_practice/putt_tracker_service.dart';
import 'package:turbo_disc_golf/state/putt_practice_history_cubit.dart';
import 'package:turbo_disc_golf/state/putt_practice_state.dart';

/// Cubit for managing putt practice session workflow
class PuttPracticeCubit extends Cubit<PuttPracticeState>
    implements ClearOnLogoutProtocol {
  PuttPracticeCubit() : super(const PuttPracticeInitial());

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  StreamSubscription<DetectedPuttAttempt>? _puttSubscription;
  PuttTrackerService? _trackerService;

  /// Initialize the camera for putt tracking
  Future<void> initializeCamera() async {
    emit(const PuttPracticeCameraInitializing(message: 'Initializing camera...'));

    try {
      // Get available cameras with timeout
      _cameras = await availableCameras().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Camera list timeout'),
      );
      if (_cameras == null || _cameras!.isEmpty) {
        emit(const PuttPracticeError(message: 'No cameras available'));
        return;
      }

      // Find the back camera (preferred for this use case)
      final CameraDescription backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // Initialize camera controller with medium resolution for performance
      // Use platform-specific image format: bgra8888 for iOS, yuv420 for Android
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );

      // Initialize with timeout to prevent hanging
      await _cameraController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Camera initialization timeout'),
      );

      if (!_cameraController!.value.isInitialized) {
        emit(const PuttPracticeError(message: 'Camera failed to initialize'));
        return;
      }

      emit(PuttPracticeCameraReady(cameraController: _cameraController!));
    } on TimeoutException catch (e) {
      debugPrint('[PuttPracticeCubit] Camera initialization timed out: $e');
      emit(const PuttPracticeError(message: 'Camera took too long to initialize. Please try again.'));
    } catch (e) {
      debugPrint('[PuttPracticeCubit] Camera initialization failed: $e');
      emit(PuttPracticeError(message: 'Failed to initialize camera: $e'));
    }
  }

  /// Start basket calibration
  Future<void> startCalibration() async {
    final PuttPracticeState currentState = state;
    if (currentState is! PuttPracticeCameraReady &&
        currentState is! PuttPracticeCalibrating) {
      debugPrint('[PuttPracticeCubit] Cannot start calibration from state: $currentState');
      return;
    }

    final CameraController controller = currentState is PuttPracticeCameraReady
        ? currentState.cameraController
        : (currentState as PuttPracticeCalibrating).cameraController;

    emit(PuttPracticeCalibrating(
      cameraController: controller,
      message: 'Point camera at basket...',
    ));

    // Initialize tracker service for calibration
    _trackerService = PuttTrackerService();

    // Start listening for basket detection
    // The frame processor will emit basket detections
    _startFrameProcessing();
  }

  /// Update calibration with detected basket
  void updateCalibration(BasketCalibration? basket) {
    final PuttPracticeState currentState = state;
    if (currentState is! PuttPracticeCalibrating) return;

    if (basket != null && basket.confidence > 0.7) {
      emit(PuttPracticeCalibrating(
        cameraController: currentState.cameraController,
        detectedBasket: basket,
        message: 'Basket detected! Tap to confirm.',
      ));
    }
  }

  /// Confirm the calibration and start the session
  Future<void> confirmCalibration() async {
    final PuttPracticeState currentState = state;
    if (currentState is! PuttPracticeCalibrating) return;

    final BasketCalibration? basket = currentState.detectedBasket;
    if (basket == null) {
      emit(PuttPracticeCalibrating(
        cameraController: currentState.cameraController,
        message: 'Please wait for basket detection...',
      ));
      return;
    }

    final AuthService authService = locator.get<AuthService>();
    final String? uid = authService.currentUid;
    if (uid == null) {
      emit(const PuttPracticeError(message: 'User not authenticated'));
      return;
    }

    // Create new session
    final PuttPracticeSession session = PuttPracticeSession(
      id: const Uuid().v4(),
      uid: uid,
      createdAt: DateTime.now(),
      status: PuttPracticeSessionStatus.active,
      calibration: basket.confirm(),
      attempts: [],
    );

    // Set up tracker service with confirmed calibration
    _trackerService?.setCalibration(basket.confirm());

    // Start listening for putt detections
    _puttSubscription = _trackerService?.puttStream.listen(_onPuttDetected);

    emit(PuttPracticeActive(
      cameraController: currentState.cameraController,
      session: session,
    ));
  }

  /// Handle detected putt attempt
  void _onPuttDetected(DetectedPuttAttempt attempt) {
    final PuttPracticeState currentState = state;
    if (currentState is! PuttPracticeActive) return;

    final PuttPracticeSession updatedSession = currentState.session.addAttempt(attempt);

    emit(PuttPracticeActive(
      cameraController: currentState.cameraController,
      session: updatedSession,
      lastDetectedAttempt: attempt,
    ));

    debugPrint(
      '[PuttPracticeCubit] Putt detected: ${attempt.made ? "MADE" : "MISSED"} '
      'at (${attempt.relativeX.toStringAsFixed(2)}, ${attempt.relativeY.toStringAsFixed(2)})',
    );
  }

  /// Manually record a putt attempt (for testing/override)
  void recordManualPutt({required bool made, double? relativeX, double? relativeY}) {
    final PuttPracticeState currentState = state;
    if (currentState is! PuttPracticeActive) return;

    final DetectedPuttAttempt attempt = DetectedPuttAttempt(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      made: made,
      relativeX: relativeX ?? 0.0,
      relativeY: relativeY ?? 0.0,
      confidence: 1.0, // Manual entry = full confidence
    );

    _onPuttDetected(attempt);
  }

  /// Pause the session
  void pauseSession() {
    final PuttPracticeState currentState = state;
    if (currentState is! PuttPracticeActive) return;

    _stopFrameProcessing();

    emit(PuttPracticePaused(
      cameraController: currentState.cameraController,
      session: currentState.session.copyWith(
        status: PuttPracticeSessionStatus.paused,
      ),
    ));
  }

  /// Resume the session
  void resumeSession() {
    final PuttPracticeState currentState = state;
    if (currentState is! PuttPracticePaused) return;

    _startFrameProcessing();

    emit(PuttPracticeActive(
      cameraController: currentState.cameraController,
      session: currentState.session.copyWith(
        status: PuttPracticeSessionStatus.active,
      ),
    ));
  }

  /// End the session and show summary
  Future<void> endSession() async {
    final PuttPracticeState currentState = state;
    PuttPracticeSession? session;

    if (currentState is PuttPracticeActive) {
      session = currentState.session;
    } else if (currentState is PuttPracticePaused) {
      session = currentState.session;
    }

    if (session == null) return;

    _stopFrameProcessing();
    await _puttSubscription?.cancel();
    _puttSubscription = null;

    final PuttPracticeSession completedSession = session.end();

    emit(PuttPracticeCompleted(session: completedSession));
  }

  /// Save the session to Firestore
  Future<void> saveSession() async {
    final PuttPracticeState currentState = state;
    if (currentState is! PuttPracticeCompleted) return;

    emit(PuttPracticeCompleted(
      session: currentState.session,
      isSaving: true,
    ));

    try {
      final bool success = await FBPuttPracticeDataLoader.saveSession(
        currentState.session,
      );

      if (success) {
        debugPrint('[PuttPracticeCubit] Session saved: ${currentState.session.id}');

        // Add session to history cubit
        locator.get<PuttPracticeHistoryCubit>().addSession(currentState.session);

        // Stay in completed state after save
        emit(PuttPracticeCompleted(
          session: currentState.session,
          isSaving: false,
        ));
      } else {
        debugPrint('[PuttPracticeCubit] Failed to save session to Firestore');
        emit(PuttPracticeError(
          message: 'Failed to save session. Please try again.',
          session: currentState.session,
        ));
      }
    } catch (e) {
      debugPrint('[PuttPracticeCubit] Failed to save session: $e');
      emit(PuttPracticeError(
        message: 'Failed to save session: $e',
        session: currentState.session,
      ));
    }
  }

  /// Start a new session (resets state)
  void startNewSession() {
    emit(const PuttPracticeInitial());
  }

  /// Start processing camera frames
  void _startFrameProcessing() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('[PuttPracticeCubit] Cannot start frame processing - camera not initialized');
      return;
    }

    // Don't start if already streaming
    if (_cameraController!.value.isStreamingImages) {
      debugPrint('[PuttPracticeCubit] Image stream already running');
      return;
    }

    try {
      _cameraController!.startImageStream((CameraImage image) {
        try {
          _trackerService?.processFrame(image);
        } catch (e) {
          debugPrint('[PuttPracticeCubit] Error in frame processing callback: $e');
        }
      });
    } catch (e) {
      debugPrint('[PuttPracticeCubit] Error starting image stream: $e');
      emit(PuttPracticeError(message: 'Failed to start camera stream: $e'));
    }
  }

  /// Stop processing camera frames
  void _stopFrameProcessing() {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        !_cameraController!.value.isStreamingImages) {
      return;
    }

    try {
      _cameraController!.stopImageStream();
    } catch (e) {
      debugPrint('[PuttPracticeCubit] Error stopping image stream: $e');
    }
  }

  /// Clean up resources
  Future<void> _disposeResources() async {
    _stopFrameProcessing();
    await _puttSubscription?.cancel();
    _puttSubscription = null;

    await _cameraController?.dispose();
    _cameraController = null;

    _trackerService?.dispose();
    _trackerService = null;
  }

  @override
  Future<void> clearOnLogout() async {
    await _disposeResources();
    emit(const PuttPracticeInitial());
  }

  @override
  Future<void> close() async {
    await _disposeResources();
    return super.close();
  }
}
