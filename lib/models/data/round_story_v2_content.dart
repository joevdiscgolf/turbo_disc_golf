import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/round_story_v3_content.dart';

part 'round_story_v2_content.g.dart';

/// Scoped statistics for a specific hole range
/// Used when a callout references stats for a subset of holes rather than the whole round
@JsonSerializable(explicitToJson: true, anyMap: true)
class ScopedStats {
  /// The hole range these stats apply to (optional, for reference)
  final HoleRange? holeRange;

  /// The percentage value for this scope (e.g., 100.0 for 100%)
  final double? percentage;

  /// Number of successful attempts (e.g., putts made)
  final int? made;

  /// Total attempts
  final int? attempts;

  /// Human-readable label for the scope (e.g., "Front 9", "Holes 7-12")
  final String? label;

  const ScopedStats({
    this.holeRange,
    this.percentage,
    this.made,
    this.attempts,
    this.label,
  });

  factory ScopedStats.fromJson(Map<String, dynamic> json) =>
      _$ScopedStatsFromJson(json);

  Map<String, dynamic> toJson() => _$ScopedStatsToJson(this);
}

/// V2 Story Callout Card (evidence/stat under paragraph)
@JsonSerializable(explicitToJson: true, anyMap: true)
class StoryCallout {
  /// Stat card ID (e.g., 'C1X_PUTTING', 'FAIRWAY_HIT')
  /// Nullable to handle legacy data that may have null cardIds
  final String? cardId;

  /// Optional scoped stats for hole-range-specific display
  /// When provided, the stat card will show these values instead of whole-round stats
  final ScopedStats? scopedStats;

  const StoryCallout({this.cardId, this.scopedStats});

  /// Whether this callout has a valid cardId
  bool get isValid => cardId != null && cardId!.isNotEmpty;

  factory StoryCallout.fromJson(Map<String, dynamic> json) =>
      _$StoryCalloutFromJson(json);

  Map<String, dynamic> toJson() => _$StoryCalloutToJson(this);
}

/// V2 Story Paragraph with optional callouts
@JsonSerializable(explicitToJson: true, anyMap: true)
class StoryParagraph {
  /// 2-5 sentences of narrative
  final String text;

  /// 0-2 callouts per paragraph
  final List<StoryCallout> callouts;

  const StoryParagraph({required this.text, this.callouts = const []});

  factory StoryParagraph.fromJson(Map<String, dynamic> json) =>
      _$StoryParagraphFromJson(json);

  Map<String, dynamic> toJson() => _$StoryParagraphToJson(this);
}

/// V2 Improvement Scenario
@JsonSerializable(explicitToJson: true, anyMap: true)
class ImprovementScenarioV2 {
  /// What to fix (e.g., "C1X Putting")
  final String fix;

  /// Result score (e.g., "-1")
  final String resultScore;

  /// Numeric strokes saved (unquoted in YAML)
  final int strokesSaved;

  const ImprovementScenarioV2({
    required this.fix,
    required this.resultScore,
    required this.strokesSaved,
  });

  factory ImprovementScenarioV2.fromJson(Map<String, dynamic> json) =>
      _$ImprovementScenarioV2FromJson(json);

  Map<String, dynamic> toJson() => _$ImprovementScenarioV2ToJson(this);
}

/// V2 "What Could Have Been" section
@JsonSerializable(explicitToJson: true, anyMap: true)
class WhatCouldHaveBeenV2 {
  /// Current score (e.g., "+5")
  final String currentScore;

  /// Potential score (e.g., "-1")
  final String potentialScore;

  /// List of improvement scenarios
  final List<ImprovementScenarioV2> scenarios;

  /// 1 sentence, calm/realistic encouragement
  final String encouragement;

  const WhatCouldHaveBeenV2({
    required this.currentScore,
    required this.potentialScore,
    required this.scenarios,
    required this.encouragement,
  });

  factory WhatCouldHaveBeenV2.fromJson(Map<String, dynamic> json) =>
      _$WhatCouldHaveBeenV2FromJson(json);

  Map<String, dynamic> toJson() => _$WhatCouldHaveBeenV2ToJson(this);
}

/// Main V2 Story Content Model
@JsonSerializable(explicitToJson: true, anyMap: true)
class RoundStoryV2Content {
  /// 3-6 words, direct title
  final String roundTitle;

  /// 2-3 sentences, NO raw stats
  final String overview;

  /// 3-6 paragraphs with callouts
  final List<StoryParagraph> story;

  /// Required score improvement section
  final WhatCouldHaveBeenV2 whatCouldHaveBeen;

  /// Optional shareable headline (1-2 sentences, starts with "You")
  final String? shareableHeadline;

  /// Optional practice advice (2 strings)
  final List<String> practiceAdvice;

  /// Optional strategy tips (2 strings)
  final List<String> strategyTips;

  /// Version tracking
  final int roundVersionId;

  const RoundStoryV2Content({
    required this.roundTitle,
    required this.overview,
    required this.story,
    required this.whatCouldHaveBeen,
    this.shareableHeadline,
    this.practiceAdvice = const [],
    this.strategyTips = const [],
    required this.roundVersionId,
  });

  factory RoundStoryV2Content.fromJson(Map<String, dynamic> json) {
    // Parse the base object
    final RoundStoryV2Content content = _$RoundStoryV2ContentFromJson(json);

    // Validate story structure
    if (content.story.length < 3 || content.story.length > 6) {
      throw Exception(
        'V2 story must have 3-6 paragraphs, got ${content.story.length}',
      );
    }

    // Validate callout uniqueness and limits
    final Set<String> seenCardIds = {};
    final List<StoryParagraph> cleanedParagraphs = [];
    int totalCallouts = 0;

    for (int i = 0; i < content.story.length; i++) {
      final StoryParagraph paragraph = content.story[i];
      final List<StoryCallout> validCallouts = [];

      // Deduplicate callouts - keep first occurrence only, skip invalid ones
      for (final StoryCallout callout in paragraph.callouts) {
        // Skip callouts with null or empty cardId
        if (!callout.isValid) {
          debugPrint(
            '⚠️  Invalid callout (null/empty cardId) in paragraph $i - skipping',
          );
          continue;
        }
        if (seenCardIds.contains(callout.cardId)) {
          debugPrint(
            '⚠️  Duplicate cardId "${callout.cardId}" in paragraph $i - removing duplicate',
          );
          continue; // Skip duplicate
        }
        seenCardIds.add(callout.cardId!);
        validCallouts.add(callout);
      }

      // Enforce max 2 callouts per paragraph
      if (validCallouts.length > 2) {
        debugPrint(
          '⚠️  Paragraph $i has ${validCallouts.length} callouts (max 2) - keeping first 2',
        );
        cleanedParagraphs.add(
          StoryParagraph(
            text: paragraph.text,
            callouts: validCallouts.take(2).toList(),
          ),
        );
        totalCallouts += 2;
      } else {
        cleanedParagraphs.add(
          StoryParagraph(text: paragraph.text, callouts: validCallouts),
        );
        totalCallouts += validCallouts.length;
      }
    }

    // Enforce max 6 total callouts (already handled above, but log if needed)
    if (totalCallouts > 6) {
      debugPrint(
        '⚠️  Total callouts ($totalCallouts) exceeds recommended maximum of 6',
      );
    }

    // Return cleaned content with deduplicated callouts
    return RoundStoryV2Content(
      roundTitle: content.roundTitle,
      overview: content.overview,
      story: cleanedParagraphs,
      whatCouldHaveBeen: content.whatCouldHaveBeen,
      shareableHeadline: content.shareableHeadline,
      practiceAdvice: content.practiceAdvice,
      strategyTips: content.strategyTips,
      roundVersionId: content.roundVersionId,
    );
  }

  Map<String, dynamic> toJson() => _$RoundStoryV2ContentToJson(this);
}
