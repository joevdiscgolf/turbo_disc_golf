// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observation_coaching.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ObservationCoaching _$ObservationCoachingFromJson(Map<String, dynamic> json) =>
    ObservationCoaching(
      summary: json['summary'] as String,
      explanation: json['explanation'] as String,
      fixSuggestion: json['fix_suggestion'] as String?,
      drillSuggestion: json['drill_suggestion'] as String?,
    );

Map<String, dynamic> _$ObservationCoachingToJson(
  ObservationCoaching instance,
) => <String, dynamic>{
  'summary': instance.summary,
  'explanation': instance.explanation,
  'fix_suggestion': instance.fixSuggestion,
  'drill_suggestion': instance.drillSuggestion,
};
