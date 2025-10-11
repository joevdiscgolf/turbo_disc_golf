import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

part 'round_analysis.g.dart';

/// Comprehensive analysis of a disc golf round
/// Contains all computed statistics that would otherwise be recalculated on-the-fly
@JsonSerializable(explicitToJson: true, anyMap: true)
class RoundAnalysis {
  const RoundAnalysis({
    required this.scoringStats,
    required this.totalScoreRelativeToPar,
    required this.bounceBackPercentage,
    required this.birdieRateByPar,
    required this.birdieRateByLength,
    required this.avgBirdieHoleDistance,
    required this.puttingStats,
    required this.avgBirdiePuttDistance,
    required this.comebackPuttStats,
    required this.coreStats,
    required this.teeShotBirdieRates,
    required this.discBirdieRates,
    required this.discParRates,
    required this.discBogeyRates,
    required this.discAverageScores,
    required this.discPerformances,
    required this.discThrowCounts,
    required this.totalMistakes,
    required this.mistakesByCategory,
    required this.mistakeTypes,
    required this.teeComparison,
    required this.scrambleStats,
  });

  // Scoring statistics
  final ScoringStats scoringStats;
  final int totalScoreRelativeToPar;
  final double bounceBackPercentage;
  final Map<int, double> birdieRateByPar;
  final Map<String, double> birdieRateByLength;
  final double avgBirdieHoleDistance;

  // Putting statistics
  final PuttStats puttingStats;
  final double avgBirdiePuttDistance;
  final Map<String, dynamic> comebackPuttStats;

  // Driving/core statistics
  final CoreStats coreStats;
  final Map<String, BirdieRateStats> teeShotBirdieRates;

  // Disc performance
  final Map<String, double> discBirdieRates;
  final Map<String, double> discParRates;
  final Map<String, double> discBogeyRates;
  final Map<String, double> discAverageScores;
  final List<DiscPerformanceSummary> discPerformances;
  final Map<String, int> discThrowCounts;

  // Mistakes analysis
  final int totalMistakes;
  final Map<String, int> mistakesByCategory;
  final List<MistakeTypeSummary> mistakeTypes;

  // Technique comparisons
  final ComparisonResult teeComparison;
  final ScrambleStats scrambleStats;

  factory RoundAnalysis.fromJson(Map<String, dynamic> json) =>
      _$RoundAnalysisFromJson(json);

  Map<String, dynamic> toJson() => _$RoundAnalysisToJson(this);
}
