// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arm_speed_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArmSpeedData _$ArmSpeedDataFromJson(Map<String, dynamic> json) => ArmSpeedData(
  speedsByFrameMph: ArmSpeedData._speedsFromJson(
    json['speeds_by_frame_mph'] as Map<String, dynamic>,
  ),
  maxSpeedMph: (json['max_speed_mph'] as num).toDouble(),
  maxSpeedFrame: (json['max_speed_frame'] as num).toInt(),
  chartStartFrame: (json['chart_start_frame'] as num).toInt(),
  chartEndFrame: (json['chart_end_frame'] as num).toInt(),
);

Map<String, dynamic> _$ArmSpeedDataToJson(
  ArmSpeedData instance,
) => <String, dynamic>{
  'speeds_by_frame_mph': ArmSpeedData._speedsToJson(instance.speedsByFrameMph),
  'max_speed_mph': instance.maxSpeedMph,
  'max_speed_frame': instance.maxSpeedFrame,
  'chart_start_frame': instance.chartStartFrame,
  'chart_end_frame': instance.chartEndFrame,
};
