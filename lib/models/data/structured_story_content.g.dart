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

StrokeCost _$StrokeCostFromJson(Map json) => StrokeCost(
  area: json['area'] as String,
  strokesLost: (json['strokesLost'] as num).toInt(),
  explanation: json['explanation'] as String,
);

Map<String, dynamic> _$StrokeCostToJson(StrokeCost instance) =>
    <String, dynamic>{
      'area': instance.area,
      'strokesLost': instance.strokesLost,
      'explanation': instance.explanation,
    };

ImprovementScenario _$ImprovementScenarioFromJson(Map json) =>
    ImprovementScenario(
      fix: json['fix'] as String,
      resultScore: json['resultScore'] as String,
      strokesSaved: (json['strokesSaved'] as num).toInt(),
    );

Map<String, dynamic> _$ImprovementScenarioToJson(
  ImprovementScenario instance,
) => <String, dynamic>{
  'fix': instance.fix,
  'resultScore': instance.resultScore,
  'strokesSaved': instance.strokesSaved,
};

WhatCouldHaveBeen _$WhatCouldHaveBeenFromJson(Map json) => WhatCouldHaveBeen(
  currentScore: json['currentScore'] as String,
  potentialScore: json['potentialScore'] as String,
  scenarios: (json['scenarios'] as List<dynamic>)
      .map(
        (e) =>
            ImprovementScenario.fromJson(Map<String, dynamic>.from(e as Map)),
      )
      .toList(),
  encouragement: json['encouragement'] as String,
);

Map<String, dynamic> _$WhatCouldHaveBeenToJson(WhatCouldHaveBeen instance) =>
    <String, dynamic>{
      'currentScore': instance.currentScore,
      'potentialScore': instance.potentialScore,
      'scenarios': instance.scenarios.map((e) => e.toJson()).toList(),
      'encouragement': instance.encouragement,
    };

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
  strokeCostBreakdown: (json['strokeCostBreakdown'] as List<dynamic>?)
      ?.map((e) => StrokeCost.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  whatCouldHaveBeen: json['whatCouldHaveBeen'] == null
      ? null
      : WhatCouldHaveBeen.fromJson(
          Map<String, dynamic>.from(json['whatCouldHaveBeen'] as Map),
        ),
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
  'strokeCostBreakdown': instance.strokeCostBreakdown
      ?.map((e) => e.toJson())
      .toList(),
  'whatCouldHaveBeen': instance.whatCouldHaveBeen?.toJson(),
  'roundVersionId': instance.roundVersionId,
};
