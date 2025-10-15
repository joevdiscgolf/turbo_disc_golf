import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/gpt_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';

class MistakesAnalysisService {
  int getTotalMistakesCount(DGRound round) {
    return getMistakeThrowDetails(round).length;
  }

  Map<String, int> getMistakesByCategory(DGRound round) {
    int drivingMistakes = 0;
    int approachMistakes = 0;
    int puttingMistakes = 0;

    final mistakes = getMistakeThrowDetails(round);

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

  List<Map<String, dynamic>> getMistakeThrowDetails(DGRound round) {
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
        // For putts, only in_basket is good; for other throws, C1/C2/parked/fairway are good
        final isGoodLanding = discThrow.purpose == ThrowPurpose.putt
            ? discThrow.landingSpot == LandingSpot.inBasket
            : (discThrow.landingSpot == LandingSpot.circle1 ||
                  discThrow.landingSpot == LandingSpot.circle2 ||
                  discThrow.landingSpot == LandingSpot.parked ||
                  discThrow.landingSpot == LandingSpot.fairway);

        final hasGoodRating =
            discThrow.resultRating == ThrowResultRating.excellent ||
            discThrow.resultRating == ThrowResultRating.good;

        // Check if next throw is a short putt (indicates this approach was good)
        final bool nextThrowIsShortPutt =
            i < hole.throws.length - 1 &&
            hole.throws[i + 1].purpose == ThrowPurpose.putt &&
            (hole.throws[i + 1].distanceFeetBeforeThrow ?? 999) <= 33;

        // Check if this was likely a good throw based on multiple signals
        final isLikelyGoodThrow =
            isGoodLanding || hasGoodRating || nextThrowIsShortPutt;

        // Recovery after penalty logic (putts are never considered recovery)
        final isRecoveryAfterPenalty =
            i > 0 &&
            discThrow.purpose != ThrowPurpose.putt &&
            (hole.throws[i - 1].penaltyStrokes ?? 0) > 0 &&
            isLikelyGoodThrow;

        // Override the analysis for approaches that seem good but weren't marked as such
        final isApproachWithGoodSignals =
            discThrow.purpose == ThrowPurpose.approach &&
            isLikelyGoodThrow &&
            analysis.execCategory == ExecCategory.bad;

        final isMistake =
            (analysis.execCategory == ExecCategory.bad ||
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

  List<MistakeTypeSummary> getMistakeTypes(round) {
    final Map<String, int> mistakeTypeCounts = {};

    final mistakes = getMistakeThrowDetails(round);
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

    if (purpose == ThrowPurpose.putt &&
        discThrow.distanceFeetBeforeThrow != null) {
      final distance = discThrow.distanceFeetBeforeThrow!;
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
}
