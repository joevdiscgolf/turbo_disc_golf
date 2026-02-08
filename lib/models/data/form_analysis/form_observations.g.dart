// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_observations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormObservations _$FormObservationsFromJson(Map<String, dynamic> json) =>
    FormObservations(
      observations: (json['observations'] as List<dynamic>)
          .map((e) => FormObservation.fromJson(e as Map<String, dynamic>))
          .toList(),
      observationsCount: (json['observations_count'] as num).toInt(),
      worstSeverity: $enumDecodeNullable(
        _$ObservationSeverityEnumMap,
        json['worst_severity'],
      ),
      hasSignificantObservations: json['has_significant_observations'] as bool,
    );

Map<String, dynamic> _$FormObservationsToJson(FormObservations instance) =>
    <String, dynamic>{
      'observations': instance.observations.map((e) => e.toJson()).toList(),
      'observations_count': instance.observationsCount,
      'worst_severity': _$ObservationSeverityEnumMap[instance.worstSeverity],
      'has_significant_observations': instance.hasSignificantObservations,
    };

const _$ObservationSeverityEnumMap = {
  ObservationSeverity.none: 'none',
  ObservationSeverity.minor: 'minor',
  ObservationSeverity.moderate: 'moderate',
  ObservationSeverity.significant: 'significant',
};
