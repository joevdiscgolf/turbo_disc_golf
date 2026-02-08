// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_reference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProReference _$ProReferenceFromJson(Map<String, dynamic> json) => ProReference(
  proName: json['pro_name'] as String,
  proImageUrl: json['pro_image_url'] as String?,
  proVideoUrl: json['pro_video_url'] as String?,
  proVideoStartSeconds: (json['pro_video_start_seconds'] as num?)?.toDouble(),
  proVideoEndSeconds: (json['pro_video_end_seconds'] as num?)?.toDouble(),
  proMeasurement: json['pro_measurement'] == null
      ? null
      : ProMeasurement.fromJson(
          json['pro_measurement'] as Map<String, dynamic>,
        ),
  comparisonNote: json['comparison_note'] as String?,
);

Map<String, dynamic> _$ProReferenceToJson(ProReference instance) =>
    <String, dynamic>{
      'pro_name': instance.proName,
      'pro_image_url': instance.proImageUrl,
      'pro_video_url': instance.proVideoUrl,
      'pro_video_start_seconds': instance.proVideoStartSeconds,
      'pro_video_end_seconds': instance.proVideoEndSeconds,
      'pro_measurement': instance.proMeasurement,
      'comparison_note': instance.comparisonNote,
    };

ProMeasurement _$ProMeasurementFromJson(Map<String, dynamic> json) =>
    ProMeasurement(
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
    );

Map<String, dynamic> _$ProMeasurementToJson(ProMeasurement instance) =>
    <String, dynamic>{'value': instance.value, 'unit': instance.unit};
