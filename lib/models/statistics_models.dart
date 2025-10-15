// Models for round statistics and analysis

import 'package:json_annotation/json_annotation.dart';

part 'statistics_models.g.dart';

@JsonSerializable()
class DiscStats {
  final String discName;
  final int timesThrown;
  final int birdies;
  final int pars;
  final int bogeys;
  final int fairwayHits;
  final int offFairway;
  final int outOfBounds;

  DiscStats({
    required this.discName,
    required this.timesThrown,
    required this.birdies,
    required this.pars,
    required this.bogeys,
    required this.fairwayHits,
    required this.offFairway,
    required this.outOfBounds,
  });

  double get birdieRate =>
      timesThrown > 0 ? (birdies / timesThrown) * 100 : 0.0;

  double get fairwayHitRate =>
      timesThrown > 0 ? (fairwayHits / timesThrown) * 100 : 0.0;

  double get averageScore {
    if (timesThrown == 0) return 0.0;
    // Simplified: birdie = -1, par = 0, bogey = +1
    return (birdies * -1 + bogeys * 1) / timesThrown;
  }

  factory DiscStats.fromJson(Map<String, dynamic> json) =>
      _$DiscStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DiscStatsToJson(this);
}

@JsonSerializable()
class PuttingStats {
  final String distanceRange; // e.g., "0-15 ft", "15-33 ft", "33-66 ft"
  final int attempted;
  final int made;

  PuttingStats({
    required this.distanceRange,
    required this.attempted,
    required this.made,
  });

  double get makePercentage => attempted > 0 ? (made / attempted) * 100 : 0.0;

  factory PuttingStats.fromJson(Map<String, dynamic> json) =>
      _$PuttingStatsFromJson(json);
  Map<String, dynamic> toJson() => _$PuttingStatsToJson(this);
}

@JsonSerializable()
class TechniqueStats {
  final String techniqueName; // "Backhand", "Forehand", etc.
  final int attempts;
  final int successful; // Based on outcome (birdie, made putt, good landing)
  final int unsuccessful; // OB, off fairway, penalties
  final int birdies;
  final int pars;
  final int bogeys;

  TechniqueStats({
    required this.techniqueName,
    required this.attempts,
    required this.successful,
    required this.unsuccessful,
    required this.birdies,
    required this.pars,
    required this.bogeys,
  });

  double get successRate => attempts > 0 ? (successful / attempts) * 100 : 0.0;

  double get birdieRate => attempts > 0 ? (birdies / attempts) * 100 : 0.0;

  factory TechniqueStats.fromJson(Map<String, dynamic> json) =>
      _$TechniqueStatsFromJson(json);
  Map<String, dynamic> toJson() => _$TechniqueStatsToJson(this);
}

@JsonSerializable()
class ScoringStats {
  final int totalHoles;
  final int eagles;
  final int birdies;
  final int pars;
  final int bogeys;
  final int doubleBogeyPlus;

  ScoringStats({
    required this.totalHoles,
    required this.eagles,
    required this.birdies,
    required this.pars,
    required this.bogeys,
    required this.doubleBogeyPlus,
  });

  double get eagleRate => totalHoles > 0 ? (eagles / totalHoles) * 100 : 0.0;
  double get birdieRate => totalHoles > 0 ? (birdies / totalHoles) * 100 : 0.0;
  double get parRate => totalHoles > 0 ? (pars / totalHoles) * 100 : 0.0;
  double get bogeyRate => totalHoles > 0 ? (bogeys / totalHoles) * 100 : 0.0;
  double get doubleBogeyPlusRate =>
      totalHoles > 0 ? (doubleBogeyPlus / totalHoles) * 100 : 0.0;

  factory ScoringStats.fromJson(Map<String, dynamic> json) =>
      _$ScoringStatsFromJson(json);
  Map<String, dynamic> toJson() => _$ScoringStatsToJson(this);
}

@JsonSerializable()
class ScrambleStats {
  final int scrambleOpportunities; // Times went OB or off fairway
  final int scrambleSaves; // Times still made par or better

  ScrambleStats({
    required this.scrambleOpportunities,
    required this.scrambleSaves,
  });

  double get scrambleRate => scrambleOpportunities > 0
      ? (scrambleSaves / scrambleOpportunities) * 100
      : 0.0;

  factory ScrambleStats.fromJson(Map<String, dynamic> json) =>
      _$ScrambleStatsFromJson(json);
  Map<String, dynamic> toJson() => _$ScrambleStatsToJson(this);
}

@JsonSerializable()
class ComparisonResult {
  final String technique1;
  final String technique2;
  final double technique1BirdieRate;
  final double technique2BirdieRate;
  final double technique1SuccessRate;
  final double technique2SuccessRate;
  final int technique1Count;
  final int technique2Count;

  ComparisonResult({
    required this.technique1,
    required this.technique2,
    required this.technique1BirdieRate,
    required this.technique2BirdieRate,
    required this.technique1SuccessRate,
    required this.technique2SuccessRate,
    required this.technique1Count,
    required this.technique2Count,
  });

  String get winner {
    if (technique1BirdieRate > technique2BirdieRate) return technique1;
    if (technique2BirdieRate > technique1BirdieRate) return technique2;
    return 'tie';
  }

  double get difference => (technique1BirdieRate - technique2BirdieRate).abs();

  factory ComparisonResult.fromJson(Map<String, dynamic> json) =>
      _$ComparisonResultFromJson(json);
  Map<String, dynamic> toJson() => _$ComparisonResultToJson(this);
}

@JsonSerializable()
class DiscInsight {
  final String discName;
  final double birdieRate;
  final int timesUsed;
  final String category; // "excellent", "good", "needs work"

  DiscInsight({
    required this.discName,
    required this.birdieRate,
    required this.timesUsed,
    required this.category,
  });

  factory DiscInsight.fromJson(Map<String, dynamic> json) =>
      _$DiscInsightFromJson(json);
  Map<String, dynamic> toJson() => _$DiscInsightToJson(this);
}

/// Per-distance-bucket putting statistics
@JsonSerializable()
class PuttBucketStats {
  final String label;
  final int makes;
  final int misses;
  final double avgDistance;

  PuttBucketStats({
    required this.label,
    required this.makes,
    required this.misses,
    required this.avgDistance,
  });

  int get attempts => makes + misses;
  double get makePercentage => attempts > 0 ? (makes / attempts) * 100 : 0.0;

  factory PuttBucketStats.fromJson(Map<String, dynamic> json) =>
      _$PuttBucketStatsFromJson(json);
  Map<String, dynamic> toJson() => _$PuttBucketStatsToJson(this);
}

/// Comprehensive putting summary with C1/C2 breakdown and distance buckets
@JsonSerializable(explicitToJson: true)
class PuttStats {
  final int c1Makes;
  final int c1Misses;
  final int c2Makes;
  final int c2Misses;
  final double avgMakeDistance;
  final double avgMissDistance;
  final double avgAttemptDistance;
  final double totalMadeDistance;
  final Map<String, PuttBucketStats> bucketStats;

  PuttStats({
    required this.c1Makes,
    required this.c1Misses,
    required this.c2Makes,
    required this.c2Misses,
    required this.avgMakeDistance,
    required this.avgMissDistance,
    required this.avgAttemptDistance,
    required this.totalMadeDistance,
    required this.bucketStats,
  });

  int get c1Attempts => c1Makes + c1Misses;
  int get c2Attempts => c2Makes + c2Misses;
  int get totalMakes => c1Makes + c2Makes;
  int get totalMisses => c1Misses + c2Misses;
  int get totalAttempts => totalMakes + totalMisses;

  // C1X stats (12-33 ft, excluding bulls-eye 0-11 ft)
  int get c1xMakes {
    final bucket1 = bucketStats['11-22 ft'];
    final bucket2 = bucketStats['22-33 ft'];
    return (bucket1?.makes ?? 0) + (bucket2?.makes ?? 0);
  }

  int get c1xMisses {
    final bucket1 = bucketStats['11-22 ft'];
    final bucket2 = bucketStats['22-33 ft'];
    return (bucket1?.misses ?? 0) + (bucket2?.misses ?? 0);
  }

  int get c1xAttempts => c1xMakes + c1xMisses;

  double get c1xPercentage =>
      c1xAttempts > 0 ? (c1xMakes / c1xAttempts) * 100 : 0.0;

  double get c1Percentage =>
      c1Attempts > 0 ? (c1Makes / c1Attempts) * 100 : 0.0;
  double get c2Percentage =>
      c2Attempts > 0 ? (c2Makes / c2Attempts) * 100 : 0.0;
  double get overallPercentage =>
      totalAttempts > 0 ? (totalMakes / totalAttempts) * 100 : 0.0;

  factory PuttStats.fromJson(Map<String, dynamic> json) =>
      _$PuttStatsFromJson(json);
  Map<String, dynamic> toJson() => _$PuttStatsToJson(this);
}

/// UDisc-style core performance metrics
@JsonSerializable()
class CoreStats {
  final double fairwayHitPct;
  final double parkedPct;
  final double c1InRegPct;
  final double c2InRegPct;
  final double obPct;
  final int totalHoles;

  CoreStats({
    required this.fairwayHitPct,
    required this.parkedPct,
    required this.c1InRegPct,
    required this.c2InRegPct,
    required this.obPct,
    required this.totalHoles,
  });

  factory CoreStats.fromJson(Map<String, dynamic> json) =>
      _$CoreStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CoreStatsToJson(this);
}

/// Disc-specific mistake tracking
@JsonSerializable()
class DiscMistake {
  final String discName;
  final int mistakeCount;
  final List<String> reasons; // LossReason strings

  DiscMistake({
    required this.discName,
    required this.mistakeCount,
    required this.reasons,
  });

  factory DiscMistake.fromJson(Map<String, dynamic> json) =>
      _$DiscMistakeFromJson(json);
  Map<String, dynamic> toJson() => _$DiscMistakeToJson(this);
}

@JsonSerializable()
class DiscPerformanceSummary {
  final String discName;
  final int goodShots;
  final int okayShots;
  final int badShots;
  final int totalShots;

  DiscPerformanceSummary({
    required this.discName,
    required this.goodShots,
    required this.okayShots,
    required this.badShots,
    required this.totalShots,
  });

  double get goodPercentage =>
      totalShots > 0 ? (goodShots / totalShots) * 100 : 0.0;
  double get okayPercentage =>
      totalShots > 0 ? (okayShots / totalShots) * 100 : 0.0;
  double get badPercentage =>
      totalShots > 0 ? (badShots / totalShots) * 100 : 0.0;

  factory DiscPerformanceSummary.fromJson(Map<String, dynamic> json) =>
      _$DiscPerformanceSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DiscPerformanceSummaryToJson(this);
}

/// Categorized mistake analysis
@JsonSerializable()
class MistakeTypeSummary {
  final String label;
  final int count;
  final double percentage;

  MistakeTypeSummary({
    required this.label,
    required this.count,
    required this.percentage,
  });

  factory MistakeTypeSummary.fromJson(Map<String, dynamic> json) =>
      _$MistakeTypeSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$MistakeTypeSummaryToJson(this);
}

/// Birdie rate statistics with counts
@JsonSerializable()
class BirdieRateStats {
  final double percentage;
  final int birdieCount;
  final int totalAttempts;

  BirdieRateStats({
    required this.percentage,
    required this.birdieCount,
    required this.totalAttempts,
  });

  factory BirdieRateStats.fromJson(Map<String, dynamic> json) =>
      _$BirdieRateStatsFromJson(json);
  Map<String, dynamic> toJson() => _$BirdieRateStatsToJson(this);
}

/// Individual segment data for score trend analysis
@JsonSerializable()
class ScoreSegment {
  final String label; // e.g., "1-3", "4-6", "7-9"
  final double avgScore; // Average relative to par for this segment
  final int holesPlayed;

  ScoreSegment({
    required this.label,
    required this.avgScore,
    required this.holesPlayed,
  });

  factory ScoreSegment.fromJson(Map<String, dynamic> json) =>
      _$ScoreSegmentFromJson(json);
  Map<String, dynamic> toJson() => _$ScoreSegmentToJson(this);
}

/// Progressive score trend analysis throughout the round
@JsonSerializable(explicitToJson: true)
class ScoreTrend {
  final List<ScoreSegment> segments;
  final String trendDirection; // "improving", "worsening", "stable"
  final double
  trendStrength; // Numeric measure of change (positive = improving)

  ScoreTrend({
    required this.segments,
    required this.trendDirection,
    required this.trendStrength,
  });

  factory ScoreTrend.fromJson(Map<String, dynamic> json) =>
      _$ScoreTrendFromJson(json);
  Map<String, dynamic> toJson() => _$ScoreTrendToJson(this);
}

/// Performance statistics for a section of the round
@JsonSerializable()
class SectionPerformance {
  final String sectionName; // "Front 9", "Back 9", "Last 6"
  final int holesPlayed;
  final double avgScore; // Average relative to par
  final double birdieRate;
  final double parRate;
  final double bogeyPlusRate;
  final double shotQualityRate; // Percentage of successful shots
  final double c1InRegRate;
  final double c2InRegRate;
  final double fairwayHitRate;
  final double obRate;
  final int mistakeCount;

  SectionPerformance({
    required this.sectionName,
    required this.holesPlayed,
    required this.avgScore,
    required this.birdieRate,
    required this.parRate,
    required this.bogeyPlusRate,
    required this.shotQualityRate,
    required this.c1InRegRate,
    required this.c2InRegRate,
    required this.fairwayHitRate,
    required this.obRate,
    required this.mistakeCount,
  });

  factory SectionPerformance.fromJson(Map<String, dynamic> json) =>
      _$SectionPerformanceFromJson(json);
  Map<String, dynamic> toJson() => _$SectionPerformanceToJson(this);
}

/// Scoring transition data - represents one row in the momentum transition matrix
@JsonSerializable()
class ScoringTransition {
  final String fromScore; // "Birdie", "Par", "Bogey", "Double+"
  final double toBirdiePercent;
  final double toParPercent;
  final double toBogeyPercent;
  final double toDoublePercent;

  ScoringTransition({
    required this.fromScore,
    required this.toBirdiePercent,
    required this.toParPercent,
    required this.toBogeyPercent,
    required this.toDoublePercent,
  });

  /// Helper: Par or better rate (birdie + par)
  double get parOrBetterPercent => toBirdiePercent + toParPercent;

  /// Helper: Bogey or worse rate (bogey + double+)
  double get bogeyOrWorsePercent => toBogeyPercent + toDoublePercent;

  factory ScoringTransition.fromJson(Map<String, dynamic> json) =>
      _$ScoringTransitionFromJson(json);
  Map<String, dynamic> toJson() => _$ScoringTransitionToJson(this);
}

/// Complete momentum and psychological analysis
@JsonSerializable(explicitToJson: true)
class PsychStats {
  /// Transition matrix: from score -> transition percentages
  final Map<String, ScoringTransition> transitionMatrix;

  /// How much more likely to birdie after birdie vs after bogey
  final double momentumMultiplier;

  /// Performance drop percentage after bad holes
  final double tiltFactor;

  /// Par-or-better rate after bogey+ holes
  final double bounceBackRate;

  /// Frequency of back-to-back bogey+ holes
  final double compoundErrorRate;

  /// Longest streak of consecutive par-or-better holes
  final int longestParStreak;

  /// Mental game profile classification
  final String
  mentalProfile; // "Momentum Player", "Even Keel", "Clutch Closer", "Slow Starter"

  /// Actionable insights based on patterns
  final List<String> insights;

  /// Performance statistics for front 9 holes
  final SectionPerformance? front9Performance;

  /// Performance statistics for back 9 holes
  final SectionPerformance? back9Performance;

  /// Performance statistics for last 6 holes
  final SectionPerformance? last6Performance;

  /// Conditioning score (0-100) - measures performance drop over the round
  final double conditioningScore;

  /// Progressive score trend analysis throughout the round
  final ScoreTrend? scoreTrend;

  PsychStats({
    required this.transitionMatrix,
    required this.momentumMultiplier,
    required this.tiltFactor,
    required this.bounceBackRate,
    required this.compoundErrorRate,
    required this.longestParStreak,
    required this.mentalProfile,
    required this.insights,
    this.front9Performance,
    this.back9Performance,
    this.last6Performance,
    required this.conditioningScore,
    this.scoreTrend,
  });

  factory PsychStats.fromJson(Map<String, dynamic> json) =>
      _$PsychStatsFromJson(json);
  Map<String, dynamic> toJson() => _$PsychStatsToJson(this);
}
