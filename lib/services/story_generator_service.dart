import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:yaml/yaml.dart';

/// Service for generating AI-powered narrative stories about disc golf rounds
class StoryGeneratorService {
  final GeminiService _geminiService;

  StoryGeneratorService(this._geminiService);

  /// Generate a narrative story for a round with embedded stat visualizations
  Future<AIContent?> generateRoundStory(DGRound round) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Generate round analysis for stats
        final analysis = RoundAnalysisGenerator.generateAnalysis(round);

        // Build the story generation prompt
        final prompt = _buildStoryPrompt(round, analysis);

        // Generate story using full Gemini model for creative content
        final response = await _geminiService.generateContent(
          prompt: prompt,
          useFullModel: true,
        );

        if (response == null || response.isEmpty) {
          debugPrint('Failed to generate story: empty response');
          retryCount++;
          continue;
        }

        // Check for likely truncated response - complete YAML should be >1200 chars
        // and should contain the 'weaknesses' section (required field)
        if (response.length < 1200 || !response.contains('weaknesses:')) {
          debugPrint('Response appears truncated (${response.length} chars, missing key sections). Retrying...');
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount));
          continue;
        }

        // Parse response into AIContent with segments
        final aiContent = _parseStoryResponse(response, round);

        // If we successfully parsed, return it
        if (aiContent.structuredContent != null) {
          return aiContent;
        }

        // If parsing failed, retry
        debugPrint('Failed to parse story response, retry $retryCount/$maxRetries');
        retryCount++;
      } catch (e, trace) {
        debugPrint('Error generating round story (attempt ${retryCount + 1}/$maxRetries): $e');
        debugPrint(trace.toString());
        retryCount++;

        // If this was the last retry, return null
        if (retryCount >= maxRetries) {
          return null;
        }

        // Wait a bit before retrying
        await Future.delayed(Duration(seconds: retryCount));
      }
    }

    debugPrint('Failed to generate story after $maxRetries attempts');
    return null;
  }

  /// Build the prompt for story generation
  String _buildStoryPrompt(DGRound round, dynamic analysis) {
    final buffer = StringBuffer();

    // Calculate round totals
    final int totalScore = round.holes.fold(0, (sum, hole) => sum + hole.holeScore);
    final int coursePar = round.holes.fold(0, (sum, hole) => sum + hole.par);
    final int scoreRelativeToPar = totalScore - coursePar;
    final String scoreRelativeStr = scoreRelativeToPar > 0
        ? '+$scoreRelativeToPar'
        : '$scoreRelativeToPar';

    // Calculate scoring summary
    final String scoringSummary = _formatScoringSummary(round);

    buffer.writeln('''
You are ScoreSensei - a wise disc golf coach who frames problems as opportunities.
TONE: Be direct about strokes lost, use "you could have" language, celebrate genuine strengths.

# Round: ${round.courseName}
Score: $totalScore ($scoreRelativeStr) | Par: $coursePar | Holes: ${round.holes.length}
$scoringSummary

# Stats
Fairway: ${(analysis.coreStats.fairwayHitPct).toStringAsFixed(1)}% | C1 in Reg: ${(analysis.coreStats.c1InRegPct).toStringAsFixed(1)}% | OB: ${(analysis.coreStats.obPct).toStringAsFixed(1)}% | Parked: ${(analysis.coreStats.parkedPct).toStringAsFixed(1)}%
C1 Putting: ${(analysis.puttingStats.c1Percentage).toStringAsFixed(1)}% (${analysis.puttingStats.c1Makes}/${analysis.puttingStats.c1Attempts}) | C1X: ${(analysis.puttingStats.c1xPercentage).toStringAsFixed(1)}% (${analysis.puttingStats.c1xMakes}/${analysis.puttingStats.c1xAttempts}) | C2: ${(analysis.puttingStats.c2Percentage).toStringAsFixed(1)}% (${analysis.puttingStats.c2Makes}/${analysis.puttingStats.c2Attempts})
Throw Types: ${_formatThrowTypeComparison(analysis)}
Mistakes: ${_formatMistakesBreakdown(round)}

# Hole Type Performance
${_formatHoleTypePerformance(round, analysis)}
# Disc Performance
${_formatDiscPerformance(analysis)}
# Stroke Cost Analysis
${_formatStrokeCostAnalysis(round, analysis)}

# OUTPUT FORMAT (raw YAML only, no markdown)

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
  potentialScore: [best possible if all fixed]
  scenarios:
    - fix: [area], resultScore: [score], strokesSaved: [n]
    - fix: "All of the above", resultScore: [best], strokesSaved: [total]
  encouragement: [1 hopeful sentence]

## OPTIONAL - Include if relevant:
shareableHeadline: [1-2 sentences for social sharing, start with "You"]
practiceAdvice: [2 specific drills]
strategyTips: [2 tips referencing specific holes/discs]

# CARD IDs: FAIRWAY_HIT, C1_IN_REG, OB_RATE, PARKED, C1_PUTTING, C1X_PUTTING, C2_PUTTING, MISTAKES, THROW_TYPE_COMPARISON, HOLE_TYPE:Par 3|4|5

# RULES:
- Each cardId used only ONCE across all sections
- Explanations: 1-2 sentences max, no emotional words
- Outlier rule: 40%+ birdie rate with ONE bad hole = NOT a weakness
''');

    return buffer.toString();
  }

  /// Format scoring summary (replaces verbose hole-by-hole list)
  String _formatScoringSummary(DGRound round) {
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
      result += ' | Best: Hole $bestHole (${bestScore > 0 ? '+' : ''}$bestScore)';
    }
    if (worstScore > 0) {
      result += ' | Worst: Hole $worstHole (+$worstScore)';
    }

    return result;
  }

  /// Format disc performance data for the prompt
  String _formatDiscPerformance(dynamic analysis) {
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
  String _formatHoleTypePerformance(DGRound round, dynamic analysis) {
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
      final List<int> relativeScores =
          holes.map((h) => h.holeScore - h.par).toList();
      relativeScores.sort();

      // Calculate stats
      final double avg =
          relativeScores.reduce((a, b) => a + b) / relativeScores.length;
      final double median = relativeScores[relativeScores.length ~/ 2].toDouble();

      // Detect outliers (scores >= +2 from median AND at least double bogey)
      final List<int> outliers =
          relativeScores.where((s) => s >= median + 2 && s >= 2).toList();

      // Calculate average without outliers
      final List<int> withoutOutliers =
          relativeScores.where((s) => !outliers.contains(s)).toList();
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
  String _formatMistakesBreakdown(DGRound round) {
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
      buffer.writeln(
        '$label: $count (${percentage.toStringAsFixed(0)}%)',
      );
    }

    return buffer.toString();
  }

  /// Format throw type comparison (backhand vs forehand) for the prompt
  String _formatThrowTypeComparison(dynamic analysis) {
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
  String _formatStrokeCostAnalysis(DGRound round, dynamic analysis) {
    final StringBuffer buffer = StringBuffer();
    final List<({String area, int strokes, String detail})> costs = [];

    // C1X putting (11-33ft) - the real differentiator
    // Each miss = 1 stroke lost (simple count, no benchmarks)
    // We use C1X instead of C1 because putts inside 11ft are tap-ins that everyone makes
    final int c1xMisses = analysis.puttingStats.c1xAttempts - analysis.puttingStats.c1xMakes;
    if (c1xMisses > 0) {
      costs.add((
        area: 'C1X Putting',
        strokes: c1xMisses,
        detail: '$c1xMisses missed of ${analysis.puttingStats.c1xAttempts} from 11-33 feet',
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

    buffer.writeln('Current Score: ${currentRelative >= 0 ? '+' : ''}$currentRelative');
    buffer.writeln('Potential Score (if all fixed): ${potentialRelative >= 0 ? '+' : ''}$potentialRelative');
    buffer.writeln('Total Strokes Left on Course: $totalStrokesLost');
    buffer.writeln();

    if (costs.isEmpty) {
      buffer.writeln('No significant stroke costs identified - clean round!');
    } else {
      for (final cost in costs) {
        buffer.writeln('${cost.area}: ~${cost.strokes} strokes (${cost.detail})');
      }
    }

    return buffer.toString();
  }

  /// Parse the AI response into AIContent with segments or structured content
  AIContent _parseStoryResponse(String response, DGRound round) {
    try {
      // Clean the response of common AI formatting issues
      String cleanedResponse = response.trim();

      // Remove markdown code blocks if present
      if (cleanedResponse.startsWith('```yaml') ||
          cleanedResponse.startsWith('```YAML')) {
        cleanedResponse = cleanedResponse.substring(cleanedResponse.indexOf('\n') + 1);
      }

      // Remove just 'yaml' or 'YAML' at the beginning
      if (cleanedResponse.startsWith('yaml\n') ||
          cleanedResponse.startsWith('YAML\n')) {
        cleanedResponse = cleanedResponse.substring(5);
      }

      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      // Try to parse as structured YAML (new format)
      debugPrint('Parsing YAML response...');
      debugPrint('Raw response length: ${cleanedResponse.length}');

      // First try to parse as-is
      dynamic yamlDoc;
      String yamlToParse = cleanedResponse;
      try {
        yamlDoc = loadYaml(cleanedResponse);
        debugPrint('Parsed YAML without repair');
      } catch (parseError) {
        // If parsing fails, try repairing truncated YAML
        debugPrint('Initial parse failed, attempting repair: $parseError');
        yamlToParse = _repairTruncatedYaml(cleanedResponse);
        debugPrint('After repair, length: ${yamlToParse.length}');
        yamlDoc = loadYaml(yamlToParse);
        debugPrint('Parsed YAML after repair');
      }

      // Convert YamlMap to regular Map<String, dynamic>
      final Map<String, dynamic> parsedData = json.decode(json.encode(yamlDoc)) as Map<String, dynamic>;
      debugPrint('Successfully parsed YAML');
      debugPrint('Parsed fields: ${parsedData.keys.toList()}');

      // Validate minimum required fields exist (core fields that define the story)
      // practiceAdvice and strategyTips are optional since AI may hit token limits
      if (parsedData.containsKey('overview') &&
          parsedData.containsKey('strengths') &&
          parsedData.containsKey('weaknesses')) {

        // Add default values for optional/missing fields (handles truncated responses)
        if (!parsedData.containsKey('roundTitle')) {
          parsedData['roundTitle'] = 'Round Summary';
        }
        if (!parsedData.containsKey('practiceAdvice')) {
          debugPrint('practiceAdvice missing, adding empty default');
          parsedData['practiceAdvice'] = <String>[];
        }
        if (!parsedData.containsKey('strategyTips')) {
          debugPrint('strategyTips missing, adding empty default');
          parsedData['strategyTips'] = <String>[];
        }

        // Ensure all required fields are valid
        if (parsedData['overview'] is! String || (parsedData['overview'] as String).isEmpty) {
          throw Exception('Invalid overview field');
        }
        if (parsedData['strengths'] is! List) {
          throw Exception('Invalid strengths field');
        }
        if (parsedData['weaknesses'] is! List) {
          throw Exception('Invalid weaknesses field');
        }
        // practiceAdvice is optional but validate if present
        if (parsedData['practiceAdvice'] is! List) {
          parsedData['practiceAdvice'] = <String>[];
        }
        // strategyTips is optional but validate if present
        if (parsedData['strategyTips'] is! List) {
          parsedData['strategyTips'] = <String>[];
        }

        // Log what we're passing to the model
        debugPrint('mistakes present: ${parsedData.containsKey('mistakes')}');
        debugPrint('practiceAdvice count: ${(parsedData['practiceAdvice'] as List).length}');
        debugPrint('strategyTips count: ${(parsedData['strategyTips'] as List).length}');

        // Parse as StructuredStoryContent
        final structuredContent = StructuredStoryContent.fromJson({
          ...parsedData,
          'roundVersionId': round.versionId,
        });

        return AIContent(
          content: response,
          roundVersionId: round.versionId,
          structuredContent: structuredContent,
        );
      } else {
        throw Exception('Missing required fields in YAML response');
      }
    } catch (e) {
      debugPrint('Failed to parse as structured YAML: $e');
      debugPrint('Response was: $response');
    }

    // Fallback: Parse as old format with {{PLACEHOLDERS}}
    return _parseOldFormat(response, round);
  }

  /// Attempt to repair truncated YAML by removing incomplete trailing content
  String _repairTruncatedYaml(String yaml) {
    final List<String> lines = yaml.split('\n');

    // If the last line appears incomplete (no colon, or ends mid-value), remove it
    while (lines.isNotEmpty) {
      final String lastLine = lines.last.trim();

      // Empty lines are fine
      if (lastLine.isEmpty) {
        lines.removeLast();
        continue;
      }

      // Check if this line looks complete
      // A complete YAML line either:
      // 1. Is a list item starting with "- " followed by content
      // 2. Has a key: value pattern
      // 3. Is just a key with nested content (ends with ":")

      // If the line is a list item, check if it has a complete value
      if (lastLine.startsWith('- ')) {
        final String content = lastLine.substring(2).trim();
        // List items with key-value pairs should have a colon
        if (content.contains(':')) {
          // Check if value after colon is complete (not cut off mid-sentence)
          final int colonIndex = content.indexOf(':');
          final String afterColon = content.substring(colonIndex + 1).trim();
          // If there's content after colon that doesn't end properly, it might be truncated
          if (afterColon.isNotEmpty && !_looksComplete(afterColon)) {
            lines.removeLast();
            continue;
          }
        }
        break; // Line looks OK
      }

      // For regular key: value lines
      if (lastLine.contains(':')) {
        final int colonIndex = lastLine.indexOf(':');
        final String afterColon = lastLine.substring(colonIndex + 1).trim();
        // If there's content after colon, check if it looks complete
        if (afterColon.isNotEmpty && !_looksComplete(afterColon)) {
          lines.removeLast();
          continue;
        }
        break; // Line looks OK
      }

      // Line doesn't have a colon and isn't a continuation - might be truncated
      // Check if it's a valid continuation (indented content)
      if (lastLine.startsWith(' ') || lastLine.startsWith('\t')) {
        // Could be continuation of multi-line string, check if it looks complete
        if (!_looksComplete(lastLine)) {
          lines.removeLast();
          continue;
        }
      }

      break;
    }

    // Also check for incomplete list items in the middle (truncated mid-object)
    // This handles cases like strengths list getting cut off
    String result = lines.join('\n');

    // Remove any trailing incomplete nested objects
    // Look for patterns like "  - headline: X\n    cardId:" with no value
    final RegExp incompleteListItem = RegExp(
      r'(\n\s+-\s+\w+:[^\n]*\n\s+\w+:\s*)$',
      multiLine: true,
    );

    if (incompleteListItem.hasMatch(result)) {
      // Find the start of the incomplete list item and remove it
      final Match? match = incompleteListItem.firstMatch(result);
      if (match != null) {
        result = result.substring(0, match.start);
      }
    }

    return result.trim();
  }

  /// Check if a YAML value looks complete (not truncated mid-sentence)
  bool _looksComplete(String value) {
    // Empty values are complete
    if (value.isEmpty) return true;

    // Quoted strings should have closing quote
    if (value.startsWith('"') && !value.endsWith('"')) return false;
    if (value.startsWith("'") && !value.endsWith("'")) return false;

    // Values ending with common truncation patterns are incomplete
    // e.g., "with a 58" (cut off mid-number or mid-sentence)
    final List<String> truncationPatterns = [
      ' a ', ' an ', ' the ', ' with ', ' to ', ' for ', ' on ', ' in ',
      ' at ', ' of ', ' and ', ' or ', ' but ', ' is ', ' was ', ' are ',
    ];

    for (final String pattern in truncationPatterns) {
      if (value.endsWith(pattern.trim())) return false;
    }

    // Single words that are likely incomplete
    if (value.split(' ').last.length <= 2 && !RegExp(r'^\d+$').hasMatch(value.split(' ').last)) {
      // Short trailing words might indicate truncation, unless they're numbers
      // This is a heuristic and might have false positives
    }

    return true;
  }

  /// Parse old markdown format with {{PLACEHOLDER}} syntax
  AIContent _parseOldFormat(String response, DGRound round) {
    final segments = <AIContentSegment>[];
    final lines = response.split('\n');

    final markdownBuffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();

      // Check if this is a stat card placeholder
      if (trimmed.startsWith('{{') && trimmed.endsWith('}}')) {
        // Save any accumulated markdown first
        if (markdownBuffer.isNotEmpty) {
          segments.add(
            AIContentSegment(
              type: AISegmentType.markdown,
              content: markdownBuffer.toString().trim(),
            ),
          );
          markdownBuffer.clear();
        }

        // Add stat card segment
        final cardId = trimmed.substring(2, trimmed.length - 2);
        segments.add(
          AIContentSegment(type: AISegmentType.statCard, content: cardId),
        );
      } else {
        // Accumulate markdown content
        markdownBuffer.writeln(line);
      }
    }

    // Add any remaining markdown
    if (markdownBuffer.isNotEmpty) {
      segments.add(
        AIContentSegment(
          type: AISegmentType.markdown,
          content: markdownBuffer.toString().trim(),
        ),
      );
    }

    // Create AIContent with segments (old format)
    return AIContent(
      content: response, // Store raw response for fallback
      roundVersionId: round.versionId,
      segments: segments,
    );
  }
}
