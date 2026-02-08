// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observation_timing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ObservationTiming _$ObservationTimingFromJson(Map<String, dynamic> json) =>
    ObservationTiming(
      displayMode:
          $enumDecodeNullable(
            _$ObservationDisplayModeEnumMap,
            json['display_mode'],
          ) ??
          ObservationDisplayMode.singleFrame,
      frameNumber: (json['frame_number'] as num).toInt(),
      timestampSeconds: (json['timestamp_seconds'] as num).toDouble(),
      startFrame: (json['start_frame'] as num?)?.toInt(),
      endFrame: (json['end_frame'] as num?)?.toInt(),
      startTimestampSeconds: (json['start_timestamp_seconds'] as num?)
          ?.toDouble(),
      endTimestampSeconds: (json['end_timestamp_seconds'] as num?)?.toDouble(),
      durationMs: (json['duration_ms'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ObservationTimingToJson(ObservationTiming instance) =>
    <String, dynamic>{
      'display_mode': _$ObservationDisplayModeEnumMap[instance.displayMode]!,
      'frame_number': instance.frameNumber,
      'timestamp_seconds': instance.timestampSeconds,
      'start_frame': instance.startFrame,
      'end_frame': instance.endFrame,
      'start_timestamp_seconds': instance.startTimestampSeconds,
      'end_timestamp_seconds': instance.endTimestampSeconds,
      'duration_ms': instance.durationMs,
    };

const _$ObservationDisplayModeEnumMap = {
  ObservationDisplayMode.singleFrame: 'single_frame',
  ObservationDisplayMode.frameRange: 'frame_range',
};
