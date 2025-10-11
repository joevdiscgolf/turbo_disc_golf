import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';

/// Generates comprehensive analysis data from a parsed round
/// This is done once after parsing to avoid recalculating stats in each tab
class RoundAnalysisGenerator {
  /// Generates all analysis data from a parsed round
  static RoundAnalysis generateAnalysis(DGRound round) {
    final statsService = RoundStatisticsService(round);

    return RoundAnalysis(
      // Scoring statistics
      scoringStats: statsService.getScoringStats(),
      totalScoreRelativeToPar: statsService.getTotalScoreRelativeToPar(),
      bounceBackPercentage: statsService.getBounceBackPercentage(),
      birdieRateByPar: statsService.getBirdieRateByPar(),
      birdieRateByLength: statsService.getBirdieRateByHoleLength(),
      avgBirdieHoleDistance: statsService.getAverageBirdieHoleDistance(),

      // Putting statistics
      puttingStats: statsService.getPuttingSummary(),
      avgBirdiePuttDistance: statsService.getAverageBirdiePuttDistance(),
      comebackPuttStats: statsService.getComebackPuttStats(),

      // Driving/core statistics
      coreStats: statsService.getCoreStats(),
      teeShotBirdieRates: statsService.getTeeShotBirdieRateStats(),

      // Disc performance
      discBirdieRates: statsService.getDiscBirdieRates(),
      discParRates: statsService.getDiscParRates(),
      discBogeyRates: statsService.getDiscBogeyRates(),
      discAverageScores: statsService.getDiscAverageScores(),
      discPerformances: statsService.getDiscPerformanceSummaries(),
      discThrowCounts: statsService.getDiscThrowCounts(),

      // Mistakes analysis
      totalMistakes: statsService.getTotalMistakesCount(),
      mistakesByCategory: statsService.getMistakesByCategory(),
      mistakeTypes: statsService.getMistakeTypes(),

      // Technique comparisons
      teeComparison: statsService.compareBackhandVsForehandTeeShots(),
      scrambleStats: statsService.getScrambleStats(),
    );
  }
}
