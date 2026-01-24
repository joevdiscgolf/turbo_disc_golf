import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
// Gemini analysis commented out - uncomment when re-enabling
// import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_result.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/video_analysis_session.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_form_analysis_data_loader.dart';
import 'package:turbo_disc_golf/services/form_analysis/pose_analysis_api_client.dart';
import 'package:turbo_disc_golf/services/form_analysis/video_form_analysis_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_cubit.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_state.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:uuid/uuid.dart';

const int kMaxVideoSeconds = 4;

/// Cubit for managing video form analysis workflow
class VideoFormAnalysisCubit extends Cubit<VideoFormAnalysisState>
    implements ClearOnLogoutProtocol {
  VideoFormAnalysisCubit() : super(const VideoFormAnalysisInitial());

  final ImagePicker _imagePicker = ImagePicker();
  Timer? _loaderDelayTimer;

  /// Start a new analysis session by recording video
  Future<void> recordVideo({
    required ThrowTechnique throwType,
    required CameraAngle cameraAngle,
    required Handedness handedness,
  }) async {
    emit(
      const VideoFormAnalysisRecording(progressMessage: 'Opening camera...'),
    );

    try {
      debugPrint(
        '[VideoFormAnalysisCubit] Waiting for video recording from camera...',
      );

      // Start timer to show loader after 200ms if picker is still open
      _loaderDelayTimer = Timer(const Duration(milliseconds: 200), () {
        debugPrint('[VideoFormAnalysisCubit] 200ms elapsed - showing loader');
        emit(
          const VideoFormAnalysisRecording(progressMessage: 'Loading video...'),
        );
      });

      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: kMaxVideoSeconds),
      );

      // Cancel timer - picker has returned
      _loaderDelayTimer?.cancel();
      _loaderDelayTimer = null;

      if (video == null) {
        debugPrint('[VideoFormAnalysisCubit] Video recording cancelled');
        emit(const VideoFormAnalysisInitial());
        return;
      }

      debugPrint('[VideoFormAnalysisCubit] Video recorded: ${video.path}');

      await _processVideo(
        videoPath: video.path,
        videoSource: VideoSource.camera,
        throwType: throwType,
        cameraAngle: cameraAngle,
        handedness: handedness,
      );
    } catch (e) {
      _loaderDelayTimer?.cancel();
      _loaderDelayTimer = null;
      debugPrint('[VideoFormAnalysisCubit] Failed to record video: $e');
      emit(
        VideoFormAnalysisError(
          message: 'Failed to record video: ${e.toString()}',
        ),
      );
    }
  }

  /// Start a new analysis session by importing video from gallery
  Future<void> importVideo({
    required ThrowTechnique throwType,
    required CameraAngle cameraAngle,
    required Handedness handedness,
  }) async {
    try {
      debugPrint(
        '[VideoFormAnalysisCubit] Waiting for video selection from gallery...',
      );

      // Start timer to show loader after 200ms if picker is still open
      _loaderDelayTimer = Timer(const Duration(milliseconds: 200), () {
        debugPrint('[VideoFormAnalysisCubit] 200ms elapsed - showing loader');
        emit(
          const VideoFormAnalysisRecording(progressMessage: 'Loading video...'),
        );
      });

      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: kMaxVideoSeconds),
      );

      // Cancel timer - picker has returned
      _loaderDelayTimer?.cancel();
      _loaderDelayTimer = null;

      if (video == null) {
        debugPrint('[VideoFormAnalysisCubit] Video selection cancelled');
        emit(const VideoFormAnalysisInitial());
        return;
      }

      debugPrint('[VideoFormAnalysisCubit] Video imported: ${video.path}');

      await _processVideo(
        videoPath: video.path,
        videoSource: VideoSource.gallery,
        throwType: throwType,
        cameraAngle: cameraAngle,
        handedness: handedness,
      );
    } catch (e) {
      _loaderDelayTimer?.cancel();
      _loaderDelayTimer = null;
      debugPrint('[VideoFormAnalysisCubit] Failed to import video: $e');
      emit(
        VideoFormAnalysisError(
          message: 'Failed to import video: ${e.toString()}',
        ),
      );
    }
  }

  /// Test with a bundled asset video (for development/testing only)
  Future<void> testWithAssetVideo({
    required ThrowTechnique throwType,
    required CameraAngle cameraAngle,
    required Handedness handedness,
    required String assetPath,
  }) async {
    emit(
      const VideoFormAnalysisRecording(
        progressMessage: 'Loading test video...',
      ),
    );

    try {
      // Copy asset to temp directory so it can be accessed as a file
      final ByteData data = await rootBundle.load(assetPath);
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = assetPath.split('/').last;
      final String tempPath = '${tempDir.path}/$fileName';

      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );

      await _processVideo(
        videoPath: tempPath,
        videoSource: VideoSource.gallery,
        throwType: throwType,
        cameraAngle: cameraAngle,
        handedness: handedness,
      );
    } catch (e) {
      emit(
        VideoFormAnalysisError(
          message: 'Failed to load test video: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _processVideo({
    required String videoPath,
    required VideoSource videoSource,
    required ThrowTechnique throwType,
    required CameraAngle cameraAngle,
    required Handedness handedness,
  }) async {
    debugPrint(
      '[VideoFormAnalysisCubit] Starting video processing: $videoPath',
    );

    final VideoFormAnalysisService analysisService = locator
        .get<VideoFormAnalysisService>();
    final AuthService authService = locator.get<AuthService>();

    final String? uid = authService.currentUid;
    if (uid == null) {
      debugPrint('[VideoFormAnalysisCubit] Error: User not authenticated');
      emit(const VideoFormAnalysisError(message: 'User not authenticated'));
      return;
    }

    // Create session
    VideoAnalysisSession session = VideoAnalysisSession(
      id: const Uuid().v4(),
      uid: uid,
      createdAt: DateTime.now().toIso8601String(),
      videoPath: videoPath,
      videoSource: videoSource,
      throwType: throwType,
      status: SessionStatus.created,
    );

    debugPrint('[VideoFormAnalysisCubit] Validating video...');
    emit(
      VideoFormAnalysisValidating(
        session: session,
        progressMessage: 'Validating video...',
      ),
    );

    // Yield to event loop so UI can render the loader
    await Future.delayed(Duration.zero);

    // 1. Validate video duration FIRST (most actionable error)
    final (double? duration, String? durationError) = await analysisService
        .validateVideoDuration(videoPath);

    debugPrint(
      '[VideoFormAnalysisCubit] Duration validation - Duration: $duration seconds, Error: $durationError',
    );

    if (durationError != null) {
      locator.get<ToastService>().showError(durationError);
      emit(const VideoFormAnalysisInitial());
      return;
    }

    // 2. Validate file size and format
    final VideoValidationResult validation = await analysisService
        .validateVideo(videoPath);
    if (!validation.isValid) {
      locator.get<ToastService>().showError(
        validation.errorMessage ?? 'Video validation failed',
      );
      emit(const VideoFormAnalysisInitial());
      return;
    }

    // Update session with file size
    session = session.copyWith(
      videoSizeBytes: validation.fileSize,
      status: SessionStatus.analyzing,
    );

    // Start analysis
    emit(
      VideoFormAnalysisAnalyzing(
        session: session,
        progressMessage: 'Detecting body positions...',
      ),
    );

    // Run pose analysis first if enabled (provides objective measurements)
    PoseAnalysisResponse? poseResult;
    String? poseAnalysisWarning;

    final FeatureFlagService flags = locator.get<FeatureFlagService>();
    if (flags.usePoseAnalysisBackend) {
      final (
        PoseAnalysisResponse? result,
        String? error,
      ) = await _runPoseAnalysis(
        videoPath: videoPath,
        throwType: throwType,
        cameraAngle: cameraAngle,
        handedness: handedness,
        sessionId: session.id,
        userId: uid,
      );
      poseResult = result;
      poseAnalysisWarning = error;

      // If analysis failed, show error and return early
      if (poseResult == null && poseAnalysisWarning != null) {
        locator.get<ToastService>().showError(poseAnalysisWarning);
        emit(
          VideoFormAnalysisError(
            message: poseAnalysisWarning,
            session: session,
          ),
        );
        return;
      }

      if (poseResult != null) {
        emit(
          VideoFormAnalysisAnalyzing(
            session: session,
            progressMessage: 'Generating coaching feedback...',
          ),
        );
      }
    }

    // Gemini analysis commented out - only using pose analysis for now
    // final FormAnalysisResult? result = await analysisService.analyzeVideo(
    //   videoPath: videoPath,
    //   throwType: throwType,
    //   poseAnalysis: poseResult, // Pass pose data to inform Gemini
    //   onProgressUpdate: (String message) {
    //     emit(VideoFormAnalysisAnalyzing(
    //       session: session,
    //       progressMessage: message,
    //     ));
    //   },
    // );

    // Save to history (fire-and-forget, don't block UI)
    if (poseResult != null) {
      debugPrint(
        '[VideoFormAnalysisCubit] Saving analysis to history (session: ${session.id})',
      );
      _saveAnalysisToHistory(
        uid: uid,
        sessionId: session.id,
        throwType: throwType,
        cameraAngle: cameraAngle,
        poseAnalysis: poseResult,
      );
    } else {
      debugPrint(
        '[VideoFormAnalysisCubit] Skipping history save - no pose analysis result',
      );
    }

    emit(
      VideoFormAnalysisComplete(
        session: session.copyWith(status: SessionStatus.completed),
        poseAnalysis: poseResult,
        poseAnalysisWarning: poseAnalysisWarning,
      ),
    );
  }

  /// Save analysis to Firestore history and automatically update history list.
  void _saveAnalysisToHistory({
    required String uid,
    required String sessionId,
    required ThrowTechnique throwType,
    required CameraAngle cameraAngle,
    required PoseAnalysisResponse poseAnalysis,
  }) {
    // Fire-and-forget - don't await, just log result and update history
    FBFormAnalysisDataLoader.saveAnalysis(
      uid: uid,
      analysisId: sessionId,
      throwType: _mapThrowTypeToString(throwType),
      cameraAngle: cameraAngle,
      poseAnalysis: poseAnalysis,
    ).then((savedRecord) {
      if (savedRecord != null) {
        debugPrint(
          '[VideoFormAnalysisCubit] Analysis saved to history: ${savedRecord.id}',
        );

        // Automatically add to history list for instant UI update
        try {
          final FormAnalysisHistoryCubit historyCubit = locator
              .get<FormAnalysisHistoryCubit>();
          historyCubit.addAnalysis(savedRecord);
          debugPrint(
            '[VideoFormAnalysisCubit] ✅ Analysis added to history list',
          );
        } catch (e) {
          debugPrint(
            '[VideoFormAnalysisCubit] ⚠️  Failed to add analysis to history list: $e',
          );
        }
      } else {
        debugPrint(
          '[VideoFormAnalysisCubit] Failed to save analysis to history',
        );
      }
    });
  }

  /// Run pose analysis using Cloud Run backend
  /// Returns a tuple of (response, errorMessage)
  Future<(PoseAnalysisResponse?, String?)> _runPoseAnalysis({
    required String videoPath,
    required ThrowTechnique throwType,
    required CameraAngle cameraAngle,
    required Handedness handedness,
    required String sessionId,
    required String userId,
  }) async {
    final FeatureFlagService flags = locator.get<FeatureFlagService>();

    try {
      debugPrint('[VideoFormAnalysisCubit] Starting pose analysis');
      debugPrint(
        '[VideoFormAnalysisCubit] Backend URL: ${flags.poseAnalysisBaseUrl}',
      );
      debugPrint('[VideoFormAnalysisCubit] Video: $videoPath');

      final PoseAnalysisApiClient poseClient = locator
          .get<PoseAnalysisApiClient>();

      // Map throw type to backend format
      final String throwTypeStr = _mapThrowTypeToString(throwType);
      debugPrint(
        '[VideoFormAnalysisCubit] Throw type: $throwTypeStr, Camera: ${cameraAngle.name}',
      );

      final PoseAnalysisResponse response = await poseClient.analyzeVideo(
        videoFile: File(videoPath),
        throwType: throwTypeStr,
        cameraAngle: cameraAngle,
        handedness: handedness,
        sessionId: sessionId,
        userId: userId,
      );

      debugPrint(
        '[VideoFormAnalysisCubit] ✅ Pose analysis successful - ${response.checkpoints.length} checkpoints',
      );
      for (final checkpoint in response.checkpoints) {
        debugPrint(
          '[VideoFormAnalysisCubit]   - ${checkpoint.checkpointName}: ${checkpoint.deviationSeverity}',
        );
      }

      return (response, null);
    } catch (e, stackTrace) {
      final String errorMessage = e.toString();
      debugPrint(
        '[VideoFormAnalysisCubit] ❌ Pose analysis failed: $errorMessage',
      );
      debugPrint('[VideoFormAnalysisCubit] Stack trace: $stackTrace');

      // Return user-friendly error message
      String userMessage;
      final String errorLower = errorMessage.toLowerCase();
      if (errorMessage.contains('SocketException') ||
          errorMessage.contains('Connection refused') ||
          errorMessage.contains('Network error')) {
        userMessage =
            'Could not connect to pose analysis server at ${flags.poseAnalysisBaseUrl}. '
            'Make sure the backend is running.';
      } else if (errorMessage.contains('timed out')) {
        userMessage = 'Pose analysis timed out. The server may be overloaded.';
      } else if (errorMessage.contains(
        'Could not detect all required positions',
      )) {
        // Parse missing positions count from error message
        // Format: "Could not detect all required positions. Missing: HEISMAN, LOADED. Please..."
        final int missingCount = _countMissingPositions(errorMessage);
        userMessage =
            'Unable to detect $missingCount position${missingCount == 1 ? '' : 's'}';
      } else if (errorLower.contains('file must be a video')) {
        // Exact match for backend's specific error message when an image is uploaded
        userMessage = 'Please upload a video file, not a photo or image';
      } else if (errorLower.contains('not a video') ||
          errorLower.contains('invalid video') ||
          errorLower.contains('image file') ||
          errorLower.contains('unsupported format') ||
          errorLower.contains('cannot process')) {
        userMessage = 'Please select a video file, not a photo';
      } else {
        userMessage =
            'Analysis failed. Please try again with a different video.';
      }

      return (null, userMessage);
    }
  }

  /// Count missing positions from error message
  /// Example: "Could not detect all required positions. Missing: HEISMAN, LOADED. Please..."
  /// Returns: 2 (count of comma-separated positions) or 1 if parsing fails
  int _countMissingPositions(String errorMessage) {
    try {
      final int startIndex = errorMessage.indexOf('Missing:');
      if (startIndex == -1) {
        return 1;
      }

      final int start = startIndex + 'Missing:'.length;
      final int endIndex = errorMessage.indexOf('.', start);
      if (endIndex == -1) {
        return 1;
      }

      final String missingStr = errorMessage.substring(start, endIndex).trim();

      // Count comma-separated positions
      // E.g., "HEISMAN, LOADED" -> 2
      if (missingStr.isEmpty) {
        return 1;
      }
      return missingStr.split(',').length;
    } catch (e) {
      debugPrint(
        '[VideoFormAnalysisCubit] Failed to parse missing positions: $e',
      );
      return 1;
    }
  }

  /// Map ThrowTechnique enum to string for backend
  String _mapThrowTypeToString(ThrowTechnique technique) {
    switch (technique) {
      case ThrowTechnique.backhand:
      case ThrowTechnique.backhandRoller:
        return 'backhand';
      case ThrowTechnique.forehand:
      case ThrowTechnique.forehandRoller:
        return 'forehand'; // Not yet supported by backend
      case ThrowTechnique.tomahawk:
      case ThrowTechnique.thumber:
      case ThrowTechnique.overhand:
      case ThrowTechnique.grenade:
      case ThrowTechnique.other:
        return 'backhand'; // Default to backhand for unsupported types
    }
  }

  /// Reset to initial state
  void reset() {
    emit(const VideoFormAnalysisInitial());
  }

  /// Retry analysis with same video
  Future<void> retryAnalysis() async {
    final VideoFormAnalysisState currentState = state;
    if (currentState is VideoFormAnalysisError &&
        currentState.session != null) {
      final VideoAnalysisSession session = currentState.session!;
      await _processVideo(
        videoPath: session.videoPath,
        videoSource: session.videoSource,
        throwType: session.throwType,
        cameraAngle: CameraAngle.side, // Default to side view for retry
        handedness: Handedness.right, // Default to right-handed for retry
      );
    }
  }

  @override
  Future<void> clearOnLogout() async {
    _loaderDelayTimer?.cancel();
    _loaderDelayTimer = null;
    emit(const VideoFormAnalysisInitial());
  }
}
