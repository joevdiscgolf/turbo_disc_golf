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

  double get successRate =>
      attempts > 0 ? (successful / attempts) * 100 : 0.0;

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

  double get scrambleRate =>
      scrambleOpportunities > 0
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
