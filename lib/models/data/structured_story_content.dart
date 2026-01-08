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

  /// Version ID of the round this story was generated for
  /// Used to detect if story is outdated
  final int roundVersionId;

  factory StructuredStoryContent.fromJson(Map<String, dynamic> json) =>
      _$StructuredStoryContentFromJson(json);

  Map<String, dynamic> toJson() => _$StructuredStoryContentToJson(this);
}
