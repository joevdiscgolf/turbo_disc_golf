// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkpoint_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckpointMetadata _$CheckpointMetadataFromJson(Map<String, dynamic> json) =>
    CheckpointMetadata(
      checkpointId: json['checkpoint_id'] as String,
      checkpointName: json['checkpoint_name'] as String,
      frameNumber: (json['frame_number'] as num).toInt(),
      timestampSeconds: (json['timestamp_seconds'] as num).toDouble(),
      detectedFrameNumber: (json['detected_frame_number'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CheckpointMetadataToJson(CheckpointMetadata instance) =>
    <String, dynamic>{
      'checkpoint_id': instance.checkpointId,
      'checkpoint_name': instance.checkpointName,
      'frame_number': instance.frameNumber,
      'timestamp_seconds': instance.timestampSeconds,
      'detected_frame_number': instance.detectedFrameNumber,
    };
