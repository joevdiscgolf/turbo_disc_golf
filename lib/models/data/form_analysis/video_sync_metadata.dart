import 'package:json_annotation/json_annotation.dart';

part 'video_sync_metadata.g.dart';

/// Represents a checkpoint synchronization point between user and pro videos
@JsonSerializable()
class CheckpointSyncPoint {
  /// Checkpoint identifier (e.g., "heisman", "loaded", "magic", "pro")
  @JsonKey(name: 'checkpoint_id')
  final String checkpointId;

  /// Timestamp in user video (seconds)
  @JsonKey(name: 'user_timestamp')
  final double userTimestamp;

  /// Corresponding timestamp in pro video (seconds)
  @JsonKey(name: 'pro_timestamp')
  final double proTimestamp;

  /// Sync priority: 1=critical (release), 2=important, 3=optional
  @JsonKey(name: 'sync_priority')
  final int syncPriority;

  CheckpointSyncPoint({
    required this.checkpointId,
    required this.userTimestamp,
    required this.proTimestamp,
    required this.syncPriority,
  });

  factory CheckpointSyncPoint.fromJson(Map<String, dynamic> json) =>
      _$CheckpointSyncPointFromJson(json);

  Map<String, dynamic> toJson() => _$CheckpointSyncPointToJson(this);
}

/// Video synchronization metadata for aligning user and pro videos
@JsonSerializable()
class VideoSyncMetadata {
  /// Synchronization strategy: "checkpoint_warp", "single_point", or "linear"
  @JsonKey(name: 'sync_strategy')
  final String syncStrategy;

  /// Duration of user video in seconds
  @JsonKey(name: 'user_video_duration')
  final double userVideoDuration;

  /// Duration of pro video in seconds
  @JsonKey(name: 'pro_video_duration')
  final double proVideoDuration;

  /// User video playback speed
  @JsonKey(name: 'user_playback_speed')
  final double userPlaybackSpeed;

  /// Pro video playback speed multiplier
  @JsonKey(name: 'pro_playback_speed_multiplier')
  final double proPlaybackSpeedMultiplier;

  /// List of checkpoint synchronization points
  @JsonKey(name: 'checkpoint_sync_points')
  final List<CheckpointSyncPoint> checkpointSyncPoints;

  /// Recommended playback rate for synchronized viewing
  @JsonKey(name: 'recommended_playback_rate')
  final double recommendedPlaybackRate;

  /// Time compression ratio between videos
  @JsonKey(name: 'time_compression_ratio')
  final double timeCompressionRatio;

  VideoSyncMetadata({
    required this.syncStrategy,
    required this.userVideoDuration,
    required this.proVideoDuration,
    required this.userPlaybackSpeed,
    required this.proPlaybackSpeedMultiplier,
    required this.checkpointSyncPoints,
    required this.recommendedPlaybackRate,
    required this.timeCompressionRatio,
  });

  factory VideoSyncMetadata.fromJson(Map<String, dynamic> json) =>
      _$VideoSyncMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$VideoSyncMetadataToJson(this);
}
