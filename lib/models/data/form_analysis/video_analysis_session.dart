import 'package:json_annotation/json_annotation.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_result.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

part 'video_analysis_session.g.dart';

/// Represents a complete video analysis session
@JsonSerializable(explicitToJson: true, anyMap: true)
class VideoAnalysisSession {
  const VideoAnalysisSession({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.videoPath,
    required this.videoSource,
    required this.throwType,
    this.videoDurationSeconds,
    this.videoSizeBytes,
    this.analysisResult,
    this.status,
    this.errorMessage,
  });

  /// Unique identifier for this session
  final String id;

  /// User ID who owns this session
  final String uid;

  /// When this session was created
  final String createdAt;

  /// Local path to the video file
  final String videoPath;

  /// Source of the video (camera or gallery)
  final VideoSource videoSource;

  /// Type of throw being analyzed
  final ThrowTechnique throwType;

  /// Duration of the video in seconds
  final double? videoDurationSeconds;

  /// Size of the video file in bytes
  final int? videoSizeBytes;

  /// Analysis result (null if not yet analyzed)
  final FormAnalysisResult? analysisResult;

  /// Current status of the session
  final SessionStatus? status;

  /// Error message if analysis failed
  final String? errorMessage;

  factory VideoAnalysisSession.fromJson(Map<String, dynamic> json) =>
      _$VideoAnalysisSessionFromJson(json);
  Map<String, dynamic> toJson() => _$VideoAnalysisSessionToJson(this);

  VideoAnalysisSession copyWith({
    String? id,
    String? uid,
    String? createdAt,
    String? videoPath,
    VideoSource? videoSource,
    ThrowTechnique? throwType,
    double? videoDurationSeconds,
    int? videoSizeBytes,
    FormAnalysisResult? analysisResult,
    SessionStatus? status,
    String? errorMessage,
  }) {
    return VideoAnalysisSession(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      videoPath: videoPath ?? this.videoPath,
      videoSource: videoSource ?? this.videoSource,
      throwType: throwType ?? this.throwType,
      videoDurationSeconds: videoDurationSeconds ?? this.videoDurationSeconds,
      videoSizeBytes: videoSizeBytes ?? this.videoSizeBytes,
      analysisResult: analysisResult ?? this.analysisResult,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Source of the video
enum VideoSource {
  @JsonValue('camera')
  camera,
  @JsonValue('gallery')
  gallery,
}

/// Status of the analysis session
enum SessionStatus {
  @JsonValue('created')
  created,
  @JsonValue('uploading')
  uploading,
  @JsonValue('analyzing')
  analyzing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
}
