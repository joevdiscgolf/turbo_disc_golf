import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/video_orientation.dart';

part 'video_metadata.g.dart';

/// Video files and technical metadata
@JsonSerializable(explicitToJson: true)
class VideoMetadata {
  const VideoMetadata({
    this.videoUrl,
    this.videoStoragePath,
    this.skeletonVideoUrl,
    this.skeletonOnlyVideoUrl,
    this.thumbnailUrl,
    required this.videoDurationSeconds,
    required this.totalFrames,
    this.videoWidth,
    this.videoHeight,
    this.videoOrientation,
    this.videoAspectRatio,
    this.returnedVideoAspectRatio,
  });

  /// URL of the user's form video
  @JsonKey(name: 'video_url')
  final String? videoUrl;

  /// Cloud Storage path for the video (e.g., "{uid}/{session_id}.mp4")
  @JsonKey(name: 'video_storage_path')
  final String? videoStoragePath;

  /// URL of the skeleton overlay video
  @JsonKey(name: 'skeleton_video_url')
  final String? skeletonVideoUrl;

  /// URL of the skeleton-only video (skeleton on black background)
  @JsonKey(name: 'skeleton_only_video_url')
  final String? skeletonOnlyVideoUrl;

  /// Cloud Storage URL for thumbnail image
  /// Used in history list for async loading
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;

  /// Video duration in seconds
  @JsonKey(name: 'video_duration_seconds')
  final double videoDurationSeconds;

  /// Total number of frames in the video
  @JsonKey(name: 'total_frames')
  final int totalFrames;

  /// Video width in pixels (after rotation correction)
  @JsonKey(name: 'video_width')
  final int? videoWidth;

  /// Video height in pixels (after rotation correction)
  @JsonKey(name: 'video_height')
  final int? videoHeight;

  /// Video orientation: portrait or landscape
  @JsonKey(name: 'video_orientation')
  final VideoOrientation? videoOrientation;

  /// Original video aspect ratio (width/height)
  @JsonKey(name: 'video_aspect_ratio')
  final double? videoAspectRatio;

  /// Aspect ratio of returned processed videos
  @JsonKey(name: 'returned_video_aspect_ratio')
  final double? returnedVideoAspectRatio;

  factory VideoMetadata.fromJson(Map<String, dynamic> json) =>
      _$VideoMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$VideoMetadataToJson(this);
}
