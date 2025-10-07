// Models for round statistics and analysis

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
}

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
}

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
}

class ScoringStats {
  final int totalHoles;
  final int birdies;
  final int pars;
  final int bogeys;
  final int doubleBogeyPlus;

  ScoringStats({
    required this.totalHoles,
    required this.birdies,
    required this.pars,
    required this.bogeys,
    required this.doubleBogeyPlus,
  });

  double get birdieRate => totalHoles > 0 ? (birdies / totalHoles) * 100 : 0.0;
  double get parRate => totalHoles > 0 ? (pars / totalHoles) * 100 : 0.0;
  double get bogeyRate => totalHoles > 0 ? (bogeys / totalHoles) * 100 : 0.0;
  double get doubleBogeyPlusRate =>
      totalHoles > 0 ? (doubleBogeyPlus / totalHoles) * 100 : 0.0;
}

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
}

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
}

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
}

/// Per-distance-bucket putting statistics
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
}

/// Comprehensive putting summary with C1/C2 breakdown and distance buckets
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

  double get c1Percentage =>
      c1Attempts > 0 ? (c1Makes / c1Attempts) * 100 : 0.0;
  double get c2Percentage =>
      c2Attempts > 0 ? (c2Makes / c2Attempts) * 100 : 0.0;
  double get overallPercentage =>
      totalAttempts > 0 ? (totalMakes / totalAttempts) * 100 : 0.0;
}

/// UDisc-style core performance metrics
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
}

/// Disc-specific mistake tracking
class DiscMistake {
  final String discName;
  final int mistakeCount;
  final List<String> reasons; // LossReason strings

  DiscMistake({
    required this.discName,
    required this.mistakeCount,
    required this.reasons,
  });
}

/// Categorized mistake analysis
class MistakeTypeSummary {
  final String label;
  final int count;
  final double percentage;

  MistakeTypeSummary({
    required this.label,
    required this.count,
    required this.percentage,
  });
}

/// Birdie rate statistics with counts
class BirdieRateStats {
  final double percentage;
  final int birdieCount;
  final int totalAttempts;

  BirdieRateStats({
    required this.percentage,
    required this.birdieCount,
    required this.totalAttempts,
  });
}
