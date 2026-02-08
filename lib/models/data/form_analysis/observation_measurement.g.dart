// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observation_measurement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ObservationMeasurement _$ObservationMeasurementFromJson(
  Map<String, dynamic> json,
) => ObservationMeasurement(
  measuredValue: (json['measured_value'] as num).toDouble(),
  idealValue: (json['ideal_value'] as num?)?.toDouble(),
  deviation: (json['deviation'] as num?)?.toDouble(),
  unit: json['unit'] as String,
  deviationDirection: json['deviation_direction'] as String?,
);

Map<String, dynamic> _$ObservationMeasurementToJson(
  ObservationMeasurement instance,
) => <String, dynamic>{
  'measured_value': instance.measuredValue,
  'ideal_value': instance.idealValue,
  'deviation': instance.deviation,
  'unit': instance.unit,
  'deviation_direction': instance.deviationDirection,
};
