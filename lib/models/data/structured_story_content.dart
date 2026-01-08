import 'package:json_annotation/json_annotation.dart';

part 'structured_story_content.g.dart';

/// Section types in a structured story
enum StorySection {
  overview,     // Round Overview - context setting
  strengths,    // What You Did Well - positive highlights
  weaknesses,   // What Cost You Strokes - mistakes/issues
  opportunity,  // Biggest Opportunity to Improve - single focus
  advice,       // Practice & Strategy - actionable advice
}

/// A stat selected by AI for the share card
@JsonSerializable(explicitToJson: true, anyMap: true)
class ShareHighlightStat {
  const ShareHighlightStat({
    required this.statId,
    this.reason,
  });

  /// Stat ID for the share card (e.g., 'c1PuttPct', 'fairwayPct', 'birdies')
  /// Valid values: score, c1PuttPct, c1xPuttPct, c2PuttPct, fairwayPct,
  /// parkedPct, c1InRegPct, obPct, birdies, bounceBack
  final String statId;

  /// Optional reason why this stat was selected (for debugging/display)
  final String? reason;

  factory ShareHighlightStat.fromJson(Map<String, dynamic> json) =>
      _$ShareHighlightStatFromJson(json);

  Map<String, dynamic> toJson() => _$ShareHighlightStatToJson(this);
}

/// Stroke cost breakdown for "What Cost You Strokes" section
/// Shows how many strokes were lost in each area with explanation
@JsonSerializable(explicitToJson: true, anyMap: true)
class StrokeCost {
  const StrokeCost({
    required this.area,
    required this.strokesLost,
    required this.explanation,
  });

  /// The area that cost strokes (e.g., "C2 Putting", "OB Penalties")
  final String area;

  /// Estimated number of strokes lost in this area
  final int strokesLost;

  /// Detailed explanation of why strokes were lost
  /// Example: "3 missed C2 putts at 8% vs your 20% average"
  final String explanation;

  factory StrokeCost.fromJson(Map<String, dynamic> json) =>
      _$StrokeCostFromJson(json);

  Map<String, dynamic> toJson() => _$StrokeCostToJson(this);
}

/// Single improvement scenario for "What Could Have Been" section
/// Shows what score would result from fixing one area
@JsonSerializable(explicitToJson: true, anyMap: true)
class ImprovementScenario {
  const ImprovementScenario({
    required this.fix,
    required this.resultScore,
    required this.strokesSaved,
  });

  /// What to fix (e.g., "C2 putting", "OB penalties", "All of the above")
  final String fix;

  /// Resulting score if this area is fixed (e.g., "+2", "-1")
  final String resultScore;

  /// Number of strokes saved by this fix
  final int strokesSaved;

  factory ImprovementScenario.fromJson(Map<String, dynamic> json) =>
      _$ImprovementScenarioFromJson(json);

  Map<String, dynamic> toJson() => _$ImprovementScenarioToJson(this);
}

/// "What Could Have Been" section showing potential score improvements
/// Numbers-focused, actionable, forward-looking
@JsonSerializable(explicitToJson: true, anyMap: true)
class WhatCouldHaveBeen {
  const WhatCouldHaveBeen({
    required this.currentScore,
    required this.potentialScore,
    required this.scenarios,
    required this.encouragement,
  });

  /// Current round score relative to par (e.g., "+5", "-2")
  final String currentScore;

  /// Best potential score if all issues fixed (e.g., "-1")
  final String potentialScore;

  /// List of improvement scenarios showing what each fix would achieve
  final List<ImprovementScenario> scenarios;

  /// Encouraging message about the path forward
  /// Example: "Your next under-par round is 6 smart decisions away."
  final String encouragement;

  factory WhatCouldHaveBeen.fromJson(Map<String, dynamic> json) =>
      _$WhatCouldHaveBeenFromJson(json);

  Map<String, dynamic> toJson() => _$WhatCouldHaveBeenToJson(this);
}

/// A single stat highlight in the story with explanation
@JsonSerializable(explicitToJson: true, anyMap: true)
class StoryHighlight {
  const StoryHighlight({
    this.headline,
    this.cardId,
    this.explanation,
    this.targetTab,
  });

  /// Optional sub-headline for this topic (e.g., "Dialed in from the tee")
  /// Used to give each highlight its own mini-title
  final String? headline;

  /// Card ID for the stat (e.g., 'C1X_PUTTING', 'FAIRWAY_HIT', 'OB_RATE')
  /// Optional to support text-only highlights without widgets
  final String? cardId;

  /// Disc golf coaching context/explanation for this stat
  /// Uses terminology like "giving yourself looks", "inside the circle", etc.
  final String? explanation;

  /// Target tab for navigation (e.g., 'putting', 'driving', 'mistakes')
  /// Used when user taps the stat card to navigate to details
  final String? targetTab;

  factory StoryHighlight.fromJson(Map<String, dynamic> json) =>
      _$StoryHighlightFromJson(json);

  Map<String, dynamic> toJson() => _$StoryHighlightToJson(this);
}

/// Structured story content with specific sections
///
/// Replaces freeform AI narrative with organized coaching sections:
/// 1. Round Title - Short headline summarizing the round
/// 2. Overview - Set context without stats
/// 3. Strengths - 1-2 things done well with stat cards
/// 4. Weaknesses - 1-2 things that cost strokes with stat cards
/// 5. Mistakes - Key mistakes that cost strokes
/// 6. Biggest Opportunity - ONE emphasized focus area
/// 7. Practice Advice - Actionable practice drills
/// 8. Strategy Tips - Course management and decision-making advice
@JsonSerializable(explicitToJson: true, anyMap: true)
class StructuredStoryContent {
  const StructuredStoryContent({
    required this.roundTitle,
    required this.overview,
    required this.strengths,
    required this.weaknesses,
    this.mistakes,
    this.biggestOpportunity,
    this.practiceAdvice = const [],
    this.strategyTips = const [],
    this.shareHighlightStats,
    this.shareableHeadline,
    this.strokeCostBreakdown,
    this.whatCouldHaveBeen,
    required this.roundVersionId,
  });

  /// Short title summarizing the round (3-5 words)
  /// Example: "Strong -6 Round", "Birdie Fest at Foxwood", "Solid Par Performance"
  final String roundTitle;

  /// 2-3 sentence round overview
  /// Sets context and tone without specific stats
  /// Example: "This was a solid round where you gave yourself chances on most holes"
  final String overview;

  /// List of 1-2 strength highlights (what went well)
  /// Each includes a stat card ID and disc golf coaching explanation
  final List<StoryHighlight> strengths;

  /// List of 1-2 weakness highlights (what cost strokes)
  /// Each includes a stat card ID and constructive explanation
  final List<StoryHighlight> weaknesses;

  /// Key mistakes that cost strokes (optional)
  /// Single highlight about mistakes made with stat card
  final StoryHighlight? mistakes;

  /// Single biggest opportunity for improvement
  /// Emphasized in UI, represents highest-impact change
  final StoryHighlight? biggestOpportunity;

  /// List of actionable practice advice (no stats)
  /// Concrete, time-bounded, disc-golf realistic
  /// Example: "Practice lag putting from 40-50 feet"
  final List<String> practiceAdvice;

  /// List of specific strategy tips (no obvious advice)
  /// Focus on non-obvious course management and decision-making
  /// Example: "Consider using a stable mid-range on hole 7 instead of overstable driver"
  final List<String> strategyTips;

  /// AI-selected stats to highlight on share card (2-3 stats)
  /// These are the most notable/impressive stats from the round
  /// Null for legacy stories - use fallback stats in that case
  final List<ShareHighlightStat>? shareHighlightStats;

  /// 2-3 sentence shareable headline for social media
  /// Encouraging, informative, and impactful summary of the round
  /// Good for sharing - similar to tagline in roast/glaze cards
  /// Example: "Crushed it at Maple Hill with 5 birdies and only 1 bogey.
  /// The putting was locked in from C1X. Personal best incoming!"
  final String? shareableHeadline;

  /// Detailed breakdown of strokes lost in each area
  /// Used in "What Cost You Strokes" section with explanations
  final List<StrokeCost>? strokeCostBreakdown;

  /// "What Could Have Been" hero card data
  /// Shows current vs potential score and improvement scenarios
  final WhatCouldHaveBeen? whatCouldHaveBeen;

  /// Version ID of the round this story was generated for
  /// Used to detect if story is outdated
  final int roundVersionId;

  factory StructuredStoryContent.fromJson(Map<String, dynamic> json) =>
      _$StructuredStoryContentFromJson(json);

  Map<String, dynamic> toJson() => _$StructuredStoryContentToJson(this);
}
