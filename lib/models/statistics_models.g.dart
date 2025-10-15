// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscStats _$DiscStatsFromJson(Map<String, dynamic> json) => DiscStats(
  discName: json['discName'] as String,
  timesThrown: (json['timesThrown'] as num).toInt(),
  birdies: (json['birdies'] as num).toInt(),
  pars: (json['pars'] as num).toInt(),
  bogeys: (json['bogeys'] as num).toInt(),
  fairwayHits: (json['fairwayHits'] as num).toInt(),
  offFairway: (json['offFairway'] as num).toInt(),
  outOfBounds: (json['outOfBounds'] as num).toInt(),
);

Map<String, dynamic> _$DiscStatsToJson(DiscStats instance) => <String, dynamic>{
  'discName': instance.discName,
  'timesThrown': instance.timesThrown,
  'birdies': instance.birdies,
  'pars': instance.pars,
  'bogeys': instance.bogeys,
  'fairwayHits': instance.fairwayHits,
  'offFairway': instance.offFairway,
  'outOfBounds': instance.outOfBounds,
};

PuttingStats _$PuttingStatsFromJson(Map<String, dynamic> json) => PuttingStats(
  distanceRange: json['distanceRange'] as String,
  attempted: (json['attempted'] as num).toInt(),
  made: (json['made'] as num).toInt(),
);

Map<String, dynamic> _$PuttingStatsToJson(PuttingStats instance) =>
    <String, dynamic>{
      'distanceRange': instance.distanceRange,
      'attempted': instance.attempted,
      'made': instance.made,
    };

TechniqueStats _$TechniqueStatsFromJson(Map<String, dynamic> json) =>
    TechniqueStats(
      techniqueName: json['techniqueName'] as String,
      attempts: (json['attempts'] as num).toInt(),
      successful: (json['successful'] as num).toInt(),
      unsuccessful: (json['unsuccessful'] as num).toInt(),
      birdies: (json['birdies'] as num).toInt(),
      pars: (json['pars'] as num).toInt(),
      bogeys: (json['bogeys'] as num).toInt(),
    );

Map<String, dynamic> _$TechniqueStatsToJson(TechniqueStats instance) =>
    <String, dynamic>{
      'techniqueName': instance.techniqueName,
      'attempts': instance.attempts,
      'successful': instance.successful,
      'unsuccessful': instance.unsuccessful,
      'birdies': instance.birdies,
      'pars': instance.pars,
      'bogeys': instance.bogeys,
    };

ScoringStats _$ScoringStatsFromJson(Map<String, dynamic> json) => ScoringStats(
  totalHoles: (json['totalHoles'] as num).toInt(),
  eagles: (json['eagles'] as num).toInt(),
  birdies: (json['birdies'] as num).toInt(),
  pars: (json['pars'] as num).toInt(),
  bogeys: (json['bogeys'] as num).toInt(),
  doubleBogeyPlus: (json['doubleBogeyPlus'] as num).toInt(),
);

Map<String, dynamic> _$ScoringStatsToJson(ScoringStats instance) =>
    <String, dynamic>{
      'totalHoles': instance.totalHoles,
      'eagles': instance.eagles,
      'birdies': instance.birdies,
      'pars': instance.pars,
      'bogeys': instance.bogeys,
      'doubleBogeyPlus': instance.doubleBogeyPlus,
    };

ScrambleStats _$ScrambleStatsFromJson(Map<String, dynamic> json) =>
    ScrambleStats(
      scrambleOpportunities: (json['scrambleOpportunities'] as num).toInt(),
      scrambleSaves: (json['scrambleSaves'] as num).toInt(),
    );

Map<String, dynamic> _$ScrambleStatsToJson(ScrambleStats instance) =>
    <String, dynamic>{
      'scrambleOpportunities': instance.scrambleOpportunities,
      'scrambleSaves': instance.scrambleSaves,
    };

ComparisonResult _$ComparisonResultFromJson(Map<String, dynamic> json) =>
    ComparisonResult(
      technique1: json['technique1'] as String,
      technique2: json['technique2'] as String,
      technique1BirdieRate: (json['technique1BirdieRate'] as num).toDouble(),
      technique2BirdieRate: (json['technique2BirdieRate'] as num).toDouble(),
      technique1SuccessRate: (json['technique1SuccessRate'] as num).toDouble(),
      technique2SuccessRate: (json['technique2SuccessRate'] as num).toDouble(),
      technique1Count: (json['technique1Count'] as num).toInt(),
      technique2Count: (json['technique2Count'] as num).toInt(),
    );

Map<String, dynamic> _$ComparisonResultToJson(ComparisonResult instance) =>
    <String, dynamic>{
      'technique1': instance.technique1,
      'technique2': instance.technique2,
      'technique1BirdieRate': instance.technique1BirdieRate,
      'technique2BirdieRate': instance.technique2BirdieRate,
      'technique1SuccessRate': instance.technique1SuccessRate,
      'technique2SuccessRate': instance.technique2SuccessRate,
      'technique1Count': instance.technique1Count,
      'technique2Count': instance.technique2Count,
    };

DiscInsight _$DiscInsightFromJson(Map<String, dynamic> json) => DiscInsight(
  discName: json['discName'] as String,
  birdieRate: (json['birdieRate'] as num).toDouble(),
  timesUsed: (json['timesUsed'] as num).toInt(),
  category: json['category'] as String,
);

Map<String, dynamic> _$DiscInsightToJson(DiscInsight instance) =>
    <String, dynamic>{
      'discName': instance.discName,
      'birdieRate': instance.birdieRate,
      'timesUsed': instance.timesUsed,
      'category': instance.category,
    };

PuttBucketStats _$PuttBucketStatsFromJson(Map<String, dynamic> json) =>
    PuttBucketStats(
      label: json['label'] as String,
      makes: (json['makes'] as num).toInt(),
      misses: (json['misses'] as num).toInt(),
      avgDistance: (json['avgDistance'] as num).toDouble(),
    );

Map<String, dynamic> _$PuttBucketStatsToJson(PuttBucketStats instance) =>
    <String, dynamic>{
      'label': instance.label,
      'makes': instance.makes,
      'misses': instance.misses,
      'avgDistance': instance.avgDistance,
    };

PuttStats _$PuttStatsFromJson(Map<String, dynamic> json) => PuttStats(
  c1Makes: (json['c1Makes'] as num).toInt(),
  c1Misses: (json['c1Misses'] as num).toInt(),
  c2Makes: (json['c2Makes'] as num).toInt(),
  c2Misses: (json['c2Misses'] as num).toInt(),
  avgMakeDistance: (json['avgMakeDistance'] as num).toDouble(),
  avgMissDistance: (json['avgMissDistance'] as num).toDouble(),
  avgAttemptDistance: (json['avgAttemptDistance'] as num).toDouble(),
  totalMadeDistance: (json['totalMadeDistance'] as num).toDouble(),
  bucketStats: (json['bucketStats'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, PuttBucketStats.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$PuttStatsToJson(PuttStats instance) => <String, dynamic>{
  'c1Makes': instance.c1Makes,
  'c1Misses': instance.c1Misses,
  'c2Makes': instance.c2Makes,
  'c2Misses': instance.c2Misses,
  'avgMakeDistance': instance.avgMakeDistance,
  'avgMissDistance': instance.avgMissDistance,
  'avgAttemptDistance': instance.avgAttemptDistance,
  'totalMadeDistance': instance.totalMadeDistance,
  'bucketStats': instance.bucketStats.map((k, e) => MapEntry(k, e.toJson())),
};

CoreStats _$CoreStatsFromJson(Map<String, dynamic> json) => CoreStats(
  fairwayHitPct: (json['fairwayHitPct'] as num).toDouble(),
  parkedPct: (json['parkedPct'] as num).toDouble(),
  c1InRegPct: (json['c1InRegPct'] as num).toDouble(),
  c2InRegPct: (json['c2InRegPct'] as num).toDouble(),
  obPct: (json['obPct'] as num).toDouble(),
  totalHoles: (json['totalHoles'] as num).toInt(),
);

Map<String, dynamic> _$CoreStatsToJson(CoreStats instance) => <String, dynamic>{
  'fairwayHitPct': instance.fairwayHitPct,
  'parkedPct': instance.parkedPct,
  'c1InRegPct': instance.c1InRegPct,
  'c2InRegPct': instance.c2InRegPct,
  'obPct': instance.obPct,
  'totalHoles': instance.totalHoles,
};

DiscMistake _$DiscMistakeFromJson(Map<String, dynamic> json) => DiscMistake(
  discName: json['discName'] as String,
  mistakeCount: (json['mistakeCount'] as num).toInt(),
  reasons: (json['reasons'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$DiscMistakeToJson(DiscMistake instance) =>
    <String, dynamic>{
      'discName': instance.discName,
      'mistakeCount': instance.mistakeCount,
      'reasons': instance.reasons,
    };

DiscPerformanceSummary _$DiscPerformanceSummaryFromJson(
  Map<String, dynamic> json,
) => DiscPerformanceSummary(
  discName: json['discName'] as String,
  goodShots: (json['goodShots'] as num).toInt(),
  okayShots: (json['okayShots'] as num).toInt(),
  badShots: (json['badShots'] as num).toInt(),
  totalShots: (json['totalShots'] as num).toInt(),
);

Map<String, dynamic> _$DiscPerformanceSummaryToJson(
  DiscPerformanceSummary instance,
) => <String, dynamic>{
  'discName': instance.discName,
  'goodShots': instance.goodShots,
  'okayShots': instance.okayShots,
  'badShots': instance.badShots,
  'totalShots': instance.totalShots,
};

MistakeTypeSummary _$MistakeTypeSummaryFromJson(Map<String, dynamic> json) =>
    MistakeTypeSummary(
      label: json['label'] as String,
      count: (json['count'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
    );

Map<String, dynamic> _$MistakeTypeSummaryToJson(MistakeTypeSummary instance) =>
    <String, dynamic>{
      'label': instance.label,
      'count': instance.count,
      'percentage': instance.percentage,
    };

BirdieRateStats _$BirdieRateStatsFromJson(Map<String, dynamic> json) =>
    BirdieRateStats(
      percentage: (json['percentage'] as num).toDouble(),
      birdieCount: (json['birdieCount'] as num).toInt(),
      totalAttempts: (json['totalAttempts'] as num).toInt(),
    );

Map<String, dynamic> _$BirdieRateStatsToJson(BirdieRateStats instance) =>
    <String, dynamic>{
      'percentage': instance.percentage,
      'birdieCount': instance.birdieCount,
      'totalAttempts': instance.totalAttempts,
    };

ScoreSegment _$ScoreSegmentFromJson(Map<String, dynamic> json) => ScoreSegment(
  label: json['label'] as String,
  avgScore: (json['avgScore'] as num).toDouble(),
  holesPlayed: (json['holesPlayed'] as num).toInt(),
);

Map<String, dynamic> _$ScoreSegmentToJson(ScoreSegment instance) =>
    <String, dynamic>{
      'label': instance.label,
      'avgScore': instance.avgScore,
      'holesPlayed': instance.holesPlayed,
    };

ScoreTrend _$ScoreTrendFromJson(Map<String, dynamic> json) => ScoreTrend(
  segments: (json['segments'] as List<dynamic>)
      .map((e) => ScoreSegment.fromJson(e as Map<String, dynamic>))
      .toList(),
  trendDirection: json['trendDirection'] as String,
  trendStrength: (json['trendStrength'] as num).toDouble(),
);

Map<String, dynamic> _$ScoreTrendToJson(ScoreTrend instance) =>
    <String, dynamic>{
      'segments': instance.segments.map((e) => e.toJson()).toList(),
      'trendDirection': instance.trendDirection,
      'trendStrength': instance.trendStrength,
    };

SectionPerformance _$SectionPerformanceFromJson(Map<String, dynamic> json) =>
    SectionPerformance(
      sectionName: json['sectionName'] as String,
      holesPlayed: (json['holesPlayed'] as num).toInt(),
      avgScore: (json['avgScore'] as num).toDouble(),
      birdieRate: (json['birdieRate'] as num).toDouble(),
      parRate: (json['parRate'] as num).toDouble(),
      bogeyPlusRate: (json['bogeyPlusRate'] as num).toDouble(),
      shotQualityRate: (json['shotQualityRate'] as num).toDouble(),
      c1InRegRate: (json['c1InRegRate'] as num).toDouble(),
      c2InRegRate: (json['c2InRegRate'] as num).toDouble(),
      fairwayHitRate: (json['fairwayHitRate'] as num).toDouble(),
      obRate: (json['obRate'] as num).toDouble(),
      mistakeCount: (json['mistakeCount'] as num).toInt(),
    );

Map<String, dynamic> _$SectionPerformanceToJson(SectionPerformance instance) =>
    <String, dynamic>{
      'sectionName': instance.sectionName,
      'holesPlayed': instance.holesPlayed,
      'avgScore': instance.avgScore,
      'birdieRate': instance.birdieRate,
      'parRate': instance.parRate,
      'bogeyPlusRate': instance.bogeyPlusRate,
      'shotQualityRate': instance.shotQualityRate,
      'c1InRegRate': instance.c1InRegRate,
      'c2InRegRate': instance.c2InRegRate,
      'fairwayHitRate': instance.fairwayHitRate,
      'obRate': instance.obRate,
      'mistakeCount': instance.mistakeCount,
    };

ScoringTransition _$ScoringTransitionFromJson(Map<String, dynamic> json) =>
    ScoringTransition(
      fromScore: json['fromScore'] as String,
      toBirdiePercent: (json['toBirdiePercent'] as num).toDouble(),
      toParPercent: (json['toParPercent'] as num).toDouble(),
      toBogeyPercent: (json['toBogeyPercent'] as num).toDouble(),
      toDoublePercent: (json['toDoublePercent'] as num).toDouble(),
    );

Map<String, dynamic> _$ScoringTransitionToJson(ScoringTransition instance) =>
    <String, dynamic>{
      'fromScore': instance.fromScore,
      'toBirdiePercent': instance.toBirdiePercent,
      'toParPercent': instance.toParPercent,
      'toBogeyPercent': instance.toBogeyPercent,
      'toDoublePercent': instance.toDoublePercent,
    };

PsychStats _$PsychStatsFromJson(Map<String, dynamic> json) => PsychStats(
  transitionMatrix: (json['transitionMatrix'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, ScoringTransition.fromJson(e as Map<String, dynamic>)),
  ),
  momentumMultiplier: (json['momentumMultiplier'] as num).toDouble(),
  tiltFactor: (json['tiltFactor'] as num).toDouble(),
  bounceBackRate: (json['bounceBackRate'] as num).toDouble(),
  compoundErrorRate: (json['compoundErrorRate'] as num).toDouble(),
  longestParStreak: (json['longestParStreak'] as num).toInt(),
  mentalProfile: json['mentalProfile'] as String,
  insights: (json['insights'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  front9Performance: json['front9Performance'] == null
      ? null
      : SectionPerformance.fromJson(
          json['front9Performance'] as Map<String, dynamic>,
        ),
  back9Performance: json['back9Performance'] == null
      ? null
      : SectionPerformance.fromJson(
          json['back9Performance'] as Map<String, dynamic>,
        ),
  last6Performance: json['last6Performance'] == null
      ? null
      : SectionPerformance.fromJson(
          json['last6Performance'] as Map<String, dynamic>,
        ),
  conditioningScore: (json['conditioningScore'] as num).toDouble(),
  scoreTrend: json['scoreTrend'] == null
      ? null
      : ScoreTrend.fromJson(json['scoreTrend'] as Map<String, dynamic>),
  flowStateAnalysis: json['flowStateAnalysis'] == null
      ? null
      : FlowStateAnalysis.fromJson(
          json['flowStateAnalysis'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PsychStatsToJson(PsychStats instance) =>
    <String, dynamic>{
      'transitionMatrix': instance.transitionMatrix.map(
        (k, e) => MapEntry(k, e.toJson()),
      ),
      'momentumMultiplier': instance.momentumMultiplier,
      'tiltFactor': instance.tiltFactor,
      'bounceBackRate': instance.bounceBackRate,
      'compoundErrorRate': instance.compoundErrorRate,
      'longestParStreak': instance.longestParStreak,
      'mentalProfile': instance.mentalProfile,
      'insights': instance.insights,
      'front9Performance': instance.front9Performance?.toJson(),
      'back9Performance': instance.back9Performance?.toJson(),
      'last6Performance': instance.last6Performance?.toJson(),
      'conditioningScore': instance.conditioningScore,
      'scoreTrend': instance.scoreTrend?.toJson(),
      'flowStateAnalysis': instance.flowStateAnalysis?.toJson(),
    };

FlowStatePeriod _$FlowStatePeriodFromJson(Map<String, dynamic> json) =>
    FlowStatePeriod(
      startHole: (json['startHole'] as num).toInt(),
      endHole: (json['endHole'] as num).toInt(),
      duration: (json['duration'] as num).toInt(),
      avgScore: (json['avgScore'] as num).toDouble(),
      shotQualityRate: (json['shotQualityRate'] as num).toDouble(),
      birdieCount: (json['birdieCount'] as num).toInt(),
      parCount: (json['parCount'] as num).toInt(),
      mistakeCount: (json['mistakeCount'] as num).toInt(),
      commonDiscs: (json['commonDiscs'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      commonTechniques: (json['commonTechniques'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dominantWindCondition: json['dominantWindCondition'] as String?,
      flowQuality: json['flowQuality'] as String,
    );

Map<String, dynamic> _$FlowStatePeriodToJson(FlowStatePeriod instance) =>
    <String, dynamic>{
      'startHole': instance.startHole,
      'endHole': instance.endHole,
      'duration': instance.duration,
      'avgScore': instance.avgScore,
      'shotQualityRate': instance.shotQualityRate,
      'birdieCount': instance.birdieCount,
      'parCount': instance.parCount,
      'mistakeCount': instance.mistakeCount,
      'commonDiscs': instance.commonDiscs,
      'commonTechniques': instance.commonTechniques,
      'dominantWindCondition': instance.dominantWindCondition,
      'flowQuality': instance.flowQuality,
    };

FlowStateAnalysis _$FlowStateAnalysisFromJson(Map<String, dynamic> json) =>
    FlowStateAnalysis(
      flowPeriods: (json['flowPeriods'] as List<dynamic>)
          .map((e) => FlowStatePeriod.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalFlowHoles: (json['totalFlowHoles'] as num).toInt(),
      flowPercentage: (json['flowPercentage'] as num).toDouble(),
      longestFlow: json['longestFlow'] == null
          ? null
          : FlowStatePeriod.fromJson(
              json['longestFlow'] as Map<String, dynamic>,
            ),
      bestFlow: json['bestFlow'] == null
          ? null
          : FlowStatePeriod.fromJson(json['bestFlow'] as Map<String, dynamic>),
      flowTriggers: (json['flowTriggers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      insights: (json['insights'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      overallFlowScore: (json['overallFlowScore'] as num).toDouble(),
    );

Map<String, dynamic> _$FlowStateAnalysisToJson(FlowStateAnalysis instance) =>
    <String, dynamic>{
      'flowPeriods': instance.flowPeriods.map((e) => e.toJson()).toList(),
      'totalFlowHoles': instance.totalFlowHoles,
      'flowPercentage': instance.flowPercentage,
      'longestFlow': instance.longestFlow?.toJson(),
      'bestFlow': instance.bestFlow?.toJson(),
      'flowTriggers': instance.flowTriggers,
      'insights': instance.insights,
      'overallFlowScore': instance.overallFlowScore,
    };
