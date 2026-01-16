// lib/services/analysis_service.dart
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

/// Derived enums & models used by the analysis service.
enum ExecCategory { good, neutral, bad, severe }

enum LossReason {
  none,
  outOfBounds,
  missedC1,
  missedC1X,
  missedC2,
  missedApproach,
  poorDrive,
  penalty,
  rollaway,
  other,
}

/// Analysis result for a single throw
class ThrowAnalysis {
  final DiscThrow discThrow;
  final ExecCategory execCategory;
  final LossReason lossReason;
  final double
  weight; // positive for gains, negative for losses (we store positive weights and interpret sign)
  final double confidence; // 0.0 - 1.0
  final String note;

  ThrowAnalysis({
    required this.discThrow,
    required this.execCategory,
    required this.lossReason,
    required this.weight,
    required this.confidence,
    required this.note,
  });
}

/// Per-hole aggregated analysis
class HoleAnalysis {
  final DGHole hole;
  final List<ThrowAnalysis> throwAnalyses;

  final double weightedLoss; // sum of weights flagged as losses
  final double weightedGain; // sum of weights flagged as gains
  final int obviousLossCount;
  final int obviousGainCount;
  final double netObvious; // weightedGain - weightedLoss
  final double driveFairwayPct; // 0..1
  final double greensReachedPct; // 0..1
  final int holeScore;

  HoleAnalysis({required this.hole, required this.throwAnalyses})
    : holeScore = hole.holeScore,
      weightedLoss = throwAnalyses
          .where(
            (ta) =>
                ta.execCategory == ExecCategory.bad ||
                ta.execCategory == ExecCategory.severe,
          )
          .fold(0.0, (p, ta) => p + ta.weight),
      weightedGain = throwAnalyses
          .where((ta) => ta.execCategory == ExecCategory.good)
          .fold(0.0, (p, ta) => p + ta.weight),
      obviousLossCount = throwAnalyses
          .where(
            (ta) =>
                ta.execCategory == ExecCategory.bad ||
                ta.execCategory == ExecCategory.severe,
          )
          .length,
      obviousGainCount = throwAnalyses
          .where((ta) => ta.execCategory == ExecCategory.good)
          .length,
      netObvious =
          throwAnalyses
              .where((ta) => ta.execCategory == ExecCategory.good)
              .fold(0.0, (p, ta) => p + ta.weight) -
          throwAnalyses
              .where(
                (ta) =>
                    ta.execCategory == ExecCategory.bad ||
                    ta.execCategory == ExecCategory.severe,
              )
              .fold(0.0, (p, ta) => p + ta.weight),
      driveFairwayPct =
          throwAnalyses.isNotEmpty &&
              (throwAnalyses.first.discThrow.landingSpot ==
                      LandingSpot.fairway ||
                  throwAnalyses.first.discThrow.landingSpot ==
                      LandingSpot.parked)
          ? 1.0
          : 0.0,
      greensReachedPct =
          throwAnalyses.any(
            (t) =>
                t.discThrow.landingSpot == LandingSpot.circle1 ||
                t.discThrow.landingSpot == LandingSpot.circle2,
          )
          ? 1.0
          : 0.0;
}

/// Coaching card / suggestion
class CoachingCard {
  final LossReason reason;
  final String title;
  final String summary;
  final List<String> drills;
  final double priorityScore; // higher = more important

  CoachingCard({
    required this.reason,
    required this.title,
    required this.summary,
    required this.drills,
    required this.priorityScore,
  });
}

/// The analysis service with deterministic rules & weights
class GPTAnalysisService {
  // Tunable thresholds
  static const double shortC1Feet = 12.0; // 0-12ft: short C1 putts
  static const double circle1Feet = 33.0; // 0-33ft: C1 range
  static const double circle2Feet = 66.0; // 33-66ft: C2 range
  static const double puttThresholdFeet =
      66.0; // <= 66 ft considered "putt-range"
  static const double severeWeight = 2.0;
  static const double majorWeight = 1.0;
  static const double moderateWeight = 0.5;
  static const double goodWeight = 1.0;
  static const int shrinkageK = 10; // for priority confidence blending

  /// Analyze one throw deterministically
  static ThrowAnalysis analyzeThrow(DiscThrow t) {
    // helper to read numeric distance safely
    final dist = t.distanceFeetBeforeThrow;
    final parseConf = (t.parseConfidence != null)
        ? t.parseConfidence!.clamp(0.0, 1.0)
        : 0.8;

    // if landingSpot explicitly out_of_bounds or penaltyStrokes > 0 => severe
    if ((t.penaltyStrokes) > 0) {
      return ThrowAnalysis(
        discThrow: t,
        execCategory: ExecCategory.severe,
        lossReason: LossReason.outOfBounds,
        weight: severeWeight,
        confidence: parseConf,
        note: 'Out of bounds / penalty',
      );
    }

    // Only treat throws as putts if they're explicitly marked as putts
    final isPutt = t.purpose == ThrowPurpose.putt;

    if (isPutt) {
      // made?
      final made = t.landingSpot == LandingSpot.inBasket;
      if (dist != null && dist <= shortC1Feet) {
        // Short C1 (0-12 ft)
        if (made) {
          return ThrowAnalysis(
            discThrow: t,
            execCategory: ExecCategory.good,
            lossReason: LossReason.none,
            weight: goodWeight,
            confidence: parseConf,
            note: 'Made short C1 putt',
          );
        } else {
          // Missed short C1 — major mistake
          return ThrowAnalysis(
            discThrow: t,
            execCategory: ExecCategory.bad,
            lossReason: LossReason.missedC1,
            weight: majorWeight,
            confidence: parseConf,
            note: 'Missed short C1 putt',
          );
        }
      } else if (dist != null && dist <= circle1Feet) {
        // C1X (12-33 ft)
        if (made) {
          return ThrowAnalysis(
            discThrow: t,
            execCategory: ExecCategory.good,
            lossReason: LossReason.none,
            weight: goodWeight,
            confidence: parseConf,
            note: 'Made C1X putt',
          );
        } else {
          return ThrowAnalysis(
            discThrow: t,
            execCategory: ExecCategory.bad,
            lossReason: LossReason.missedC1X,
            weight: moderateWeight,
            confidence: parseConf,
            note: 'Missed C1X putt',
          );
        }
      } else if (dist != null && dist <= circle2Feet) {
        // C2 (33-66 ft)
        if (made) {
          return ThrowAnalysis(
            discThrow: t,
            execCategory: ExecCategory.good,
            lossReason: LossReason.none,
            weight: goodWeight,
            confidence: parseConf,
            note: 'Made C2 putt',
          );
        } else {
          return ThrowAnalysis(
            discThrow: t,
            execCategory: ExecCategory.bad,
            lossReason: LossReason.missedC2,
            weight: moderateWeight,
            confidence: parseConf,
            note: 'Missed C2 putt',
          );
        }
      } else {
        // long putt > 66ft
        if (made) {
          // high-value make
          return ThrowAnalysis(
            discThrow: t,
            execCategory: ExecCategory.good,
            lossReason: LossReason.none,
            weight: goodWeight,
            confidence: parseConf,
            note: 'Made long putt',
          );
        } else {
          // long putt miss is neutral by default (it's expected to be hard)
          return ThrowAnalysis(
            discThrow: t,
            execCategory: ExecCategory.neutral,
            lossReason: LossReason.none,
            weight: 0.0,
            confidence: parseConf,
            note: 'Missed long putt (neutral)',
          );
        }
      }
    }

    // Non-putt throws: drives & approaches
    // Drive (index == 0) rules
    if (t.index == 0) {
      // parked = great tee; fairway = good; offFairway = bad; trees/other -> moderate.
      if (t.landingSpot == LandingSpot.parked ||
          t.landingSpot == LandingSpot.circle1) {
        return ThrowAnalysis(
          discThrow: t,
          execCategory: ExecCategory.good,
          lossReason: LossReason.none,
          weight: goodWeight,
          confidence: parseConf,
          note: 'Excellent tee shot (parked/close)',
        );
      } else if (t.landingSpot == LandingSpot.fairway) {
        return ThrowAnalysis(
          discThrow: t,
          execCategory: ExecCategory.good,
          lossReason: LossReason.none,
          weight: goodWeight * 0.8,
          confidence: parseConf,
          note: 'Fairway drive',
        );
      } else if (t.landingSpot == LandingSpot.offFairway) {
        return ThrowAnalysis(
          discThrow: t,
          execCategory: ExecCategory.bad,
          lossReason: LossReason.poorDrive,
          weight: moderateWeight,
          confidence: parseConf,
          note: 'Off fairway tee shot — trouble likely',
        );
      } else {
        return ThrowAnalysis(
          discThrow: t,
          execCategory: ExecCategory.neutral,
          lossReason: LossReason.other,
          weight: 0.0,
          confidence: parseConf * 0.8,
          note: 'Tee shot (neutral)',
        );
      }
    }

    // Approach shot (non-putt & non-tee)
    if (t.purpose == ThrowPurpose.approach ||
        t.purpose == ThrowPurpose.scramble) {
      final landedOnGreen =
          t.landingSpot == LandingSpot.circle1 ||
          t.landingSpot == LandingSpot.circle2;
      if (landedOnGreen) {
        // Good approach, smaller weight for circle2 vs circle1
        final isC1 = t.landingSpot == LandingSpot.circle1;
        return ThrowAnalysis(
          discThrow: t,
          execCategory: ExecCategory.good,
          lossReason: LossReason.none,
          weight: isC1 ? goodWeight : goodWeight * 0.7,
          confidence: parseConf,
          note: 'Approach: hit green',
        );
      } else {
        // missed green -> likely negative
        return ThrowAnalysis(
          discThrow: t,
          execCategory: ExecCategory.bad,
          lossReason: LossReason.missedApproach,
          weight: majorWeight,
          confidence: parseConf,
          note: 'Approach missed green',
        );
      }
    }

    // fallback neutral
    return ThrowAnalysis(
      discThrow: t,
      execCategory: ExecCategory.neutral,
      lossReason: LossReason.none,
      weight: 0.0,
      confidence: parseConf * 0.7,
      note: 'Neutral / unclassified',
    );
  }

  /// Generates prioritized coaching cards from aggregated impact and counts.
  /// Uses Impact × Confidence as the priority score where Confidence = n/(n+k)
  static List<CoachingCard> generateCoachingCards(
    Map<LossReason, double> impact,
    Map<LossReason, int> counts,
  ) {
    final List<CoachingCard> cards = [];

    impact.forEach((reason, imp) {
      final n = counts[reason] ?? 0;
      final confidence = n / (n + shrinkageK);
      final priority = imp * confidence;

      if (priority <= 0.1) return; // ignore tiny priorities

      // map reason -> text + drills (simple mapping)
      switch (reason) {
        case LossReason.missedC1:
          cards.add(
            CoachingCard(
              reason: reason,
              title: 'Short putting (≤12 ft) misses',
              summary:
                  'You missed $n short putts — these are high-impact mistakes that are usually fixable with short practice.',
              drills: [
                'Tap & Step: 5 sets × 10 reps from 8–12 ft (goal: 80% makes)',
                'Pressure Ladder: 2-in-a-row to advance distance; repeat 10 times',
              ],
              priorityScore: priority,
            ),
          );
          break;
        case LossReason.missedC1X:
          cards.add(
            CoachingCard(
              reason: reason,
              title: 'C1X putting (12-33 ft) misses',
              summary:
                  'You missed $n putts in the 12-33 ft range — work on distance control and form consistency.',
              drills: [
                'Circle drill: 10 putts from each station (15, 20, 25, 30 ft)',
                'Run it: Practice aggressive putts from 20-25 ft for 15 minutes',
              ],
              priorityScore: priority,
            ),
          );
          break;
        case LossReason.outOfBounds:
          cards.add(
            CoachingCard(
              reason: reason,
              title: 'OB / Penalty management',
              summary:
                  'Out-of-bounds throws cost strokes directly. Work on tee discipline & conservative lines.',
              drills: [
                'Targeted Tee Practice: 50 drives aiming at two safe targets; name score',
                'Play “safe line” on 5 holes and track OB=0',
              ],
              priorityScore: priority,
            ),
          );
          break;
        case LossReason.missedApproach:
          cards.add(
            CoachingCard(
              reason: reason,
              title: 'Approach control',
              summary:
                  'Missed greens led to extra strokes. Practice approach distance control and landing in circle 2.',
              drills: [
                '30-ft placement: 4×12 reps with midrange; target inside 30 ft',
                'Upshot Game: 20 reps from rough to green, focus on landing',
              ],
              priorityScore: priority,
            ),
          );
          break;
        case LossReason.poorDrive:
          cards.add(
            CoachingCard(
              reason: reason,
              title: 'Tee shot accuracy',
              summary:
                  'Drives not hitting fairway or landing in trouble. Work on aim and disc selection.',
              drills: [
                'Target practice: 50 drives at fairway target',
                'Throw only 3 disc types in practice',
              ],
              priorityScore: priority,
            ),
          );
          break;
        default:
          cards.add(
            CoachingCard(
              reason: reason,
              title: describeLossReason(reason),
              summary: 'Observed $n events for ${describeLossReason(reason)}.',
              drills: ['Practice relevant game situations for this issue.'],
              priorityScore: priority,
            ),
          );
          break;
      }
    });

    // sort descending by priority
    cards.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return cards;
  }

  static String describeLossReason(LossReason r) {
    switch (r) {
      case LossReason.outOfBounds:
        return 'Out-of-bounds';
      case LossReason.missedC1:
        return 'Missed short putt (≤12 ft)';
      case LossReason.missedC1X:
        return 'Missed C1X putt (12-33 ft)';
      case LossReason.missedC2:
        return 'Missed C2 putt (33-66 ft)';
      case LossReason.missedApproach:
        return 'Missed approach';
      case LossReason.poorDrive:
        return 'Poor drive';
      case LossReason.penalty:
        return 'Penalty';
      case LossReason.rollaway:
        return 'Rollaway';
      default:
        return 'Other';
    }
  }
}
