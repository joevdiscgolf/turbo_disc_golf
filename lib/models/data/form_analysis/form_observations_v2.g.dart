// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_observations_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormObservationsV2 _$FormObservationsV2FromJson(Map<String, dynamic> json) =>
    FormObservationsV2(
      observations: (json['observations'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, FormObservation.fromJson(e as Map<String, dynamic>)),
      ),
      overallScore: (json['overall_score'] as num).toDouble(),
    );

Map<String, dynamic> _$FormObservationsV2ToJson(
  FormObservationsV2 instance,
) => <String, dynamic>{
  'observations': instance.observations.map((k, e) => MapEntry(k, e.toJson())),
  'overall_score': instance.overallScore,
};
