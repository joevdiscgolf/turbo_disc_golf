import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_result.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/video_analysis_session.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_form_analysis_data_loader.dart';
import 'package:turbo_disc_golf/services/form_analysis/pose_analysis_api_client.dart';
import 'package:turbo_disc_golf/services/form_analysis/video_form_analysis_service.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_cubit.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_state.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:uuid/uuid.dart';

/// Cubit for managing video form analysis workflow
class VideoFormAnalysisCubit extends Cubit<VideoFormAnalysisState>
    implements ClearOnLogoutProtocol {
  VideoFormAnalysisCubit() : super(const VideoFormAnalysisInitial());

  final ImagePicker _imagePicker = ImagePicker();

  /// Start a new analysis session by recording video
  Future<void> recordVideo({
    required ThrowTechnique throwType,
    required CameraAngle cameraAngle,
  }) async {
    emit(
      const VideoFormAnalysisRecording(progressMessage: 'Opening camera...'),
    );

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(
          seconds: VideoFormAnalysisService.maxVideoDurationSeconds,
        ),
      );

      if (video == null) {
        emit(const VideoFormAnalysisInitial());
        return;
      }

      await _processVideo(
        videoPath: video.path,
        videoSource: VideoSource.camera,
        throwType: throwType,
        cameraAngle: cameraAngle,
      );
    } catch (e) {
      emit(VideoFormAnalysisError(
        message: 'Failed to record video: ${e.toString()}',
      ));
    }
  }

  /// Start a new analysis session by importing video from gallery
  Future<void> importVideo({
    required ThrowTechnique throwType,
    required CameraAngle cameraAngle,
  }) async {
    emit(const VideoFormAnalysisRecording(
      progressMessage: 'Opening gallery...',
    ));

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(
          seconds: VideoFormAnalysisService.maxVideoDurationSeconds,
        ),
      );

      if (video == null) {
        emit(const VideoFormAnalysisInitial());
        return;
      }

      await _processVideo(
        videoPath: video.path,
        videoSource: VideoSource.gallery,
        throwType: throwType,
        cameraAngle: cameraAngle,
      );
    } catch (e) {
      emit(VideoFormAnalysisError(
        message: 'Failed to import video: ${e.toString()}',
      ));
    }
  }

  /// Test with a bundled asset video (for development/testing only)
  Future<void> testWithAssetVideo({
    required ThrowTechnique throwType,
    required CameraAngle cameraAngle,
    required String assetPath,
  }) async {
    emit(const VideoFormAnalysisRecording(
      progressMessage: 'Loading test video...',
    ));

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
      );
    } catch (e) {
      emit(VideoFormAnalysisError(
        message: 'Failed to load test video: ${e.toString()}',
      ));
    }
  }

  Future<void> _processVideo({
    required String videoPath,
    required VideoSource videoSource,
    required ThrowTechnique throwType,
    required CameraAngle cameraAngle,
  }) async {
    final VideoFormAnalysisService analysisService =
        locator.get<VideoFormAnalysisService>();
    final AuthService authService = locator.get<AuthService>();

    final String? uid = authService.currentUid;
    if (uid == null) {
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

    emit(VideoFormAnalysisValidating(
      session: session,
      progressMessage: 'Validating video...',
    ));

    // Validate video
    final VideoValidationResult validation =
        await analysisService.validateVideo(videoPath);
    if (!validation.isValid) {
      emit(VideoFormAnalysisError(
        message: validation.errorMessage ?? 'Video validation failed',
        session: session,
      ));
      return;
    }

    // Update session with file size
    session = session.copyWith(
      videoSizeBytes: validation.fileSize,
      status: SessionStatus.analyzing,
    );

    // Start analysis
    emit(VideoFormAnalysisAnalyzing(
      session: session,
      progressMessage: 'Detecting body positions...',
    ));

    // Run pose analysis first if enabled (provides objective measurements)
    PoseAnalysisResponse? poseResult;
    String? poseAnalysisWarning;

    if (usePoseAnalysisBackend) {
      final (PoseAnalysisResponse? result, String? error) =
          await _runPoseAnalysis(
        videoPath: videoPath,
        throwType: throwType,
        cameraAngle: cameraAngle,
        sessionId: session.id,
        userId: uid,
      );
      poseResult = result;
      poseAnalysisWarning = error;

      if (poseResult != null) {
        emit(VideoFormAnalysisAnalyzing(
          session: session,
          progressMessage: 'Generating coaching feedback...',
        ));
      }
    }

    // Run Gemini analysis with pose data (if available) for informed feedback
    final FormAnalysisResult? result = await analysisService.analyzeVideo(
      videoPath: videoPath,
      throwType: throwType,
      poseAnalysis: poseResult, // Pass pose data to inform Gemini
      onProgressUpdate: (String message) {
        emit(VideoFormAnalysisAnalyzing(
          session: session,
          progressMessage: message,
        ));
      },
    );

    if (result == null) {
      emit(VideoFormAnalysisError(
        message: 'Analysis failed. Please try again with a clearer video.',
        session: session.copyWith(status: SessionStatus.failed),
      ));
      return;
    }

    // Save to history (fire-and-forget, don't block UI)
    if (poseResult != null) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('💾 SAVING TO HISTORY: Starting save...');
      debugPrint('💾 User ID: $uid');
      debugPrint('💾 Session ID: ${session.id}');
      debugPrint('💾 Checkpoints: ${poseResult.checkpoints.length}');
      debugPrint('═══════════════════════════════════════════════════════');
      _saveAnalysisToHistory(
        uid: uid,
        sessionId: session.id,
        throwType: throwType,
        cameraAngle: cameraAngle,
        poseAnalysis: poseResult,
      );
    } else {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('⚠️ SKIPPING HISTORY SAVE: poseResult is null');
      debugPrint('⚠️ Pose analysis warning: $poseAnalysisWarning');
      debugPrint('═══════════════════════════════════════════════════════');
    }

    emit(VideoFormAnalysisComplete(
      session: session.copyWith(
        status: SessionStatus.completed,
        analysisResult: result,
      ),
      result: result,
      poseAnalysis: poseResult,
      poseAnalysisWarning: poseAnalysisWarning,
    ));
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
      cameraAngle: cameraAngle.apiValue,
      poseAnalysis: poseAnalysis,
    ).then((savedRecord) {
      if (savedRecord != null) {
        debugPrint('[VideoFormAnalysisCubit] Analysis saved to history: ${savedRecord.id}');

        // Automatically add to history list for instant UI update
        try {
          final FormAnalysisHistoryCubit historyCubit =
              locator.get<FormAnalysisHistoryCubit>();
          historyCubit.addAnalysis(savedRecord);
          debugPrint('[VideoFormAnalysisCubit] ✅ Analysis added to history list');
        } catch (e) {
          debugPrint('[VideoFormAnalysisCubit] ⚠️  Failed to add analysis to history list: $e');
        }
      } else {
        debugPrint('[VideoFormAnalysisCubit] Failed to save analysis to history');
      }
    });
  }

  /// Run pose analysis using Cloud Run backend
  /// Returns a tuple of (response, errorMessage)
  Future<(PoseAnalysisResponse?, String?)> _runPoseAnalysis({
    required String videoPath,
    required ThrowTechnique throwType,
    required CameraAngle cameraAngle,
    required String sessionId,
    required String userId,
  }) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🎯 POSE ANALYSIS: Starting...');
    debugPrint('🎯 Video path: $videoPath');
    debugPrint('🎯 Backend URL: $poseAnalysisBaseUrl');
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      final PoseAnalysisApiClient poseClient =
          locator.get<PoseAnalysisApiClient>();

      // Map throw type to backend format
      final String throwTypeStr = _mapThrowTypeToString(throwType);
      debugPrint('🎯 Throw type: $throwTypeStr');

      final PoseAnalysisResponse response = await poseClient.analyzeVideo(
        videoFile: File(videoPath),
        throwType: throwTypeStr,
        cameraAngle: cameraAngle.apiValue, // Dynamic based on user selection
        sessionId: sessionId,
        userId: userId,
      );

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('✅ POSE ANALYSIS: SUCCESS!');
      debugPrint('✅ Checkpoints found: ${response.checkpoints.length}');
      for (final checkpoint in response.checkpoints) {
        debugPrint('   - ${checkpoint.checkpointName}: ${checkpoint.deviationSeverity}');
      }
      debugPrint('═══════════════════════════════════════════════════════');

      return (response, null);
    } catch (e, stackTrace) {
      final String errorMessage = e.toString();
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('❌ POSE ANALYSIS: FAILED!');
      debugPrint('❌ Error: $errorMessage');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════');

      // Return user-friendly error message
      String userMessage;
      if (errorMessage.contains('SocketException') ||
          errorMessage.contains('Connection refused') ||
          errorMessage.contains('Network error')) {
        userMessage =
            'Could not connect to pose analysis server at $poseAnalysisBaseUrl. '
            'Make sure the backend is running.';
      } else if (errorMessage.contains('timed out')) {
        userMessage = 'Pose analysis timed out. The server may be overloaded.';
      } else {
        userMessage = 'Pose analysis failed: $errorMessage';
      }

      return (null, userMessage);
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
      );
    }
  }

  @override
  Future<void> clearOnLogout() async {
    emit(const VideoFormAnalysisInitial());
  }
}
