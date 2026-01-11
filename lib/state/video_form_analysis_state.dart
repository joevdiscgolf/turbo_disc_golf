import 'package:flutter/foundation.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_result.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/video_analysis_session.dart';

@immutable
abstract class VideoFormAnalysisState {
  const VideoFormAnalysisState();
}

/// Initial state - no analysis in progress
class VideoFormAnalysisInitial extends VideoFormAnalysisState {
  const VideoFormAnalysisInitial();
}

/// Recording or selecting video
class VideoFormAnalysisRecording extends VideoFormAnalysisState {
  const VideoFormAnalysisRecording({required this.progressMessage});

  final String progressMessage;
}

/// Validating video file
class VideoFormAnalysisValidating extends VideoFormAnalysisState {
  const VideoFormAnalysisValidating({
    required this.session,
    required this.progressMessage,
  });

  final VideoAnalysisSession session;
  final String progressMessage;
}

/// Analyzing video with Gemini
class VideoFormAnalysisAnalyzing extends VideoFormAnalysisState {
  const VideoFormAnalysisAnalyzing({
    required this.session,
    required this.progressMessage,
  });

  final VideoAnalysisSession session;
  final String progressMessage;
}

/// Analysis complete with results
class VideoFormAnalysisComplete extends VideoFormAnalysisState {
  const VideoFormAnalysisComplete({
    required this.session,
    required this.result,
    this.poseAnalysis,
    this.poseAnalysisWarning,
  });

  final VideoAnalysisSession session;
  final FormAnalysisResult result;

  /// Pose analysis from Cloud Run backend (skeleton comparison, angles, etc.)
  final PoseAnalysisResponse? poseAnalysis;

  /// Warning message if pose analysis failed (analysis continued with Gemini only)
  final String? poseAnalysisWarning;
}

/// Error state
class VideoFormAnalysisError extends VideoFormAnalysisState {
  const VideoFormAnalysisError({
    required this.message,
    this.session,
  });

  final String message;
  final VideoAnalysisSession? session;
}
