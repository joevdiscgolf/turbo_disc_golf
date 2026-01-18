// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scoring_streak_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScoringStreakStats _$ScoringStreakStatsFromJson(Map json) => ScoringStreakStats(
  longestBirdieStreak: (json['longestBirdieStreak'] as num).toInt(),
  birdieStreaks: (json['birdieStreaks'] as List<dynamic>)
      .map((e) => StreakInfo.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  longestBogeyStreak: (json['longestBogeyStreak'] as num).toInt(),
  bogeyStreaks: (json['bogeyStreaks'] as List<dynamic>)
      .map((e) => StreakInfo.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  longestParOrBetterStreak: (json['longestParOrBetterStreak'] as num).toInt(),
  parOrBetterStreaks: (json['parOrBetterStreaks'] as List<dynamic>)
      .map((e) => StreakInfo.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  scoringRuns: (json['scoringRuns'] as List<dynamic>)
      .map((e) => ScoringRun.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  momentumShifts: (json['momentumShifts'] as List<dynamic>)
      .map((e) => MomentumShift.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  frontNineStats: json['frontNineStats'] == null
      ? null
      : CourseSectionStats.fromJson(
          Map<String, dynamic>.from(json['frontNineStats'] as Map),
        ),
  backNineStats: json['backNineStats'] == null
      ? null
      : CourseSectionStats.fromJson(
          Map<String, dynamic>.from(json['backNineStats'] as Map),
        ),
);

Map<String, dynamic> _$ScoringStreakStatsToJson(ScoringStreakStats instance) =>
    <String, dynamic>{
      'longestBirdieStreak': instance.longestBirdieStreak,
      'birdieStreaks': instance.birdieStreaks.map((e) => e.toJson()).toList(),
      'longestBogeyStreak': instance.longestBogeyStreak,
      'bogeyStreaks': instance.bogeyStreaks.map((e) => e.toJson()).toList(),
      'longestParOrBetterStreak': instance.longestParOrBetterStreak,
      'parOrBetterStreaks': instance.parOrBetterStreaks
          .map((e) => e.toJson())
          .toList(),
      'scoringRuns': instance.scoringRuns.map((e) => e.toJson()).toList(),
      'momentumShifts': instance.momentumShifts.map((e) => e.toJson()).toList(),
      'frontNineStats': instance.frontNineStats?.toJson(),
      'backNineStats': instance.backNineStats?.toJson(),
    };

StreakInfo _$StreakInfoFromJson(Map json) => StreakInfo(
  startHole: (json['startHole'] as num).toInt(),
  endHole: (json['endHole'] as num).toInt(),
  length: (json['length'] as num).toInt(),
  streakType: json['streakType'] as String,
  totalRelativeScore: (json['totalRelativeScore'] as num).toInt(),
);

Map<String, dynamic> _$StreakInfoToJson(StreakInfo instance) =>
    <String, dynamic>{
      'startHole': instance.startHole,
      'endHole': instance.endHole,
      'length': instance.length,
      'streakType': instance.streakType,
      'totalRelativeScore': instance.totalRelativeScore,
    };

ScoringRun _$ScoringRunFromJson(Map json) => ScoringRun(
  startHole: (json['startHole'] as num).toInt(),
  endHole: (json['endHole'] as num).toInt(),
  relativeScore: (json['relativeScore'] as num).toInt(),
  description: json['description'] as String,
);

Map<String, dynamic> _$ScoringRunToJson(ScoringRun instance) =>
    <String, dynamic>{
      'startHole': instance.startHole,
      'endHole': instance.endHole,
      'relativeScore': instance.relativeScore,
      'description': instance.description,
    };

MomentumShift _$MomentumShiftFromJson(Map json) => MomentumShift(
  holeNumber: (json['holeNumber'] as num).toInt(),
  description: json['description'] as String,
  holesInRecovery: (json['holesInRecovery'] as num).toInt(),
);

Map<String, dynamic> _$MomentumShiftToJson(MomentumShift instance) =>
    <String, dynamic>{
      'holeNumber': instance.holeNumber,
      'description': instance.description,
      'holesInRecovery': instance.holesInRecovery,
    };

CourseSectionStats _$CourseSectionStatsFromJson(Map json) => CourseSectionStats(
  sectionName: json['sectionName'] as String,
  startHole: (json['startHole'] as num).toInt(),
  endHole: (json['endHole'] as num).toInt(),
  totalScore: (json['totalScore'] as num).toInt(),
  totalPar: (json['totalPar'] as num).toInt(),
  relativeScore: (json['relativeScore'] as num).toInt(),
  birdies: (json['birdies'] as num).toInt(),
  pars: (json['pars'] as num).toInt(),
  bogeys: (json['bogeys'] as num).toInt(),
  doublesOrWorse: (json['doublesOrWorse'] as num).toInt(),
);

Map<String, dynamic> _$CourseSectionStatsToJson(CourseSectionStats instance) =>
    <String, dynamic>{
      'sectionName': instance.sectionName,
      'startHole': instance.startHole,
      'endHole': instance.endHole,
      'totalScore': instance.totalScore,
      'totalPar': instance.totalPar,
      'relativeScore': instance.relativeScore,
      'birdies': instance.birdies,
      'pars': instance.pars,
      'bogeys': instance.bogeys,
      'doublesOrWorse': instance.doublesOrWorse,
    };
