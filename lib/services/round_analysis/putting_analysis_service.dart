import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class PuttingAnalysisService {
  /// Get putting statistics by distance range
  Map<String, PuttingStats> getPuttingStatsByDistance(DGRound round) {
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

  /// Get comprehensive putting summary with C1/C2 breakdown and distance buckets
  PuttStats getPuttingSummary(DGRound round) {
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
  double getAverageBirdiePuttDistance(DGRound round) {
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

  Map<String, dynamic> getComebackPuttStats(DGRound round) {
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

  /// Get all putt attempts with distance and made/missed status
  /// Returns a list of maps containing: distance, made, holeNumber, throwIndex
  List<Map<String, dynamic>> getPuttAttempts(DGRound round) {
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
