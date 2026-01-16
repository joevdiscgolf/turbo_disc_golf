import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/protocols/llm_service.dart';
import 'package:turbo_disc_golf/services/chatgpt_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/llm_helpers/chat_gpt_helpers.dart';
import 'package:turbo_disc_golf/utils/llm_helpers/story_service_helpers.dart';
import 'package:yaml/yaml.dart';

/// Service for generating AI-powered narrative stories about disc golf rounds
class StoryGeneratorService {
  final LLMService _llmService;

  StoryGeneratorService(this._llmService);

  /// Generate a narrative story for a round with embedded stat visualizations
  Future<AIContent?> generateRoundStory(DGRound round) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Generate round analysis for stats
        final RoundAnalysis analysis = RoundAnalysisGenerator.generateAnalysis(
          round,
        );

        // Build the story generation prompt
        // Use ChatGPTHelpers for OpenAI, default prompt for Gemini
        final bool isOpenAI = _llmService is ChatGPTService;
        debugPrint(
          '📝 Using ${isOpenAI ? 'ChatGPT' : 'Gemini'} prompt strategy',
        );

        final String prompt = isOpenAI
            ? ChatGPTHelpers.buildStoryPrompt(round, analysis)
            : _buildDefaultStoryPrompt(round, analysis);

        // Generate story using full model for creative content
        final response = await _llmService.generateContent(prompt: prompt);

        // Debug log the entire response
        debugPrint('📖 Story Generator Response (${response?.length ?? 0} chars):');
        debugPrint('═══════════════════════════════════════════════════════════════');
        debugPrint(response ?? '(null response)');
        debugPrint('═══════════════════════════════════════════════════════════════');

        if (response == null || response.isEmpty) {
          debugPrint('Failed to generate story: empty response');
          retryCount++;
          continue;
        }

        // Check for likely truncated response - complete YAML should be >1200 chars
        // and should contain the 'weaknesses' section (required field)
        if (response.length < 1200 || !response.contains('weaknesses:')) {
          debugPrint(
            'Response appears truncated (${response.length} chars, missing key sections). Retrying...',
          );
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
        debugPrint(
          'Failed to parse story response, retry $retryCount/$maxRetries',
        );
        retryCount++;
      } catch (e, trace) {
        debugPrint(
          'Error generating round story (attempt ${retryCount + 1}/$maxRetries): $e',
        );
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
  String _buildDefaultStoryPrompt(DGRound round, RoundAnalysis analysis) {
    final buffer = StringBuffer();

    // Calculate round totals
    final int totalScore = round.getTotalScore();
    final int coursePar = round.getTotalPar();
    final String scoreRelativeStr = round.getScoreRelativeToParString();

    // Calculate scoring summary
    final String scoringSummary = StoryServiceHelpers.formatScoringSummary(
      round,
    );

    buffer.writeln('''
You are not just summarizing stats — you are interpreting a round.

You are allowed to:
- Draw confident conclusions when the data clearly supports them.
- State when a single decision or sequence materially changed the round.
- Explain cause-and-effect plainly (e.g. “this decision led to X strokes lost”).

Write like a coach who watched the round unfold and understands tournament pressure.
Be direct and specific when something clearly cost strokes.
If a pattern is obvious, name it plainly rather than hedging.

Do not hedge obvious conclusions with excessive uncertainty language.
Avoid phrases like “may have,” “could be,” or “possibly” when the data is clear.

When possible, structure insights as:
- What happened
- Why it mattered
- What decision would have reduced damage

Prefer this over generic advice.

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
''');

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
        cleanedResponse = cleanedResponse.substring(
          cleanedResponse.indexOf('\n') + 1,
        );
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
        cleanedResponse = cleanedResponse.substring(
          0,
          cleanedResponse.length - 3,
        );
      }
      cleanedResponse = cleanedResponse.trim();

      // Try to parse as structured YAML (new format)
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 YAML PARSING ATTEMPT');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('Raw response length: ${cleanedResponse.length} characters');
      debugPrint(
        'First 200 chars: ${cleanedResponse.substring(0, cleanedResponse.length < 200 ? cleanedResponse.length : 200)}',
      );

      // First try to parse as-is
      dynamic yamlDoc;
      String yamlToParse = cleanedResponse;
      try {
        yamlDoc = loadYaml(cleanedResponse);
        debugPrint('✅ SUCCESS: Parsed YAML without repair');
      } catch (parseError) {
        // If parsing fails, show detailed error with context
        debugPrint('❌ YAML PARSE FAILED:');
        debugPrint('Error: $parseError');

        // Extract line number from error if available
        final RegExp linePattern = RegExp(r'line (\d+)');
        final Match? lineMatch = linePattern.firstMatch(parseError.toString());
        if (lineMatch != null) {
          final int errorLine = int.parse(lineMatch.group(1)!);
          final List<String> lines = cleanedResponse.split('\n');

          debugPrint('\n📍 ERROR CONTEXT (lines around error):');
          debugPrint('─────────────────────────────────────────────');
          // Show 3 lines before and after the error line
          for (int i = errorLine - 4; i <= errorLine + 2; i++) {
            if (i >= 0 && i < lines.length) {
              final String marker = i == errorLine - 1 ? '>>> ' : '    ';
              debugPrint('$marker${i + 1}: ${lines[i]}');
            }
          }
          debugPrint('─────────────────────────────────────────────\n');
        }

        debugPrint('🔧 Attempting repair of truncated YAML...');
        yamlToParse = _repairTruncatedYaml(cleanedResponse);
        debugPrint('After repair, length: ${yamlToParse.length}');

        try {
          yamlDoc = loadYaml(yamlToParse);
          debugPrint('✅ SUCCESS: Parsed YAML after repair');
        } catch (repairError) {
          debugPrint('❌ REPAIR FAILED: $repairError');
          debugPrint('\n📄 FULL YAML CONTENT:');
          debugPrint('─────────────────────────────────────────────');
          debugPrint(yamlToParse);
          debugPrint('─────────────────────────────────────────────\n');
          rethrow;
        }
      }

      // Convert YamlMap to regular Map<String, dynamic>
      final Map<String, dynamic> parsedData =
          json.decode(json.encode(yamlDoc)) as Map<String, dynamic>;
      debugPrint('✅ Successfully parsed YAML');
      debugPrint('Parsed fields: ${parsedData.keys.toList()}');

      // Normalize data types: convert score integers to strings
      // ChatGPT sometimes generates scores as integers instead of strings
      _normalizeScoreTypes(parsedData);
      debugPrint('Data types normalized');

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
        if (parsedData['overview'] is! String ||
            (parsedData['overview'] as String).isEmpty) {
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
        debugPrint(
          'practiceAdvice count: ${(parsedData['practiceAdvice'] as List).length}',
        );
        debugPrint(
          'strategyTips count: ${(parsedData['strategyTips'] as List).length}',
        );

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
        debugPrint('❌ VALIDATION FAILED: Missing required fields');
        debugPrint('Available fields: ${parsedData.keys.toList()}');
        debugPrint(
          'Missing: ${['overview', 'strengths', 'weaknesses'].where((f) => !parsedData.containsKey(f)).toList()}',
        );
        throw Exception('Missing required fields in YAML response');
      }
    } catch (e, stackTrace) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ STRUCTURED YAML PARSING COMPLETELY FAILED');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('Error: $e');
      debugPrint('\n📄 FULL RESPONSE:');
      debugPrint('─────────────────────────────────────────────');
      debugPrint(response);
      debugPrint('─────────────────────────────────────────────\n');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
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

  /// Normalize score types in parsed YAML data
  /// Converts integer scores to strings where needed (potentialScore, resultScore)
  void _normalizeScoreTypes(Map<String, dynamic> data) {
    // Fix whatCouldHaveBeen.potentialScore
    if (data.containsKey('whatCouldHaveBeen') &&
        data['whatCouldHaveBeen'] is Map) {
      final Map<String, dynamic> whatCouldHaveBeen =
          data['whatCouldHaveBeen'] as Map<String, dynamic>;

      // Convert potentialScore from int to string if needed
      if (whatCouldHaveBeen.containsKey('potentialScore')) {
        final dynamic potentialScore = whatCouldHaveBeen['potentialScore'];
        if (potentialScore is int) {
          whatCouldHaveBeen['potentialScore'] = potentialScore >= 0
              ? '+$potentialScore'
              : '$potentialScore';
          debugPrint(
            '🔧 Converted potentialScore from int ($potentialScore) to string',
          );
        }
      }

      // Fix scenarios[].resultScore
      if (whatCouldHaveBeen.containsKey('scenarios') &&
          whatCouldHaveBeen['scenarios'] is List) {
        final List<dynamic> scenarios =
            whatCouldHaveBeen['scenarios'] as List<dynamic>;
        for (int i = 0; i < scenarios.length; i++) {
          if (scenarios[i] is Map) {
            final Map<String, dynamic> scenario =
                scenarios[i] as Map<String, dynamic>;
            if (scenario.containsKey('resultScore')) {
              final dynamic resultScore = scenario['resultScore'];
              if (resultScore is int) {
                scenario['resultScore'] = resultScore >= 0
                    ? '+$resultScore'
                    : '$resultScore';
                debugPrint(
                  '🔧 Converted scenarios[$i].resultScore from int ($resultScore) to string',
                );
              }
            }
          }
        }
      }
    }
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
      ' a ',
      ' an ',
      ' the ',
      ' with ',
      ' to ',
      ' for ',
      ' on ',
      ' in ',
      ' at ',
      ' of ',
      ' and ',
      ' or ',
      ' but ',
      ' is ',
      ' was ',
      ' are ',
    ];

    for (final String pattern in truncationPatterns) {
      if (value.endsWith(pattern.trim())) return false;
    }

    // Single words that are likely incomplete
    if (value.split(' ').last.length <= 2 &&
        !RegExp(r'^\d+$').hasMatch(value.split(' ').last)) {
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
