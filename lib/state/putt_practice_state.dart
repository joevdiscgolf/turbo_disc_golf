import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/basket_calibration.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/detected_putt_attempt.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/putt_practice_session.dart';

/// Base state for putt practice feature
sealed class PuttPracticeState extends Equatable {
  const PuttPracticeState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any session is started
class PuttPracticeInitial extends PuttPracticeState {
  const PuttPracticeInitial();
}

/// State when initializing the camera
class PuttPracticeCameraInitializing extends PuttPracticeState {
  final String message;

  const PuttPracticeCameraInitializing({
    this.message = 'Initializing camera...',
  });

  @override
  List<Object?> get props => [message];
}

/// State when camera is ready and waiting to detect basket
class PuttPracticeCameraReady extends PuttPracticeState {
  final CameraController cameraController;

  const PuttPracticeCameraReady({
    required this.cameraController,
  });

  @override
  List<Object?> get props => [cameraController];
}

/// State when calibrating the basket position
class PuttPracticeCalibrating extends PuttPracticeState {
  final CameraController cameraController;
  final BasketCalibration? detectedBasket;
  final String message;
  final int stableFrameCount;
  final List<Rect> motionBoxes;

  const PuttPracticeCalibrating({
    required this.cameraController,
    this.detectedBasket,
    this.message = 'Point camera at basket...',
    this.stableFrameCount = 0,
    this.motionBoxes = const [],
  });

  @override
  List<Object?> get props =>
      [cameraController, detectedBasket, message, stableFrameCount, motionBoxes];
}

/// State when session is active and tracking putts
class PuttPracticeActive extends PuttPracticeState {
  final CameraController cameraController;
  final PuttPracticeSession session;
  final DetectedPuttAttempt? lastDetectedAttempt;
  final bool isProcessingFrame;
  final List<Rect> motionBoxes;

  const PuttPracticeActive({
    required this.cameraController,
    required this.session,
    this.lastDetectedAttempt,
    this.isProcessingFrame = false,
    this.motionBoxes = const [],
  });

  @override
  List<Object?> get props => [
        cameraController,
        session,
        lastDetectedAttempt,
        isProcessingFrame,
        motionBoxes,
      ];
}

/// State when session is paused
class PuttPracticePaused extends PuttPracticeState {
  final CameraController cameraController;
  final PuttPracticeSession session;

  const PuttPracticePaused({
    required this.cameraController,
    required this.session,
  });

  @override
  List<Object?> get props => [cameraController, session];
}

/// State when session has ended and showing summary
class PuttPracticeCompleted extends PuttPracticeState {
  final PuttPracticeSession session;
  final bool isSaving;

  const PuttPracticeCompleted({
    required this.session,
    this.isSaving = false,
  });

  @override
  List<Object?> get props => [session, isSaving];
}

/// Error state
class PuttPracticeError extends PuttPracticeState {
  final String message;
  final PuttPracticeSession? session;
  final CameraController? cameraController;

  const PuttPracticeError({
    required this.message,
    this.session,
    this.cameraController,
  });

  @override
  List<Object?> get props => [message, session, cameraController];
}
