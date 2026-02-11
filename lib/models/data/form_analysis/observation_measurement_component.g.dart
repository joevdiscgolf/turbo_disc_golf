// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observation_measurement_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ObservationMeasurementComponent _$ObservationMeasurementComponentFromJson(
  Map<String, dynamic> json,
) => ObservationMeasurementComponent(
  name: json['name'] as String,
  label: json['label'] as String,
  measuredValue: (json['measured_value'] as num).toDouble(),
  score: (json['score'] as num).toDouble(),
  unit: json['unit'] as String,
  idealValue: (json['ideal_value'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ObservationMeasurementComponentToJson(
  ObservationMeasurementComponent instance,
) => <String, dynamic>{
  'name': instance.name,
  'label': instance.label,
  'measured_value': instance.measuredValue,
  'score': instance.score,
  'unit': instance.unit,
  'ideal_value': instance.idealValue,
};
