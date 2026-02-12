// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_observation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormObservation _$FormObservationFromJson(
  Map<String, dynamic> json,
) => FormObservation(
  observationId: json['observation_id'] as String,
  observationName: json['observation_name'] as String,
  category: $enumDecode(_$ObservationCategoryEnumMap, json['category']),
  observationType: $enumDecode(
    _$ObservationTypeEnumMap,
    json['observation_type'],
  ),
  severity: $enumDecode(_$ObservationSeverityEnumMap, json['severity']),
  score: (json['score'] as num?)?.toDouble(),
  confidence: (json['confidence'] as num).toDouble(),
  timing: ObservationTiming.fromJson(json['timing'] as Map<String, dynamic>),
  measurement: json['measurement'] == null
      ? null
      : ObservationMeasurement.fromJson(
          json['measurement'] as Map<String, dynamic>,
        ),
  coaching: ObservationCoaching.fromJson(
    json['coaching'] as Map<String, dynamic>,
  ),
  proReference: json['pro_reference'] == null
      ? null
      : ProReference.fromJson(json['pro_reference'] as Map<String, dynamic>),
  cropMetadata: json['crop_metadata'] == null
      ? null
      : CropMetadata.fromJson(json['crop_metadata'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FormObservationToJson(FormObservation instance) =>
    <String, dynamic>{
      'observation_id': instance.observationId,
      'observation_name': instance.observationName,
      'category': _$ObservationCategoryEnumMap[instance.category]!,
      'observation_type': _$ObservationTypeEnumMap[instance.observationType]!,
      'severity': _$ObservationSeverityEnumMap[instance.severity]!,
      'score': instance.score,
      'confidence': instance.confidence,
      'timing': instance.timing.toJson(),
      'measurement': instance.measurement?.toJson(),
      'coaching': instance.coaching.toJson(),
      'pro_reference': instance.proReference?.toJson(),
      'crop_metadata': instance.cropMetadata?.toJson(),
    };

const _$ObservationCategoryEnumMap = {
  ObservationCategory.footwork: 'footwork',
  ObservationCategory.armMechanics: 'arm_mechanics',
  ObservationCategory.timing: 'timing',
  ObservationCategory.balance: 'balance',
  ObservationCategory.rotation: 'rotation',
};

const _$ObservationTypeEnumMap = {
  ObservationType.positive: 'positive',
  ObservationType.negative: 'negative',
  ObservationType.neutral: 'neutral',
};

const _$ObservationSeverityEnumMap = {
  ObservationSeverity.none: 'none',
  ObservationSeverity.minor: 'minor',
  ObservationSeverity.moderate: 'moderate',
  ObservationSeverity.significant: 'significant',
};
