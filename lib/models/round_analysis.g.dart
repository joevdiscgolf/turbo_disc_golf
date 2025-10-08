// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoundAnalysis _$RoundAnalysisFromJson(Map json) => RoundAnalysis(
  scoringStats: ScoringStats.fromJson(
    Map<String, dynamic>.from(json['scoringStats'] as Map),
  ),
  totalScoreRelativeToPar: (json['totalScoreRelativeToPar'] as num).toInt(),
  bounceBackPercentage: (json['bounceBackPercentage'] as num).toDouble(),
  birdieRateByPar: (json['birdieRateByPar'] as Map).map(
    (k, e) => MapEntry(int.parse(k as String), (e as num).toDouble()),
  ),
  birdieRateByLength: (json['birdieRateByLength'] as Map).map(
    (k, e) => MapEntry(k as String, (e as num).toDouble()),
  ),
  avgBirdieHoleDistance: (json['avgBirdieHoleDistance'] as num).toDouble(),
  puttingStats: PuttStats.fromJson(
    Map<String, dynamic>.from(json['puttingStats'] as Map),
  ),
  avgBirdiePuttDistance: (json['avgBirdiePuttDistance'] as num).toDouble(),
  comebackPuttStats: Map<String, dynamic>.from(
    json['comebackPuttStats'] as Map,
  ),
  coreStats: CoreStats.fromJson(
    Map<String, dynamic>.from(json['coreStats'] as Map),
  ),
  teeShotBirdieRates: (json['teeShotBirdieRates'] as Map).map(
    (k, e) => MapEntry(
      k as String,
      BirdieRateStats.fromJson(Map<String, dynamic>.from(e as Map)),
    ),
  ),
  discBirdieRates: (json['discBirdieRates'] as Map).map(
    (k, e) => MapEntry(k as String, (e as num).toDouble()),
  ),
  discParRates: (json['discParRates'] as Map).map(
    (k, e) => MapEntry(k as String, (e as num).toDouble()),
  ),
  discBogeyRates: (json['discBogeyRates'] as Map).map(
    (k, e) => MapEntry(k as String, (e as num).toDouble()),
  ),
  discAverageScores: (json['discAverageScores'] as Map).map(
    (k, e) => MapEntry(k as String, (e as num).toDouble()),
  ),
  discPerformances: (json['discPerformances'] as List<dynamic>)
      .map(
        (e) => DiscPerformanceSummary.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
      )
      .toList(),
  discThrowCounts: Map<String, int>.from(json['discThrowCounts'] as Map),
  totalMistakes: (json['totalMistakes'] as num).toInt(),
  mistakesByCategory: Map<String, int>.from(json['mistakesByCategory'] as Map),
  mistakeTypes: (json['mistakeTypes'] as List<dynamic>)
      .map(
        (e) => MistakeTypeSummary.fromJson(Map<String, dynamic>.from(e as Map)),
      )
      .toList(),
  teeComparison: ComparisonResult.fromJson(
    Map<String, dynamic>.from(json['teeComparison'] as Map),
  ),
  scrambleStats: ScrambleStats.fromJson(
    Map<String, dynamic>.from(json['scrambleStats'] as Map),
  ),
);

Map<String, dynamic> _$RoundAnalysisToJson(
  RoundAnalysis instance,
) => <String, dynamic>{
  'scoringStats': instance.scoringStats.toJson(),
  'totalScoreRelativeToPar': instance.totalScoreRelativeToPar,
  'bounceBackPercentage': instance.bounceBackPercentage,
  'birdieRateByPar': instance.birdieRateByPar.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
  'birdieRateByLength': instance.birdieRateByLength,
  'avgBirdieHoleDistance': instance.avgBirdieHoleDistance,
  'puttingStats': instance.puttingStats.toJson(),
  'avgBirdiePuttDistance': instance.avgBirdiePuttDistance,
  'comebackPuttStats': instance.comebackPuttStats,
  'coreStats': instance.coreStats.toJson(),
  'teeShotBirdieRates': instance.teeShotBirdieRates.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'discBirdieRates': instance.discBirdieRates,
  'discParRates': instance.discParRates,
  'discBogeyRates': instance.discBogeyRates,
  'discAverageScores': instance.discAverageScores,
  'discPerformances': instance.discPerformances.map((e) => e.toJson()).toList(),
  'discThrowCounts': instance.discThrowCounts,
  'totalMistakes': instance.totalMistakes,
  'mistakesByCategory': instance.mistakesByCategory,
  'mistakeTypes': instance.mistakeTypes.map((e) => e.toJson()).toList(),
  'teeComparison': instance.teeComparison.toJson(),
  'scrambleStats': instance.scrambleStats.toJson(),
};
