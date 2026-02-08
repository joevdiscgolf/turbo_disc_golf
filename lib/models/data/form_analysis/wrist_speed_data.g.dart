// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrist_speed_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WristSpeedData _$WristSpeedDataFromJson(Map<String, dynamic> json) =>
    WristSpeedData(
      speedsMph: (json['speeds_mph'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      maxSpeedMph: (json['max_speed_mph'] as num).toDouble(),
      maxSpeedFrame: (json['max_speed_frame'] as num).toInt(),
      startFrame: (json['start_frame'] as num).toInt(),
      endFrame: (json['end_frame'] as num).toInt(),
    );

Map<String, dynamic> _$WristSpeedDataToJson(WristSpeedData instance) =>
    <String, dynamic>{
      'speeds_mph': instance.speedsMph,
      'max_speed_mph': instance.maxSpeedMph,
      'max_speed_frame': instance.maxSpeedFrame,
      'start_frame': instance.startFrame,
      'end_frame': instance.endFrame,
    };
