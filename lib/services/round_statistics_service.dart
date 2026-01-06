import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/gpt_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/shot_analysis_service.dart';

/// Service for calculating round statistics based on outcomes (not AI ratings)
class RoundStatisticsService {
  final DGRound round;

  RoundStatisticsService(this.round);

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

        if (locator.get<ShotAnalysisService>().isSuccessfulShot(
          discThrow,
          hole,
        )) {
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
            (discThrow.customPenaltyStrokes != null &&
                discThrow.customPenaltyStrokes! > 0)) {
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
    final puttingStats = locator
        .get<PuttingAnalysisService>()
        .getPuttingStatsByDistance(round);
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

  /// Get UDisc-style core performance metrics
  /// Optionally filter by disc
  CoreStats getCoreStats({DGDisc? filterDisc}) {
    int fairwayHits = 0;
    int parked = 0;
    int c1InReg = 0;
    int c2InReg = 0;
    int obThrows = 0;
    int totalThrows = 0;
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

      // Fairway hit: tee shot landed in a good position (fairway, circle1, circle2, parked, or in basket)
      if (teeShot.landingSpot == LandingSpot.fairway ||
          teeShot.landingSpot == LandingSpot.circle1 ||
          teeShot.landingSpot == LandingSpot.circle2 ||
          teeShot.landingSpot == LandingSpot.parked ||
          teeShot.landingSpot == LandingSpot.inBasket) {
        fairwayHits++;
      }

      // Parked: tee shot landed ≤10ft from basket
      if (teeShot.landingSpot == LandingSpot.parked) {
        parked++;
      }

      // Count OB throws and total throws (OB% = OB throws / total throws)
      for (var discThrow in hole.throws) {
        totalThrows++;
        if (discThrow.landingSpot == LandingSpot.outOfBounds) {
          obThrows++;
        }
      }

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
      obPct: totalThrows > 0 ? (obThrows / totalThrows) * 100 : 0.0,
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
      '<250 ft': 0,
      '250-400 ft': 0,
      '400-550 ft': 0,
      '550+ ft': 0,
    };
    final Map<String, int> holesByLength = {
      '<250 ft': 0,
      '250-400 ft': 0,
      '400-550 ft': 0,
      '550+ ft': 0,
    };

    for (var hole in round.holes) {
      final distance = hole.feet;
      String category;
      if (distance < 250) {
        category = '<250 ft';
      } else if (distance < 400) {
        category = '250-400 ft';
      } else if (distance < 550) {
        category = '400-550 ft';
      } else {
        category = '550+ ft';
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
      (sum, hole) => sum + (hole.feet),
    );

    return totalDistance / birdieHoles.length;
  }

  int getTotalScoreRelativeToPar() {
    return round.holes.fold<int>(
      0,
      (sum, hole) => sum + hole.relativeHoleScore,
    );
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

  /// Get performance statistics by hole distance
  Map<String, Map<String, double>> getPerformanceByDistance() {
    final Map<String, List<DGHole>> holesByDistance = {
      '<250 ft': [],
      '250-400 ft': [],
      '400-550 ft': [],
      '550+ ft': [],
    };

    // Group holes by distance
    for (var hole in round.holes) {
      final distance = hole.feet;
      String category;
      if (distance < 250) {
        category = '<250 ft';
      } else if (distance < 400) {
        category = '250-400 ft';
      } else if (distance < 550) {
        category = '400-550 ft';
      } else {
        category = '550+ ft';
      }

      holesByDistance[category]!.add(hole);
    }

    // Calculate stats for each distance category
    final Map<String, Map<String, double>> result = {};

    holesByDistance.forEach((distance, holes) {
      if (holes.isEmpty) {
        return; // Skip empty categories
      }

      int birdies = 0;
      int pars = 0;
      int bogeys = 0;
      int doubleBogeyPlus = 0;
      double totalScore = 0;

      for (var hole in holes) {
        totalScore += hole.relativeHoleScore;

        // Count scores
        if (hole.relativeHoleScore < 0) {
          birdies++;
        } else if (hole.relativeHoleScore == 0) {
          pars++;
        } else if (hole.relativeHoleScore == 1) {
          bogeys++;
        } else {
          doubleBogeyPlus++;
        }
      }

      final totalHoles = holes.length;

      result[distance] = {
        'birdieRate': totalHoles > 0 ? (birdies / totalHoles) * 100 : 0.0,
        'parRate': totalHoles > 0 ? (pars / totalHoles) * 100 : 0.0,
        'bogeyRate': totalHoles > 0 ? (bogeys / totalHoles) * 100 : 0.0,
        'doubleBogeyPlusRate': totalHoles > 0
            ? (doubleBogeyPlus / totalHoles) * 100
            : 0.0,
        'avgScore': totalHoles > 0 ? totalScore / totalHoles : 0.0,
        'holesPlayed': totalHoles.toDouble(),
      };
    });

    return result;
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
      int doubleBogeyPlus = 0;
      int c1InReg = 0;
      int c2InReg = 0;
      int obHoles = 0;
      double totalScore = 0;

      for (var hole in holes) {
        totalScore += hole.relativeHoleScore;

        // Count scores
        if (hole.relativeHoleScore < 0) {
          birdies++;
        } else if (hole.relativeHoleScore == 0) {
          pars++;
        } else if (hole.relativeHoleScore == 1) {
          bogeys++;
        } else {
          doubleBogeyPlus++;
        }

        // Check C1/C2 in regulation
        final regulationStrokes = hole.par - 2;
        if (regulationStrokes > 0) {
          for (
            int i = 0;
            i < hole.throws.length && i < regulationStrokes;
            i++
          ) {
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
        'doubleBogeyPlusRate': totalHoles > 0
            ? (doubleBogeyPlus / totalHoles) * 100
            : 0.0,
        'avgScore': totalHoles > 0 ? totalScore / totalHoles : 0.0,
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
      int doubleBogeyPlus = 0;
      int c1InReg = 0;
      int c2InReg = 0;
      int obHoles = 0;
      double totalScore = 0;

      for (var hole in holes) {
        totalScore += hole.relativeHoleScore;

        // Count scores
        if (hole.relativeHoleScore < 0) {
          birdies++;
        } else if (hole.relativeHoleScore == 0) {
          pars++;
        } else if (hole.relativeHoleScore == 1) {
          bogeys++;
        } else {
          doubleBogeyPlus++;
        }

        // Check C1/C2 in regulation
        final regulationStrokes = hole.par - 2;
        if (regulationStrokes > 0) {
          for (
            int i = 0;
            i < hole.throws.length && i < regulationStrokes;
            i++
          ) {
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
        'doubleBogeyPlusRate': totalHoles > 0
            ? (doubleBogeyPlus / totalHoles) * 100
            : 0.0,
        'avgScore': totalHoles > 0 ? totalScore / totalHoles : 0.0,
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
      '<250 ft': 0,
      '250-400 ft': 0,
      '400-550 ft': 0,
      '550+ ft': 0,
    };
    final Map<String, int> c2InRegByLength = {
      '<250 ft': 0,
      '250-400 ft': 0,
      '400-550 ft': 0,
      '550+ ft': 0,
    };
    final Map<String, int> holesByLength = {
      '<250 ft': 0,
      '250-400 ft': 0,
      '400-550 ft': 0,
      '550+ ft': 0,
    };

    for (var hole in round.holes) {
      final distance = hole.feet;
      String category;
      if (distance < 250) {
        category = '<250 ft';
      } else if (distance < 400) {
        category = '250-400 ft';
      } else if (distance < 550) {
        category = '400-550 ft';
      } else {
        category = '550+ ft';
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
      int doubleBogeyPlus = 0;
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
        } else if (hole.relativeHoleScore == 1) {
          bogeys++;
        } else {
          doubleBogeyPlus++;
        }

        // Check C1/C2 in regulation
        final regulationStrokes = hole.par - 2;
        if (regulationStrokes > 0) {
          for (
            int i = 0;
            i < hole.throws.length && i < regulationStrokes;
            i++
          ) {
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

      final birdieRateCalc = totalHoles > 0
          ? (birdies / totalHoles) * 100
          : 0.0;
      final parRateCalc = totalHoles > 0 ? (pars / totalHoles) * 100 : 0.0;
      final bogeyRateCalc = totalHoles > 0 ? (bogeys / totalHoles) * 100 : 0.0;
      final doubleBogeyPlusRateCalc = totalHoles > 0
          ? (doubleBogeyPlus / totalHoles) * 100
          : 0.0;

      result[par] = {
        'birdieRate': birdieRateCalc,
        'parRate': parRateCalc,
        'bogeyRate': bogeyRateCalc,
        'doubleBogeyPlusRate': doubleBogeyPlusRateCalc,
        'c1InRegRate': totalHoles > 0 ? (c1InReg / totalHoles) * 100 : 0.0,
        'c2InRegRate': totalHoles > 0 ? (c2InReg / totalHoles) * 100 : 0.0,
        'avgScore': totalHoles > 0 ? totalScore / totalHoles : 0.0,
        'holesPlayed': totalHoles.toDouble(),
      };
    });

    return result;
  }

  /// Get birdie rate statistics by shot shape (hyzer, flat, anhyzer, etc.)
  Map<String, BirdieRateStats> getShotShapeBirdieRateStats() {
    final Map<String, List<DGHole>> teeThrowsByShape = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      // Get the tee shot (first throw, index 0)
      final teeShot = hole.throws.first;

      if (teeShot.shotShape != null) {
        final shapeName = teeShot.shotShape!.name;
        teeThrowsByShape.putIfAbsent(shapeName, () => []);
        teeThrowsByShape[shapeName]!.add(hole);
      }
    }

    // Calculate birdie percentage and counts for each shot shape
    return teeThrowsByShape.map((shapeName, holes) {
      final birdieCount = holes
          .where((hole) => hole.relativeHoleScore < 0)
          .length;
      final totalAttempts = holes.length;
      final birdieRate = totalAttempts > 0
          ? (birdieCount / totalAttempts) * 100
          : 0.0;
      return MapEntry(
        shapeName,
        BirdieRateStats(
          percentage: birdieRate,
          birdieCount: birdieCount,
          totalAttempts: totalAttempts,
        ),
      );
    });
  }

  /// Get C1 and C2 in regulation percentages by shot shape
  Map<String, Map<String, double>> getCircleInRegByShotShape() {
    final Map<String, int> c1InRegByShape = {};
    final Map<String, int> c2InRegByShape = {};
    final Map<String, int> totalByShape = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      if (teeShot.shotShape == null) continue;

      final shapeName = teeShot.shotShape!.name;
      totalByShape[shapeName] = (totalByShape[shapeName] ?? 0) + 1;

      // Check if reached C1/C2 in regulation (par - 2 strokes or less)
      final regulationStrokes = hole.par - 2;
      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked) {
            c1InRegByShape[shapeName] = (c1InRegByShape[shapeName] ?? 0) + 1;
            c2InRegByShape[shapeName] = (c2InRegByShape[shapeName] ?? 0) + 1;
            break;
          } else if (discThrow.landingSpot == LandingSpot.circle2) {
            c2InRegByShape[shapeName] = (c2InRegByShape[shapeName] ?? 0) + 1;
            break;
          }
        }
      }
    }

    return totalByShape.map((shapeName, total) {
      final c1Count = c1InRegByShape[shapeName] ?? 0;
      final c2Count = c2InRegByShape[shapeName] ?? 0;
      return MapEntry(shapeName, {
        'c1Percentage': total > 0 ? (c1Count / total) * 100 : 0.0,
        'c2Percentage': total > 0 ? (c2Count / total) * 100 : 0.0,
        'c1Count': c1Count.toDouble(),
        'c2Count': c2Count.toDouble(),
        'totalAttempts': total.toDouble(),
      });
    });
  }

  /// Get ALL tee shots grouped by shot shape
  Map<String, List<MapEntry<DGHole, DiscThrow>>> getAllTeeShotsByShotShape() {
    final Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByShape =
        {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;

      if (teeShot.shotShape != null) {
        final shapeName = teeShot.shotShape!.name;
        allTeeShotsByShape.putIfAbsent(shapeName, () => []);
        allTeeShotsByShape[shapeName]!.add(MapEntry(hole, teeShot));
      }
    }

    return allTeeShotsByShape;
  }

  /// Get birdie rate statistics by shot shape AND technique combination
  /// Returns data grouped by keys like "backhand_hyzer", "forehand_flat", etc.
  Map<String, BirdieRateStats> getShotShapeByTechniqueBirdieRateStats() {
    final Map<String, List<DGHole>> teeThrowsByCombo = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      // Get the tee shot (first throw, index 0)
      final teeShot = hole.throws.first;

      if (teeShot.technique != null && teeShot.shotShape != null) {
        final comboKey =
            '${teeShot.technique!.name}_${teeShot.shotShape!.name}';
        teeThrowsByCombo.putIfAbsent(comboKey, () => []);
        teeThrowsByCombo[comboKey]!.add(hole);
      }
    }

    // Calculate birdie percentage and counts for each combination
    return teeThrowsByCombo.map((comboKey, holes) {
      final birdieCount = holes
          .where((hole) => hole.relativeHoleScore < 0)
          .length;
      final totalAttempts = holes.length;
      final birdieRate = totalAttempts > 0
          ? (birdieCount / totalAttempts) * 100
          : 0.0;
      return MapEntry(
        comboKey,
        BirdieRateStats(
          percentage: birdieRate,
          birdieCount: birdieCount,
          totalAttempts: totalAttempts,
        ),
      );
    });
  }

  /// Get C1 and C2 in regulation percentages by shot shape AND technique combination
  /// Returns data grouped by keys like "backhand_hyzer", "forehand_flat", etc.
  Map<String, Map<String, double>> getCircleInRegByShotShapeAndTechnique() {
    final Map<String, int> c1InRegByCombo = {};
    final Map<String, int> c2InRegByCombo = {};
    final Map<String, int> totalByCombo = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      if (teeShot.shotShape == null || teeShot.technique == null) continue;

      final comboKey = '${teeShot.technique!.name}_${teeShot.shotShape!.name}';
      totalByCombo[comboKey] = (totalByCombo[comboKey] ?? 0) + 1;

      // Check if reached C1/C2 in regulation (par - 2 strokes or less)
      final regulationStrokes = hole.par - 2;
      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked) {
            c1InRegByCombo[comboKey] = (c1InRegByCombo[comboKey] ?? 0) + 1;
            c2InRegByCombo[comboKey] = (c2InRegByCombo[comboKey] ?? 0) + 1;
            break;
          } else if (discThrow.landingSpot == LandingSpot.circle2) {
            c2InRegByCombo[comboKey] = (c2InRegByCombo[comboKey] ?? 0) + 1;
            break;
          }
        }
      }
    }

    return totalByCombo.map((comboKey, total) {
      final c1Count = c1InRegByCombo[comboKey] ?? 0;
      final c2Count = c2InRegByCombo[comboKey] ?? 0;
      return MapEntry(comboKey, {
        'c1Percentage': total > 0 ? (c1Count / total) * 100 : 0.0,
        'c2Percentage': total > 0 ? (c2Count / total) * 100 : 0.0,
        'c1Count': c1Count.toDouble(),
        'c2Count': c2Count.toDouble(),
        'totalAttempts': total.toDouble(),
      });
    });
  }

  /// Get technique comparison for backhand vs forehand across multiple metrics
  Map<String, Map<String, double>> getTechniqueComparison() {
    final Map<String, int> birdiesByTechnique = {};
    final Map<String, int> c1InRegByTechnique = {};
    final Map<String, int> c2InRegByTechnique = {};
    final Map<String, int> totalByTechnique = {};

    for (var hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final teeShot = hole.throws.first;
      if (teeShot.technique == null) continue;

      final techniqueName = teeShot.technique!.name;

      // Only track backhand and forehand
      if (techniqueName != 'backhand' && techniqueName != 'forehand') continue;

      totalByTechnique[techniqueName] =
          (totalByTechnique[techniqueName] ?? 0) + 1;

      // Count birdies
      if (hole.relativeHoleScore < 0) {
        birdiesByTechnique[techniqueName] =
            (birdiesByTechnique[techniqueName] ?? 0) + 1;
      }

      // Check C1/C2 in regulation
      final regulationStrokes = hole.par - 2;
      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked) {
            c1InRegByTechnique[techniqueName] =
                (c1InRegByTechnique[techniqueName] ?? 0) + 1;
            c2InRegByTechnique[techniqueName] =
                (c2InRegByTechnique[techniqueName] ?? 0) + 1;
            break;
          } else if (discThrow.landingSpot == LandingSpot.circle2) {
            c2InRegByTechnique[techniqueName] =
                (c2InRegByTechnique[techniqueName] ?? 0) + 1;
            break;
          }
        }
      }
    }

    return totalByTechnique.map((techniqueName, total) {
      final birdies = birdiesByTechnique[techniqueName] ?? 0;
      final c1Count = c1InRegByTechnique[techniqueName] ?? 0;
      final c2Count = c2InRegByTechnique[techniqueName] ?? 0;
      return MapEntry(techniqueName, {
        'birdiePercentage': total > 0 ? (birdies / total) * 100 : 0.0,
        'c1InRegPercentage': total > 0 ? (c1Count / total) * 100 : 0.0,
        'c2InRegPercentage': total > 0 ? (c2Count / total) * 100 : 0.0,
        'birdieCount': birdies.toDouble(),
        'c1Count': c1Count.toDouble(),
        'c2Count': c2Count.toDouble(),
        'totalAttempts': total.toDouble(),
      });
    });
  }

  /// Get the player's strongest performance category
  /// Returns a map with category info and performance metrics
  Map<String, dynamic> getStrongestPerformance() {
    String? strongestCategory;
    double bestScore = double.infinity;
    Map<String, double>? bestStats;
    String? categoryType; // 'par', 'distance', 'holeType', 'fairwayWidth'

    // Check performance by par
    final parStats = getPerformanceByPar();
    for (final entry in parStats.entries) {
      final avgScore = entry.value['avgScore'] ?? 0.0;
      final holesPlayed = entry.value['holesPlayed'] ?? 0.0;
      if (holesPlayed >= 3 && avgScore < bestScore) {
        bestScore = avgScore;
        strongestCategory = 'Par ${entry.key}s';
        bestStats = entry.value;
        categoryType = 'par';
      }
    }

    // Check performance by hole type
    final holeTypeStats = getPerformanceByHoleType();
    for (final entry in holeTypeStats.entries) {
      final avgScore = entry.value['avgScore'] ?? 0.0;
      final holesPlayed = entry.value['holesPlayed'] ?? 0.0;
      if (holesPlayed >= 3 && avgScore < bestScore) {
        bestScore = avgScore;
        strongestCategory = _formatHoleTypeName(entry.key);
        bestStats = entry.value;
        categoryType = 'holeType';
      }
    }

    // Check performance by fairway width
    final fairwayStats = getPerformanceByFairwayWidth();
    for (final entry in fairwayStats.entries) {
      final avgScore = entry.value['avgScore'] ?? 0.0;
      final holesPlayed = entry.value['holesPlayed'] ?? 0.0;
      if (holesPlayed >= 3 && avgScore < bestScore) {
        bestScore = avgScore;
        strongestCategory = _formatFairwayWidthName(entry.key);
        bestStats = entry.value;
        categoryType = 'fairwayWidth';
      }
    }

    if (strongestCategory == null || bestStats == null) {
      return {};
    }

    return {
      'category': strongestCategory,
      'categoryType': categoryType,
      'avgScore': bestScore,
      'birdieRate': bestStats['birdieRate'] ?? 0.0,
      'parRate': bestStats['parRate'] ?? 0.0,
      'bogeyRate': bestStats['bogeyRate'] ?? 0.0,
      'holesPlayed': bestStats['holesPlayed'] ?? 0.0,
    };
  }

  /// Get the player's weakest performance category
  /// Returns a map with category info and performance metrics
  Map<String, dynamic> getWeakestPerformance() {
    String? weakestCategory;
    double worstScore = double.negativeInfinity;
    Map<String, double>? worstStats;
    String? categoryType;

    // Check performance by par
    final parStats = getPerformanceByPar();
    for (final entry in parStats.entries) {
      final avgScore = entry.value['avgScore'] ?? 0.0;
      final holesPlayed = entry.value['holesPlayed'] ?? 0.0;
      if (holesPlayed >= 3 && avgScore > worstScore) {
        worstScore = avgScore;
        weakestCategory = 'Par ${entry.key}s';
        worstStats = entry.value;
        categoryType = 'par';
      }
    }

    // Check performance by hole type
    final holeTypeStats = getPerformanceByHoleType();
    for (final entry in holeTypeStats.entries) {
      final avgScore = entry.value['avgScore'] ?? 0.0;
      final holesPlayed = entry.value['holesPlayed'] ?? 0.0;
      if (holesPlayed >= 3 && avgScore > worstScore) {
        worstScore = avgScore;
        weakestCategory = _formatHoleTypeName(entry.key);
        worstStats = entry.value;
        categoryType = 'holeType';
      }
    }

    // Check performance by fairway width
    final fairwayStats = getPerformanceByFairwayWidth();
    for (final entry in fairwayStats.entries) {
      final avgScore = entry.value['avgScore'] ?? 0.0;
      final holesPlayed = entry.value['holesPlayed'] ?? 0.0;
      if (holesPlayed >= 3 && avgScore > worstScore) {
        worstScore = avgScore;
        weakestCategory = _formatFairwayWidthName(entry.key);
        worstStats = entry.value;
        categoryType = 'fairwayWidth';
      }
    }

    if (weakestCategory == null || worstStats == null) {
      return {};
    }

    return {
      'category': weakestCategory,
      'categoryType': categoryType,
      'avgScore': worstScore,
      'birdieRate': worstStats['birdieRate'] ?? 0.0,
      'parRate': worstStats['parRate'] ?? 0.0,
      'bogeyRate': worstStats['bogeyRate'] ?? 0.0,
      'holesPlayed': worstStats['holesPlayed'] ?? 0.0,
    };
  }

  /// Get a key insight or opportunity for improvement
  Map<String, dynamic> getKeyOpportunity() {
    final List<Map<String, dynamic>> opportunities = [];

    // Check if there's a significant difference between hole types
    final holeTypeStats = getPerformanceByHoleType();
    if (holeTypeStats.length >= 2) {
      final entries = holeTypeStats.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        for (int j = i + 1; j < entries.length; j++) {
          final holesPlayed1 = entries[i].value['holesPlayed'] ?? 0.0;
          final holesPlayed2 = entries[j].value['holesPlayed'] ?? 0.0;
          if (holesPlayed1 >= 3 && holesPlayed2 >= 3) {
            final avgScore1 = entries[i].value['avgScore'] ?? 0.0;
            final avgScore2 = entries[j].value['avgScore'] ?? 0.0;
            final difference = (avgScore1 - avgScore2).abs();
            if (difference >= 0.5) {
              final worseType = avgScore1 > avgScore2
                  ? entries[i].key
                  : entries[j].key;
              final betterType = avgScore1 < avgScore2
                  ? entries[i].key
                  : entries[j].key;
              opportunities.add({
                'type': 'holeType',
                'message':
                    'You score ${difference.toStringAsFixed(1)} strokes better on ${_formatHoleTypeName(betterType)} holes than ${_formatHoleTypeName(worseType)} holes',
                'priority': difference,
              });
            }
          }
        }
      }
    }

    // Check if there's a significant difference between fairway widths
    final fairwayStats = getPerformanceByFairwayWidth();
    if (fairwayStats.length >= 2) {
      final entries = fairwayStats.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        for (int j = i + 1; j < entries.length; j++) {
          final holesPlayed1 = entries[i].value['holesPlayed'] ?? 0.0;
          final holesPlayed2 = entries[j].value['holesPlayed'] ?? 0.0;
          if (holesPlayed1 >= 3 && holesPlayed2 >= 3) {
            final avgScore1 = entries[i].value['avgScore'] ?? 0.0;
            final avgScore2 = entries[j].value['avgScore'] ?? 0.0;
            final difference = (avgScore1 - avgScore2).abs();
            if (difference >= 0.5) {
              final worseType = avgScore1 > avgScore2
                  ? entries[i].key
                  : entries[j].key;
              final betterType = avgScore1 < avgScore2
                  ? entries[i].key
                  : entries[j].key;
              opportunities.add({
                'type': 'fairwayWidth',
                'message':
                    'Your ${_formatFairwayWidthName(worseType)} fairway performance is ${difference.toStringAsFixed(1)} strokes worse than ${_formatFairwayWidthName(betterType)} fairways',
                'priority': difference,
              });
            }
          }
        }
      }
    }

    // Return the highest priority opportunity
    if (opportunities.isEmpty) {
      return {};
    }

    opportunities.sort(
      (a, b) => (b['priority'] as double).compareTo(a['priority'] as double),
    );
    return opportunities.first;
  }

  String _formatHoleTypeName(String holeType) {
    switch (holeType.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'slightlywooded':
        return 'Lightly Wooded';
      case 'wooded':
        return 'Wooded';
      default:
        return holeType.capitalize();
    }
  }

  String _formatFairwayWidthName(String fairwayWidth) {
    switch (fairwayWidth.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'moderate':
        return 'Moderate';
      case 'tight':
        return 'Tight';
      case 'verytight':
        return 'Very Tight';
      default:
        return fairwayWidth.capitalize();
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
