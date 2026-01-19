import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/scoring_streak_stats.dart';

/// Service for calculating scoring streaks, runs, and momentum patterns
///
/// Pre-calculates these statistics in Dart code to provide accurate data
/// to the LLM, avoiding errors from having the LLM count/calculate itself.
class ScoringStreakService {
  /// Calculate all scoring streak statistics for a round
  ScoringStreakStats calculateStreaks(DGRound round) {
    final List<DGHole> holes = round.holes;

    // Calculate streaks
    final List<StreakInfo> birdieStreaks = _findStreaks(
      holes,
      (relative) => relative == -1,
      'birdie',
    );
    final int longestBirdieStreak =
        birdieStreaks.isEmpty ? 0 : birdieStreaks.map((s) => s.length).reduce((a, b) => a > b ? a : b);

    final List<StreakInfo> bogeyStreaks = _findStreaks(
      holes,
      (relative) => relative >= 1,
      'bogey',
    );
    final int longestBogeyStreak =
        bogeyStreaks.isEmpty ? 0 : bogeyStreaks.map((s) => s.length).reduce((a, b) => a > b ? a : b);

    final List<StreakInfo> parOrBetterStreaks = _findStreaks(
      holes,
      (relative) => relative <= 0,
      'par-or-better',
    );
    final int longestParOrBetterStreak =
        parOrBetterStreaks.isEmpty ? 0 : parOrBetterStreaks.map((s) => s.length).reduce((a, b) => a > b ? a : b);

    // Calculate scoring runs
    final List<ScoringRun> scoringRuns = _identifyScoringRuns(holes);

    // Find momentum shifts
    final List<MomentumShift> momentumShifts = _findMomentumShifts(holes);

    // Calculate course section stats (front 9, back 9)
    final CourseSectionStats? frontNine = _calculateSectionStats(
      holes,
      sectionName: 'Front 9',
      startHole: 1,
      endHole: 9,
    );
    final CourseSectionStats? backNine = _calculateSectionStats(
      holes,
      sectionName: 'Back 9',
      startHole: 10,
      endHole: 18,
    );

    return ScoringStreakStats(
      longestBirdieStreak: longestBirdieStreak,
      birdieStreaks: birdieStreaks,
      longestBogeyStreak: longestBogeyStreak,
      bogeyStreaks: bogeyStreaks,
      longestParOrBetterStreak: longestParOrBetterStreak,
      parOrBetterStreaks: parOrBetterStreaks,
      scoringRuns: scoringRuns,
      momentumShifts: momentumShifts,
      frontNineStats: frontNine,
      backNineStats: backNine,
    );
  }

  /// Find all streaks matching a condition (2+ consecutive holes)
  List<StreakInfo> _findStreaks(
    List<DGHole> holes,
    bool Function(int relativeScore) condition,
    String streakType,
  ) {
    final List<StreakInfo> streaks = [];
    int? currentStreakStart;
    int currentStreakLength = 0;
    int currentStreakScore = 0;

    for (int i = 0; i < holes.length; i++) {
      final DGHole hole = holes[i];
      final int relative = hole.holeScore - hole.par;

      if (condition(relative)) {
        // Continue or start streak
        if (currentStreakStart == null) {
          currentStreakStart = hole.number;
          currentStreakLength = 1;
          currentStreakScore = relative;
        } else {
          currentStreakLength++;
          currentStreakScore += relative;
        }
      } else {
        // End streak if it was 2+ holes
        if (currentStreakStart != null && currentStreakLength >= 2) {
          streaks.add(StreakInfo(
            startHole: currentStreakStart,
            endHole: currentStreakStart + currentStreakLength - 1,
            length: currentStreakLength,
            streakType: streakType,
            totalRelativeScore: currentStreakScore,
          ));
        }
        // Reset
        currentStreakStart = null;
        currentStreakLength = 0;
        currentStreakScore = 0;
      }
    }

    // Handle streak that extends to end of round
    if (currentStreakStart != null && currentStreakLength >= 2) {
      streaks.add(StreakInfo(
        startHole: currentStreakStart,
        endHole: currentStreakStart + currentStreakLength - 1,
        length: currentStreakLength,
        streakType: streakType,
        totalRelativeScore: currentStreakScore,
      ));
    }

    return streaks;
  }

  /// Identify significant scoring runs (windows with notable cumulative scores)
  List<ScoringRun> _identifyScoringRuns(List<DGHole> holes) {
    final List<ScoringRun> runs = [];

    // Use sliding window approach with 5-hole minimum
    const int minWindowSize = 5;

    // Try different window sizes (5 to total holes)
    for (int windowSize = minWindowSize; windowSize <= holes.length; windowSize++) {
      for (int start = 0; start <= holes.length - windowSize; start++) {
        final int end = start + windowSize - 1;
        int cumulativeScore = 0;

        for (int i = start; i <= end; i++) {
          cumulativeScore += (holes[i].holeScore - holes[i].par);
        }

        // Consider it significant if -3 or better, or +3 or worse
        if (cumulativeScore.abs() >= 3) {
          final int startHole = holes[start].number;
          final int endHole = holes[end].number;

          final String scoreStr = cumulativeScore >= 0 ? '+$cumulativeScore' : '$cumulativeScore';
          final String description = 'Went $scoreStr over holes $startHole-$endHole';

          // Avoid duplicates - only add if this is a better score for overlapping ranges
          final bool shouldAdd = !runs.any((existingRun) {
            final bool overlaps = (startHole <= existingRun.endHole && endHole >= existingRun.startHole);
            final bool worseScore = cumulativeScore.abs() <= existingRun.relativeScore.abs();
            return overlaps && worseScore;
          });

          if (shouldAdd) {
            runs.add(ScoringRun(
              startHole: startHole,
              endHole: endHole,
              relativeScore: cumulativeScore,
              description: description,
            ));
          }
        }
      }
    }

    // Sort by start hole
    runs.sort((a, b) => a.startHole.compareTo(b.startHole));

    // Limit to top 3 most significant runs to avoid clutter
    runs.sort((a, b) => b.relativeScore.abs().compareTo(a.relativeScore.abs()));
    return runs.take(3).toList();
  }

  /// Find momentum shifts (recovery patterns, blow-ups followed by surges)
  List<MomentumShift> _findMomentumShifts(List<DGHole> holes) {
    final List<MomentumShift> shifts = [];

    for (int i = 0; i < holes.length; i++) {
      final DGHole hole = holes[i];
      final int relative = hole.holeScore - hole.par;

      // Pattern 1: Double bogey or worse followed by recovery (2+ birdies in next 4 holes)
      if (relative >= 2 && i < holes.length - 1) {
        int birdiesInNext4 = 0;
        int holesChecked = 0;

        for (int j = i + 1; j < holes.length && holesChecked < 4; j++) {
          final int nextRelative = holes[j].holeScore - holes[j].par;
          if (nextRelative == -1) birdiesInNext4++;
          holesChecked++;
        }

        if (birdiesInNext4 >= 2) {
          final String blowUpLabel = relative == 2 ? 'double bogey' : relative == 3 ? 'triple bogey' : '+$relative';
          shifts.add(MomentumShift(
            holeNumber: hole.number,
            description: 'Recovered from $blowUpLabel with $birdiesInNext4 birdies in the next $holesChecked holes',
            holesInRecovery: holesChecked,
          ));
        }
      }

      // Pattern 2: Long birdie streak (3+) broken by bad hole
      if (relative >= 1 && i >= 3) {
        int birdieStreakBefore = 0;
        for (int j = i - 1; j >= 0 && (holes[j].holeScore - holes[j].par) == -1; j--) {
          birdieStreakBefore++;
        }

        if (birdieStreakBefore >= 3) {
          final String badHoleLabel = relative == 1 ? 'bogey' : relative == 2 ? 'double bogey' : '+$relative';
          shifts.add(MomentumShift(
            holeNumber: hole.number,
            description: '$birdieStreakBefore-birdie streak ended by $badHoleLabel on hole ${hole.number}',
            holesInRecovery: 0,
          ));
        }
      }
    }

    return shifts;
  }

  /// Calculate statistics for a section of the course
  CourseSectionStats? _calculateSectionStats(
    List<DGHole> holes, {
    required String sectionName,
    required int startHole,
    required int endHole,
  }) {
    // Filter holes in this section
    final List<DGHole> sectionHoles = holes.where(
      (h) => h.number >= startHole && h.number <= endHole,
    ).toList();

    if (sectionHoles.isEmpty) return null;

    int totalScore = 0;
    int totalPar = 0;
    int birdies = 0;
    int pars = 0;
    int bogeys = 0;
    int doublesOrWorse = 0;

    for (final hole in sectionHoles) {
      totalScore += hole.holeScore;
      totalPar += hole.par;

      final int relative = hole.holeScore - hole.par;
      if (relative == -1) {
        birdies++;
      } else if (relative == 0) {
        pars++;
      } else if (relative == 1) {
        bogeys++;
      } else if (relative >= 2) {
        doublesOrWorse++;
      }
    }

    return CourseSectionStats(
      sectionName: sectionName,
      startHole: startHole,
      endHole: endHole,
      totalScore: totalScore,
      totalPar: totalPar,
      relativeScore: totalScore - totalPar,
      birdies: birdies,
      pars: pars,
      bogeys: bogeys,
      doublesOrWorse: doublesOrWorse,
    );
  }
}
