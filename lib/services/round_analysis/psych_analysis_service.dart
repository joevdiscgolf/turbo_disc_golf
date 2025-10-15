import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/score_analysis_service.dart';

class PsychAnalysisService {
  /// Get comprehensive momentum and psychological analysis
  PsychStats getPsychStats(DGRound round) {
    // Need at least 3 holes for meaningful momentum analysis
    if (round.holes.length < 3) {
      return PsychStats(
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
        avgBogeyPlusAfterBad += transitionMatrix['Bogey']!.bogeyOrWorsePercent;
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
        final overallBogeyRate =
            locator
                .get<ScoreAnalysisService>()
                .getScoringStats(round)
                .bogeyRate +
            locator
                .get<ScoreAnalysisService>()
                .getScoringStats(round)
                .doubleBogeyPlusRate;
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
        if (nextHole.relativeHoleScore < 0) {
          // Birdie or better
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
    int longestParStreak =
        0; // Note: field name kept for backward compatibility
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

      final last3Avg =
          last3Holes.fold<double>(0.0, (sum, h) => sum + h.relativeHoleScore) /
          3;
      final first3Avg =
          first3Holes.fold<double>(0.0, (sum, h) => sum + h.relativeHoleScore) /
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
      insights.add('You rarely compound mistakes - excellent damage control!');
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
        round,
        round.holes.sublist(0, 9),
        'Front 9',
      );
    }

    // Back 9 (holes 9+)
    if (round.holes.length > 9) {
      back9Performance = _calculateSectionPerformance(
        round,
        round.holes.sublist(9),
        'Back 9',
      );
    }

    // Last 6 holes
    if (round.holes.length >= 6) {
      final startIndex = round.holes.length - 6;
      last6Performance = _calculateSectionPerformance(
        round,
        round.holes.sublist(startIndex),
        'Last 6',
      );
    }

    // Step 11: Calculate conditioning score
    double conditioningScore = 50.0; // Default neutral score

    if (front9Performance != null && back9Performance != null) {
      final scoreDiff = (back9Performance.avgScore - front9Performance.avgScore)
          .abs();

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
      if (back9Performance.shotQualityRate <
          front9Performance.shotQualityRate - 15) {
        insights.add(
          'Shot quality drops ${(front9Performance.shotQualityRate - back9Performance.shotQualityRate).toStringAsFixed(0)}% in back 9. Focus on maintaining form when fatigued.',
        );
      }
    }

    // Last 6 holes analysis
    if (last6Performance != null) {
      final overallAvgScore =
          round.holes.fold<int>(
            0,
            (sum, hole) => sum + hole.relativeHoleScore,
          ) /
          round.holes.length;

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

    // Calculate score trend
    final scoreTrend = getScoreTrend(round);

    return PsychStats(
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
      scoreTrend: scoreTrend,
    );
  }

  /// Get progressive score trend analysis throughout the round
  ScoreTrend? getScoreTrend(DGRound round) {
    // Need at least 6 holes for meaningful trend analysis
    if (round.holes.length < 6) {
      return null;
    }

    // Divide round into segments of 3 holes each
    final List<ScoreSegment> segments = [];
    int segmentSize = 3;

    for (int i = 0; i < round.holes.length; i += segmentSize) {
      final endIndex = (i + segmentSize).clamp(0, round.holes.length);
      final segmentHoles = round.holes.sublist(i, endIndex);

      if (segmentHoles.isEmpty) continue;

      // Calculate average score for this segment
      final totalScore = segmentHoles.fold<int>(
        0,
        (sum, hole) => sum + hole.relativeHoleScore,
      );
      final avgScore = totalScore / segmentHoles.length;

      // Create label (e.g., "1-3", "4-6", "7-9")
      final startHole = i + 1;
      final endHole = endIndex;
      final label = endHole - startHole == 0
          ? '$startHole'
          : '$startHole-$endHole';

      segments.add(
        ScoreSegment(
          label: label,
          avgScore: avgScore,
          holesPlayed: segmentHoles.length,
        ),
      );
    }

    if (segments.length < 2) {
      return null;
    }

    // Calculate trend direction by comparing first third to last third
    final firstThirdCount = (segments.length / 3).ceil();
    final lastThirdCount = (segments.length / 3).ceil();

    final firstThirdSegments = segments.sublist(0, firstThirdCount);
    final lastThirdSegments = segments.sublist(
      segments.length - lastThirdCount,
    );

    final firstThirdAvg =
        firstThirdSegments.fold<double>(0.0, (sum, seg) => sum + seg.avgScore) /
        firstThirdSegments.length;
    final lastThirdAvg =
        lastThirdSegments.fold<double>(0.0, (sum, seg) => sum + seg.avgScore) /
        lastThirdSegments.length;

    // Trend strength: negative means scores got better (improving)
    // positive means scores got worse (worsening)
    final trendStrength = lastThirdAvg - firstThirdAvg;

    String trendDirection;
    if (trendStrength < -0.3) {
      trendDirection = 'improving';
    } else if (trendStrength > 0.3) {
      trendDirection = 'worsening';
    } else {
      trendDirection = 'stable';
    }

    return ScoreTrend(
      segments: segments,
      trendDirection: trendDirection,
      trendStrength: -trendStrength, // Negate so positive = improving
    );
  }

  /// Helper method to calculate section performance for a list of holes
  SectionPerformance _calculateSectionPerformance(
    DGRound round,
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

    // Count total shots in this section
    int totalShots = 0;
    for (var hole in sectionHoles) {
      totalShots += hole.throws.length;
    }

    // Count mistakes in this section
    final allMistakes = locator
        .get<MistakesAnalysisService>()
        .getMistakeThrowDetails(round);
    final sectionHoleNumbers = sectionHoles.map((h) => h.number).toSet();
    final mistakeCount = allMistakes
        .where((m) => sectionHoleNumbers.contains(m['holeNumber']))
        .length;

    // Calculate shot quality based on mistakes (consistent metric)
    final shotQualityRate = totalShots > 0
        ? ((totalShots - mistakeCount) / totalShots) * 100
        : 0.0;

    final totalHoles = sectionHoles.length;
    return SectionPerformance(
      sectionName: sectionName,
      holesPlayed: totalHoles,
      avgScore: totalScore / totalHoles,
      birdieRate: (birdies / totalHoles) * 100,
      parRate: (pars / totalHoles) * 100,
      bogeyPlusRate: (bogeyPlus / totalHoles) * 100,
      shotQualityRate: shotQualityRate,
      c1InRegRate: (c1InReg / totalHoles) * 100,
      c2InRegRate: (c2InReg / totalHoles) * 100,
      fairwayHitRate: (fairwayHits / totalHoles) * 100,
      obRate: (obHoles / totalHoles) * 100,
      mistakeCount: mistakeCount,
    );
  }
}
