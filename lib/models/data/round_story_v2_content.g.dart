// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_story_v2_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScopedStats _$ScopedStatsFromJson(Map json) => ScopedStats(
  holeRange: json['holeRange'] == null
      ? null
      : HoleRange.fromJson(Map<String, dynamic>.from(json['holeRange'] as Map)),
  percentage: (json['percentage'] as num?)?.toDouble(),
  made: (json['made'] as num?)?.toInt(),
  attempts: (json['attempts'] as num?)?.toInt(),
  label: json['label'] as String?,
);

Map<String, dynamic> _$ScopedStatsToJson(ScopedStats instance) =>
    <String, dynamic>{
      'holeRange': instance.holeRange?.toJson(),
      'percentage': instance.percentage,
      'made': instance.made,
      'attempts': instance.attempts,
      'label': instance.label,
    };

StoryCallout _$StoryCalloutFromJson(Map json) => StoryCallout(
  cardId: json['cardId'] as String?,
  scopedStats: json['scopedStats'] == null
      ? null
      : ScopedStats.fromJson(
          Map<String, dynamic>.from(json['scopedStats'] as Map),
        ),
);

Map<String, dynamic> _$StoryCalloutToJson(StoryCallout instance) =>
    <String, dynamic>{
      'cardId': instance.cardId,
      'scopedStats': instance.scopedStats?.toJson(),
    };

StoryParagraph _$StoryParagraphFromJson(Map json) => StoryParagraph(
  text: json['text'] as String,
  callouts:
      (json['callouts'] as List<dynamic>?)
          ?.map(
            (e) => StoryCallout.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$StoryParagraphToJson(StoryParagraph instance) =>
    <String, dynamic>{
      'text': instance.text,
      'callouts': instance.callouts.map((e) => e.toJson()).toList(),
    };

ImprovementScenarioV2 _$ImprovementScenarioV2FromJson(Map json) =>
    ImprovementScenarioV2(
      fix: json['fix'] as String,
      resultScore: json['resultScore'] as String,
      strokesSaved: (json['strokesSaved'] as num).toInt(),
    );

Map<String, dynamic> _$ImprovementScenarioV2ToJson(
  ImprovementScenarioV2 instance,
) => <String, dynamic>{
  'fix': instance.fix,
  'resultScore': instance.resultScore,
  'strokesSaved': instance.strokesSaved,
};

WhatCouldHaveBeenV2 _$WhatCouldHaveBeenV2FromJson(Map json) =>
    WhatCouldHaveBeenV2(
      currentScore: json['currentScore'] as String,
      potentialScore: json['potentialScore'] as String,
      scenarios: (json['scenarios'] as List<dynamic>)
          .map(
            (e) => ImprovementScenarioV2.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      encouragement: json['encouragement'] as String,
    );

Map<String, dynamic> _$WhatCouldHaveBeenV2ToJson(
  WhatCouldHaveBeenV2 instance,
) => <String, dynamic>{
  'currentScore': instance.currentScore,
  'potentialScore': instance.potentialScore,
  'scenarios': instance.scenarios.map((e) => e.toJson()).toList(),
  'encouragement': instance.encouragement,
};

RoundStoryV2Content _$RoundStoryV2ContentFromJson(Map json) =>
    RoundStoryV2Content(
      roundTitle: json['roundTitle'] as String,
      overview: json['overview'] as String,
      story: (json['story'] as List<dynamic>)
          .map(
            (e) => StoryParagraph.fromJson(Map<String, dynamic>.from(e as Map)),
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
      roundVersionId: (json['roundVersionId'] as num).toInt(),
    );

Map<String, dynamic> _$RoundStoryV2ContentToJson(
  RoundStoryV2Content instance,
) => <String, dynamic>{
  'roundTitle': instance.roundTitle,
  'overview': instance.overview,
  'story': instance.story.map((e) => e.toJson()).toList(),
  'whatCouldHaveBeen': instance.whatCouldHaveBeen.toJson(),
  'shareableHeadline': instance.shareableHeadline,
  'practiceAdvice': instance.practiceAdvice,
  'strategyTips': instance.strategyTips,
  'roundVersionId': instance.roundVersionId,
};
