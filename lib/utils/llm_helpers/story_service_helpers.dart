import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
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

# Stats
Fairway: ${(analysis.coreStats.fairwayHitPct).toStringAsFixed(1)}% | C1 in Reg: ${(analysis.coreStats.c1InRegPct).toStringAsFixed(1)}% | OB: ${(analysis.coreStats.obPct).toStringAsFixed(1)}% | Parked: ${(analysis.coreStats.parkedPct).toStringAsFixed(1)}%
C1 Putting: ${(analysis.puttingStats.c1Percentage).toStringAsFixed(1)}% (${analysis.puttingStats.c1Makes}/${analysis.puttingStats.c1Attempts}) | C1X: ${(analysis.puttingStats.c1xPercentage).toStringAsFixed(1)}% (${analysis.puttingStats.c1xMakes}/${analysis.puttingStats.c1xAttempts}) | C2: ${(analysis.puttingStats.c2Percentage).toStringAsFixed(1)}% (${analysis.puttingStats.c2Makes}/${analysis.puttingStats.c2Attempts})
Throw Types: ${StoryServiceHelpers.formatThrowTypeComparison(analysis)}
Mistakes: ${StoryServiceHelpers.formatMistakesBreakdown(round)}

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
  encouragement: [1 hopeful sentence]

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
      return 'No significant mistakes recorded';
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Total Mistakes: $totalMistakes');

    for (final mistake in mistakeTypes) {
      final String label = mistake.label;
      final int count = mistake.count;
      final double percentage = mistake.percentage;
      buffer.writeln('$label: $count (${percentage.toStringAsFixed(0)}%)');
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
          '$tech1Name: ${tech1Birdie.toStringAsFixed(1)}% birdie rate ($tech1Count tee shots)',
        );
      }
      if (tech2Count > 0) {
        buffer.writeln(
          '$tech2Name: ${tech2Birdie.toStringAsFixed(1)}% birdie rate ($tech2Count tee shots)',
        );
      }
    }

    if (buffer.isEmpty) {
      return 'No throw type comparison data available';
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
}
