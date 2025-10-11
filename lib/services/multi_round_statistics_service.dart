import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';

/// Service for calculating aggregated statistics across multiple rounds
class MultiRoundStatisticsService {
  MultiRoundStatisticsService(this.rounds);

  final List<DGRound> rounds;

  /// Get overall scoring statistics across all rounds
  ScoringStats getScoringStats() {
    int totalBirdies = 0;
    int totalPars = 0;
    int totalBogeys = 0;
    int totalDoubleBogeyPlus = 0;
    int totalHoles = 0;

    for (var round in rounds) {
      final roundStats = RoundStatisticsService(round).getScoringStats();
      totalBirdies += roundStats.birdies;
      totalPars += roundStats.pars;
      totalBogeys += roundStats.bogeys;
      totalDoubleBogeyPlus += roundStats.doubleBogeyPlus;
      totalHoles += roundStats.totalHoles;
    }

    return ScoringStats(
      totalHoles: totalHoles,
      birdies: totalBirdies,
      pars: totalPars,
      bogeys: totalBogeys,
      doubleBogeyPlus: totalDoubleBogeyPlus,
    );
  }

  /// Get aggregated putting statistics
  PuttStats getPuttingStats() {
    int totalC1Makes = 0;
    int totalC1Misses = 0;
    int totalC2Makes = 0;
    int totalC2Misses = 0;

    final List<double> allMakeDistances = [];
    final List<double> allMissDistances = [];
    final List<double> allAttemptDistances = [];
    double totalMadeDistance = 0.0;

    // Aggregate bucket stats
    final Map<String, List<int>> bucketMakes = {};
    final Map<String, List<int>> bucketMisses = {};
    final Map<String, List<double>> bucketDistances = {};

    for (var round in rounds) {
      final roundPuttStats = RoundStatisticsService(round).getPuttingSummary();

      totalC1Makes += roundPuttStats.c1Makes;
      totalC1Misses += roundPuttStats.c1Misses;
      totalC2Makes += roundPuttStats.c2Makes;
      totalC2Misses += roundPuttStats.c2Misses;
      totalMadeDistance += roundPuttStats.totalMadeDistance;

      // Collect distances for averaging (weighted by round)
      if (roundPuttStats.totalMakes > 0) {
        allMakeDistances.add(roundPuttStats.avgMakeDistance);
      }
      if (roundPuttStats.totalMisses > 0) {
        allMissDistances.add(roundPuttStats.avgMissDistance);
      }
      if (roundPuttStats.totalAttempts > 0) {
        allAttemptDistances.add(roundPuttStats.avgAttemptDistance);
      }

      // Aggregate bucket stats
      roundPuttStats.bucketStats.forEach((label, bucket) {
        bucketMakes.putIfAbsent(label, () => []);
        bucketMisses.putIfAbsent(label, () => []);
        bucketDistances.putIfAbsent(label, () => []);

        bucketMakes[label]!.add(bucket.makes);
        bucketMisses[label]!.add(bucket.misses);
        bucketDistances[label]!.add(bucket.avgDistance);
      });
    }

    // Calculate average distances
    final avgMakeDistance = allMakeDistances.isNotEmpty
        ? allMakeDistances.reduce((a, b) => a + b) / allMakeDistances.length
        : 0.0;
    final avgMissDistance = allMissDistances.isNotEmpty
        ? allMissDistances.reduce((a, b) => a + b) / allMissDistances.length
        : 0.0;
    final avgAttemptDistance = allAttemptDistances.isNotEmpty
        ? allAttemptDistances.reduce((a, b) => a + b) / allAttemptDistances.length
        : 0.0;

    // Build aggregated bucket stats
    final Map<String, PuttBucketStats> aggregatedBucketStats = {};
    bucketMakes.forEach((label, makes) {
      final totalMakes = makes.fold<int>(0, (sum, val) => sum + val);
      final totalMisses = bucketMisses[label]!.fold<int>(0, (sum, val) => sum + val);
      final avgDist = bucketDistances[label]!.fold<double>(0.0, (sum, val) => sum + val) /
          bucketDistances[label]!.length;

      aggregatedBucketStats[label] = PuttBucketStats(
        label: label,
        makes: totalMakes,
        misses: totalMisses,
        avgDistance: avgDist,
      );
    });

    return PuttStats(
      c1Makes: totalC1Makes,
      c1Misses: totalC1Misses,
      c2Makes: totalC2Makes,
      c2Misses: totalC2Misses,
      avgMakeDistance: avgMakeDistance,
      avgMissDistance: avgMissDistance,
      avgAttemptDistance: avgAttemptDistance,
      totalMadeDistance: totalMadeDistance,
      bucketStats: aggregatedBucketStats,
    );
  }

  /// Get aggregated core stats (UDisc-style)
  CoreStats getCoreStats() {
    double totalFairwayHitPct = 0.0;
    double totalParkedPct = 0.0;
    double totalC1InRegPct = 0.0;
    double totalC2InRegPct = 0.0;
    double totalObPct = 0.0;
    int totalHoles = 0;
    int roundCount = 0;

    for (var round in rounds) {
      final roundCoreStats = RoundStatisticsService(round).getCoreStats();
      if (roundCoreStats.totalHoles > 0) {
        totalFairwayHitPct += roundCoreStats.fairwayHitPct;
        totalParkedPct += roundCoreStats.parkedPct;
        totalC1InRegPct += roundCoreStats.c1InRegPct;
        totalC2InRegPct += roundCoreStats.c2InRegPct;
        totalObPct += roundCoreStats.obPct;
        totalHoles += roundCoreStats.totalHoles;
        roundCount++;
      }
    }

    return CoreStats(
      fairwayHitPct: roundCount > 0 ? totalFairwayHitPct / roundCount : 0.0,
      parkedPct: roundCount > 0 ? totalParkedPct / roundCount : 0.0,
      c1InRegPct: roundCount > 0 ? totalC1InRegPct / roundCount : 0.0,
      c2InRegPct: roundCount > 0 ? totalC2InRegPct / roundCount : 0.0,
      obPct: roundCount > 0 ? totalObPct / roundCount : 0.0,
      totalHoles: totalHoles,
    );
  }

  /// Get aggregated tee shot birdie rates by technique
  Map<String, BirdieRateStats> getTeeShotBirdieRates() {
    final Map<String, int> birdiesByTechnique = {};
    final Map<String, int> attemptsByTechnique = {};

    for (var round in rounds) {
      final roundStats = RoundStatisticsService(round).getTeeShotBirdieRateStats();
      roundStats.forEach((technique, stats) {
        birdiesByTechnique[technique] =
            (birdiesByTechnique[technique] ?? 0) + stats.birdieCount;
        attemptsByTechnique[technique] =
            (attemptsByTechnique[technique] ?? 0) + stats.totalAttempts;
      });
    }

    return attemptsByTechnique.map((technique, attempts) {
      final birdies = birdiesByTechnique[technique] ?? 0;
      final percentage = attempts > 0 ? (birdies / attempts) * 100 : 0.0;
      return MapEntry(
        technique,
        BirdieRateStats(
          percentage: percentage,
          birdieCount: birdies,
          totalAttempts: attempts,
        ),
      );
    });
  }

  /// Get aggregated disc performance summaries
  List<DiscPerformanceSummary> getDiscPerformanceSummaries() {
    final Map<String, Map<String, int>> performanceByDisc = {};

    for (var round in rounds) {
      final roundSummaries =
          RoundStatisticsService(round).getDiscPerformanceSummaries();
      for (var summary in roundSummaries) {
        performanceByDisc.putIfAbsent(
          summary.discName,
          () => {'good': 0, 'okay': 0, 'bad': 0},
        );
        performanceByDisc[summary.discName]!['good'] =
            performanceByDisc[summary.discName]!['good']! + summary.goodShots;
        performanceByDisc[summary.discName]!['okay'] =
            performanceByDisc[summary.discName]!['okay']! + summary.okayShots;
        performanceByDisc[summary.discName]!['bad'] =
            performanceByDisc[summary.discName]!['bad']! + summary.badShots;
      }
    }

    final summaries = performanceByDisc.entries.map((entry) {
      final stats = entry.value;
      final totalShots = stats['good']! + stats['okay']! + stats['bad']!;
      return DiscPerformanceSummary(
        discName: entry.key,
        goodShots: stats['good']!,
        okayShots: stats['okay']!,
        badShots: stats['bad']!,
        totalShots: totalShots,
      );
    }).toList();

    summaries.sort((a, b) {
      final percentageComparison = b.goodPercentage.compareTo(a.goodPercentage);
      if (percentageComparison != 0) return percentageComparison;
      return b.totalShots.compareTo(a.totalShots);
    });

    return summaries;
  }

  /// Get aggregated mistake types
  List<MistakeTypeSummary> getMistakeTypes() {
    final Map<String, int> mistakeTypeCounts = {};
    int totalMistakes = 0;

    for (var round in rounds) {
      final roundMistakes = RoundStatisticsService(round).getMistakeTypes();
      for (var mistake in roundMistakes) {
        mistakeTypeCounts[mistake.label] =
            (mistakeTypeCounts[mistake.label] ?? 0) + mistake.count;
        totalMistakes += mistake.count;
      }
    }

    final summaries = mistakeTypeCounts.entries.map((entry) {
      final percentage = totalMistakes > 0
          ? (entry.value / totalMistakes) * 100
          : 0.0;
      return MistakeTypeSummary(
        label: entry.key,
        count: entry.value,
        percentage: percentage,
      );
    }).toList();

    summaries.sort((a, b) => b.count.compareTo(a.count));

    return summaries;
  }

  /// Get average birdie putt distance across all rounds
  double getAverageBirdiePuttDistance() {
    final List<double> birdiePuttDistances = [];

    for (var round in rounds) {
      final distance = RoundStatisticsService(round).getAverageBirdiePuttDistance();
      if (distance > 0) {
        birdiePuttDistances.add(distance);
      }
    }

    if (birdiePuttDistances.isEmpty) return 0.0;

    return birdiePuttDistances.reduce((a, b) => a + b) / birdiePuttDistances.length;
  }

  /// Get average score relative to par across all rounds
  double getAverageScoreRelativeToPar() {
    if (rounds.isEmpty) return 0.0;

    int totalRelativeScore = 0;
    int roundCount = 0;

    for (var round in rounds) {
      final relativeScore = RoundStatisticsService(round).getTotalScoreRelativeToPar();
      totalRelativeScore += relativeScore;
      roundCount++;
    }

    return roundCount > 0 ? totalRelativeScore / roundCount : 0.0;
  }

  /// Get total number of rounds
  int getRoundCount() => rounds.length;

  /// Get total number of holes played
  int getTotalHolesPlayed() {
    return rounds.fold<int>(0, (sum, round) => sum + round.holes.length);
  }

  /// Get backhand vs forehand comparison for tee shots
  ComparisonResult compareBackhandVsForehandTeeShots() {
    int backhandAttempts = 0;
    int backhandBirdies = 0;
    int backhandSuccessful = 0;

    int forehandAttempts = 0;
    int forehandBirdies = 0;
    int forehandSuccessful = 0;

    for (var round in rounds) {
      final comparison =
          RoundStatisticsService(round).compareBackhandVsForehandTeeShots();

      // Aggregate backhand stats
      backhandAttempts += comparison.technique1Count;
      final backhandBirdiesThisRound =
          (comparison.technique1BirdieRate / 100 * comparison.technique1Count)
              .round();
      backhandBirdies += backhandBirdiesThisRound;
      final backhandSuccessfulThisRound =
          (comparison.technique1SuccessRate / 100 * comparison.technique1Count)
              .round();
      backhandSuccessful += backhandSuccessfulThisRound;

      // Aggregate forehand stats
      forehandAttempts += comparison.technique2Count;
      final forehandBirdiesThisRound =
          (comparison.technique2BirdieRate / 100 * comparison.technique2Count)
              .round();
      forehandBirdies += forehandBirdiesThisRound;
      final forehandSuccessfulThisRound =
          (comparison.technique2SuccessRate / 100 * comparison.technique2Count)
              .round();
      forehandSuccessful += forehandSuccessfulThisRound;
    }

    final backhandBirdieRate = backhandAttempts > 0
        ? (backhandBirdies / backhandAttempts) * 100
        : 0.0;
    final forehandBirdieRate = forehandAttempts > 0
        ? (forehandBirdies / forehandAttempts) * 100
        : 0.0;
    final backhandSuccessRate = backhandAttempts > 0
        ? (backhandSuccessful / backhandAttempts) * 100
        : 0.0;
    final forehandSuccessRate = forehandAttempts > 0
        ? (forehandSuccessful / forehandAttempts) * 100
        : 0.0;

    return ComparisonResult(
      technique1: 'Backhand',
      technique2: 'Forehand',
      technique1BirdieRate: backhandBirdieRate,
      technique2BirdieRate: forehandBirdieRate,
      technique1SuccessRate: backhandSuccessRate,
      technique2SuccessRate: forehandSuccessRate,
      technique1Count: backhandAttempts,
      technique2Count: forehandAttempts,
    );
  }

  /// Get scramble statistics across all rounds
  ScrambleStats getScrambleStats() {
    int totalOpportunities = 0;
    int totalSaves = 0;

    for (var round in rounds) {
      final roundScramble = RoundStatisticsService(round).getScrambleStats();
      totalOpportunities += roundScramble.scrambleOpportunities;
      totalSaves += roundScramble.scrambleSaves;
    }

    return ScrambleStats(
      scrambleOpportunities: totalOpportunities,
      scrambleSaves: totalSaves,
    );
  }
}
