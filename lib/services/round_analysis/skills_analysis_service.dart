import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/constants/putting_constants.dart';

/// Data model for individual skill scores
class SkillScore {
  const SkillScore({
    required this.skillName,
    required this.percentage,
    required this.rawValue,
    required this.maxValue,
  });

  final String skillName;
  final double percentage; // 0-100
  final double rawValue;
  final double maxValue;
}

/// Data model for overall skills analysis
class SkillsAnalysis {
  const SkillsAnalysis({
    required this.backhandDriving,
    required this.forehandDriving,
    required this.approaching,
    required this.putting,
    required this.mentalFocus,
    required this.overallScore,
  });

  final SkillScore backhandDriving;
  final SkillScore forehandDriving;
  final SkillScore approaching;
  final SkillScore putting;
  final SkillScore mentalFocus;
  final double overallScore; // Average of all skills

  List<SkillScore> get allSkills => [
    backhandDriving,
    forehandDriving,
    approaching,
    putting,
    mentalFocus,
  ];
}

/// Service to analyze and calculate skill scores from round data
class SkillsAnalysisService {
  /// Calculate backhand driving score based on C1 in regulation %
  SkillScore calculateBackhandDriving(DGRound round) {
    int backhandAttempts = 0;
    int backhandC1InReg = 0;

    for (final DGHole hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final DiscThrow teeShot = hole.throws.first;
      final int regulationStrokes = hole.par - 2;

      // Check if it's a backhand drive
      if (teeShot.technique?.name == 'backhand' && regulationStrokes > 0) {
        backhandAttempts++;

        // Check if reached C1 in regulation
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final DiscThrow discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked) {
            backhandC1InReg++;
            break;
          }
        }
      }
    }

    final double percentage = backhandAttempts > 0
        ? (backhandC1InReg / backhandAttempts * 100)
        : 0;

    return SkillScore(
      skillName: 'Backhand Driving',
      percentage: percentage,
      rawValue: backhandC1InReg.toDouble(),
      maxValue: backhandAttempts.toDouble(),
    );
  }

  /// Calculate forehand driving score based on C1 in regulation %
  SkillScore calculateForehandDriving(DGRound round) {
    int forehandAttempts = 0;
    int forehandC1InReg = 0;

    for (final DGHole hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      final DiscThrow teeShot = hole.throws.first;
      final int regulationStrokes = hole.par - 2;

      // Check if it's a forehand drive
      if (teeShot.technique?.name == 'forehand' && regulationStrokes > 0) {
        forehandAttempts++;

        // Check if reached C1 in regulation
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final DiscThrow discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked) {
            forehandC1InReg++;
            break;
          }
        }
      }
    }

    final double percentage = forehandAttempts > 0
        ? (forehandC1InReg / forehandAttempts * 100)
        : 0;

    return SkillScore(
      skillName: 'Forehand Driving',
      percentage: percentage,
      rawValue: forehandC1InReg.toDouble(),
      maxValue: forehandAttempts.toDouble(),
    );
  }

  /// Calculate approaching score based on C1 in regulation % for approach shots
  /// (non-tee shots that land in C1)
  SkillScore calculateApproaching(DGRound round) {
    int approachAttempts = 0;
    int approachC1Success = 0;

    for (final DGHole hole in round.holes) {
      if (hole.throws.length < 2) continue;

      // Look at throws after the tee shot
      for (int i = 1; i < hole.throws.length; i++) {
        final DiscThrow discThrow = hole.throws[i];

        // Skip putts
        if (discThrow.purpose == ThrowPurpose.putt) continue;

        approachAttempts++;

        // Check if approach landed in C1
        if (discThrow.landingSpot == LandingSpot.circle1 ||
            discThrow.landingSpot == LandingSpot.parked ||
            discThrow.landingSpot == LandingSpot.inBasket) {
          approachC1Success++;
        }
      }
    }

    final double percentage = approachAttempts > 0
        ? (approachC1Success / approachAttempts * 100)
        : 0;

    return SkillScore(
      skillName: 'Approaching',
      percentage: percentage,
      rawValue: approachC1Success.toDouble(),
      maxValue: approachAttempts.toDouble(),
    );
  }

  /// Calculate putting score as weighted average: 75% C1, 25% C2
  SkillScore calculatePutting(DGRound round) {
    int c1Attempts = 0;
    int c1Makes = 0;
    int c2Attempts = 0;
    int c2Makes = 0;

    for (final DGHole hole in round.holes) {
      for (final DiscThrow discThrow in hole.throws) {
        if (discThrow.purpose == ThrowPurpose.putt) {
          final double? distance = discThrow.distanceFeetBeforeThrow
              ?.toDouble();
          final bool made = discThrow.landingSpot == LandingSpot.inBasket;

          if (distance != null) {
            // C1 putts (0-33 ft)
            if (distance >= c1MinDistance && distance <= c1MaxDistance) {
              c1Attempts++;
              if (made) c1Makes++;
            }
            // C2 putts (33-66 ft)
            else if (distance > c2MinDistance && distance <= c2MaxDistance) {
              c2Attempts++;
              if (made) c2Makes++;
            }
          }
        }
      }
    }

    final double c1Percentage = c1Attempts > 0 ? (c1Makes / c1Attempts) : 0;
    final double c2Percentage = c2Attempts > 0 ? (c2Makes / c2Attempts) : 0;

    // Weighted score: 75% C1, 25% C2
    final double weightedScore = (c1Percentage * 0.75) + (c2Percentage * 0.25);
    final double percentage = weightedScore * 100;

    return SkillScore(
      skillName: 'Putting',
      percentage: percentage,
      rawValue: (c1Makes * 0.75) + (c2Makes * 0.25),
      maxValue: (c1Attempts * 0.75) + (c2Attempts * 0.25),
    );
  }

  /// Calculate mental focus score based on bounce-back rate and consistency
  /// This is a simplified calculation that can be enhanced later
  SkillScore calculateMentalFocus(DGRound round) {
    if (round.holes.length < 2) {
      return const SkillScore(
        skillName: 'Mental Focus',
        percentage: 0,
        rawValue: 0,
        maxValue: 0,
      );
    }

    int bounceBackAttempts = 0;
    int bounceBackSuccesses = 0;

    // Calculate bounce-back rate (par or better after bogey)
    for (int i = 0; i < round.holes.length - 1; i++) {
      final DGHole currentHole = round.holes[i];
      final DGHole nextHole = round.holes[i + 1];

      // If current hole was a bogey or worse
      if (currentHole.relativeHoleScore > 0) {
        bounceBackAttempts++;
        // Check if bounced back with par or better
        if (nextHole.relativeHoleScore <= 0) {
          bounceBackSuccesses++;
        }
      }
    }

    final double percentage = bounceBackAttempts > 0
        ? (bounceBackSuccesses / bounceBackAttempts * 100)
        : 50.0; // Default to 50% if no data

    return SkillScore(
      skillName: 'Mental Focus',
      percentage: percentage,
      rawValue: bounceBackSuccesses.toDouble(),
      maxValue: bounceBackAttempts.toDouble(),
    );
  }

  /// Get complete skills analysis for a round
  SkillsAnalysis getSkillsAnalysis(DGRound round) {
    final SkillScore backhandDriving = calculateBackhandDriving(round);
    final SkillScore forehandDriving = calculateForehandDriving(round);
    final SkillScore approaching = calculateApproaching(round);
    final SkillScore putting = calculatePutting(round);
    final SkillScore mentalFocus = calculateMentalFocus(round);

    // Calculate overall score as average
    final double overallScore =
        (backhandDriving.percentage +
            forehandDriving.percentage +
            approaching.percentage +
            putting.percentage +
            mentalFocus.percentage) /
        5;

    return SkillsAnalysis(
      backhandDriving: backhandDriving,
      forehandDriving: forehandDriving,
      approaching: approaching,
      putting: putting,
      mentalFocus: mentalFocus,
      overallScore: overallScore,
    );
  }
}
