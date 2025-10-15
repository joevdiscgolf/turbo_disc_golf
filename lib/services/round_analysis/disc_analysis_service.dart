import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/gpt_analysis_service.dart';

class DiscAnalysisService {
  List<DiscPerformanceSummary> getDiscPerformanceSummaries(DGRound round) {
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

  Map<String, double> getDiscBirdieRates(DGRound round) {
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

  Map<String, double> getDiscParRates(DGRound round) {
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

  Map<String, double> getDiscBogeyRates(DGRound round) {
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

  Map<String, double> getDiscAverageScores(DGRound round) {
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
      final avg =
          scores.fold<int>(0, (sum, score) => sum + score) / scores.length;
      return MapEntry(disc, avg);
    });
  }

  Map<String, int> getDiscThrowCounts(DGRound round) {
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

  Map<String, double> getDiscC1InRegPercentages(DGRound round) {
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
          for (
            int i = 0;
            i < hole.throws.length && i < regulationStrokes;
            i++
          ) {
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

  Map<String, double> getDiscC2InRegPercentages(DGRound round) {
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
          for (
            int i = 0;
            i < hole.throws.length && i < regulationStrokes;
            i++
          ) {
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

  List<Map<String, dynamic>> getThrowsForDisc(String discName, DGRound round) {
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
  Map<String, DiscStats> getDiscPerformance(DGRound round) {
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
  List<DiscInsight> getTopPerformingDiscs(DGRound round, {int limit = 3}) {
    final discStats = getDiscPerformance(round);
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

  List<DiscMistake> getMajorMistakesByDisc(DGRound round) {
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
}
