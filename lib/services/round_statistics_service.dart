import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/gpt_analysis_service.dart';

/// Service for calculating round statistics based on outcomes (not AI ratings)
class RoundStatisticsService {
  final DGRound round;

  RoundStatisticsService(this.round);

  /// Determine if a shot was successful based on outcome
  bool _isSuccessfulShot(DiscThrow discThrow, DGHole hole) {
    // Made putt = success
    if (discThrow.landingSpot == LandingSpot.inBasket) return true;

    // Good landing spots = success
    if (discThrow.landingSpot == LandingSpot.parked) return true;
    if (discThrow.landingSpot == LandingSpot.circle1) return true;
    if (discThrow.landingSpot == LandingSpot.circle2) return true;
    if (discThrow.landingSpot == LandingSpot.fairway) return true;

    // Bad outcomes = failure
    if (discThrow.landingSpot == LandingSpot.outOfBounds) return false;
    if (discThrow.landingSpot == LandingSpot.offFairway) return false;
    if (discThrow.penaltyStrokes != null && discThrow.penaltyStrokes! > 0) {
      return false;
    }

    // Hole resulted in birdie and this was tee shot or approach = success
    if (hole.relativeHoleScore < 0 &&
        (discThrow.purpose == ThrowPurpose.teeDrive ||
            discThrow.purpose == ThrowPurpose.fairwayDrive ||
            discThrow.purpose == ThrowPurpose.approach)) {
      return true;
    }

    // Use result rating as fallback if available
    if (discThrow.resultRating == ThrowResultRating.excellent ||
        discThrow.resultRating == ThrowResultRating.good) {
      return true;
    }

    // Default: not clearly successful
    return false;
  }

  /// Get overall scoring statistics
  ScoringStats getScoringStats() {
    int birdies = 0;
    int pars = 0;
    int bogeys = 0;
    int doubleBogeyPlus = 0;

    for (var hole in round.holes) {
      final score = hole.relativeHoleScore;
      if (score < 0) {
        birdies++;
      } else if (score == 0) {
        pars++;
      } else if (score == 1) {
        bogeys++;
      } else {
        doubleBogeyPlus++;
      }
    }

    return ScoringStats(
      totalHoles: round.holes.length,
      birdies: birdies,
      pars: pars,
      bogeys: bogeys,
      doubleBogeyPlus: doubleBogeyPlus,
    );
  }

  /// Get putting statistics by distance range
  Map<String, PuttingStats> getPuttingStatsByDistance() {
    final Map<String, List<DiscThrow>> puttsByRange = {
      '0-15 ft': [],
      '15-33 ft (C1)': [],
      '33-66 ft (C2)': [],
    };

    for (var hole in round.holes) {
      for (var discThrow in hole.throws) {
        if (discThrow.purpose == ThrowPurpose.putt &&
            discThrow.distanceFeet != null) {
          final distance = discThrow.distanceFeet!;
          if (distance <= 15) {
            puttsByRange['0-15 ft']!.add(discThrow);
          } else if (distance <= 33) {
            puttsByRange['15-33 ft (C1)']!.add(discThrow);
          } else if (distance <= 66) {
            puttsByRange['33-66 ft (C2)']!.add(discThrow);
          }
        }
      }
    }

    return puttsByRange.map((range, putts) {
      final made = putts
          .where((p) => p.landingSpot == LandingSpot.inBasket)
          .length;
      return MapEntry(
        range,
        PuttingStats(distanceRange: range, attempted: putts.length, made: made),
      );
    });
  }

  /// Get technique statistics for a specific purpose
  Map<String, TechniqueStats> getTechniqueStats(ThrowPurpose purpose) {
    final Map<String, List<MapEntry<DiscThrow, DGHole>>> throwsByTechnique = {};

    for (var hole in round.holes) {
      for (var discThrow in hole.throws) {
        if (discThrow.purpose == purpose && discThrow.technique != null) {
          final techniqueName = discThrow.technique!.name;
          throwsByTechnique.putIfAbsent(techniqueName, () => []);
          throwsByTechnique[techniqueName]!.add(MapEntry(discThrow, hole));
        }
      }
    }

    return throwsByTechnique.map((technique, throwsWithHoles) {
      int successful = 0;
      int unsuccessful = 0;
      int birdies = 0;
      int pars = 0;
      int bogeys = 0;

      for (var entry in throwsWithHoles) {
        final discThrow = entry.key;
        final hole = entry.value;

        if (_isSuccessfulShot(discThrow, hole)) {
          successful++;
        } else {
          unsuccessful++;
        }

        // Count hole outcomes
        if (hole.relativeHoleScore < 0) {
          birdies++;
        } else if (hole.relativeHoleScore == 0) {
          pars++;
        } else {
          bogeys++;
        }
      }

      return MapEntry(
        technique,
        TechniqueStats(
          techniqueName: technique,
          attempts: throwsWithHoles.length,
          successful: successful,
          unsuccessful: unsuccessful,
          birdies: birdies,
          pars: pars,
          bogeys: bogeys,
        ),
      );
    });
  }

  /// Compare backhand vs forehand for tee shots
  ComparisonResult compareBackhandVsForehandTeeShots() {
    final teeStats = getTechniqueStats(ThrowPurpose.teeDrive);

    final backhandStats =
        teeStats['backhand'] ??
        TechniqueStats(
          techniqueName: 'backhand',
          attempts: 0,
          successful: 0,
          unsuccessful: 0,
          birdies: 0,
          pars: 0,
          bogeys: 0,
        );

    final forehandStats =
        teeStats['forehand'] ??
        TechniqueStats(
          techniqueName: 'forehand',
          attempts: 0,
          successful: 0,
          unsuccessful: 0,
          birdies: 0,
          pars: 0,
          bogeys: 0,
        );

    return ComparisonResult(
      technique1: 'Backhand',
      technique2: 'Forehand',
      technique1BirdieRate: backhandStats.birdieRate,
      technique2BirdieRate: forehandStats.birdieRate,
      technique1SuccessRate: backhandStats.successRate,
      technique2SuccessRate: forehandStats.successRate,
      technique1Count: backhandStats.attempts,
      technique2Count: forehandStats.attempts,
    );
  }

  /// Compare backhand vs forehand for approach shots
  ComparisonResult compareBackhandVsForehandApproaches() {
    final approachStats = getTechniqueStats(ThrowPurpose.approach);

    final backhandStats =
        approachStats['backhand'] ??
        TechniqueStats(
          techniqueName: 'backhand',
          attempts: 0,
          successful: 0,
          unsuccessful: 0,
          birdies: 0,
          pars: 0,
          bogeys: 0,
        );

    final forehandStats =
        approachStats['forehand'] ??
        TechniqueStats(
          techniqueName: 'forehand',
          attempts: 0,
          successful: 0,
          unsuccessful: 0,
          birdies: 0,
          pars: 0,
          bogeys: 0,
        );

    return ComparisonResult(
      technique1: 'Backhand',
      technique2: 'Forehand',
      technique1BirdieRate: backhandStats.birdieRate,
      technique2BirdieRate: forehandStats.birdieRate,
      technique1SuccessRate: backhandStats.successRate,
      technique2SuccessRate: forehandStats.successRate,
      technique1Count: backhandStats.attempts,
      technique2Count: forehandStats.attempts,
    );
  }

  /// Get scramble statistics
  ScrambleStats getScrambleStats() {
    int opportunities = 0;
    int saves = 0;

    for (var hole in round.holes) {
      bool hadTrouble = false;

      for (var discThrow in hole.throws) {
        if (discThrow.landingSpot == LandingSpot.outOfBounds ||
            discThrow.landingSpot == LandingSpot.offFairway ||
            (discThrow.penaltyStrokes != null &&
                discThrow.penaltyStrokes! > 0)) {
          hadTrouble = true;
          break;
        }
      }

      if (hadTrouble) {
        opportunities++;
        // Scramble save if made par or better
        if (hole.relativeHoleScore <= 0) {
          saves++;
        }
      }
    }

    return ScrambleStats(
      scrambleOpportunities: opportunities,
      scrambleSaves: saves,
    );
  }

  /// Extract disc name from notes or rawText (best effort)
  String? _extractDiscName(DiscThrow discThrow) {
    final text = discThrow.notes ?? discThrow.rawText ?? '';
    if (text.isEmpty) return null;

    // Common disc names (this is a simplified extraction)
    final commonDiscs = [
      'Destroyer',
      'Firebird',
      'Buzzz',
      'River',
      'Judge',
      'Aviar',
      'Thunderbird',
      'Teebird',
      'Leopard',
      'Roc',
      'Mako3',
      'Truth',
      'Harp',
      'Zone',
      'Essence',
      'Wraith',
      'Valkyrie',
      'Tactic',
      'Vanguard',
      'Instinct',
      'Glacier',
      'md3',
      'md4',
      'fd3',
      'dd3',
      'pd',
      'Logic',
      'Cloudbreaker',
    ];

    for (var disc in commonDiscs) {
      if (text.toLowerCase().contains(disc.toLowerCase())) {
        return disc;
      }
    }

    return null;
  }

  /// Get disc performance statistics
  Map<String, DiscStats> getDiscPerformance() {
    final Map<String, List<MapEntry<DiscThrow, DGHole>>> throwsByDisc = {};

    for (var hole in round.holes) {
      for (var discThrow in hole.throws) {
        final discName = _extractDiscName(discThrow);
        if (discName != null) {
          throwsByDisc.putIfAbsent(discName, () => []);
          throwsByDisc[discName]!.add(MapEntry(discThrow, hole));
        }
      }
    }

    return throwsByDisc.map((discName, throwsWithHoles) {
      int birdies = 0;
      int pars = 0;
      int bogeys = 0;
      int fairwayHits = 0;
      int offFairway = 0;
      int outOfBounds = 0;

      for (var entry in throwsWithHoles) {
        final discThrow = entry.key;
        final hole = entry.value;

        // Count hole outcomes
        if (hole.relativeHoleScore < 0) {
          birdies++;
        } else if (hole.relativeHoleScore == 0) {
          pars++;
        } else {
          bogeys++;
        }

        // Count landing spots
        if (discThrow.landingSpot == LandingSpot.fairway) {
          fairwayHits++;
        } else if (discThrow.landingSpot == LandingSpot.offFairway) {
          offFairway++;
        } else if (discThrow.landingSpot == LandingSpot.outOfBounds) {
          outOfBounds++;
        }
      }

      return MapEntry(
        discName,
        DiscStats(
          discName: discName,
          timesThrown: throwsWithHoles.length,
          birdies: birdies,
          pars: pars,
          bogeys: bogeys,
          fairwayHits: fairwayHits,
          offFairway: offFairway,
          outOfBounds: outOfBounds,
        ),
      );
    });
  }

  /// Get top performing discs
  List<DiscInsight> getTopPerformingDiscs({int limit = 3}) {
    final discStats = getDiscPerformance();
    final insights = discStats.values.map((stats) {
      String category;
      if (stats.birdieRate >= 40) {
        category = 'excellent';
      } else if (stats.birdieRate >= 25) {
        category = 'good';
      } else {
        category = 'needs work';
      }

      return DiscInsight(
        discName: stats.discName,
        birdieRate: stats.birdieRate,
        timesUsed: stats.timesThrown,
        category: category,
      );
    }).toList();

    insights.sort((a, b) => b.birdieRate.compareTo(a.birdieRate));
    return insights.take(limit).toList();
  }

  /// Get problem areas (techniques/discs with poor performance)
  List<String> getProblemAreas() {
    final problems = <String>[];

    // Check tee shot techniques
    final teeStats = getTechniqueStats(ThrowPurpose.teeDrive);
    for (var entry in teeStats.entries) {
      if (entry.value.attempts >= 3 && entry.value.successRate < 40) {
        problems.add(
          '${entry.key.capitalize()} tee shots - ${entry.value.successRate.toStringAsFixed(0)}% success',
        );
      }
    }

    // Check approach techniques
    final approachStats = getTechniqueStats(ThrowPurpose.approach);
    for (var entry in approachStats.entries) {
      if (entry.value.attempts >= 3 && entry.value.successRate < 50) {
        problems.add(
          '${entry.key.capitalize()} approaches - ${entry.value.successRate.toStringAsFixed(0)}% success',
        );
      }
    }

    // Check putting
    final puttingStats = getPuttingStatsByDistance();
    final circle1Stats = puttingStats['15-33 ft (C1)'];
    if (circle1Stats != null &&
        circle1Stats.attempted >= 3 &&
        circle1Stats.makePercentage < 60) {
      problems.add(
        'Circle 1 putting - ${circle1Stats.makePercentage.toStringAsFixed(0)}% make rate',
      );
    }

    return problems;
  }

  /// Get birdie rates for each throw type used off the tee
  Map<String, double> getTeeShotBirdieRates() {
    final stats = getTeeShotBirdieRateStats();
    return stats.map((key, value) => MapEntry(key, value.percentage));
  }

  /// Get birdie rate statistics with counts for each throw type used off the tee
  Map<String, BirdieRateStats> getTeeShotBirdieRateStats() {
    final Map<String, List<DGHole>> teeThrowsByType = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      // Get the tee shot (first throw, index 0)
      final teeShot = hole.throws.first;

      if (teeShot.technique != null) {
        final throwType = teeShot.technique!.name;
        teeThrowsByType.putIfAbsent(throwType, () => []);
        teeThrowsByType[throwType]!.add(hole);
      }
    }

    // Calculate birdie percentage and counts for each throw type
    return teeThrowsByType.map((throwType, holes) {
      final birdieCount = holes
          .where((hole) => hole.relativeHoleScore < 0)
          .length;
      final totalAttempts = holes.length;
      final birdieRate = totalAttempts > 0
          ? (birdieCount / totalAttempts) * 100
          : 0.0;
      return MapEntry(
        throwType,
        BirdieRateStats(
          percentage: birdieRate,
          birdieCount: birdieCount,
          totalAttempts: totalAttempts,
        ),
      );
    });
  }

  /// Get detailed birdie throw information grouped by tee shot type
  /// Returns a map of throw type to list of (hole, tee shot) pairs
  Map<String, List<MapEntry<DGHole, DiscThrow>>> getTeeShotBirdieDetails() {
    final Map<String, List<MapEntry<DGHole, DiscThrow>>> birdieDetailsByType =
        {};

    for (var hole in round.holes) {
      // Only consider birdie holes
      if (hole.relativeHoleScore >= 0) continue;
      if (hole.throws.isEmpty) continue;

      // Get the tee shot (first throw, index 0)
      final teeShot = hole.throws.first;

      if (teeShot.technique != null) {
        final throwType = teeShot.technique!.name;
        birdieDetailsByType.putIfAbsent(throwType, () => []);

        birdieDetailsByType[throwType]!.add(MapEntry(hole, teeShot));
      }
    }

    return birdieDetailsByType;
  }

  /// Get comprehensive putting summary with C1/C2 breakdown and distance buckets
  PuttStats getPuttingSummary() {
    int c1Makes = 0;
    int c1Misses = 0;
    int c2Makes = 0;
    int c2Misses = 0;

    final List<double> makeDistances = [];
    final List<double> missDistances = [];
    final List<double> allDistances = [];

    // Bucket definitions: C1 (1-11ft, 11-22ft, 22-33ft), C2 (33-44ft, 44-55ft, 55-66ft)
    final Map<String, List<DiscThrow>> buckets = {
      '1-11 ft': [],
      '11-22 ft': [],
      '22-33 ft': [],
      '33-44 ft': [],
      '44-55 ft': [],
      '55-66 ft': [],
    };

    // Collect all putts and classify them
    for (var hole in round.holes) {
      for (var discThrow in hole.throws) {
        if (discThrow.purpose == ThrowPurpose.putt &&
            discThrow.distanceFeet != null) {
          final distance = discThrow.distanceFeet!;
          final made = discThrow.landingSpot == LandingSpot.inBasket;
          allDistances.add(distance.toDouble());

          // Classify into C1/C2
          if (distance <= 33) {
            if (made) {
              c1Makes++;
              makeDistances.add(distance.toDouble());
            } else {
              c1Misses++;
              missDistances.add(distance.toDouble());
            }
          } else if (distance <= 66) {
            if (made) {
              c2Makes++;
              makeDistances.add(distance.toDouble());
            } else {
              c2Misses++;
              missDistances.add(distance.toDouble());
            }
          }

          // Classify into buckets
          if (distance <= 11) {
            buckets['1-11 ft']!.add(discThrow);
          } else if (distance <= 22) {
            buckets['11-22 ft']!.add(discThrow);
          } else if (distance <= 33) {
            buckets['22-33 ft']!.add(discThrow);
          } else if (distance <= 44) {
            buckets['33-44 ft']!.add(discThrow);
          } else if (distance <= 55) {
            buckets['44-55 ft']!.add(discThrow);
          } else if (distance <= 66) {
            buckets['55-66 ft']!.add(discThrow);
          }
        }
      }
    }

    // Calculate bucket stats
    final bucketStatsMap = <String, PuttBucketStats>{};
    buckets.forEach((label, putts) {
      if (putts.isEmpty) return;

      final makes = putts
          .where((p) => p.landingSpot == LandingSpot.inBasket)
          .length;
      final misses = putts.length - makes;
      final avgDistance =
          putts.fold<double>(
            0.0,
            (sum, p) => sum + (p.distanceFeet?.toDouble() ?? 0.0),
          ) /
          putts.length;

      bucketStatsMap[label] = PuttBucketStats(
        label: label,
        makes: makes,
        misses: misses,
        avgDistance: avgDistance,
      );
    });

    final avgMakeDistance = makeDistances.isNotEmpty
        ? makeDistances.reduce((a, b) => a + b) / makeDistances.length
        : 0.0;

    final avgMissDistance = missDistances.isNotEmpty
        ? missDistances.reduce((a, b) => a + b) / missDistances.length
        : 0.0;

    final avgAttemptDistance = allDistances.isNotEmpty
        ? allDistances.reduce((a, b) => a + b) / allDistances.length
        : 0.0;

    final totalMadeDistance = makeDistances.isNotEmpty
        ? makeDistances.reduce((a, b) => a + b)
        : 0.0;

    return PuttStats(
      c1Makes: c1Makes,
      c1Misses: c1Misses,
      c2Makes: c2Makes,
      c2Misses: c2Misses,
      avgMakeDistance: avgMakeDistance,
      avgMissDistance: avgMissDistance,
      avgAttemptDistance: avgAttemptDistance,
      totalMadeDistance: totalMadeDistance,
      bucketStats: bucketStatsMap,
    );
  }

  /// Get average distance of made putts on birdie holes
  double getAverageBirdiePuttDistance() {
    final List<double> birdiePuttDistances = [];

    for (var hole in round.holes) {
      // Only consider birdie holes
      if (hole.relativeHoleScore >= 0) continue;

      // Find the made putt on this hole
      for (var discThrow in hole.throws) {
        if (discThrow.purpose == ThrowPurpose.putt &&
            discThrow.landingSpot == LandingSpot.inBasket &&
            discThrow.distanceFeet != null) {
          birdiePuttDistances.add(discThrow.distanceFeet!.toDouble());
          break; // Only count the made putt
        }
      }
    }

    if (birdiePuttDistances.isEmpty) return 0.0;

    return birdiePuttDistances.reduce((a, b) => a + b) /
        birdiePuttDistances.length;
  }

  /// Get UDisc-style core performance metrics
  /// Optionally filter by disc
  CoreStats getCoreStats({DGDisc? filterDisc}) {
    int fairwayHits = 0;
    int parked = 0;
    int c1InReg = 0;
    int c2InReg = 0;
    int obHoles = 0;
    int validHoles = 0;

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      // Check if we should consider this hole based on disc filter
      bool holeHasFilteredDisc = false;
      if (filterDisc != null) {
        for (var discThrow in hole.throws) {
          final discName = discThrow.disc?.name;
          if (discName != null &&
              (discName.toLowerCase() == filterDisc.name.toLowerCase() ||
                  discName.toLowerCase() ==
                      filterDisc.moldName?.toLowerCase())) {
            holeHasFilteredDisc = true;
            break;
          }
        }
        if (!holeHasFilteredDisc) continue;
      }

      validHoles++;

      // Get tee shot (first throw)
      final teeShot = hole.throws.first;

      // Fairway hit: tee shot landed on fairway or was parked
      if (teeShot.landingSpot == LandingSpot.fairway ||
          teeShot.landingSpot == LandingSpot.parked) {
        fairwayHits++;
      }

      // Parked: tee shot landed ≤10ft from basket
      if (teeShot.landingSpot == LandingSpot.parked) {
        parked++;
      }

      // OB: check if any throw on this hole went out of bounds
      bool hadOB = false;
      for (var discThrow in hole.throws) {
        if (discThrow.landingSpot == LandingSpot.outOfBounds) {
          hadOB = true;
          break;
        }
      }
      if (hadOB) obHoles++;

      // C1 in Regulation: reached Circle 1 in ≤(par-1) strokes
      // C2 in Regulation: reached Circle 2 in ≤(par-1) strokes
      final regulationStrokes = hole.par - 1;
      for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
        final discThrow = hole.throws[i];
        if (discThrow.landingSpot == LandingSpot.circle1 ||
            discThrow.landingSpot == LandingSpot.parked) {
          c1InReg++;
          c2InReg++; // C1 also counts as C2
          break;
        } else if (discThrow.landingSpot == LandingSpot.circle2) {
          c2InReg++;
          break;
        }
      }
    }

    final totalHoles = filterDisc != null ? validHoles : round.holes.length;

    return CoreStats(
      fairwayHitPct: totalHoles > 0 ? (fairwayHits / totalHoles) * 100 : 0.0,
      parkedPct: totalHoles > 0 ? (parked / totalHoles) * 100 : 0.0,
      c1InRegPct: totalHoles > 0 ? (c1InReg / totalHoles) * 100 : 0.0,
      c2InRegPct: totalHoles > 0 ? (c2InReg / totalHoles) * 100 : 0.0,
      obPct: totalHoles > 0 ? (obHoles / totalHoles) * 100 : 0.0,
      totalHoles: totalHoles,
    );
  }

  /// Get summary of miss reasons across the round
  Map<LossReason, int> getMissReasonSummary() {
    final Map<LossReason, int> reasonCounts = {};

    for (var hole in round.holes) {
      for (var discThrow in hole.throws) {
        // Use GPT analysis service to determine loss reason
        final analysis = GPTAnalysisService.analyzeThrow(discThrow);

        // Only count non-none loss reasons
        if (analysis.lossReason != LossReason.none) {
          reasonCounts[analysis.lossReason] =
              (reasonCounts[analysis.lossReason] ?? 0) + 1;
        }
      }
    }

    return reasonCounts;
  }

  /// Get major mistakes grouped by disc
  List<DiscMistake> getMajorMistakesByDisc() {
    final Map<String, List<LossReason>> mistakesByDisc = {};

    for (var hole in round.holes) {
      for (var discThrow in hole.throws) {
        // Use GPT analysis service to determine execution category
        final analysis = GPTAnalysisService.analyzeThrow(discThrow);

        // Only count bad or severe mistakes
        if (analysis.execCategory == ExecCategory.bad ||
            analysis.execCategory == ExecCategory.severe) {
          final discName = _extractDiscName(discThrow);
          if (discName != null) {
            mistakesByDisc.putIfAbsent(discName, () => []);
            mistakesByDisc[discName]!.add(analysis.lossReason);
          }
        }
      }
    }

    // Convert to list of DiscMistake objects
    final List<DiscMistake> mistakes = [];
    mistakesByDisc.forEach((discName, reasons) {
      mistakes.add(
        DiscMistake(
          discName: discName,
          mistakeCount: reasons.length,
          reasons: reasons.map((r) => r.name).toList(),
        ),
      );
    });

    // Sort by mistake count (descending)
    mistakes.sort((a, b) => b.mistakeCount.compareTo(a.mistakeCount));

    return mistakes;
  }

  /// Get categorized mistake types with counts and percentages
  List<MistakeTypeSummary> getMistakeTypes() {
    final Map<String, int> mistakeTypeCounts = {};
    int totalMistakes = 0;

    for (var hole in round.holes) {
      for (var discThrow in hole.throws) {
        // Use GPT analysis service to determine execution category
        final analysis = GPTAnalysisService.analyzeThrow(discThrow);

        // Only count bad or severe mistakes
        if (analysis.execCategory == ExecCategory.bad ||
            analysis.execCategory == ExecCategory.severe) {
          totalMistakes++;

          // Create descriptive label
          String label = _createMistakeLabel(discThrow, analysis);

          mistakeTypeCounts[label] = (mistakeTypeCounts[label] ?? 0) + 1;
        }
      }
    }

    // Convert to list of MistakeTypeSummary objects
    final List<MistakeTypeSummary> summaries = [];
    mistakeTypeCounts.forEach((label, count) {
      final percentage = totalMistakes > 0
          ? (count / totalMistakes) * 100
          : 0.0;
      summaries.add(
        MistakeTypeSummary(label: label, count: count, percentage: percentage),
      );
    });

    // Sort by count (descending)
    summaries.sort((a, b) => b.count.compareTo(a.count));

    return summaries;
  }

  /// Helper method to create descriptive mistake labels
  String _createMistakeLabel(DiscThrow discThrow, ThrowAnalysis analysis) {
    // Start with the loss reason
    String label = GPTAnalysisService.describeLossReason(analysis.lossReason);

    // Add throw technique if available
    if (discThrow.technique != null) {
      final technique = discThrow.technique!.name.capitalize();
      label = '$technique - $label';
    }

    // Add throw purpose for context
    if (discThrow.purpose != null) {
      switch (discThrow.purpose) {
        case ThrowPurpose.putt:
          if (discThrow.distanceFeet != null) {
            if (discThrow.distanceFeet! <= 10) {
              label = 'Missed C1 putt';
            } else if (discThrow.distanceFeet! <= 33) {
              label = 'Missed C2 putt (inside C1)';
            } else {
              label = 'Missed long putt';
            }
          }
          break;
        case ThrowPurpose.teeDrive:
          if (analysis.lossReason == LossReason.outOfBounds) {
            label = 'OB tee shot';
          } else if (analysis.lossReason == LossReason.poorDrive) {
            label = 'Poor tee shot';
          }
          break;
        case ThrowPurpose.approach:
          if (analysis.lossReason == LossReason.missedApproach) {
            label = 'Missed approach';
          }
          break;
        default:
          break;
      }
    }

    return label;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
