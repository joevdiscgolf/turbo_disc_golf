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

  /// Extract disc name from disc property, notes, or rawText (best effort)
  String? _extractDiscName(DiscThrow discThrow) {
    // First check if there's a disc object
    if (discThrow.disc != null) {
      return discThrow.disc!.name;
    }

    // Fall back to parsing notes/rawText
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

  /// Get ALL tee shots grouped by throw type (not just birdies)
  Map<String, List<MapEntry<DGHole, DiscThrow>>> getAllTeeShotsByType() {
    final Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;

      if (teeShot.technique != null) {
        final throwType = teeShot.technique!.name;
        allTeeShotsByType.putIfAbsent(throwType, () => []);
        allTeeShotsByType[throwType]!.add(MapEntry(hole, teeShot));
      }
    }

    return allTeeShotsByType;
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

      // Fairway hit: tee shot that didn't go off_fairway, OB, or other
      if (teeShot.landingSpot != LandingSpot.offFairway &&
          teeShot.landingSpot != LandingSpot.outOfBounds &&
          teeShot.landingSpot != LandingSpot.other) {
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

      // C1 in Regulation: reached Circle 1 in ≤(par-2) strokes (chance for birdie)
      // C2 in Regulation: reached Circle 2 in ≤(par-2) strokes (chance for birdie)
      final regulationStrokes = hole.par - 2;
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

  List<DiscMistake> getMajorMistakesByDisc() {
    final Map<String, List<LossReason>> mistakesByDisc = {};

    for (var hole in round.holes) {
      for (var discThrow in hole.throws) {
        final analysis = GPTAnalysisService.analyzeThrow(discThrow);
        final isMajorMistake =
            analysis.execCategory == ExecCategory.bad ||
            analysis.execCategory == ExecCategory.severe;

        if (isMajorMistake) {
          final discName = _extractDiscName(discThrow);
          if (discName != null) {
            mistakesByDisc.putIfAbsent(discName, () => []);
            mistakesByDisc[discName]!.add(analysis.lossReason);
          }
        }
      }
    }

    final mistakes = mistakesByDisc.entries.map((entry) {
      return DiscMistake(
        discName: entry.key,
        mistakeCount: entry.value.length,
        reasons: entry.value.map((reason) => reason.name).toList(),
      );
    }).toList();

    mistakes.sort((a, b) => b.mistakeCount.compareTo(a.mistakeCount));

    return mistakes;
  }

  List<DiscPerformanceSummary> getDiscPerformanceSummaries() {
    final Map<String, Map<String, int>> performanceByDisc = {};

    for (var hole in round.holes) {
      for (var discThrow in hole.throws) {
        final discName = _extractDiscName(discThrow);
        if (discName == null) continue;

        performanceByDisc.putIfAbsent(
          discName,
          () => {'good': 0, 'okay': 0, 'bad': 0},
        );

        final analysis = GPTAnalysisService.analyzeThrow(discThrow);

        switch (analysis.execCategory) {
          case ExecCategory.good:
            performanceByDisc[discName]!['good'] =
                performanceByDisc[discName]!['good']! + 1;
            break;
          case ExecCategory.neutral:
            performanceByDisc[discName]!['okay'] =
                performanceByDisc[discName]!['okay']! + 1;
            break;
          case ExecCategory.bad:
          case ExecCategory.severe:
            performanceByDisc[discName]!['bad'] =
                performanceByDisc[discName]!['bad']! + 1;
            break;
        }
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

  List<MistakeTypeSummary> getMistakeTypes() {
    final Map<String, int> mistakeTypeCounts = {};

    final mistakes = getMistakeThrowDetails();
    final totalMistakes = mistakes.length;

    for (var mistake in mistakes) {
      final label = mistake['label'] as String;
      mistakeTypeCounts[label] = (mistakeTypeCounts[label] ?? 0) + 1;
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

  String _createMistakeLabel(DiscThrow discThrow, ThrowAnalysis analysis) {
    final purpose = discThrow.purpose;
    final lossReason = analysis.lossReason;

    if (purpose == ThrowPurpose.putt && discThrow.distanceFeet != null) {
      final distance = discThrow.distanceFeet!;
      if (distance <= 12) return 'Missed short putt';
      if (distance <= 33) return 'Missed C1X putt';
      if (distance <= 66) return 'Missed C2 putt';
      return 'Missed long putt';
    }

    if (purpose == ThrowPurpose.teeDrive) {
      if (lossReason == LossReason.outOfBounds) return 'OB tee shot';
      if (lossReason == LossReason.poorDrive) return 'Poor tee shot';
    }

    if (purpose == ThrowPurpose.approach &&
        lossReason == LossReason.missedApproach) {
      return 'Missed approach';
    }

    final baseLabel = GPTAnalysisService.describeLossReason(lossReason);
    if (discThrow.technique != null) {
      final technique = discThrow.technique!.name.capitalize();
      return '$technique - $baseLabel';
    }

    return baseLabel;
  }

  double getBounceBackPercentage() {
    int bounceBackOpportunities = 0;
    int bounceBackSuccesses = 0;

    for (int i = 0; i < round.holes.length - 1; i++) {
      final currentHole = round.holes[i];
      final nextHole = round.holes[i + 1];

      if (currentHole.relativeHoleScore > 0) {
        bounceBackOpportunities++;
        if (nextHole.relativeHoleScore < 0) {
          bounceBackSuccesses++;
        }
      }
    }

    return bounceBackOpportunities > 0
        ? (bounceBackSuccesses / bounceBackOpportunities) * 100
        : 0.0;
  }

  Map<int, double> getBirdieRateByPar() {
    final Map<int, int> birdiesByPar = {};
    final Map<int, int> holesByPar = {};

    for (var hole in round.holes) {
      holesByPar[hole.par] = (holesByPar[hole.par] ?? 0) + 1;
      if (hole.relativeHoleScore < 0) {
        birdiesByPar[hole.par] = (birdiesByPar[hole.par] ?? 0) + 1;
      }
    }

    return holesByPar.map((par, count) {
      final birdies = birdiesByPar[par] ?? 0;
      return MapEntry(par, count > 0 ? (birdies / count) * 100 : 0.0);
    });
  }

  Map<String, double> getBirdieRateByHoleLength() {
    final Map<String, int> birdiesByLength = {
      'Short (<250 ft)': 0,
      'Medium (250-400 ft)': 0,
      'Long (400-550 ft)': 0,
      'Very Long (550+ ft)': 0,
    };
    final Map<String, int> holesByLength = {
      'Short (<250 ft)': 0,
      'Medium (250-400 ft)': 0,
      'Long (400-550 ft)': 0,
      'Very Long (550+ ft)': 0,
    };

    for (var hole in round.holes) {
      final distance = hole.feet ?? 0;
      String category;
      if (distance < 250) {
        category = 'Short (<250 ft)';
      } else if (distance < 400) {
        category = 'Medium (250-400 ft)';
      } else if (distance < 550) {
        category = 'Long (400-550 ft)';
      } else {
        category = 'Very Long (550+ ft)';
      }

      holesByLength[category] = holesByLength[category]! + 1;
      if (hole.relativeHoleScore < 0) {
        birdiesByLength[category] = birdiesByLength[category]! + 1;
      }
    }

    return holesByLength.map((length, count) {
      final birdies = birdiesByLength[length]!;
      return MapEntry(length, count > 0 ? (birdies / count) * 100 : 0.0);
    });
  }

  double getAverageBirdieHoleDistance() {
    final birdieHoles = round.holes.where((h) => h.relativeHoleScore < 0);
    if (birdieHoles.isEmpty) return 0.0;

    final totalDistance = birdieHoles.fold<int>(
      0,
      (sum, hole) => sum + (hole.feet ?? 0),
    );

    return totalDistance / birdieHoles.length;
  }

  int getTotalScoreRelativeToPar() {
    return round.holes.fold<int>(
      0,
      (sum, hole) => sum + hole.relativeHoleScore,
    );
  }

  Map<String, dynamic> getComebackPuttStats() {
    int comebackAttempts = 0;
    int comebackMakes = 0;
    final List<Map<String, dynamic>> comebackDetails = [];

    for (var hole in round.holes) {
      bool previousPuttMissed = false;

      for (var discThrow in hole.throws) {
        if (discThrow.purpose == ThrowPurpose.putt) {
          final made = discThrow.landingSpot == LandingSpot.inBasket;

          if (previousPuttMissed) {
            comebackAttempts++;
            if (made) comebackMakes++;

            comebackDetails.add({
              'holeNumber': hole.number,
              'distance': discThrow.distanceFeet,
              'made': made,
            });
          }

          previousPuttMissed = !made;
        }
      }
    }

    return {
      'attempts': comebackAttempts,
      'makes': comebackMakes,
      'details': comebackDetails,
    };
  }

  Map<String, double> getDiscBirdieRates() {
    final Map<String, int> birdiesByDisc = {};
    final Map<String, int> throwsByDisc = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      final discName = _extractDiscName(teeShot);

      if (discName != null) {
        throwsByDisc[discName] = (throwsByDisc[discName] ?? 0) + 1;
        if (hole.relativeHoleScore < 0) {
          birdiesByDisc[discName] = (birdiesByDisc[discName] ?? 0) + 1;
        }
      }
    }

    return throwsByDisc.map((disc, count) {
      final birdies = birdiesByDisc[disc] ?? 0;
      return MapEntry(disc, count > 0 ? (birdies / count) * 100 : 0.0);
    });
  }

  Map<String, double> getDiscParRates() {
    final Map<String, int> parsByDisc = {};
    final Map<String, int> throwsByDisc = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      final discName = _extractDiscName(teeShot);

      if (discName != null) {
        throwsByDisc[discName] = (throwsByDisc[discName] ?? 0) + 1;
        if (hole.relativeHoleScore == 0) {
          parsByDisc[discName] = (parsByDisc[discName] ?? 0) + 1;
        }
      }
    }

    return throwsByDisc.map((disc, count) {
      final pars = parsByDisc[disc] ?? 0;
      return MapEntry(disc, count > 0 ? (pars / count) * 100 : 0.0);
    });
  }

  Map<String, double> getDiscBogeyRates() {
    final Map<String, int> bogeysByDisc = {};
    final Map<String, int> throwsByDisc = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      final discName = _extractDiscName(teeShot);

      if (discName != null) {
        throwsByDisc[discName] = (throwsByDisc[discName] ?? 0) + 1;
        if (hole.relativeHoleScore > 0) {
          bogeysByDisc[discName] = (bogeysByDisc[discName] ?? 0) + 1;
        }
      }
    }

    return throwsByDisc.map((disc, count) {
      final bogeys = bogeysByDisc[disc] ?? 0;
      return MapEntry(disc, count > 0 ? (bogeys / count) * 100 : 0.0);
    });
  }

  Map<String, double> getDiscAverageScores() {
    final Map<String, List<int>> scoresByDisc = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      final discName = _extractDiscName(teeShot);

      if (discName != null) {
        scoresByDisc.putIfAbsent(discName, () => []);
        scoresByDisc[discName]!.add(hole.relativeHoleScore);
      }
    }

    return scoresByDisc.map((disc, scores) {
      final avg = scores.fold<int>(0, (sum, score) => sum + score) / scores.length;
      return MapEntry(disc, avg);
    });
  }

  Map<String, int> getDiscThrowCounts() {
    final Map<String, int> throwsByDisc = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      final discName = _extractDiscName(teeShot);

      if (discName != null) {
        throwsByDisc[discName] = (throwsByDisc[discName] ?? 0) + 1;
      }
    }

    return throwsByDisc;
  }

  Map<String, double> getDiscC1InRegPercentages() {
    final Map<String, int> c1InRegByDisc = {};
    final Map<String, int> throwsByDisc = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      final discName = _extractDiscName(teeShot);

      if (discName != null) {
        throwsByDisc[discName] = (throwsByDisc[discName] ?? 0) + 1;

        // Check if reached C1 in regulation (par - 2 strokes or less)
        final regulationStrokes = hole.par - 2;
        if (regulationStrokes > 0) {
          for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
            final discThrow = hole.throws[i];
            if (discThrow.landingSpot == LandingSpot.circle1 ||
                discThrow.landingSpot == LandingSpot.parked) {
              c1InRegByDisc[discName] = (c1InRegByDisc[discName] ?? 0) + 1;
              break;
            }
          }
        }
      }
    }

    return throwsByDisc.map((disc, count) {
      final c1InReg = c1InRegByDisc[disc] ?? 0;
      return MapEntry(disc, count > 0 ? (c1InReg / count) * 100 : 0.0);
    });
  }

  Map<String, double> getDiscC2InRegPercentages() {
    final Map<String, int> c2InRegByDisc = {};
    final Map<String, int> throwsByDisc = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      final discName = _extractDiscName(teeShot);

      if (discName != null) {
        throwsByDisc[discName] = (throwsByDisc[discName] ?? 0) + 1;

        // Check if reached C2 in regulation (par - 2 strokes or less)
        final regulationStrokes = hole.par - 2;
        if (regulationStrokes > 0) {
          for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
            final discThrow = hole.throws[i];
            if (discThrow.landingSpot == LandingSpot.circle1 ||
                discThrow.landingSpot == LandingSpot.parked ||
                discThrow.landingSpot == LandingSpot.circle2) {
              c2InRegByDisc[discName] = (c2InRegByDisc[discName] ?? 0) + 1;
              break;
            }
          }
        }
      }
    }

    return throwsByDisc.map((disc, count) {
      final c2InReg = c2InRegByDisc[disc] ?? 0;
      return MapEntry(disc, count > 0 ? (c2InReg / count) * 100 : 0.0);
    });
  }

  int getTotalMistakesCount() {
    return getMistakeThrowDetails().length;
  }

  Map<String, int> getMistakesByCategory() {
    int drivingMistakes = 0;
    int approachMistakes = 0;
    int puttingMistakes = 0;

    final mistakes = getMistakeThrowDetails();

    for (var mistake in mistakes) {
      final discThrow = mistake['throw'] as DiscThrow;
      switch (discThrow.purpose) {
        case ThrowPurpose.teeDrive:
        case ThrowPurpose.fairwayDrive:
          drivingMistakes++;
          break;
        case ThrowPurpose.approach:
          approachMistakes++;
          break;
        case ThrowPurpose.putt:
          puttingMistakes++;
          break;
        default:
          break;
      }
    }

    return {
      'driving': drivingMistakes,
      'approach': approachMistakes,
      'putting': puttingMistakes,
    };
  }

  List<Map<String, dynamic>> getMistakeThrowDetails() {
    final List<Map<String, dynamic>> mistakes = [];

    for (var hole in round.holes) {
      // Calculate cumulative penalties to determine actual stroke numbers
      int cumulativePenalties = 0;
      final List<int> strokeNumbers = [];

      for (var i = 0; i < hole.throws.length; i++) {
        final discThrow = hole.throws[i];
        final actualStrokeNumber = i + 1 + cumulativePenalties;
        strokeNumbers.add(actualStrokeNumber);

        // Add penalties from this throw to the cumulative count
        if (discThrow.penaltyStrokes != null && discThrow.penaltyStrokes! > 0) {
          cumulativePenalties += discThrow.penaltyStrokes!;
        }
      }

      for (var i = 0; i < hole.throws.length; i++) {
        final discThrow = hole.throws[i];
        final analysis = GPTAnalysisService.analyzeThrow(discThrow);
        final actualStrokeNumber = strokeNumbers[i];

        // Check for indicators of a good throw
        final isGoodLanding = discThrow.landingSpot == LandingSpot.circle1 ||
            discThrow.landingSpot == LandingSpot.circle2 ||
            discThrow.landingSpot == LandingSpot.parked ||
            discThrow.landingSpot == LandingSpot.fairway;

        final hasGoodRating = discThrow.resultRating == ThrowResultRating.excellent ||
            discThrow.resultRating == ThrowResultRating.good;

        // Check if next throw is a short putt (indicates this approach was good)
        final bool nextThrowIsShortPutt = i < hole.throws.length - 1 &&
            hole.throws[i + 1].purpose == ThrowPurpose.putt &&
            (hole.throws[i + 1].distanceFeet ?? 999) <= 33;

        // Check if this was likely a good throw based on multiple signals
        final isLikelyGoodThrow = isGoodLanding || hasGoodRating || nextThrowIsShortPutt;

        // Recovery after penalty logic
        final isRecoveryAfterPenalty = i > 0 &&
            (hole.throws[i - 1].penaltyStrokes ?? 0) > 0 &&
            isLikelyGoodThrow;

        // Override the analysis for approaches that seem good but weren't marked as such
        final isApproachWithGoodSignals = discThrow.purpose == ThrowPurpose.approach &&
            isLikelyGoodThrow &&
            analysis.execCategory == ExecCategory.bad;

        final isMistake = (analysis.execCategory == ExecCategory.bad ||
            analysis.execCategory == ExecCategory.severe) &&
            !isRecoveryAfterPenalty &&
            !isApproachWithGoodSignals;

        if (isMistake) {
          mistakes.add({
            'holeNumber': hole.number,
            'throwIndex': i,
            'actualStrokeNumber': actualStrokeNumber,
            'throw': discThrow,
            'analysis': analysis,
            'label': _createMistakeLabel(discThrow, analysis),
          });
        }
      }
    }

    return mistakes;
  }

  List<Map<String, dynamic>> getThrowsForDisc(String discName) {
    final List<Map<String, dynamic>> throws = [];

    for (var hole in round.holes) {
      for (var i = 0; i < hole.throws.length; i++) {
        final discThrow = hole.throws[i];
        final throwDiscName = _extractDiscName(discThrow);

        if (throwDiscName == discName) {
          throws.add({
            'holeNumber': hole.number,
            'throwIndex': i,
            'throw': discThrow,
          });
        }
      }
    }

    return throws;
  }

  /// Get C1 and C2 in regulation percentages by tee shot throw type
  Map<String, Map<String, double>> getCircleInRegByThrowType() {
    final Map<String, int> c1InRegByType = {};
    final Map<String, int> c2InRegByType = {};
    final Map<String, int> totalByType = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      if (teeShot.technique == null) continue;

      final throwType = teeShot.technique!.name;
      totalByType[throwType] = (totalByType[throwType] ?? 0) + 1;

      // Check if reached C1/C2 in regulation (par - 2 strokes or less)
      final regulationStrokes = hole.par - 2;
      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked) {
            c1InRegByType[throwType] = (c1InRegByType[throwType] ?? 0) + 1;
            c2InRegByType[throwType] = (c2InRegByType[throwType] ?? 0) + 1;
            break;
          } else if (discThrow.landingSpot == LandingSpot.circle2) {
            c2InRegByType[throwType] = (c2InRegByType[throwType] ?? 0) + 1;
            break;
          }
        }
      }
    }

    return totalByType.map((throwType, total) {
      final c1Count = c1InRegByType[throwType] ?? 0;
      final c2Count = c2InRegByType[throwType] ?? 0;
      return MapEntry(throwType, {
        'c1Percentage': total > 0 ? (c1Count / total) * 100 : 0.0,
        'c2Percentage': total > 0 ? (c2Count / total) * 100 : 0.0,
        'c1Count': c1Count.toDouble(),
        'c2Count': c2Count.toDouble(),
        'totalAttempts': total.toDouble(),
      });
    });
  }

  /// Get C1 in regulation details by throw type (with hole and the throw that reached C1)
  Map<String, List<Map<String, dynamic>>> getC1InRegDetails() {
    final Map<String, List<Map<String, dynamic>>> c1DetailsByType = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      if (teeShot.technique == null) continue;

      final throwType = teeShot.technique!.name;
      final regulationStrokes = hole.par - 2;

      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked) {
            c1DetailsByType.putIfAbsent(throwType, () => []);
            c1DetailsByType[throwType]!.add({
              'hole': hole,
              'throw': discThrow,
              'throwIndex': i,
            });
            break;
          }
        }
      }
    }

    return c1DetailsByType;
  }

  /// Get C2 in regulation details by throw type (with hole and the throw that reached C2)
  Map<String, List<Map<String, dynamic>>> getC2InRegDetails() {
    final Map<String, List<Map<String, dynamic>>> c2DetailsByType = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      if (teeShot.technique == null) continue;

      final throwType = teeShot.technique!.name;
      final regulationStrokes = hole.par - 2;

      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked ||
              discThrow.landingSpot == LandingSpot.circle2) {
            c2DetailsByType.putIfAbsent(throwType, () => []);
            c2DetailsByType[throwType]!.add({
              'hole': hole,
              'throw': discThrow,
              'throwIndex': i,
            });
            break;
          }
        }
      }
    }

    return c2DetailsByType;
  }

  /// Helper method to calculate section performance for a list of holes
  SectionPerformance _calculateSectionPerformance(
    List<DGHole> sectionHoles,
    String sectionName,
  ) {
    if (sectionHoles.isEmpty) {
      return SectionPerformance(
        sectionName: sectionName,
        holesPlayed: 0,
        avgScore: 0.0,
        birdieRate: 0.0,
        parRate: 0.0,
        bogeyPlusRate: 0.0,
        shotQualityRate: 0.0,
        c1InRegRate: 0.0,
        c2InRegRate: 0.0,
        fairwayHitRate: 0.0,
        obRate: 0.0,
        mistakeCount: 0,
      );
    }

    // Calculate scoring stats
    int birdies = 0;
    int pars = 0;
    int bogeyPlus = 0;
    int totalScore = 0;
    int c1InReg = 0;
    int c2InReg = 0;
    int fairwayHits = 0;
    int obHoles = 0;

    for (var hole in sectionHoles) {
      totalScore += hole.relativeHoleScore;

      if (hole.relativeHoleScore < 0) {
        birdies++;
      } else if (hole.relativeHoleScore == 0) {
        pars++;
      } else {
        bogeyPlus++;
      }

      // Check fairway hit (tee shot)
      if (hole.throws.isNotEmpty) {
        final teeShot = hole.throws.first;
        if (teeShot.landingSpot != LandingSpot.offFairway &&
            teeShot.landingSpot != LandingSpot.outOfBounds &&
            teeShot.landingSpot != LandingSpot.other) {
          fairwayHits++;
        }
      }

      // Check OB
      bool hadOB = false;
      for (var discThrow in hole.throws) {
        if (discThrow.landingSpot == LandingSpot.outOfBounds) {
          hadOB = true;
          break;
        }
      }
      if (hadOB) obHoles++;

      // Check C1/C2 in regulation
      final regulationStrokes = hole.par - 2;
      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked) {
            c1InReg++;
            c2InReg++;
            break;
          } else if (discThrow.landingSpot == LandingSpot.circle2) {
            c2InReg++;
            break;
          }
        }
      }
    }

    // Calculate shot quality
    int successfulShots = 0;
    int totalShots = 0;

    for (var hole in sectionHoles) {
      for (var discThrow in hole.throws) {
        totalShots++;
        if (_isSuccessfulShot(discThrow, hole)) {
          successfulShots++;
        }
      }
    }

    // Count mistakes in this section
    final allMistakes = getMistakeThrowDetails();
    final sectionHoleNumbers = sectionHoles.map((h) => h.number).toSet();
    final mistakeCount = allMistakes
        .where((m) => sectionHoleNumbers.contains(m['holeNumber']))
        .length;

    final totalHoles = sectionHoles.length;
    return SectionPerformance(
      sectionName: sectionName,
      holesPlayed: totalHoles,
      avgScore: totalScore / totalHoles,
      birdieRate: (birdies / totalHoles) * 100,
      parRate: (pars / totalHoles) * 100,
      bogeyPlusRate: (bogeyPlus / totalHoles) * 100,
      shotQualityRate: totalShots > 0 ? (successfulShots / totalShots) * 100 : 0.0,
      c1InRegRate: (c1InReg / totalHoles) * 100,
      c2InRegRate: (c2InReg / totalHoles) * 100,
      fairwayHitRate: (fairwayHits / totalHoles) * 100,
      obRate: (obHoles / totalHoles) * 100,
      mistakeCount: mistakeCount,
    );
  }

  /// Get comprehensive momentum and psychological analysis
  MomentumStats getMomentumStats() {
    // Need at least 3 holes for meaningful momentum analysis
    if (round.holes.length < 3) {
      return MomentumStats(
        transitionMatrix: {},
        momentumMultiplier: 1.0,
        tiltFactor: 0.0,
        bounceBackRate: 0.0,
        compoundErrorRate: 0.0,
        longestParStreak: 0,
        mentalProfile: 'Insufficient Data',
        insights: ['Need at least 3 holes for momentum analysis'],
        conditioningScore: 50.0, // Neutral score for insufficient data
      );
    }

    // Step 1: Build transition counts
    final Map<String, Map<String, int>> transitionCounts = {
      'Birdie': {'Birdie': 0, 'Par': 0, 'Bogey': 0, 'Double+': 0},
      'Par': {'Birdie': 0, 'Par': 0, 'Bogey': 0, 'Double+': 0},
      'Bogey': {'Birdie': 0, 'Par': 0, 'Bogey': 0, 'Double+': 0},
      'Double+': {'Birdie': 0, 'Par': 0, 'Bogey': 0, 'Double+': 0},
    };

    // Helper to categorize score
    String categorizeScore(int relativeScore) {
      if (relativeScore < 0) return 'Birdie';
      if (relativeScore == 0) return 'Par';
      if (relativeScore == 1) return 'Bogey';
      return 'Double+';
    }

    // Iterate through holes sequentially to build transitions
    for (int i = 0; i < round.holes.length - 1; i++) {
      final currentHole = round.holes[i];
      final nextHole = round.holes[i + 1];

      final fromCategory = categorizeScore(currentHole.relativeHoleScore);
      final toCategory = categorizeScore(nextHole.relativeHoleScore);

      transitionCounts[fromCategory]![toCategory] =
          transitionCounts[fromCategory]![toCategory]! + 1;
    }

    // Step 2: Convert counts to percentages and build transition matrix
    final Map<String, ScoringTransition> transitionMatrix = {};

    transitionCounts.forEach((from, toCounts) {
      final total = toCounts.values.reduce((a, b) => a + b);
      if (total > 0) {
        transitionMatrix[from] = ScoringTransition(
          fromScore: from,
          toBirdiePercent: (toCounts['Birdie']! / total) * 100,
          toParPercent: (toCounts['Par']! / total) * 100,
          toBogeyPercent: (toCounts['Bogey']! / total) * 100,
          toDoublePercent: (toCounts['Double+']! / total) * 100,
        );
      }
    });

    // Step 3: Calculate momentum multiplier
    double momentumMultiplier = 1.0;
    if (transitionMatrix.containsKey('Birdie') &&
        transitionMatrix.containsKey('Bogey')) {
      final birdieAfterBirdie = transitionMatrix['Birdie']!.toBirdiePercent;
      final birdieAfterBogey = transitionMatrix['Bogey']!.toBirdiePercent;
      if (birdieAfterBogey > 0) {
        momentumMultiplier = birdieAfterBirdie / birdieAfterBogey;
      }
    }

    // Step 4: Calculate tilt factor (performance drop after bad holes)
    double tiltFactor = 0.0;
    if (transitionMatrix.containsKey('Bogey') ||
        transitionMatrix.containsKey('Double+')) {
      double avgBogeyPlusAfterBad = 0.0;
      int count = 0;

      if (transitionMatrix.containsKey('Bogey')) {
        avgBogeyPlusAfterBad +=
            transitionMatrix['Bogey']!.bogeyOrWorsePercent;
        count++;
      }
      if (transitionMatrix.containsKey('Double+')) {
        avgBogeyPlusAfterBad +=
            transitionMatrix['Double+']!.bogeyOrWorsePercent;
        count++;
      }

      if (count > 0) {
        avgBogeyPlusAfterBad /= count;
        // Compare to overall bogey rate
        final overallBogeyRate = getScoringStats().bogeyRate +
            getScoringStats().doubleBogeyPlusRate;
        tiltFactor = avgBogeyPlusAfterBad - overallBogeyRate;
      }
    }

    // Step 5: Calculate bounce back rate
    double bounceBackRate = 0.0;
    int bounceBackOpportunities = 0;
    int bounceBackSuccesses = 0;

    for (int i = 0; i < round.holes.length - 1; i++) {
      final currentHole = round.holes[i];
      final nextHole = round.holes[i + 1];

      if (currentHole.relativeHoleScore > 0) {
        // Bogey or worse
        bounceBackOpportunities++;
        if (nextHole.relativeHoleScore <= 0) {
          // Par or better
          bounceBackSuccesses++;
        }
      }
    }

    if (bounceBackOpportunities > 0) {
      bounceBackRate = (bounceBackSuccesses / bounceBackOpportunities) * 100;
    }

    // Step 6: Calculate compound error rate
    double compoundErrorRate = 0.0;
    int compoundErrors = 0;
    int errorOpportunities = 0;

    for (int i = 0; i < round.holes.length - 1; i++) {
      final currentHole = round.holes[i];
      final nextHole = round.holes[i + 1];

      if (currentHole.relativeHoleScore > 0) {
        errorOpportunities++;
        if (nextHole.relativeHoleScore > 0) {
          compoundErrors++;
        }
      }
    }

    if (errorOpportunities > 0) {
      compoundErrorRate = (compoundErrors / errorOpportunities) * 100;
    }

    // Step 7: Find longest birdie+ streak
    int longestParStreak = 0; // Note: field name kept for backward compatibility
    int currentStreak = 0;

    for (var hole in round.holes) {
      if (hole.relativeHoleScore < 0) {
        // Birdie or better
        currentStreak++;
        if (currentStreak > longestParStreak) {
          longestParStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }

    // Step 8: Determine mental profile
    String mentalProfile = 'Even Keel'; // Default

    // Momentum Player: High momentum multiplier
    if (momentumMultiplier > 2.0) {
      mentalProfile = 'Momentum Player';
    }
    // Even Keel: Low momentum multiplier
    else if (momentumMultiplier < 1.5 && tiltFactor < 5) {
      mentalProfile = 'Even Keel';
    }
    // Clutch Closer: Better performance in last 3 holes
    else if (round.holes.length >= 6) {
      final last3Holes = round.holes.sublist(round.holes.length - 3);
      final first3Holes = round.holes.sublist(0, 3);

      final last3Avg = last3Holes.fold<double>(
              0.0, (sum, h) => sum + h.relativeHoleScore) /
          3;
      final first3Avg = first3Holes.fold<double>(
              0.0, (sum, h) => sum + h.relativeHoleScore) /
          3;

      if (last3Avg < first3Avg - 0.5) {
        mentalProfile = 'Clutch Closer';
      } else if (first3Avg < last3Avg - 0.5) {
        mentalProfile = 'Slow Starter';
      }
    }

    // Step 9: Generate insights
    final List<String> insights = [];

    // Momentum insight
    if (momentumMultiplier > 2.0) {
      insights.add(
        'You\'re a momentum player - one birdie leads to another. Use this to your advantage!',
      );
    } else if (momentumMultiplier < 1.2) {
      insights.add(
        'Your performance is consistent regardless of previous holes - that\'s impressive mental toughness!',
      );
    }

    // Tilt insight
    if (tiltFactor > 15) {
      insights.add(
        'Your tilt factor is high. After a bad hole, take 30 seconds to reset before your next throw.',
      );
    } else if (tiltFactor < 5) {
      insights.add(
        'You maintain composure well after mistakes - that\'s a key strength!',
      );
    }

    // Bounce back insight
    if (bounceBackRate > 60) {
      insights.add(
        'You bounce back well from adversity (${bounceBackRate.toStringAsFixed(0)}% recovery rate). Trust this ability under pressure.',
      );
    } else if (bounceBackRate > 0 && bounceBackRate < 40) {
      insights.add(
        'Work on mental reset after bogeys. Your bounce-back rate (${bounceBackRate.toStringAsFixed(0)}%) can improve with practice.',
      );
    }

    // Compound error insight
    if (compoundErrorRate < 20) {
      insights.add(
        'You rarely compound mistakes - excellent damage control!',
      );
    } else if (compoundErrorRate > 40) {
      insights.add(
        'Back-to-back mistakes are common (${compoundErrorRate.toStringAsFixed(0)}%). Focus on breaking the chain after the first bad hole.',
      );
    }

    // Streak insight
    if (longestParStreak >= round.holes.length / 2) {
      insights.add(
        'Your longest birdie streak was $longestParStreak holes - you can sustain excellence!',
      );
    }

    // Profile-specific insight
    switch (mentalProfile) {
      case 'Slow Starter':
        insights.add(
          'You finish stronger than you start. Consider a longer warm-up routine before rounds.',
        );
        break;
      case 'Clutch Closer':
        insights.add(
          'You perform best under pressure in the closing holes. Trust yourself in clutch moments!',
        );
        break;
    }

    // Ensure we have at least one insight
    if (insights.isEmpty) {
      insights.add(
        'Keep playing! More rounds will reveal clearer mental game patterns.',
      );
    }

    // Step 10: Calculate section performances
    SectionPerformance? front9Performance;
    SectionPerformance? back9Performance;
    SectionPerformance? last6Performance;

    // Front 9 (holes 0-8)
    if (round.holes.length >= 9) {
      front9Performance = _calculateSectionPerformance(
        round.holes.sublist(0, 9),
        'Front 9',
      );
    }

    // Back 9 (holes 9+)
    if (round.holes.length > 9) {
      back9Performance = _calculateSectionPerformance(
        round.holes.sublist(9),
        'Back 9',
      );
    }

    // Last 6 holes
    if (round.holes.length >= 6) {
      final startIndex = round.holes.length - 6;
      last6Performance = _calculateSectionPerformance(
        round.holes.sublist(startIndex),
        'Last 6',
      );
    }

    // Step 11: Calculate conditioning score
    double conditioningScore = 50.0; // Default neutral score

    if (front9Performance != null && back9Performance != null) {
      final scoreDiff = (back9Performance.avgScore - front9Performance.avgScore).abs();

      // Score drops up to 2.0 strokes, scale from 100 (no drop) to 0 (2+ stroke drop)
      conditioningScore = (100 - (scoreDiff * 50)).clamp(0, 100);

      // Add conditioning insights
      if (back9Performance.avgScore > front9Performance.avgScore + 0.5) {
        insights.add(
          'Back 9 performance drops significantly (avg +${back9Performance.avgScore.toStringAsFixed(1)} vs +${front9Performance.avgScore.toStringAsFixed(1)} on front 9). Work on conditioning and endurance.',
        );
      } else if (front9Performance.avgScore > back9Performance.avgScore + 0.5) {
        insights.add(
          'You finish strong! Your back 9 performance (avg +${back9Performance.avgScore.toStringAsFixed(1)}) is better than your front 9 (+${front9Performance.avgScore.toStringAsFixed(1)}).',
        );
      }

      // Check shot quality drop
      if (back9Performance.shotQualityRate < front9Performance.shotQualityRate - 15) {
        insights.add(
          'Shot quality drops ${(front9Performance.shotQualityRate - back9Performance.shotQualityRate).toStringAsFixed(0)}% in back 9. Focus on maintaining form when fatigued.',
        );
      }
    }

    // Last 6 holes analysis
    if (last6Performance != null) {
      final overallAvgScore = round.holes.fold<int>(
        0,
        (sum, hole) => sum + hole.relativeHoleScore,
      ) / round.holes.length;

      if (last6Performance.avgScore > overallAvgScore + 0.75) {
        insights.add(
          'Your last 6 holes show significant fatigue (avg +${last6Performance.avgScore.toStringAsFixed(1)} vs +${overallAvgScore.toStringAsFixed(1)} overall). Mental and physical conditioning could help.',
        );
      } else if (last6Performance.avgScore < overallAvgScore - 0.5) {
        insights.add(
          'You close rounds strong! Your final 6 holes (avg +${last6Performance.avgScore.toStringAsFixed(1)}) outperform your overall average (+${overallAvgScore.toStringAsFixed(1)}).',
        );
      }
    }

    return MomentumStats(
      transitionMatrix: transitionMatrix,
      momentumMultiplier: momentumMultiplier,
      tiltFactor: tiltFactor,
      bounceBackRate: bounceBackRate,
      compoundErrorRate: compoundErrorRate,
      longestParStreak: longestParStreak,
      mentalProfile: mentalProfile,
      insights: insights,
      front9Performance: front9Performance,
      back9Performance: back9Performance,
      last6Performance: last6Performance,
      conditioningScore: conditioningScore,
    );
  }

  /// Get performance statistics by fairway width
  Map<String, Map<String, double>> getPerformanceByFairwayWidth() {
    final Map<FairwayWidth, List<DGHole>> holesByWidth = {};

    // Group holes by fairway width (from tee shot)
    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      if (teeShot.fairwayWidth != null) {
        holesByWidth.putIfAbsent(teeShot.fairwayWidth!, () => []);
        holesByWidth[teeShot.fairwayWidth!]!.add(hole);
      }
    }

    // Calculate stats for each fairway width
    final Map<String, Map<String, double>> result = {};

    holesByWidth.forEach((width, holes) {
      int birdies = 0;
      int pars = 0;
      int bogeys = 0;
      int c1InReg = 0;
      int c2InReg = 0;
      int obHoles = 0;

      for (var hole in holes) {
        // Count scores
        if (hole.relativeHoleScore < 0) {
          birdies++;
        } else if (hole.relativeHoleScore == 0) {
          pars++;
        } else {
          bogeys++;
        }

        // Check C1/C2 in regulation
        final regulationStrokes = hole.par - 2;
        if (regulationStrokes > 0) {
          for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
            final discThrow = hole.throws[i];
            if (discThrow.landingSpot == LandingSpot.circle1 ||
                discThrow.landingSpot == LandingSpot.parked) {
              c1InReg++;
              c2InReg++;
              break;
            } else if (discThrow.landingSpot == LandingSpot.circle2) {
              c2InReg++;
              break;
            }
          }
        }

        // Check for OB
        for (var discThrow in hole.throws) {
          if (discThrow.landingSpot == LandingSpot.outOfBounds) {
            obHoles++;
            break;
          }
        }
      }

      final totalHoles = holes.length;
      final widthName = width.toString().split('.').last;

      result[widthName] = {
        'birdieRate': totalHoles > 0 ? (birdies / totalHoles) * 100 : 0.0,
        'parRate': totalHoles > 0 ? (pars / totalHoles) * 100 : 0.0,
        'bogeyRate': totalHoles > 0 ? (bogeys / totalHoles) * 100 : 0.0,
        'c1InRegRate': totalHoles > 0 ? (c1InReg / totalHoles) * 100 : 0.0,
        'c2InRegRate': totalHoles > 0 ? (c2InReg / totalHoles) * 100 : 0.0,
        'obRate': totalHoles > 0 ? (obHoles / totalHoles) * 100 : 0.0,
        'holesPlayed': totalHoles.toDouble(),
      };
    });

    return result;
  }

  /// Get performance statistics by hole type (wooded, open, slightly wooded)
  Map<String, Map<String, double>> getPerformanceByHoleType() {
    final Map<HoleType, List<DGHole>> holesByType = {};

    // Group holes by hole type
    for (var hole in round.holes) {
      if (hole.holeType != null) {
        holesByType.putIfAbsent(hole.holeType!, () => []);
        holesByType[hole.holeType!]!.add(hole);
      }
    }

    // Calculate stats for each hole type
    final Map<String, Map<String, double>> result = {};

    holesByType.forEach((holeType, holes) {
      int birdies = 0;
      int pars = 0;
      int bogeys = 0;
      int c1InReg = 0;
      int c2InReg = 0;
      int obHoles = 0;

      for (var hole in holes) {
        // Count scores
        if (hole.relativeHoleScore < 0) {
          birdies++;
        } else if (hole.relativeHoleScore == 0) {
          pars++;
        } else {
          bogeys++;
        }

        // Check C1/C2 in regulation
        final regulationStrokes = hole.par - 2;
        if (regulationStrokes > 0) {
          for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
            final discThrow = hole.throws[i];
            if (discThrow.landingSpot == LandingSpot.circle1 ||
                discThrow.landingSpot == LandingSpot.parked) {
              c1InReg++;
              c2InReg++;
              break;
            } else if (discThrow.landingSpot == LandingSpot.circle2) {
              c2InReg++;
              break;
            }
          }
        }

        // Check for OB
        for (var discThrow in hole.throws) {
          if (discThrow.landingSpot == LandingSpot.outOfBounds) {
            obHoles++;
            break;
          }
        }
      }

      final totalHoles = holes.length;
      final typeName = holeType.toString().split('.').last;

      result[typeName] = {
        'birdieRate': totalHoles > 0 ? (birdies / totalHoles) * 100 : 0.0,
        'parRate': totalHoles > 0 ? (pars / totalHoles) * 100 : 0.0,
        'bogeyRate': totalHoles > 0 ? (bogeys / totalHoles) * 100 : 0.0,
        'c1InRegRate': totalHoles > 0 ? (c1InReg / totalHoles) * 100 : 0.0,
        'c2InRegRate': totalHoles > 0 ? (c2InReg / totalHoles) * 100 : 0.0,
        'obRate': totalHoles > 0 ? (obHoles / totalHoles) * 100 : 0.0,
        'holesPlayed': totalHoles.toDouble(),
      };
    });

    return result;
  }

  /// Get C1 and C2 in regulation percentages by hole length
  Map<String, Map<String, double>> getC1C2ByHoleLength() {
    final Map<String, int> c1InRegByLength = {
      'Short (<250 ft)': 0,
      'Medium (250-400 ft)': 0,
      'Long (400-550 ft)': 0,
      'Very Long (550+ ft)': 0,
    };
    final Map<String, int> c2InRegByLength = {
      'Short (<250 ft)': 0,
      'Medium (250-400 ft)': 0,
      'Long (400-550 ft)': 0,
      'Very Long (550+ ft)': 0,
    };
    final Map<String, int> holesByLength = {
      'Short (<250 ft)': 0,
      'Medium (250-400 ft)': 0,
      'Long (400-550 ft)': 0,
      'Very Long (550+ ft)': 0,
    };

    for (var hole in round.holes) {
      final distance = hole.feet ?? 0;
      String category;
      if (distance < 250) {
        category = 'Short (<250 ft)';
      } else if (distance < 400) {
        category = 'Medium (250-400 ft)';
      } else if (distance < 550) {
        category = 'Long (400-550 ft)';
      } else {
        category = 'Very Long (550+ ft)';
      }

      holesByLength[category] = holesByLength[category]! + 1;

      // Check C1/C2 in regulation
      final regulationStrokes = hole.par - 2;
      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked) {
            c1InRegByLength[category] = c1InRegByLength[category]! + 1;
            c2InRegByLength[category] = c2InRegByLength[category]! + 1;
            break;
          } else if (discThrow.landingSpot == LandingSpot.circle2) {
            c2InRegByLength[category] = c2InRegByLength[category]! + 1;
            break;
          }
        }
      }
    }

    return holesByLength.map((length, count) {
      final c1InReg = c1InRegByLength[length]!;
      final c2InReg = c2InRegByLength[length]!;
      return MapEntry(length, {
        'c1InRegRate': count > 0 ? (c1InReg / count) * 100 : 0.0,
        'c2InRegRate': count > 0 ? (c2InReg / count) * 100 : 0.0,
        'holesPlayed': count.toDouble(),
      });
    });
  }

  /// Get detailed performance statistics by par
  Map<int, Map<String, double>> getPerformanceByPar() {
    final Map<int, List<DGHole>> holesByPar = {};

    // Group holes by par
    for (var hole in round.holes) {
      holesByPar.putIfAbsent(hole.par, () => []);
      holesByPar[hole.par]!.add(hole);
    }

    // Calculate stats for each par
    final Map<int, Map<String, double>> result = {};

    holesByPar.forEach((par, holes) {
      int birdies = 0;
      int pars = 0;
      int bogeys = 0;
      int c1InReg = 0;
      int c2InReg = 0;
      double totalScore = 0;

      for (var hole in holes) {
        totalScore += hole.relativeHoleScore;

        // Count scores
        if (hole.relativeHoleScore < 0) {
          birdies++;
        } else if (hole.relativeHoleScore == 0) {
          pars++;
        } else {
          bogeys++;
        }

        // Check C1/C2 in regulation
        final regulationStrokes = hole.par - 2;
        if (regulationStrokes > 0) {
          for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
            final discThrow = hole.throws[i];
            if (discThrow.landingSpot == LandingSpot.circle1 ||
                discThrow.landingSpot == LandingSpot.parked) {
              c1InReg++;
              c2InReg++;
              break;
            } else if (discThrow.landingSpot == LandingSpot.circle2) {
              c2InReg++;
              break;
            }
          }
        }
      }

      final totalHoles = holes.length;

      result[par] = {
        'birdieRate': totalHoles > 0 ? (birdies / totalHoles) * 100 : 0.0,
        'parRate': totalHoles > 0 ? (pars / totalHoles) * 100 : 0.0,
        'bogeyRate': totalHoles > 0 ? (bogeys / totalHoles) * 100 : 0.0,
        'c1InRegRate': totalHoles > 0 ? (c1InReg / totalHoles) * 100 : 0.0,
        'c2InRegRate': totalHoles > 0 ? (c2InReg / totalHoles) * 100 : 0.0,
        'avgScore': totalHoles > 0 ? totalScore / totalHoles : 0.0,
        'holesPlayed': totalHoles.toDouble(),
      };
    });

    return result;
  }

  /// Get all putt attempts with distance and made/missed status
  /// Returns a list of maps containing: distance, made, holeNumber, throwIndex
  List<Map<String, dynamic>> getPuttAttempts() {
    final List<Map<String, dynamic>> puttAttempts = [];

    for (var hole in round.holes) {
      for (int i = 0; i < hole.throws.length; i++) {
        final discThrow = hole.throws[i];
        if (discThrow.purpose == ThrowPurpose.putt &&
            discThrow.distanceFeet != null) {
          puttAttempts.add({
            'distance': discThrow.distanceFeet!.toDouble(),
            'made': discThrow.landingSpot == LandingSpot.inBasket,
            'holeNumber': hole.number,
            'throwIndex': i,
          });
        }
      }
    }

    return puttAttempts;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
