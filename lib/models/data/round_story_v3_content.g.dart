// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_story_v3_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StorySection _$StorySectionFromJson(Map json) => StorySection(
  text: json['text'] as String,
  callouts:
      (json['callouts'] as List<dynamic>?)
          ?.map(
            (e) => StoryCallout.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList() ??
      const [],
  holeRange: HoleRange.fromJson(
    Map<String, dynamic>.from(json['holeRange'] as Map),
  ),
);

Map<String, dynamic> _$StorySectionToJson(StorySection instance) =>
    <String, dynamic>{
      'text': instance.text,
      'callouts': instance.callouts.map((e) => e.toJson()).toList(),
      'holeRange': instance.holeRange.toJson(),
    };

HoleRange _$HoleRangeFromJson(Map json) => HoleRange(
  startHole: (json['startHole'] as num).toInt(),
  endHole: (json['endHole'] as num).toInt(),
);

Map<String, dynamic> _$HoleRangeToJson(HoleRange instance) => <String, dynamic>{
  'startHole': instance.startHole,
  'endHole': instance.endHole,
};

SkillAssessment _$SkillAssessmentFromJson(Map json) => SkillAssessment(
  strengths: (json['strengths'] as List<dynamic>)
      .map((e) => SkillHighlight.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  weaknesses: (json['weaknesses'] as List<dynamic>)
      .map((e) => SkillHighlight.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  keyInsight: json['keyInsight'] as String,
);

Map<String, dynamic> _$SkillAssessmentToJson(SkillAssessment instance) =>
    <String, dynamic>{
      'strengths': instance.strengths.map((e) => e.toJson()).toList(),
      'weaknesses': instance.weaknesses.map((e) => e.toJson()).toList(),
      'keyInsight': instance.keyInsight,
    };

SkillHighlight _$SkillHighlightFromJson(Map json) => SkillHighlight(
  skill: json['skill'] as String,
  description: json['description'] as String,
  statHighlight: json['statHighlight'] as String,
);

Map<String, dynamic> _$SkillHighlightToJson(SkillHighlight instance) =>
    <String, dynamic>{
      'skill': instance.skill,
      'description': instance.description,
      'statHighlight': instance.statHighlight,
    };

RoundStoryV3Content _$RoundStoryV3ContentFromJson(Map json) =>
    RoundStoryV3Content(
      roundTitle: json['roundTitle'] as String,
      overview: json['overview'] as String,
      sections: (json['sections'] as List<dynamic>)
          .map(
            (e) => StorySection.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      whatCouldHaveBeen: WhatCouldHaveBeenV2.fromJson(
        Map<String, dynamic>.from(json['whatCouldHaveBeen'] as Map),
      ),
      shareableHeadline: json['shareableHeadline'] as String?,
      practiceAdvice:
          (json['practiceAdvice'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      strategyTips:
          (json['strategyTips'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      skillsAssessment: json['skillsAssessment'] == null
          ? null
          : SkillAssessment.fromJson(
              Map<String, dynamic>.from(json['skillsAssessment'] as Map),
            ),
      roundVersionId: (json['roundVersionId'] as num).toInt(),
    );

Map<String, dynamic> _$RoundStoryV3ContentToJson(
  RoundStoryV3Content instance,
) => <String, dynamic>{
  'roundTitle': instance.roundTitle,
  'overview': instance.overview,
  'sections': instance.sections.map((e) => e.toJson()).toList(),
  'whatCouldHaveBeen': instance.whatCouldHaveBeen.toJson(),
  'shareableHeadline': instance.shareableHeadline,
  'practiceAdvice': instance.practiceAdvice,
  'strategyTips': instance.strategyTips,
  'skillsAssessment': instance.skillsAssessment?.toJson(),
  'roundVersionId': instance.roundVersionId,
};
