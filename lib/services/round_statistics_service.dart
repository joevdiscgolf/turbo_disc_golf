import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

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
    if (discThrow.penaltyStrokes != null && discThrow.penaltyStrokes! > 0) return false;

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
        if (discThrow.purpose == ThrowPurpose.putt && discThrow.distanceFeet != null) {
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
      final made = putts.where((p) => p.landingSpot == LandingSpot.inBasket).length;
      return MapEntry(
        range,
        PuttingStats(
          distanceRange: range,
          attempted: putts.length,
          made: made,
        ),
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

    final backhandStats = teeStats['backhand'] ??
        TechniqueStats(
          techniqueName: 'backhand',
          attempts: 0,
          successful: 0,
          unsuccessful: 0,
          birdies: 0,
          pars: 0,
          bogeys: 0,
        );

    final forehandStats = teeStats['forehand'] ??
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

    final backhandStats = approachStats['backhand'] ??
        TechniqueStats(
          techniqueName: 'backhand',
          attempts: 0,
          successful: 0,
          unsuccessful: 0,
          birdies: 0,
          pars: 0,
          bogeys: 0,
        );

    final forehandStats = approachStats['forehand'] ??
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
            (discThrow.penaltyStrokes != null && discThrow.penaltyStrokes! > 0)) {
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
            '${entry.key.capitalize()} tee shots - ${entry.value.successRate.toStringAsFixed(0)}% success');
      }
    }

    // Check approach techniques
    final approachStats = getTechniqueStats(ThrowPurpose.approach);
    for (var entry in approachStats.entries) {
      if (entry.value.attempts >= 3 && entry.value.successRate < 50) {
        problems.add(
            '${entry.key.capitalize()} approaches - ${entry.value.successRate.toStringAsFixed(0)}% success');
      }
    }

    // Check putting
    final puttingStats = getPuttingStatsByDistance();
    final circle1Stats = puttingStats['15-33 ft (C1)'];
    if (circle1Stats != null &&
        circle1Stats.attempted >= 3 &&
        circle1Stats.makePercentage < 60) {
      problems.add(
          'Circle 1 putting - ${circle1Stats.makePercentage.toStringAsFixed(0)}% make rate');
    }

    return problems;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
