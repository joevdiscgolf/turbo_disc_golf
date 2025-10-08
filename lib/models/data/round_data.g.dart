// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DGRound _$DGRoundFromJson(Map json) => DGRound(
  id: json['id'] as String,
  courseName: json['courseName'] as String,
  courseId: json['courseId'] as String?,
  holes: (json['holes'] as List<dynamic>)
      .map((e) => DGHole.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  analysis: json['analysis'] == null
      ? null
      : RoundAnalysis.fromJson(
          Map<String, dynamic>.from(json['analysis'] as Map),
        ),
  aiSummary: json['aiSummary'] as String?,
  aiCoachSuggestion: json['aiCoachSuggestion'] as String?,
);

Map<String, dynamic> _$DGRoundToJson(DGRound instance) => <String, dynamic>{
  'id': instance.id,
  'courseId': instance.courseId,
  'courseName': instance.courseName,
  'holes': instance.holes.map((e) => e.toJson()).toList(),
  'analysis': instance.analysis?.toJson(),
  'aiSummary': instance.aiSummary,
  'aiCoachSuggestion': instance.aiCoachSuggestion,
};
