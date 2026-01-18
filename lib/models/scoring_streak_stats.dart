import 'package:json_annotation/json_annotation.dart';

part 'scoring_streak_stats.g.dart';

/// Models for scoring streaks, runs, and momentum patterns
///
/// These are pre-calculated in Dart code to provide accurate scoring analysis
/// to the LLM, avoiding errors from having the LLM count/calculate itself.
@JsonSerializable(explicitToJson: true, anyMap: true)
class ScoringStreakStats {
  // Birdie streaks (consecutive birdie holes)
  final int longestBirdieStreak;
  final List<StreakInfo> birdieStreaks; // All streaks of 2+ holes

  // Bogey-or-worse streaks (consecutive bogey+ holes)
  final int longestBogeyStreak;
  final List<StreakInfo> bogeyStreaks; // All streaks of 2+ holes

  // Par-or-better streaks (consecutive par or birdie holes)
  final int longestParOrBetterStreak;
  final List<StreakInfo> parOrBetterStreaks;

  // Scoring runs (cumulative score changes over hole ranges)
  final List<ScoringRun> scoringRuns;

  // Momentum shifts (recovery patterns, blow-up followed by surge, etc.)
  final List<MomentumShift> momentumShifts;

  // Front 9 vs Back 9 breakdown
  final CourseSectionStats? frontNineStats;
  final CourseSectionStats? backNineStats;

  const ScoringStreakStats({
    required this.longestBirdieStreak,
    required this.birdieStreaks,
    required this.longestBogeyStreak,
    required this.bogeyStreaks,
    required this.longestParOrBetterStreak,
    required this.parOrBetterStreaks,
    required this.scoringRuns,
    required this.momentumShifts,
    this.frontNineStats,
    this.backNineStats,
  });

  factory ScoringStreakStats.fromJson(Map<String, dynamic> json) =>
      _$ScoringStreakStatsFromJson(json);

  Map<String, dynamic> toJson() => _$ScoringStreakStatsToJson(this);
}

/// Information about a scoring streak
@JsonSerializable(explicitToJson: true, anyMap: true)
class StreakInfo {
  final int startHole;
  final int endHole;
  final int length;
  final String streakType; // 'birdie', 'bogey', 'par-or-better'
  final int totalRelativeScore; // e.g., -5 for 5-hole birdie streak

  const StreakInfo({
    required this.startHole,
    required this.endHole,
    required this.length,
    required this.streakType,
    required this.totalRelativeScore,
  });

  String get holeRangeDisplay {
    if (startHole == endHole) return 'Hole $startHole';
    return 'Holes $startHole-$endHole';
  }

  factory StreakInfo.fromJson(Map<String, dynamic> json) =>
      _$StreakInfoFromJson(json);

  Map<String, dynamic> toJson() => _$StreakInfoToJson(this);
}

/// Information about a significant scoring run
@JsonSerializable(explicitToJson: true, anyMap: true)
class ScoringRun {
  final int startHole;
  final int endHole;
  final int relativeScore; // e.g., -4 over holes 4-8
  final String description; // e.g., "Went -4 over holes 4-8"

  const ScoringRun({
    required this.startHole,
    required this.endHole,
    required this.relativeScore,
    required this.description,
  });

  factory ScoringRun.fromJson(Map<String, dynamic> json) =>
      _$ScoringRunFromJson(json);

  Map<String, dynamic> toJson() => _$ScoringRunToJson(this);
}

/// Information about a momentum shift in the round
@JsonSerializable(explicitToJson: true, anyMap: true)
class MomentumShift {
  final int holeNumber;
  final String description; // e.g., "Recovered from double bogey with 3 straight birdies"
  final int holesInRecovery;

  const MomentumShift({
    required this.holeNumber,
    required this.description,
    required this.holesInRecovery,
  });

  factory MomentumShift.fromJson(Map<String, dynamic> json) =>
      _$MomentumShiftFromJson(json);

  Map<String, dynamic> toJson() => _$MomentumShiftToJson(this);
}

/// Stats for a section of the course (front 9, back 9, etc.)
@JsonSerializable(explicitToJson: true, anyMap: true)
class CourseSectionStats {
  final String sectionName; // e.g., "Front 9", "Back 9"
  final int startHole;
  final int endHole;
  final int totalScore;
  final int totalPar;
  final int relativeScore; // score - par
  final int birdies;
  final int pars;
  final int bogeys;
  final int doublesOrWorse;

  const CourseSectionStats({
    required this.sectionName,
    required this.startHole,
    required this.endHole,
    required this.totalScore,
    required this.totalPar,
    required this.relativeScore,
    required this.birdies,
    required this.pars,
    required this.bogeys,
    required this.doublesOrWorse,
  });

  String get scoreRelativeDisplay {
    if (relativeScore == 0) return 'E';
    if (relativeScore > 0) return '+$relativeScore';
    return '$relativeScore';
  }

  /// Get list of holes where specific scores occurred
  List<int> getHolesWithScore(String scoreType, List holes) {
    final List<int> result = [];
    for (int i = startHole - 1; i < endHole && i < holes.length; i++) {
      final hole = holes[i];
      final int relative = hole.holeScore - hole.par;

      switch (scoreType) {
        case 'birdie':
          if (relative == -1) result.add(hole.number);
          break;
        case 'par':
          if (relative == 0) result.add(hole.number);
          break;
        case 'bogey':
          if (relative == 1) result.add(hole.number);
          break;
        case 'double+':
          if (relative >= 2) result.add(hole.number);
          break;
      }
    }
    return result;
  }

  factory CourseSectionStats.fromJson(Map<String, dynamic> json) =>
      _$CourseSectionStatsFromJson(json);

  Map<String, dynamic> toJson() => _$CourseSectionStatsToJson(this);
}
