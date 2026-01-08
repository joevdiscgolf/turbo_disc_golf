// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'structured_story_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShareHighlightStat _$ShareHighlightStatFromJson(Map json) => ShareHighlightStat(
  statId: json['statId'] as String,
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$ShareHighlightStatToJson(ShareHighlightStat instance) =>
    <String, dynamic>{'statId': instance.statId, 'reason': instance.reason};

StoryHighlight _$StoryHighlightFromJson(Map json) => StoryHighlight(
  headline: json['headline'] as String?,
  cardId: json['cardId'] as String?,
  explanation: json['explanation'] as String?,
  targetTab: json['targetTab'] as String?,
);

Map<String, dynamic> _$StoryHighlightToJson(StoryHighlight instance) =>
    <String, dynamic>{
      'headline': instance.headline,
      'cardId': instance.cardId,
      'explanation': instance.explanation,
      'targetTab': instance.targetTab,
    };

StructuredStoryContent _$StructuredStoryContentFromJson(
  Map json,
) => StructuredStoryContent(
  roundTitle: json['roundTitle'] as String,
  overview: json['overview'] as String,
  strengths: (json['strengths'] as List<dynamic>)
      .map((e) => StoryHighlight.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  weaknesses: (json['weaknesses'] as List<dynamic>)
      .map((e) => StoryHighlight.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  mistakes: json['mistakes'] == null
      ? null
      : StoryHighlight.fromJson(
          Map<String, dynamic>.from(json['mistakes'] as Map),
        ),
  biggestOpportunity: json['biggestOpportunity'] == null
      ? null
      : StoryHighlight.fromJson(
          Map<String, dynamic>.from(json['biggestOpportunity'] as Map),
        ),
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
  shareHighlightStats: (json['shareHighlightStats'] as List<dynamic>?)
      ?.map(
        (e) => ShareHighlightStat.fromJson(Map<String, dynamic>.from(e as Map)),
      )
      .toList(),
  shareableHeadline: json['shareableHeadline'] as String?,
  roundVersionId: (json['roundVersionId'] as num).toInt(),
);

Map<String, dynamic> _$StructuredStoryContentToJson(
  StructuredStoryContent instance,
) => <String, dynamic>{
  'roundTitle': instance.roundTitle,
  'overview': instance.overview,
  'strengths': instance.strengths.map((e) => e.toJson()).toList(),
  'weaknesses': instance.weaknesses.map((e) => e.toJson()).toList(),
  'mistakes': instance.mistakes?.toJson(),
  'biggestOpportunity': instance.biggestOpportunity?.toJson(),
  'practiceAdvice': instance.practiceAdvice,
  'strategyTips': instance.strategyTips,
  'shareHighlightStats': instance.shareHighlightStats
      ?.map((e) => e.toJson())
      .toList(),
  'shareableHeadline': instance.shareableHeadline,
  'roundVersionId': instance.roundVersionId,
};
