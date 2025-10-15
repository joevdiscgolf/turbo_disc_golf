import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/round_analysis/disc_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/score_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';

/// Generates comprehensive analysis data from a parsed round
/// This is done once after parsing to avoid recalculating stats in each tab
class RoundAnalysisGenerator {
  /// Generates all analysis data from a parsed round
  static RoundAnalysis generateAnalysis(DGRound round) {
    final statsService = RoundStatisticsService(round);
    final puttingAnalysisService = locator.get<PuttingAnalysisService>();
    final mistakesAnalysisService = locator.get<MistakesAnalysisService>();
    final discAnalysisService = locator.get<DiscAnalysisService>();

    return RoundAnalysis(
      // Scoring statistics
      scoringStats: locator.get<ScoreAnalysisService>().getScoringStats(round),
      totalScoreRelativeToPar: statsService.getTotalScoreRelativeToPar(),
      bounceBackPercentage: statsService.getBounceBackPercentage(),
      birdieRateByPar: statsService.getBirdieRateByPar(),
      birdieRateByLength: statsService.getBirdieRateByHoleLength(),
      avgBirdieHoleDistance: statsService.getAverageBirdieHoleDistance(),

      // Putting statistics
      puttingStats: puttingAnalysisService.getPuttingSummary(round),
      avgBirdiePuttDistance: puttingAnalysisService
          .getAverageBirdiePuttDistance(round),
      comebackPuttStats: puttingAnalysisService.getComebackPuttStats(round),

      // Driving/core statistics
      coreStats: statsService.getCoreStats(),
      teeShotBirdieRates: statsService.getTeeShotBirdieRateStats(),

      // Disc performance
      discBirdieRates: discAnalysisService.getDiscBirdieRates(round),
      discParRates: discAnalysisService.getDiscParRates(round),
      discBogeyRates: discAnalysisService.getDiscBogeyRates(round),
      discAverageScores: discAnalysisService.getDiscAverageScores(round),
      discPerformances: discAnalysisService.getDiscPerformanceSummaries(round),
      discThrowCounts: discAnalysisService.getDiscThrowCounts(round),

      // Mistakes analysis
      totalMistakes: mistakesAnalysisService.getTotalMistakesCount(round),
      mistakesByCategory: mistakesAnalysisService.getMistakesByCategory(round),
      mistakeTypes: mistakesAnalysisService.getMistakeTypes(round),

      // Technique comparisons
      teeComparison: statsService.compareBackhandVsForehandTeeShots(),
      scrambleStats: statsService.getScrambleStats(),
    );
  }
}
