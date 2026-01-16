// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_sync_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckpointSyncPoint _$CheckpointSyncPointFromJson(Map<String, dynamic> json) =>
    CheckpointSyncPoint(
      checkpointId: json['checkpoint_id'] as String,
      userTimestamp: (json['user_timestamp'] as num).toDouble(),
      proTimestamp: (json['pro_timestamp'] as num).toDouble(),
      syncPriority: (json['sync_priority'] as num).toInt(),
    );

Map<String, dynamic> _$CheckpointSyncPointToJson(
  CheckpointSyncPoint instance,
) => <String, dynamic>{
  'checkpoint_id': instance.checkpointId,
  'user_timestamp': instance.userTimestamp,
  'pro_timestamp': instance.proTimestamp,
  'sync_priority': instance.syncPriority,
};

VideoSyncMetadata _$VideoSyncMetadataFromJson(Map<String, dynamic> json) =>
    VideoSyncMetadata(
      syncStrategy: json['sync_strategy'] as String,
      userVideoDuration: (json['user_video_duration'] as num).toDouble(),
      proVideoDuration: (json['pro_video_duration'] as num).toDouble(),
      userPlaybackSpeed: (json['user_playback_speed'] as num).toDouble(),
      proPlaybackSpeedMultiplier: (json['pro_playback_speed_multiplier'] as num)
          .toDouble(),
      checkpointSyncPoints: (json['checkpoint_sync_points'] as List<dynamic>)
          .map((e) => CheckpointSyncPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendedPlaybackRate: (json['recommended_playback_rate'] as num)
          .toDouble(),
      timeCompressionRatio: (json['time_compression_ratio'] as num).toDouble(),
    );

Map<String, dynamic> _$VideoSyncMetadataToJson(VideoSyncMetadata instance) =>
    <String, dynamic>{
      'sync_strategy': instance.syncStrategy,
      'user_video_duration': instance.userVideoDuration,
      'pro_video_duration': instance.proVideoDuration,
      'user_playback_speed': instance.userPlaybackSpeed,
      'pro_playback_speed_multiplier': instance.proPlaybackSpeedMultiplier,
      'checkpoint_sync_points': instance.checkpointSyncPoints,
      'recommended_playback_rate': instance.recommendedPlaybackRate,
      'time_compression_ratio': instance.timeCompressionRatio,
    };
