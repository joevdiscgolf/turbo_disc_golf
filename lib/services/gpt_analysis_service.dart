// lib/services/analysis_service.dart
import 'dart:math';

import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

/// Derived enums & models used by the analysis service.
enum ExecCategory { good, neutral, bad, severe }

enum LossReason {
  none,
  outOfBounds,
  missedC1,
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

/// Per-round aggregated analysis and coaching suggestions
class RoundAnalysis {
  final DGRound round;
  final List<HoleAnalysis> holeAnalyses;

  final double weightedLoss;
  final double weightedGain;
  final double netObvious;
  final int obviousLossCount;
  final int obviousGainCount;
  final Map<LossReason, double> impactByReason;
  final Map<LossReason, int> countByReason;
  final List<CoachingCard> coachingCards;

  RoundAnalysis({required this.round, required this.holeAnalyses})
    : weightedLoss = holeAnalyses.fold(0.0, (p, h) => p + h.weightedLoss),
      weightedGain = holeAnalyses.fold(0.0, (p, h) => p + h.weightedGain),
      netObvious = holeAnalyses.fold(
        0.0,
        (p, h) => p + (h.weightedGain - h.weightedLoss),
      ),
      obviousLossCount = holeAnalyses.fold(0, (p, h) => p + h.obviousLossCount),
      obviousGainCount = holeAnalyses.fold(0, (p, h) => p + h.obviousGainCount),
      impactByReason = _aggregateImpact(holeAnalyses).$1,
      countByReason = _aggregateImpact(holeAnalyses).$2,
      coachingCards = GPTAnalysisService.generateCoachingCards(
        _aggregateImpact(holeAnalyses).$1,
        _aggregateImpact(holeAnalyses).$2,
      );

  static (_MapDouble, _MapInt) _aggregateImpact(List<HoleAnalysis> holes) {
    final impact = <LossReason, double>{};
    final counts = <LossReason, int>{};
    for (final h in holes) {
      for (final ta in h.throwAnalyses) {
        final reason = ta.lossReason;
        if (reason == LossReason.none) continue;
        impact[reason] = (impact[reason] ?? 0) + ta.weight;
        counts[reason] = (counts[reason] ?? 0) + 1;
      }
    }
    return (impact, counts);
  }
}

typedef _MapDouble = Map<LossReason, double>;
typedef _MapInt = Map<LossReason, int>;

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
  static const double circle1Feet = 10.0;
  static const double circle2Feet = 30.0;
  static const double puttThresholdFeet =
      33.0; // <= 33 ft considered "putt-range"
  static const double severeWeight = 2.0;
  static const double majorWeight = 1.0;
  static const double moderateWeight = 0.5;
  static const double goodWeight = 1.0;
  static const int shrinkageK = 10; // for priority confidence blending

  /// Analyze a whole round
  static RoundAnalysis analyzeRound(DGRound round) {
    final holes = <HoleAnalysis>[];
    for (final hole in round.holes) {
      final throwAnalyses = <ThrowAnalysis>[];
      for (final t in hole.throws) {
        final ta = analyzeThrow(t);
        throwAnalyses.add(ta);
      }

      // post-process scramble attribution or approach->scramble inference:
      // If an approach missed green and final hole score <= par => treat later throws as successful scrambles (reduce loss or add gain)
      final missedGreen = hole.throws.any(
        (t) =>
            t.purpose == ThrowPurpose.approach &&
            t.landingSpot != LandingSpot.circle1 &&
            t.landingSpot != LandingSpot.circle2,
      );
      if (missedGreen && hole.holeScore <= hole.par) {
        // find the throw that landed on green or in basket after the miss and mark it as a small positive gain (if not already good)
        for (int i = 0; i < hole.throws.length; i++) {
          final t = hole.throws[i];
          if (t.landingSpot == LandingSpot.circle1 ||
              t.landingSpot == LandingSpot.circle2 ||
              t.landingSpot == LandingSpot.inBasket) {
            // find existing throwAnalysis and, if it's neutral or bad, nudge it to a "good" scramble save
            final taIndex = throwAnalyses.indexWhere((ta) => ta.discThrow == t);
            if (taIndex >= 0) {
              final current = throwAnalyses[taIndex];
              if (current.execCategory != ExecCategory.good) {
                throwAnalyses[taIndex] = ThrowAnalysis(
                  discThrow: current.discThrow,
                  execCategory: ExecCategory.good,
                  lossReason: LossReason.none,
                  weight: goodWeight,
                  confidence: max(0.5, current.confidence),
                  note: 'Scramble save credited',
                );
              }
            }
            break;
          }
        }
      }
      holes.add(HoleAnalysis(hole: hole, throwAnalyses: throwAnalyses));
    }
    return RoundAnalysis(round: round, holeAnalyses: holes);
  }

  /// Analyze one throw deterministically
  static ThrowAnalysis analyzeThrow(DiscThrow t) {
    // helper to read numeric distance safely
    final dist = t.distanceFeet;
    final parseConf = (t.parseConfidence != null)
        ? t.parseConfidence!.clamp(0.0, 1.0)
        : 0.8;

    // if landingSpot explicitly out_of_bounds or penaltyStrokes > 0 => severe
    if (t.landingSpot == LandingSpot.outOfBounds ||
        (t.penaltyStrokes ?? 0) > 0) {
      return ThrowAnalysis(
        discThrow: t,
        execCategory: ExecCategory.severe,
        lossReason: LossReason.outOfBounds,
        weight: severeWeight,
        confidence: parseConf,
        note: 'Out of bounds / penalty',
      );
    }

    // If the throw is a putt (either declared or by distance)
    final isPutt =
        t.purpose == ThrowPurpose.putt ||
        (dist != null && dist <= puttThresholdFeet);

    if (isPutt) {
      // made?
      final made = t.landingSpot == LandingSpot.inBasket;
      if (dist != null && dist <= circle1Feet) {
        // C1 (<= 10 ft)
        if (made) {
          return ThrowAnalysis(
            discThrow: t,
            execCategory: ExecCategory.good,
            lossReason: LossReason.none,
            weight: goodWeight,
            confidence: parseConf,
            note: 'Made C1 putt',
          );
        } else {
          // Missed C1 — major / severe depending on context (use major here)
          return ThrowAnalysis(
            discThrow: t,
            execCategory: ExecCategory.bad,
            lossReason: LossReason.missedC1,
            weight: majorWeight,
            confidence: parseConf,
            note: 'Missed C1 putt',
          );
        }
      } else if (dist != null && dist <= circle2Feet) {
        // C2 10-30 ft
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
        // long putt > 30ft
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
              title: 'Short putting (≤10 ft) misses',
              summary:
                  'You missed $n short putts — these are high-impact mistakes that are usually fixable with short practice.',
              drills: [
                'Tap & Step: 5 sets × 10 reps from 8–10 ft (goal: 80% makes)',
                'Pressure Ladder: 2-in-a-row to advance distance; repeat 10 times',
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
        return 'Missed short putt (C1)';
      case LossReason.missedC2:
        return 'Missed mid putt (C2)';
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
