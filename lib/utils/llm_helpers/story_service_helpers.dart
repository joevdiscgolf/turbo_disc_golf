import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';

abstract class StoryServiceHelpers {
  /// Build the prompt for story generation
  static String formatAllRoundData(DGRound round, RoundAnalysis analysis) {
    // Calculate round totals using DGRound methods
    final int totalScore = round.getTotalScore();
    final int coursePar = round.getTotalPar();
    final String scoreRelativeStr = round.getScoreRelativeToParString();

    // Calculate scoring summary
    final String scoringSummary = StoryServiceHelpers.formatScoringSummary(
      round,
    );

    return '''
============================
ROUND DATA START
============================

# Round: ${round.courseName}
Score: $totalScore ($scoreRelativeStr) | Par: $coursePar | Holes: ${round.holes.length}
$scoringSummary

# Hole-by-Hole Breakdown
${round.holes.map((hole) => StoryServiceHelpers._formatHoleDetails(hole)).join('\n')}

# Stats
Fairway: ${(analysis.coreStats.fairwayHitPct).toStringAsFixed(1)}% | C1 in Reg: ${(analysis.coreStats.c1InRegPct).toStringAsFixed(1)}% | OB: ${(analysis.coreStats.obPct).toStringAsFixed(1)}% | Parked: ${(analysis.coreStats.parkedPct).toStringAsFixed(1)}%
C1 Putting: ${(analysis.puttingStats.c1Percentage).toStringAsFixed(1)}% (${analysis.puttingStats.c1Makes}/${analysis.puttingStats.c1Attempts}) | C1X: ${(analysis.puttingStats.c1xPercentage).toStringAsFixed(1)}% (${analysis.puttingStats.c1xMakes}/${analysis.puttingStats.c1xAttempts}) | C2: ${(analysis.puttingStats.c2Percentage).toStringAsFixed(1)}% (${analysis.puttingStats.c2Makes}/${analysis.puttingStats.c2Attempts})

# Scoring Streaks and Momentum (PRE-CALCULATED - USE THESE EXACT COUNTS)
${StoryServiceHelpers.formatScoringStreaks(round, analysis)}
${StoryServiceHelpers.formatChronologicalStoryBeats(round, analysis)}

Throw Types:
${StoryServiceHelpers.formatThrowTypeComparison(analysis)}
Mistakes:
${StoryServiceHelpers.formatMistakesBreakdown(round)}

# Hole Type Performance
${StoryServiceHelpers.formatHoleTypePerformance(round, analysis)}
# Disc Performance
${StoryServiceHelpers.formatDiscPerformance(analysis)}
# Stroke Cost Analysis
${StoryServiceHelpers.formatStrokeCostAnalysis(round, analysis)}

============================
ROUND DATA END
============================
''';
  }

  static String getStoryOutputFormatInstructions({
    required String scoreRelativeStr,
  }) {
    return '''
# OUTPUT FORMAT (MUST BE VALID YAML - NO MARKDOWN, NO CODE BLOCKS)

CRITICAL YAML RULES:
- Use proper multi-line format for lists with multiple properties
- Each property on its own line with proper indentation
- Quote string values that contain special characters
- Numbers should be unquoted
- NO commas in YAML lists (commas are only for inline arrays like [1, 2, 3])

## REQUIRED - Always include these:
roundTitle: [3-5 words, be direct - "Putting Woes Cost Strokes" not "Putting Focus"]
overview: [2 sentences, no stats, just context]
strengths: (max 2 items)
  - headline: [short title]
    cardId: [CARD_ID]
    explanation: [1 sentence with key stat]
    targetTab: driving|putting
weaknesses: (max 2 items)
  - headline: [short title]
    cardId: [CARD_ID]
    explanation: [1 sentence about strokes lost]
    targetTab: driving|putting|mistakes

## IMPORTANT - For the "What Could Have Been" card:
strokeCostBreakdown:
  - area: [from Stroke Cost Analysis]
    strokesLost: [number]
    explanation: [1 sentence why]
whatCouldHaveBeen:
  currentScore: "$scoreRelativeStr"
  potentialScore: "[best score as quoted string, e.g. '-13']"
  scenarios:
    - fix: "[area name]"
      resultScore: "[score as quoted string, e.g. '-11']"
      strokesSaved: [n as unquoted number, e.g. 5]
    - fix: "All of the above"
      resultScore: "[best as quoted string, e.g. '-13']"
      strokesSaved: [total as unquoted number, e.g. 7]
  encouragement: [Required. 1 hopeful sentence grounded in evidence]

## OPTIONAL - Include if relevant:
shareableHeadline: [1-2 sentences for social sharing, start with "You"]
practiceAdvice: [2 specific drills]
strategyTips: [2 tips referencing specific holes/discs]

# CARD IDs: FAIRWAY_HIT, C1_IN_REG, OB_RATE, PARKED, C1_PUTTING, C1X_PUTTING, C2_PUTTING, MISTAKES, THROW_TYPE_COMPARISON, HOLE_TYPE:Par 3|4|5

# RULES:
- Each cardId used only ONCE across all sections
- Explanations: 1–2 sentences max, factual and direct. 
- Use plain language to describe impact, not emotion.
- Outlier rule: 40%+ birdie rate with ONE bad hole = NOT a weakness

# VALID YAML EXAMPLE (follow this exact format):
roundTitle: "Putting Woes Cost Strokes"
overview: "You had a solid round with good driving, but missed putts and penalties added strokes."
strengths:
  - headline: "Strong Fairway Accuracy"
    cardId: FAIRWAY_HIT
    explanation: "You hit 88.9% of fairways, setting up good scoring chances."
    targetTab: driving
weaknesses:
  - headline: "C1X Putting Struggles"
    cardId: C1X_PUTTING
    explanation: "Missing 5 putts cost you around 5 strokes."
    targetTab: putting
strokeCostBreakdown:
  - area: "C1X Putting"
    strokesLost: 5
    explanation: "Missing these putts prevented scoring opportunities."
whatCouldHaveBeen:
  currentScore: "$scoreRelativeStr"
  potentialScore: "-13"
  scenarios:
    - fix: "C1X Putting"
      resultScore: "-11"
      strokesSaved: 5
    - fix: "All of the above"
      resultScore: "-13"
      strokesSaved: 7
  encouragement: "You have the skills to make these adjustments next time!"
practiceAdvice:
  - "Focus on C1X putting drills from 11-33 feet."
  - "Practice target zones for OB recovery."
strategyTips:
  - "On hole 4, aim for a conservative throw to avoid OB."
  - "Use your forehand on hole 7 to improve fairway hits."
''';
  }

  /// Format scoring summary (replaces verbose hole-by-hole list)
  static String formatScoringSummary(DGRound round) {
    int eagles = 0, birdies = 0, pars = 0, bogeys = 0, doubles = 0;
    int? bestHole, worstHole;
    int bestScore = 0, worstScore = 0;

    for (final hole in round.holes) {
      final int relative = hole.holeScore - hole.par;
      if (relative <= -2) {
        eagles++;
      } else if (relative == -1) {
        birdies++;
      } else if (relative == 0) {
        pars++;
      } else if (relative == 1) {
        bogeys++;
      } else {
        doubles++;
      }

      if (bestHole == null || relative < bestScore) {
        bestHole = hole.number;
        bestScore = relative;
      }
      if (worstHole == null || relative > worstScore) {
        worstHole = hole.number;
        worstScore = relative;
      }
    }

    final List<String> parts = [];
    if (eagles > 0) parts.add('$eagles eagle${eagles > 1 ? 's' : ''}');
    if (birdies > 0) parts.add('$birdies birdie${birdies > 1 ? 's' : ''}');
    if (pars > 0) parts.add('$pars par${pars > 1 ? 's' : ''}');
    if (bogeys > 0) parts.add('$bogeys bogey${bogeys > 1 ? 's' : ''}');
    if (doubles > 0) parts.add('$doubles double+');

    String result = 'Scoring: ${parts.join(', ')}';
    if (bestScore < 0) {
      result +=
          ' | Best: Hole $bestHole (${bestScore > 0 ? '+' : ''}$bestScore)';
    }
    if (worstScore > 0) {
      result += ' | Worst: Hole $worstHole (+$worstScore)';
    }

    return result;
  }

  /// Format disc performance data for the prompt
  static String formatDiscPerformance(dynamic analysis) {
    final StringBuffer buffer = StringBuffer();
    final List discPerfs = analysis.discPerformances as List;

    // Take top 5 discs by throw count
    final List sortedDiscs = List.from(discPerfs);
    sortedDiscs.sort((a, b) => b.totalShots.compareTo(a.totalShots));

    for (final disc in sortedDiscs.take(5)) {
      final String discName = disc.discName;
      final double birdieRate =
          (analysis.discBirdieRates[discName] ?? 0.0) as double;
      final double avgScore =
          (analysis.discAverageScores[discName] ?? 0.0) as double;
      final int throwCount = disc.totalShots;

      buffer.writeln(
        '$discName: ${birdieRate.toStringAsFixed(1)}% birdie rate, '
        '$throwCount throws, ${avgScore >= 0 ? '+' : ''}${avgScore.toStringAsFixed(2)} avg score',
      );
    }

    return buffer.toString();
  }

  /// Format hole type performance data with outlier detection for the prompt
  static String formatHoleTypePerformance(DGRound round, dynamic analysis) {
    final Map<int, List<DGHole>> holesByPar = {};

    for (final DGHole hole in round.holes) {
      holesByPar.putIfAbsent(hole.par, () => []).add(hole);
    }

    final StringBuffer buffer = StringBuffer();

    // Sort by par (3, 4, 5)
    final List<int> sortedPars = holesByPar.keys.toList()..sort();

    for (final int par in sortedPars) {
      final List<DGHole> holes = holesByPar[par]!;

      // Calculate individual relative scores
      final List<int> relativeScores = holes
          .map((h) => h.holeScore - h.par)
          .toList();
      relativeScores.sort();

      // Calculate stats
      final double avg =
          relativeScores.reduce((a, b) => a + b) / relativeScores.length;
      final double median = relativeScores[relativeScores.length ~/ 2]
          .toDouble();

      // Detect outliers (scores >= +2 from median AND at least double bogey)
      final List<int> outliers = relativeScores
          .where((s) => s >= median + 2 && s >= 2)
          .toList();

      // Calculate average without outliers
      final List<int> withoutOutliers = relativeScores
          .where((s) => !outliers.contains(s))
          .toList();
      final double avgWithoutOutliers = withoutOutliers.isEmpty
          ? avg
          : withoutOutliers.reduce((a, b) => a + b) / withoutOutliers.length;

      final double birdieRate =
          (analysis.birdieRateByPar[par] ?? 0.0) as double;

      buffer.writeln('Par $par (${holes.length} holes):');
      buffer.writeln(
        '  Scores: ${relativeScores.map((s) => s >= 0 ? "+$s" : "$s").join(", ")}',
      );
      buffer.writeln(
        '  Avg: ${avg >= 0 ? "+" : ""}${avg.toStringAsFixed(2)}, Birdie rate: ${birdieRate.toStringAsFixed(0)}%',
      );

      if (outliers.isNotEmpty) {
        buffer.writeln(
          '  OUTLIER DETECTED: ${outliers.length} hole(s) with +${outliers.first} or worse',
        );
        buffer.writeln(
          '  Avg WITHOUT outlier: ${avgWithoutOutliers >= 0 ? "+" : ""}${avgWithoutOutliers.toStringAsFixed(2)}',
        );
        if (birdieRate >= 40 && avgWithoutOutliers <= 0) {
          buffer.writeln(
            '  → This is GOOD performance with one bad hole, NOT a weakness',
          );
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Format mistakes breakdown for the prompt
  static String formatMistakesBreakdown(DGRound round) {
    final MistakesAnalysisService mistakesService = MistakesAnalysisService();
    final List mistakeTypes = mistakesService.getMistakeTypes(round);
    final int totalMistakes = mistakesService.getTotalMistakesCount(round);

    if (totalMistakes == 0) {
      return '  No significant mistakes recorded';
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('  Total: $totalMistakes');

    for (final mistake in mistakeTypes) {
      final String label = mistake.label;
      final int count = mistake.count;
      final double percentage = mistake.percentage;
      buffer.writeln('  $label: $count (${percentage.toStringAsFixed(0)}%)');
    }

    return buffer.toString();
  }

  /// Format throw type comparison (backhand vs forehand) for the prompt
  static String formatThrowTypeComparison(dynamic analysis) {
    final StringBuffer buffer = StringBuffer();

    // Get tee shot comparison from analysis
    final teeComparison = analysis.teeComparison;
    if (teeComparison != null) {
      final String tech1Name = teeComparison.technique1 ?? 'Backhand';
      final String tech2Name = teeComparison.technique2 ?? 'Forehand';
      final double tech1Birdie = teeComparison.technique1BirdieRate ?? 0.0;
      final double tech2Birdie = teeComparison.technique2BirdieRate ?? 0.0;
      final int tech1Count = teeComparison.technique1Count ?? 0;
      final int tech2Count = teeComparison.technique2Count ?? 0;

      if (tech1Count > 0) {
        buffer.writeln(
          '  $tech1Name: ${tech1Birdie.toStringAsFixed(1)}% birdie rate ($tech1Count tee shots)',
        );
      }
      if (tech2Count > 0) {
        buffer.writeln(
          '  $tech2Name: ${tech2Birdie.toStringAsFixed(1)}% birdie rate ($tech2Count tee shots)',
        );
      }
    }

    if (buffer.isEmpty) {
      return '  No throw type comparison data available';
    }

    return buffer.toString();
  }

  /// Calculate stroke cost analysis for the prompt
  /// Uses mutually exclusive categories: C1X putting misses and OB penalties
  static String formatStrokeCostAnalysis(DGRound round, dynamic analysis) {
    final StringBuffer buffer = StringBuffer();
    final List<({String area, int strokes, String detail})> costs = [];

    // C1X putting (11-33ft) - the real differentiator
    // Each miss = 1 stroke lost (simple count, no benchmarks)
    // We use C1X instead of C1 because putts inside 11ft are tap-ins that everyone makes
    final int c1xMisses =
        analysis.puttingStats.c1xAttempts - analysis.puttingStats.c1xMakes;
    if (c1xMisses > 0) {
      costs.add((
        area: 'C1X Putting',
        strokes: c1xMisses,
        detail:
            '$c1xMisses missed of ${analysis.puttingStats.c1xAttempts} from 11-33 feet',
      ));
    }

    // Count OB penalties (always independent, doesn't overlap with putting)
    int obStrokes = 0;
    final List<int> obHoles = [];
    for (final hole in round.holes) {
      for (final throw_ in hole.throws) {
        if (throw_.penaltyStrokes > 0) {
          obStrokes += throw_.penaltyStrokes;
          if (!obHoles.contains(hole.number)) {
            obHoles.add(hole.number);
          }
        }
      }
    }
    if (obStrokes > 0) {
      final String holesStr = obHoles.length <= 3
          ? 'holes ${obHoles.join(', ')}'
          : '${obHoles.length} holes';
      costs.add((
        area: 'OB Penalties',
        strokes: obStrokes,
        detail: '$obStrokes penalty strokes on $holesStr',
      ));
    }

    // NOTE: We intentionally don't count:
    // - C1 (0-33ft) separately - C1X is already counted, and tap-ins <11ft are gimmes
    // - 3-putts - already reflected in C1X misses (the miss that caused the 3-putt)
    // - C2 (33-66ft) - you're not expected to make these, so missing isn't "losing" strokes

    // Sort by strokes lost (highest first)
    costs.sort((a, b) => b.strokes.compareTo(a.strokes));

    // Calculate total and potential score
    final int totalScore = round.holes.fold(0, (sum, h) => sum + h.holeScore);
    final int coursePar = round.holes.fold(0, (sum, h) => sum + h.par);
    final int currentRelative = totalScore - coursePar;
    final int totalStrokesLost = costs.fold(0, (sum, c) => sum + c.strokes);
    final int potentialRelative = currentRelative - totalStrokesLost;

    buffer.writeln(
      'Current Score: ${currentRelative >= 0 ? '+' : ''}$currentRelative',
    );
    buffer.writeln(
      'Potential Score (if all fixed): ${potentialRelative >= 0 ? '+' : ''}$potentialRelative',
    );
    buffer.writeln('Total Strokes Left on Course: $totalStrokesLost');
    buffer.writeln();

    if (costs.isEmpty) {
      buffer.writeln('No significant stroke costs identified - clean round!');
    } else {
      for (final cost in costs) {
        buffer.writeln(
          '${cost.area}: ~${cost.strokes} strokes (${cost.detail})',
        );
      }
    }

    return buffer.toString();
  }

  /// Calculate performance stats for a specific hole range (streak)
  /// Used to provide per-streak stats to help explain WHY streaks happened
  static Map<String, dynamic> _calculateStreakStats({
    required List<DGHole> holes,
    required int startHole,
    required int endHole,
    required RoundAnalysis analysis,
  }) {
    // Get holes in the streak range
    final List<DGHole> streakHoles = holes
        .where((h) => h.number >= startHole && h.number <= endHole)
        .toList();

    if (streakHoles.isEmpty) {
      return {};
    }

    // Calculate putting stats
    int c1Makes = 0, c1Attempts = 0;
    int c1xMakes = 0, c1xAttempts = 0;
    int c2Makes = 0, c2Attempts = 0;
    int overallMakes = 0, overallAttempts = 0;

    // Calculate approach stats
    int c1InReg = 0, c1InRegOpportunities = 0;
    int fairwayHits = 0, fairwayOpportunities = 0;
    int parked = 0;

    // Calculate throw type stats
    int backhandThrows = 0, backhandClean = 0;
    int forehandThrows = 0, forehandClean = 0;

    // Calculate mistakes
    int obCount = 0;
    int penaltyStrokes = 0;

    for (final hole in streakHoles) {
      // Count opportunities
      c1InRegOpportunities++;
      fairwayOpportunities++;

      // Check if C1 in regulation (looking at second-to-last throw distance)
      if (hole.throws.length >= 2) {
        final approachThrow = hole.throws[hole.throws.length - 2];
        if (approachThrow.distanceFeetAfterThrow != null &&
            approachThrow.distanceFeetAfterThrow! <= 33.0) {
          c1InReg++;
        }
        // Check if parked (<= 11 ft)
        if (approachThrow.distanceFeetAfterThrow != null &&
            approachThrow.distanceFeetAfterThrow! <= 11.0) {
          parked++;
        }
      }

      // Process all throws for this hole
      for (int i = 0; i < hole.throws.length; i++) {
        final throw_ = hole.throws[i];
        final bool isTee = (i == 0);
        final bool isPutt = (i == hole.throws.length - 1);

        // Fairway hits (tee shots only)
        if (isTee) {
          if (throw_.landingSpot?.toString().contains('fairway') ?? false) {
            fairwayHits++;
          }
        }

        // Putting stats (last throw of the hole)
        if (isPutt && throw_.distanceFeetBeforeThrow != null) {
          final double distance = throw_.distanceFeetBeforeThrow!.toDouble();
          final bool made = (throw_.distanceFeetAfterThrow == 0.0);

          // Overall putting
          overallAttempts++;
          if (made) overallMakes++;

          // C1 putting (0-33 ft)
          if (distance <= 33.0) {
            c1Attempts++;
            if (made) c1Makes++;

            // C1X putting (11-33 ft)
            if (distance >= 11.0) {
              c1xAttempts++;
              if (made) c1xMakes++;
            }
          }
          // C2 putting (33-66 ft)
          else if (distance <= 66.0) {
            c2Attempts++;
            if (made) c2Makes++;
          }
        }

        // Throw type analysis
        final String? technique = throw_.technique?.toString();
        final bool isClean =
            throw_.penaltyStrokes == 0 &&
            !(throw_.landingSpot?.toString().contains('outOfBounds') ?? false);

        if (technique?.contains('backhand') ?? false) {
          backhandThrows++;
          if (isClean) backhandClean++;
        } else if (technique?.contains('forehand') ?? false) {
          forehandThrows++;
          if (isClean) forehandClean++;
        }

        // Count OB and penalties
        if (throw_.penaltyStrokes > 0) {
          obCount++;
          penaltyStrokes += throw_.penaltyStrokes;
        }
      }
    }

    // Build performance object
    final Map<String, dynamic> performance = {};

    // Putting performance
    final Map<String, String> puttingPerf = {};
    if (c1Attempts > 0) {
      final double c1Pct = (c1Makes / c1Attempts) * 100;
      puttingPerf['c1'] = '$c1Makes/$c1Attempts (${c1Pct.toStringAsFixed(0)}%)';
    }
    if (c1xAttempts > 0) {
      final double c1xPct = (c1xMakes / c1xAttempts) * 100;
      puttingPerf['c1x'] =
          '$c1xMakes/$c1xAttempts (${c1xPct.toStringAsFixed(0)}%)';
    }
    if (c2Attempts > 0) {
      final double c2Pct = (c2Makes / c2Attempts) * 100;
      puttingPerf['c2'] = '$c2Makes/$c2Attempts (${c2Pct.toStringAsFixed(0)}%)';
    }
    if (overallAttempts > 0) {
      final double overallPct = (overallMakes / overallAttempts) * 100;
      puttingPerf['overall'] =
          '$overallMakes/$overallAttempts (${overallPct.toStringAsFixed(0)}%)';
    }
    if (puttingPerf.isNotEmpty) {
      performance['putting'] = puttingPerf;
    }

    // Approach performance
    final Map<String, String> approachPerf = {};
    if (c1InRegOpportunities > 0) {
      final double c1InRegPct = (c1InReg / c1InRegOpportunities) * 100;
      approachPerf['c1InReg'] =
          '$c1InReg/$c1InRegOpportunities (${c1InRegPct.toStringAsFixed(0)}%)';
    }
    if (fairwayOpportunities > 0) {
      final double fairwayPct = (fairwayHits / fairwayOpportunities) * 100;
      approachPerf['fairwayHit'] =
          '$fairwayHits/$fairwayOpportunities (${fairwayPct.toStringAsFixed(0)}%)';
    }
    if (parked > 0) {
      approachPerf['parked'] =
          '$parked/${streakHoles.length} (${(parked / streakHoles.length * 100).toStringAsFixed(0)}%)';
    }
    if (approachPerf.isNotEmpty) {
      performance['approach'] = approachPerf;
    }

    // Throw type analysis
    final Map<String, String> throwTypes = {};
    if (backhandThrows > 0) {
      final double backhandCleanPct = (backhandClean / backhandThrows) * 100;
      throwTypes['backhand'] =
          '$backhandThrows throws (${backhandCleanPct.toStringAsFixed(0)}% clean)';
    }
    if (forehandThrows > 0) {
      final double forehandCleanPct = (forehandClean / forehandThrows) * 100;
      throwTypes['forehand'] =
          '$forehandThrows throws (${forehandCleanPct.toStringAsFixed(0)}% clean)';
    }
    if (backhandThrows > 0 || forehandThrows > 0) {
      throwTypes['preference'] = backhandThrows > forehandThrows
          ? 'backhand'
          : 'forehand';
      performance['throwTypes'] = throwTypes;
    }

    // Mistakes
    if (obCount > 0 || penaltyStrokes > 0) {
      performance['mistakes'] = {
        'obCount': obCount,
        'penaltyStrokes': penaltyStrokes,
      };
    }

    return performance;
  }

  /// Format scoring streaks for the prompt with per-streak performance stats
  static String formatScoringStreaks(DGRound round, RoundAnalysis analysis) {
    final StringBuffer buffer = StringBuffer();
    final streakStats = analysis.streakStats;

    // Handle legacy rounds without streak stats
    if (streakStats == null) {
      buffer.writeln('(Streak stats not available for this round)');
      return buffer.toString();
    }

    // Front 9 vs Back 9 breakdown with performance stats
    if (streakStats.frontNineStats != null ||
        streakStats.backNineStats != null) {
      buffer.writeln('Course Section Performance:');
      if (streakStats.frontNineStats != null) {
        final front = streakStats.frontNineStats!;
        buffer.writeln(
          '  ${front.sectionName}: ${front.scoreRelativeDisplay} '
          '(${front.birdies} birdies, ${front.pars} pars, '
          '${front.bogeys} bogeys, ${front.doublesOrWorse} doubles+)',
        );
        // Add performance stats for Front 9
        final frontPerf = _calculateStreakStats(
          holes: round.holes,
          startHole: front.startHole,
          endHole: front.endHole,
          analysis: analysis,
        );
        _appendPerformanceStats(buffer, frontPerf);
      }
      if (streakStats.backNineStats != null) {
        final back = streakStats.backNineStats!;
        buffer.writeln(
          '  ${back.sectionName}: ${back.scoreRelativeDisplay} '
          '(${back.birdies} birdies, ${back.pars} pars, '
          '${back.bogeys} bogeys, ${back.doublesOrWorse} doubles+)',
        );
        // Add performance stats for Back 9
        final backPerf = _calculateStreakStats(
          holes: round.holes,
          startHole: back.startHole,
          endHole: back.endHole,
          analysis: analysis,
        );
        _appendPerformanceStats(buffer, backPerf);
      }
      buffer.writeln();
    }

    // Birdie streaks with performance stats
    if (streakStats.birdieStreaks.isNotEmpty) {
      buffer.writeln('Birdie Streaks (with performance stats):');
      for (final streak in streakStats.birdieStreaks) {
        buffer.writeln(
          '  ${streak.holeRangeDisplay}: ${streak.length} consecutive birdies (${streak.totalRelativeScore})',
        );
        // Calculate and add performance stats for this streak
        final performance = _calculateStreakStats(
          holes: round.holes,
          startHole: streak.startHole,
          endHole: streak.endHole,
          analysis: analysis,
        );
        _appendPerformanceStats(buffer, performance, indent: '    ');
      }
      buffer.writeln('  Longest: ${streakStats.longestBirdieStreak} holes');
      buffer.writeln();
    }

    // Bogey-or-worse streaks with performance stats
    if (streakStats.bogeyStreaks.isNotEmpty) {
      buffer.writeln('Bogey/Worse Streaks (with performance stats):');
      for (final streak in streakStats.bogeyStreaks) {
        buffer.writeln(
          '  ${streak.holeRangeDisplay}: ${streak.length} consecutive bogeys or worse (+${-streak.totalRelativeScore})',
        );
        // Calculate and add performance stats for this streak
        final performance = _calculateStreakStats(
          holes: round.holes,
          startHole: streak.startHole,
          endHole: streak.endHole,
          analysis: analysis,
        );
        _appendPerformanceStats(buffer, performance, indent: '    ');
      }
      buffer.writeln('  Longest: ${streakStats.longestBogeyStreak} holes');
      buffer.writeln();
    }

    // Scoring runs
    if (streakStats.scoringRuns.isNotEmpty) {
      buffer.writeln('Significant Scoring Runs:');
      for (final run in streakStats.scoringRuns) {
        buffer.writeln('  ${run.description}');
        // Calculate and add performance stats for scoring runs
        final performance = _calculateStreakStats(
          holes: round.holes,
          startHole: run.startHole,
          endHole: run.endHole,
          analysis: analysis,
        );
        _appendPerformanceStats(buffer, performance, indent: '    ');
      }
      buffer.writeln();
    }

    // Momentum shifts
    if (streakStats.momentumShifts.isNotEmpty) {
      buffer.writeln('Momentum Shifts:');
      for (final shift in streakStats.momentumShifts) {
        buffer.writeln('  Hole ${shift.holeNumber}: ${shift.description}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Helper to append performance stats to the buffer
  static void _appendPerformanceStats(
    StringBuffer buffer,
    Map<String, dynamic> performance, {
    String indent = '    ',
  }) {
    if (performance.isEmpty) return;

    // Putting stats
    if (performance.containsKey('putting')) {
      final putting = performance['putting'] as Map<String, String>;
      if (putting.isNotEmpty) {
        buffer.writeln('${indent}Putting:');
        if (putting.containsKey('c1')) {
          buffer.writeln('$indent  C1: ${putting['c1']}');
        }
        if (putting.containsKey('c1x')) {
          buffer.writeln('$indent  C1X: ${putting['c1x']}');
        }
        if (putting.containsKey('c2')) {
          buffer.writeln('$indent  C2: ${putting['c2']}');
        }
        if (putting.containsKey('overall')) {
          buffer.writeln('$indent  Overall: ${putting['overall']}');
        }
      }
    }

    // Approach stats
    if (performance.containsKey('approach')) {
      final approach = performance['approach'] as Map<String, String>;
      if (approach.isNotEmpty) {
        buffer.writeln('${indent}Approach:');
        if (approach.containsKey('c1InReg')) {
          buffer.writeln('$indent  C1 in Reg: ${approach['c1InReg']}');
        }
        if (approach.containsKey('fairwayHit')) {
          buffer.writeln('$indent  Fairway Hit: ${approach['fairwayHit']}');
        }
        if (approach.containsKey('parked')) {
          buffer.writeln('$indent  Parked: ${approach['parked']}');
        }
      }
    }

    // Throw types
    if (performance.containsKey('throwTypes')) {
      final throwTypes = performance['throwTypes'] as Map<String, String>;
      if (throwTypes.isNotEmpty) {
        buffer.writeln('${indent}Throw Types:');
        if (throwTypes.containsKey('backhand')) {
          buffer.writeln('$indent  Backhand: ${throwTypes['backhand']}');
        }
        if (throwTypes.containsKey('forehand')) {
          buffer.writeln('$indent  Forehand: ${throwTypes['forehand']}');
        }
        if (throwTypes.containsKey('preference')) {
          buffer.writeln('$indent  Preference: ${throwTypes['preference']}');
        }
      }
    }

    // Mistakes
    if (performance.containsKey('mistakes')) {
      final mistakes = performance['mistakes'] as Map<String, int>;
      buffer.writeln('${indent}Mistakes:');
      buffer.writeln('$indent  OB Count: ${mistakes['obCount']}');
      buffer.writeln('$indent  Penalty Strokes: ${mistakes['penaltyStrokes']}');
    }
  }

  /// Generate chronological story beats for narrative flow
  static String formatChronologicalStoryBeats(
    DGRound round,
    RoundAnalysis analysis,
  ) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('# Chronological Round Narrative');
    buffer.writeln('(Present story elements in this order):');
    buffer.writeln();

    final streakStats = analysis.streakStats;

    // Handle legacy rounds without streak stats
    if (streakStats == null) {
      buffer.writeln('(Chronological timeline not available for this round)');
      return buffer.toString();
    }

    // Create timeline of significant events
    final List<({int hole, String event, String type})> timeline = [];

    // Add streaks to timeline
    for (final streak in streakStats.birdieStreaks) {
      timeline.add((
        hole: streak.startHole,
        event:
            'Birdie streak: ${streak.length} birdies from ${streak.holeRangeDisplay} (${streak.totalRelativeScore})',
        type: 'strength',
      ));
    }

    for (final streak in streakStats.bogeyStreaks) {
      timeline.add((
        hole: streak.startHole,
        event:
            'Struggle: ${streak.length} bogeys or worse from ${streak.holeRangeDisplay} (+${-streak.totalRelativeScore})',
        type: 'weakness',
      ));
    }

    // Add momentum shifts
    for (final shift in streakStats.momentumShifts) {
      timeline.add((
        hole: shift.holeNumber,
        event: shift.description,
        type: 'momentum',
      ));
    }

    // Add scoring runs
    for (final run in streakStats.scoringRuns) {
      timeline.add((
        hole: run.startHole,
        event: run.description,
        type: run.relativeScore < 0 ? 'strength' : 'weakness',
      ));
    }

    // Sort by hole number (chronological)
    timeline.sort((a, b) => a.hole.compareTo(b.hole));

    // Output in chronological order
    for (final event in timeline) {
      buffer.writeln(
        'Hole ${event.hole}: [${event.type.toUpperCase()}] ${event.event}',
      );
    }

    buffer.writeln();
    buffer.writeln(
      'NOTE: Present these events in this exact order when constructing your narrative.',
    );

    return buffer.toString();
  }

  /// Format a complete hole section with header and all throws
  static String _formatHoleDetails(DGHole hole) {
    final StringBuffer buffer = StringBuffer();

    // Hole header
    buffer.writeln('## HOLE ${hole.number}');
    buffer.write('Par: ${hole.par} | Distance: ${hole.feet} ft | ');
    buffer.write('Score: ${hole.holeScore} ');

    final int relative = hole.relativeHoleScore;
    if (relative == 0) {
      buffer.writeln('(Even)');
    } else if (relative > 0) {
      buffer.writeln('(+$relative)');
    } else {
      buffer.writeln('($relative)');
    }

    if (hole.holeType != null) {
      buffer.writeln('Type: ${_formatEnumValue(hole.holeType)}');
    }

    // Throws section
    buffer.writeln('\nThrows (${hole.throws.length} total):');
    for (int i = 0; i < hole.throws.length; i++) {
      final DiscThrow throw_ = hole.throws[i];
      final bool isTee = (i == 0);
      buffer.writeln(_formatThrowDetails(throw_, i + 1, isTee));
    }

    return buffer.toString();
  }

  /// Format a single throw with only non-null properties
  static String _formatThrowDetails(
    DiscThrow throw_,
    int throwNumber,
    bool isTee,
  ) {
    final StringBuffer buffer = StringBuffer();

    // Throw header
    String throwLabel = 'Throw $throwNumber';
    if (isTee) {
      throwLabel += ' (Tee)';
    } else if (throw_.purpose != null) {
      throwLabel += ' (${_formatEnumValue(throw_.purpose)})';
    }
    buffer.writeln('  $throwLabel:');

    // Build list of properties (only non-null)
    final List<String> details = [];

    // Core throw info
    if (throw_.technique != null) {
      details.add('Technique: ${_formatEnumValue(throw_.technique)}');
    }

    if (throw_.shotShape != null) {
      details.add('Shape: ${_formatEnumValue(throw_.shotShape)}');
    }

    if (throw_.power != null) {
      details.add('Power: ${_formatEnumValue(throw_.power)}');
    }

    if (throw_.stance != null) {
      details.add('Stance: ${_formatEnumValue(throw_.stance)}');
    }

    if (throw_.puttStyle != null) {
      details.add('Putt Style: ${_formatEnumValue(throw_.puttStyle)}');
    }

    // Distance info
    if (throw_.distanceFeetBeforeThrow != null ||
        throw_.distanceFeetAfterThrow != null) {
      String distStr = 'Distance:';
      if (throw_.distanceFeetBeforeThrow != null) {
        distStr += ' ${throw_.distanceFeetBeforeThrow} ft before';
      }
      if (throw_.distanceFeetAfterThrow != null) {
        distStr += ' → ${throw_.distanceFeetAfterThrow} ft after';
      }
      details.add(distStr);
    }

    if (throw_.elevationChangeFeet != null) {
      details.add(
        'Elevation change: ${throw_.elevationChangeFeet!.toStringAsFixed(1)} ft',
      );
    }

    // Landing and result
    if (throw_.landingSpot != null) {
      details.add('Landing: ${_formatEnumValue(throw_.landingSpot)}');
    }

    if (throw_.resultRating != null) {
      details.add('Result: ${_formatEnumValue(throw_.resultRating)}');
    }

    if (throw_.penaltyStrokes > 0) {
      details.add(
        'Penalty: +${throw_.penaltyStrokes} stroke${throw_.penaltyStrokes > 1 ? 's' : ''}',
      );
    }

    // Disc info
    if (throw_.discName != null && throw_.discName!.isNotEmpty) {
      String discStr = 'Disc: ${throw_.discName}';
      if (throw_.disc != null) {
        final DGDisc disc = throw_.disc!;
        if (disc.speed != null ||
            disc.glide != null ||
            disc.turn != null ||
            disc.fade != null) {
          discStr += ' (';
          final List<String> flightNumbers = [];
          if (disc.speed != null) flightNumbers.add('${disc.speed}');
          if (disc.glide != null) flightNumbers.add('${disc.glide}');
          if (disc.turn != null) flightNumbers.add('${disc.turn}');
          if (disc.fade != null) flightNumbers.add('${disc.fade}');
          discStr += flightNumbers.join('|');
          discStr += ')';
        }
      }
      details.add(discStr);
    }

    // Environmental conditions
    if (throw_.windDirection != null || throw_.windStrength != null) {
      String windStr = 'Wind:';
      if (throw_.windDirection != null) {
        windStr += ' ${_formatEnumValue(throw_.windDirection)}';
      }
      if (throw_.windStrength != null) {
        windStr += ' (${_formatEnumValue(throw_.windStrength)})';
      }
      details.add(windStr);
    }

    if (throw_.fairwayWidth != null) {
      details.add('Fairway: ${_formatEnumValue(throw_.fairwayWidth)}');
    }

    // Notes and metadata
    if (throw_.notes != null && throw_.notes!.isNotEmpty) {
      details.add('Notes: ${throw_.notes}');
    }

    if (throw_.rawText != null && throw_.rawText!.isNotEmpty) {
      details.add('Raw: "${throw_.rawText}"');
    }

    if (throw_.parseConfidence != null) {
      final String confidence = (throw_.parseConfidence! * 100).toStringAsFixed(
        0,
      );
      details.add('Confidence: $confidence%');
    }

    // Output all details
    for (final String detail in details) {
      buffer.writeln('    - $detail');
    }

    return buffer.toString();
  }

  /// Convert enum values to human-readable strings
  static String _formatEnumValue(dynamic enumValue) {
    if (enumValue == null) return '';

    // Get the enum name (e.g., "teeDrive" from "ThrowPurpose.teeDrive")
    final String enumStr = enumValue.toString().split('.').last;

    // Convert camelCase to Title Case with spaces
    // teeDrive → Tee Drive
    // backhandRoller → Backhand Roller
    final RegExp regex = RegExp(r'([a-z])([A-Z])');
    final String spaced = enumStr.replaceAllMapped(
      regex,
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // Capitalize first letter
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}
