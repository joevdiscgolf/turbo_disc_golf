// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DGRound _$DGRoundFromJson(Map json) => DGRound(
  uid: json['uid'] as String,
  id: json['id'] as String,
  courseName: json['courseName'] as String,
  courseId: json['courseId'] as String,
  course: Course.fromJson(Map<String, dynamic>.from(json['course'] as Map)),
  layoutId: json['layoutId'] as String,
  holes: (json['holes'] as List<dynamic>)
      .map((e) => DGHole.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  analysis: json['analysis'] == null
      ? null
      : RoundAnalysis.fromJson(
          Map<String, dynamic>.from(json['analysis'] as Map),
        ),
  aiSummary: json['aiSummary'] == null
      ? null
      : AIContent.fromJson(Map<String, dynamic>.from(json['aiSummary'] as Map)),
  aiCoachSuggestion: json['aiCoachSuggestion'] == null
      ? null
      : AIContent.fromJson(
          Map<String, dynamic>.from(json['aiCoachSuggestion'] as Map),
        ),
  versionId: (json['versionId'] as num?)?.toInt() ?? 1,
  createdAt: json['createdAt'] as String,
  playedRoundAt: json['playedRoundAt'] as String,
);

Map<String, dynamic> _$DGRoundToJson(DGRound instance) => <String, dynamic>{
  'uid': instance.uid,
  'id': instance.id,
  'courseId': instance.courseId,
  'courseName': instance.courseName,
  'course': instance.course.toJson(),
  'layoutId': instance.layoutId,
  'holes': instance.holes.map((e) => e.toJson()).toList(),
  'analysis': instance.analysis?.toJson(),
  'aiSummary': instance.aiSummary?.toJson(),
  'aiCoachSuggestion': instance.aiCoachSuggestion?.toJson(),
  'versionId': instance.versionId,
  'createdAt': instance.createdAt,
  'playedRoundAt': instance.playedRoundAt,
};
