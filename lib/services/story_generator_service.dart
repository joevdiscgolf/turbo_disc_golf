import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
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
    final int totalScore = round.holes.fold(
      0,
      (sum, hole) => sum + hole.holeScore,
    );
    final int coursePar = round.holes.fold(0, (sum, hole) => sum + hole.par);
    final int scoreRelativeToPar = totalScore - coursePar;
    final String scoreRelativeStr = scoreRelativeToPar > 0
        ? '+$scoreRelativeToPar'
        : '$scoreRelativeToPar';
    final String date = round.playedRoundAt;

    buffer.writeln('''
You are a knowledgeable disc golf coach analyzing a player's round.
Your task is to provide a structured breakdown in YAML format with specific sections.

# Round Information
Course: ${round.courseName}
Date: $date
Score: $totalScore ($scoreRelativeStr)
Par: $coursePar
Holes Played: ${round.holes.length}

# Scoring Breakdown
''');

    // Add hole-by-hole scores
    for (final hole in round.holes) {
      final int score = hole.holeScore;
      final int par = hole.par;
      final int relative = score - par;
      final String relativeStr = relative > 0 ? '+$relative' : '$relative';
      buffer.writeln('Hole ${hole.number}: $score ($relativeStr) - Par $par');
    }

    buffer.writeln('''

# Stats
Fairway: ${(analysis.coreStats.fairwayHitPct).toStringAsFixed(1)}% | C1 in Reg: ${(analysis.coreStats.c1InRegPct).toStringAsFixed(1)}% | OB: ${(analysis.coreStats.obPct).toStringAsFixed(1)}% | Parked: ${(analysis.coreStats.parkedPct).toStringAsFixed(1)}%
C1 Putting: ${(analysis.puttingStats.c1Percentage).toStringAsFixed(1)}% (${analysis.puttingStats.c1Makes}/${analysis.puttingStats.c1Attempts}) | C1X: ${(analysis.puttingStats.c1xPercentage).toStringAsFixed(1)}% (${analysis.puttingStats.c1xMakes}/${analysis.puttingStats.c1xAttempts}) | C2: ${(analysis.puttingStats.c2Percentage).toStringAsFixed(1)}% (${analysis.puttingStats.c2Makes}/${analysis.puttingStats.c2Attempts})
Mistakes: ${_formatMistakesBreakdown(round)}
Throw Types: ${_formatThrowTypeComparison(analysis)}

# Hole Type Breakdown (with outlier analysis)
${_formatHoleTypePerformance(round, analysis)}
# Disc Performance (top 5 by usage)
${_formatDiscPerformance(analysis)}
# Disc Usage by Hole (for specific context in explanations)
${_formatDiscByHole(round)}
# Shot Shape Performance
${_formatShotShapePerformance(round)}
# CRITICAL: You MUST output ALL sections below. Keep explanations to 1-2 sentences max.
# Output raw YAML only - NO markdown code blocks, NO ``` symbols.

Required YAML structure (include ALL fields):

roundTitle: [3-5 word title summarizing the round's outcome/vibe. Examples: "Birdie Fest at Maple Hill", "Solid Under-Par Round", "Putting Struggles Cost Strokes", "Clean Drives, Missed Putts". Be direct - if putting was bad, say "Putting Woes" not "Putting Focus".]
overview: [2 sentences, no stats, just context]
strengths:
  - headline: [short title]
    cardId: [CARD_ID or null]
    explanation: [1 sentence with key stat]
    targetTab: [driving/putting/mistakes]
weaknesses:
  - headline: [short title]
    cardId: [CARD_ID or null]
    explanation: [1 sentence - expand on mistakes with performance context]
    targetTab: [driving/putting/mistakes]
mistakes:
  cardId: MISTAKES
  explanation: [1 sentence summarizing key errors and stroke cost]
  targetTab: mistakes
biggestOpportunity:
  cardId: [CARD_ID]
  explanation: [1 sentence]
  targetTab: [driving/putting]
practiceAdvice:
  - [specific drill]
  - [specific drill]
strategyTips:
  - [specific non-obvious tip]
  - [specific non-obvious tip]
shareHighlightStats:
  - statId: [STAT_ID]
    reason: [why this stat is notable - 5-10 words]
  - statId: [STAT_ID]
    reason: [why this stat is notable - 5-10 words]
shareableHeadline: [1-2 SHORT sentences for social sharing. Start with "You" not "This round". Use simple words over verbose phrases. Be encouraging but honest. Example: "You crushed it with 5 birdies and 80% C1 putting. A few OBs held you back from going even lower."]

# Card IDs: FAIRWAY_HIT, C1_IN_REG, OB_RATE, PARKED, C1_PUTTING, C1X_PUTTING, C2_PUTTING, MISTAKES, THROW_TYPE_COMPARISON, SHOT_SHAPE_BREAKDOWN, DISC_PERFORMANCE:{name}, HOLE_TYPE:Par {3/4/5}
# Share Stat IDs (pick 2 most notable): c1PuttPct, c1xPuttPct, c2PuttPct, fairwayPct, parkedPct, c1InRegPct, obPct, birdies, bounceBack

# Rules:
- Use each card ID only ONCE across all sections
- Weaknesses should show DIFFERENT stats than the mistakes bar chart (add context, not repeat counts)
- NO emotional assumptions (no "frustrating", "disappointing") - stick to facts and stroke counts
- Strategy tips must be SPECIFIC (reference holes, discs) not generic ("play safer")
- Keep ALL text SHORT - 1-2 sentences max per explanation
- CRITICAL: When a hole type has 40%+ birdie rate but high average due to ONE outlier (double/triple bogey), that is NOT a weakness - it's good play with one anomaly. Only flag as weakness if there's a PATTERN of poor scores across multiple holes.
- DISC BLAME RULE: Only blame a disc for poor performance if: (1) at least 2 bad shots with that disc, AND (2) bad shots account for ≥50% of total shots with that disc. When mentioning a disc weakness, cite specific holes (e.g., "PD2 struggled on Holes 7 and 15 (both OB)").
''');

    return buffer.toString();
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

  /// Format disc usage by hole for the prompt - shows which holes each disc was used on
  /// and what happened (for AI to provide specific context in explanations)
  String _formatDiscByHole(DGRound round) {
    final Map<String, List<String>> discHoleResults = {};

    for (final DGHole hole in round.holes) {
      final int holeScore = hole.holeScore;
      final int par = hole.par;
      final int relative = holeScore - par;
      final String outcome = _getShortOutcome(relative);

      for (int i = 0; i < hole.throws.length; i++) {
        final throw_ = hole.throws[i];
        final String discName = throw_.discName ?? 'Unknown';
        if (discName == 'Unknown') continue;

        // Determine throw type (tee, approach, putt)
        final String throwType = i == 0
            ? 'tee'
            : (i == hole.throws.length - 1 ? 'putt' : 'approach');

        // Get landing result
        final String landing = throw_.landingSpot?.name ?? '';
        final bool hasPenalty = throw_.penaltyStrokes > 0;

        // Build result string
        String result = 'H${hole.number} ($throwType';
        if (landing.isNotEmpty) result += ', $landing';
        if (hasPenalty) result += ', OB';
        result += ', $outcome)';

        discHoleResults.putIfAbsent(discName, () => []).add(result);
      }
    }

    // Sort by throw count and format
    final List<MapEntry<String, List<String>>> sorted =
        discHoleResults.entries.toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final StringBuffer buffer = StringBuffer();
    for (final MapEntry<String, List<String>> entry in sorted.take(6)) {
      buffer.writeln('${entry.key}: ${entry.value.join(', ')}');
    }

    return buffer.toString();
  }

  String _getShortOutcome(int relativeToPar) {
    switch (relativeToPar) {
      case -2:
        return 'eagle';
      case -1:
        return 'birdie';
      case 0:
        return 'par';
      case 1:
        return 'bogey';
      case 2:
        return 'double';
      case 3:
        return 'triple';
      default:
        return relativeToPar > 0 ? '+$relativeToPar' : '$relativeToPar';
    }
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

  /// Format shot shape performance for the prompt
  String _formatShotShapePerformance(DGRound round) {
    final RoundStatisticsService statsService = RoundStatisticsService(round);
    final Map<String, dynamic> shotShapeStats =
        statsService.getShotShapeBirdieRateStats();

    if (shotShapeStats.isEmpty) {
      return 'No shot shape data available';
    }

    final StringBuffer buffer = StringBuffer();

    // Sort by attempts (most used first)
    final List<MapEntry<String, dynamic>> entries = shotShapeStats.entries
        .where((e) => (e.value.totalAttempts ?? 0) >= 2) // Min 2 attempts
        .toList();
    entries.sort((a, b) =>
        (b.value.totalAttempts ?? 0).compareTo(a.value.totalAttempts ?? 0));

    for (final MapEntry<String, dynamic> entry in entries.take(6)) {
      final String shapeName = entry.key;
      final double birdieRate = entry.value.percentage ?? 0.0;
      final int attempts = entry.value.totalAttempts ?? 0;

      buffer.writeln(
        '$shapeName: ${birdieRate.toStringAsFixed(1)}% birdie rate ($attempts attempts)',
      );
    }

    if (buffer.isEmpty) {
      return 'No shot shape data with sufficient attempts';
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
