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

# Performance Statistics
C1 in Regulation: ${(analysis.coreStats.c1InRegPct).toStringAsFixed(1)}%
Fairway Hits: ${(analysis.coreStats.fairwayHitPct).toStringAsFixed(1)}%
OB Rate: ${(analysis.coreStats.obPct).toStringAsFixed(1)}%
Parked Rate: ${(analysis.coreStats.parkedPct).toStringAsFixed(1)}%

# Putting Performance
C1 Putting: ${(analysis.puttingStats.c1Percentage).toStringAsFixed(1)}% (${analysis.puttingStats.c1Makes}/${analysis.puttingStats.c1Attempts})
C1X Putting: ${(analysis.puttingStats.c1xPercentage).toStringAsFixed(1)}% (${analysis.puttingStats.c1xMakes}/${analysis.puttingStats.c1xAttempts})
C2 Putting: ${(analysis.puttingStats.c2Percentage).toStringAsFixed(1)}% (${analysis.puttingStats.c2Makes}/${analysis.puttingStats.c2Attempts})

# Disc Performance
${_formatDiscPerformance(analysis)}

# Hole Type Performance
${_formatHoleTypePerformance(round, analysis)}

# Mistakes Breakdown
${_formatMistakesBreakdown(round)}

# Throw Type Performance (Backhand vs Forehand)
${_formatThrowTypeComparison(analysis)}

# Shot Shape Performance
${_formatShotShapePerformance(round)}

# Your Task
Analyze this disc golf round and provide a structured breakdown in YAML format:

roundTitle: Strong -6 Round
overview: 2-3 sentence summary. Set context, not hype. NO STATS. Just the big picture tone of the round.
strengths:
  - headline: Dialed in from the tee
    cardId: FAIRWAY_HIT
    explanation: Your 89% fairway accuracy gave you clean looks all day. You were consistently in position to score.
    targetTab: driving
  - headline: Parked it consistently
    cardId: PARKED
    explanation: Your 17% parked rate gave you easy birdie opportunities. When you gave yourself chances, you capitalized.
    targetTab: driving
weaknesses:
  - headline: Missed makeable putts
    cardId: C1X_PUTTING
    explanation: C1X putting at 67% left strokes on the table. Missing these routine putts prevented a lower score.
    targetTab: putting
  - headline: null
    cardId: null
    explanation: Your distance control on Par 5s was inconsistent, often coming up short and leaving yourself tough upshots.
mistakes:
  cardId: MISTAKES
  explanation: 3 OB drives and 2 three-putts cost you 5 strokes. These avoidable errors prevented an even lower score.
  targetTab: mistakes
biggestOpportunity:
  cardId: C1_IN_REG
  explanation: Only 28% C1 in regulation. Giving yourself more looks inside the circle is your path to lower scores.
  targetTab: driving
practiceAdvice:
  - Work on driving accuracy from 300-350 feet
  - Practice lag putting from 40-50 feet to reduce three-putts
strategyTips:
  - Consider using a fairway driver instead of distance driver on tight holes 3, 7, and 12
  - Focus on lag putting from 40+ feet rather than running hot - safer two-putt strategy

# Available Card IDs
PUTTING CARDS:
- C1X_PUTTING - Use when C1X (11-33 ft) putting is notable
- C1_PUTTING - Use when overall C1 (0-33 ft) putting is notable
- C2_PUTTING - Use when C2 (33-66 ft) putting is notable

DRIVING CARDS:
- FAIRWAY_HIT - Use when fairway hit % is notable
- C1_IN_REG - Use when reaching C1 in regulation is notable
- OB_RATE - Use when out-of-bounds drives are notable
- PARKED - Use when parking drives close to basket is notable

SCORING CARDS:
- BIRDIES - Use when birdie count is notable
- SCORING - Use for overall scoring distribution

MISTAKE CARDS:
- MISTAKES - Use for mistakes breakdown (OB, three-putts, missed C1, etc.)

THROW TYPE CARDS:
- THROW_TYPE_COMPARISON - Use when backhand vs forehand performance is notably different
  Displays: Side-by-side birdie % and C1 in reg % for BH vs FH
  When to use: When one throw type significantly outperformed the other (>15% difference in birdie rate)

SHOT SHAPE CARDS:
- SHOT_SHAPE_BREAKDOWN - Use when specific shot shapes dominated performance
  Displays: Top shot shapes with birdie % and C1 in reg %
  When to use: When one shot shape has notably higher success (e.g., backhand hyzer at 40% birdie vs others at 15%)

DISC PERFORMANCE CARDS:
- DISC_PERFORMANCE:{discName} - Use when a specific disc was notably good/bad
  Example: "DISC_PERFORMANCE:Destroyer"
  Displays: Birdie %, avg score, throw count for that disc
  When to use: When a disc has exceptional performance (>35% birdie rate) or poor performance (<10% on birdie-able holes)
  Parameters: {discName} should be the exact disc name from the round data

HOLE TYPE CARDS:
- HOLE_TYPE:{parType} - Use when performance on specific hole types is notable
  Example: "HOLE_TYPE:Par 3", "HOLE_TYPE:Par 4", "HOLE_TYPE:Par 5"
  Displays: Scoring average, birdie rate for that hole type
  When to use: When a hole type shows clear strength/weakness (e.g., -0.8 avg on Par 3s vs +0.5 on Par 5s)

IMPORTANT: Use these exact card IDs in your YAML response.

# Disc Golf Language Guidelines
Sound like a knowledgeable disc golfer, not a generic LLM:

APPROVED TERMINOLOGY:
- "giving yourself looks" = getting into birdie position
- "inside the circle" = C1 (0-33 feet)
- "leaking strokes" = avoidable mistakes
- "in regulation" = reaching target position in expected throws
- "playing for par" = conservative strategy
- "capitalizing on chances" = converting opportunities
- "stress-free approaches" = safe positioning

TONE:
- Honest but constructive (NOT overly emotional)
- Specific patterns, not one-offs
- Actionable insights, not just data reporting
- Coach mode, not entertainer mode (save sarcasm for Judge tab)

RULES:
1. Round Title: 3-5 words summarizing the round (e.g., "Strong -6 Round", "Birdie Fest", "Consistent Par Round")
2. Overview: 2-3 sentences max, no stats, set context
3. Strengths: 1-4 highlights of what went well (flexible based on round)
   - Each highlight can have: optional headline, optional cardId, explanation text
   - Pick VARIED stats/topics - don't just show all 4 driving stats
   - For text-only insights, set cardId to null and provide headline + explanation
   - Aim for 2-3 highlights when there's enough notable data
4. Weaknesses: 1-4 highlights of what cost strokes (flexible based on round)
   - Same structure as strengths
   - Be constructive, focus on patterns not isolated mistakes
   - Aim for 2-3 highlights when there's enough notable data
5. Mistakes: REQUIRED - 1 highlight about key mistakes (ALWAYS use MISTAKES card)
   - Include cardId: MISTAKES to show the mistakes breakdown widget
   - Summarize the key errors that cost strokes
6. Biggest Opportunity: ONE SINGLE focus area (highest impact)
7. Practice Advice: REQUIRED - 2-4 concrete, realistic practice drills (no vague advice)
8. Strategy Tips: REQUIRED - 2-4 specific, NON-OBVIOUS course management tips

IMPORTANT: ALL sections (mistakes, practiceAdvice, strategyTips) MUST be included in your response.

INSIGHT GUIDELINES:
- Prioritize DIFFERENT topics in strengths/weaknesses for maximum insight
- Example: If fairway hits were great, also mention parked % or throw type performance
- Use text-only highlights (cardId: null) for nuanced observations that don't fit a widget
- Mix widget-backed highlights with text-only insights for depth
- Each highlight should tell a different part of the story

CRITICAL - Card Usage:
- DO NOT use the same card ID multiple times across all sections
- Each widget should appear at most once in the entire response
- If talking about driving, pick DIFFERENT specific stats for multiple highlights
- Example: Use FAIRWAY_HIT for one strength, PARKED for another, THROW_TYPE_COMPARISON for weaknesses

WIDGET SELECTION STRATEGY:
- Use specific widgets that match the insight (don't default to generic driving card for all tee shots)
- Prefer THROW_TYPE_COMPARISON when BH vs FH difference is the key insight
- Prefer PARKED or C1_IN_REG over FAIRWAY_HIT when approach quality is the focus
- Use DISC_PERFORMANCE when a specific disc dominated (e.g., Destroyer with 8 birdies)
- Use HOLE_TYPE when performance varies significantly by par (e.g., crushing Par 3s but struggling on Par 5s)
- Use SHOT_SHAPE_BREAKDOWN when a specific shot shape was notably strong/weak
- Use text-only highlights for nuanced insights (e.g., "Your upshots were more conservative than usual, favoring safety over birdie attempts")

CRITICAL - "What Cost You Strokes" (Weaknesses) Guidelines:
- ALWAYS check the Mistakes Breakdown FIRST - it shows exactly what went wrong
- If missed C1X putts are the #1 mistake type, they MUST appear in weaknesses
- If OB shots appear in mistakes, include them in weaknesses with the count
- Use the actual mistake counts in your explanations (e.g., "5 missed C1X putts cost you...")
- The Mistakes Breakdown data is the PRIMARY source for the weaknesses section
- Disc/shot type/shot shape performance is SECONDARY context for weaknesses
- Example: If mistakes show "Missed C1X putt: 5 (56%)", your weaknesses MUST include a highlight about C1X putting

THROW TYPE INSIGHTS:
- If backhand birdie rate is >15% higher than forehand (or vice versa), mention it in strengths or weaknesses
- Use THROW_TYPE_COMPARISON card when the difference is notable
- Ignore throw type data with only 1-2 attempts - not enough to show a pattern

SHOT SHAPE INSIGHTS:
- If a specific shot shape (hyzer, anhyzer, etc.) has notably better/worse birdie rate, include it
- Use SHOT_SHAPE_BREAKDOWN card when shape performance varies significantly
- Ignore shapes with only 1-2 attempts - not enough data to be meaningful

DISC PERFORMANCE INSIGHTS:
- If a specific disc has notably high/low birdie rate compared to others, mention it
- Use DISC_PERFORMANCE:{discName} card when a disc dominated or underperformed
- Ignore discs with only 1-2 throws - not enough data to draw conclusions

CRITICAL - Strategy Tips Guidelines:
- DO NOT state obvious advice like "be more conservative on OB holes" or "play safer on difficult holes"
- DO give specific disc selection, shot shape, or positioning advice
- DO reference specific holes or situations from this round
- DO focus on non-obvious decisions that would improve scoring
- Examples of GOOD strategy tips:
  ✓ "Consider using a stable mid-range on hole 7 instead of overstable driver to avoid the OB left"
  ✓ "On holes 3 and 15, layup short of the gap and give yourself a controlled upshot"
  ✓ "Your C2 putting is strong - be more aggressive from 35-45 feet to capitalize on makes"
- Examples of BAD strategy tips (avoid these):
  ✗ "Develop a more conservative strategy on known OB-heavy holes"
  ✗ "Play it safe on difficult holes"
  ✗ "Focus on course management"

CRITICAL FORMATTING REQUIREMENTS:
- RESPOND ONLY WITH VALID, COMPLETE YAML
- NO markdown formatting, NO code blocks (```), NO explanations
- Use proper YAML indentation (2 spaces per level)
- ENSURE the YAML is complete - do not cut off mid-response
- All strings should be properly quoted if they contain special characters
- Lists use dash (-) prefix with proper indentation
- Use null for null values (not "null" string)

If you're approaching token limits, prioritize completing the YAML structure over adding more details.
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

  /// Format hole type performance data for the prompt
  String _formatHoleTypePerformance(DGRound round, dynamic analysis) {
    final Map<int, List<DGHole>> holesByPar = {};

    for (final DGHole hole in round.holes) {
      holesByPar.putIfAbsent(hole.par, () => []).add(hole);
    }

    final StringBuffer buffer = StringBuffer();

    for (final MapEntry<int, List<DGHole>> entry in holesByPar.entries) {
      final int par = entry.key;
      final List<DGHole> holes = entry.value;
      final int totalScore = holes.fold<int>(0, (sum, h) => sum + h.holeScore);
      final int totalPar = holes.length * par;
      final double avgRelative = (totalScore - totalPar) / holes.length;
      final double birdieRate =
          (analysis.birdieRateByPar[par] ?? 0.0) as double;

      buffer.writeln(
        'Par $par: ${avgRelative >= 0 ? '+' : ''}${avgRelative.toStringAsFixed(2)} avg, '
        '${birdieRate.toStringAsFixed(1)}% birdie rate, '
        '${holes.length} holes',
      );
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
