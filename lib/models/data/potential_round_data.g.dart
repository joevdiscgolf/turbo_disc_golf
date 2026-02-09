// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'potential_round_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PotentialDGHole _$PotentialDGHoleFromJson(Map json) => PotentialDGHole(
  number: (json['number'] as num?)?.toInt(),
  par: (json['par'] as num?)?.toInt(),
  feet: (json['feet'] as num?)?.toInt(),
  throws: (json['throws'] as List<dynamic>?)
      ?.map((e) => DiscThrow.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  holeType: $enumDecodeNullable(_$HoleTypeEnumMap, json['holeType']),
  explicitScore: (json['explicitScore'] as num?)?.toInt(),
);

Map<String, dynamic> _$PotentialDGHoleToJson(PotentialDGHole instance) =>
    <String, dynamic>{
      'number': instance.number,
      'par': instance.par,
      'feet': instance.feet,
      'throws': instance.throws?.map((e) => e.toJson()).toList(),
      'holeType': _$HoleTypeEnumMap[instance.holeType],
      'explicitScore': instance.explicitScore,
    };

const _$HoleTypeEnumMap = {
  HoleType.open: 'open',
  HoleType.slightlyWooded: 'slightly_wooded',
  HoleType.wooded: 'wooded',
};

PotentialDGRound _$PotentialDGRoundFromJson(Map json) => PotentialDGRound(
  uid: json['uid'] as String,
  id: json['id'] as String,
  courseId: json['courseId'] as String?,
  courseName: json['courseName'] as String?,
  course: json['course'] == null
      ? null
      : Course.fromJson(Map<String, dynamic>.from(json['course'] as Map)),
  layoutId: json['layoutId'] as String?,
  holes: (json['holes'] as List<dynamic>?)
      ?.map(
        (e) => PotentialDGHole.fromJson(Map<String, dynamic>.from(e as Map)),
      )
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
  createdAt: json['createdAt'] as String?,
  playedRoundAt: json['playedRoundAt'] as String?,
);

Map<String, dynamic> _$PotentialDGRoundToJson(PotentialDGRound instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'id': instance.id,
      'courseId': instance.courseId,
      'courseName': instance.courseName,
      'course': instance.course?.toJson(),
      'layoutId': instance.layoutId,
      'holes': instance.holes?.map((e) => e.toJson()).toList(),
      'analysis': instance.analysis?.toJson(),
      'aiSummary': instance.aiSummary?.toJson(),
      'aiCoachSuggestion': instance.aiCoachSuggestion?.toJson(),
      'versionId': instance.versionId,
      'createdAt': instance.createdAt,
      'playedRoundAt': instance.playedRoundAt,
    };
