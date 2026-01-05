import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';

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
Your task is to provide a structured breakdown in JSON format with specific sections.

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

# Your Task
Analyze this disc golf round and provide a structured breakdown in JSON format:

{
  "roundTitle": "Strong -6 Round",
  "overview": "2-3 sentence summary. Set context, not hype. NO STATS. Just the big picture tone of the round.",
  "strengths": [
    {
      "cardId": "FAIRWAY_HIT",
      "explanation": "Your 89% fairway accuracy gave you clean looks all day. You were dialed in off the tee.",
      "targetTab": "driving"
    }
  ],
  "weaknesses": [
    {
      "cardId": "C1X_PUTTING",
      "explanation": "C1X putting at 67% left opportunities on the table. Missing makeable putts cost you strokes.",
      "targetTab": "putting"
    }
  ],
  "mistakes": {
    "cardId": "MISTAKES",
    "explanation": "3 OB drives and 2 three-putts cost you 5 strokes. These avoidable errors prevented an even lower score.",
    "targetTab": "mistakes"
  },
  "biggestOpportunity": {
    "cardId": "C1_IN_REG",
    "explanation": "Only 28% C1 in regulation. Giving yourself more looks inside the circle is your path to lower scores.",
    "targetTab": "driving"
  },
  "practiceAdvice": [
    "Work on driving accuracy from 300-350 feet",
    "Practice lag putting from 40-50 feet to reduce three-putts"
  ],
  "strategyTips": [
    "Consider using a fairway driver instead of distance driver on tight holes 3, 7, and 12",
    "Focus on lag putting from 40+ feet rather than running hot - safer two-putt strategy"
  ]
}

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

IMPORTANT: Use these exact card IDs in your JSON response.

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
3. Strengths: 1 highlight of what went well (pick ONE specific stat, not all 4 driving stats)
4. Weaknesses: 1 highlight of what cost strokes (pick ONE specific stat)
5. Mistakes: 1 highlight about key mistakes (optional, use MISTAKES card)
6. Biggest Opportunity: ONE SINGLE focus area (highest impact)
7. Practice Advice: 2-4 concrete, realistic practice drills (no vague advice)
8. Strategy Tips: 2-4 specific, NON-OBVIOUS course management tips

CRITICAL - Card Usage:
- DO NOT use the same card ID multiple times (e.g., don't use FAIRWAY_HIT in both strengths and weaknesses)
- Each section should focus on ONE specific stat, not show all 4 driving stats every time
- If talking about driving, pick the MOST RELEVANT stat (FAIRWAY_HIT, C1_IN_REG, OB_RATE, or PARKED)
- If talking about putting, pick the MOST RELEVANT stat (C1_PUTTING, C1X_PUTTING, or C2_PUTTING)

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
- RESPOND ONLY WITH VALID, COMPLETE JSON
- NO markdown formatting, NO code blocks (```), NO explanations
- The response must start with { and end with }
- ENSURE the JSON is complete - do not cut off mid-response
- All strings must be properly quoted and escaped
- All arrays and objects must be properly closed with ] and }

If you're approaching token limits, prioritize completing the JSON structure over adding more details.
''');

    return buffer.toString();
  }

  /// Parse the AI response into AIContent with segments or structured content
  AIContent _parseStoryResponse(String response, DGRound round) {
    try {
      // Clean the response of common AI formatting issues
      String cleanedResponse = response.trim();

      // Remove markdown code blocks if present
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      // Try to parse as structured JSON (new format)
      Map<String, dynamic>? json;

      try {
        json = jsonDecode(cleanedResponse);
      } catch (e) {
        // If JSON is incomplete, try to repair it
        debugPrint('JSON parse error: $e');
        debugPrint('Attempting to repair incomplete JSON...');

        final String repairedJson = _attemptJsonRepair(cleanedResponse);
        try {
          json = jsonDecode(repairedJson);
          debugPrint('Successfully repaired JSON');
        } catch (repairError) {
          debugPrint('JSON repair failed: $repairError');
          throw Exception('Could not parse or repair JSON');
        }
      }

      if (json == null) {
        throw Exception('JSON parsing resulted in null');
      }

      // Validate required fields exist (some fields optional for backwards compatibility)
      if (json.containsKey('overview') &&
          json.containsKey('strengths') &&
          json.containsKey('weaknesses') &&
          json.containsKey('practiceAdvice')) {

        // Add default values for new fields if not present (backwards compatibility)
        if (!json.containsKey('roundTitle')) {
          json['roundTitle'] = 'Round Summary';
        }
        if (!json.containsKey('strategyTips')) {
          json['strategyTips'] = <String>[];
        }

        // Ensure all required fields are valid
        if (json['overview'] is! String || (json['overview'] as String).isEmpty) {
          throw Exception('Invalid overview field');
        }
        if (json['strengths'] is! List) {
          throw Exception('Invalid strengths field');
        }
        if (json['weaknesses'] is! List) {
          throw Exception('Invalid weaknesses field');
        }
        if (json['practiceAdvice'] is! List) {
          throw Exception('Invalid practiceAdvice field');
        }

        // Parse as StructuredStoryContent
        final structuredContent = StructuredStoryContent.fromJson({
          ...json,
          'roundVersionId': round.versionId,
        });

        return AIContent(
          content: response,
          roundVersionId: round.versionId,
          structuredContent: structuredContent,
        );
      } else {
        throw Exception('Missing required fields in JSON response');
      }
    } catch (e) {
      debugPrint('Failed to parse as structured JSON: $e');
      debugPrint('Response was: $response');
    }

    // Fallback: Parse as old format with {{PLACEHOLDERS}}
    return _parseOldFormat(response, round);
  }

  /// Attempt to repair incomplete JSON by closing unclosed structures
  String _attemptJsonRepair(String incompleteJson) {
    final StringBuffer repaired = StringBuffer(incompleteJson);

    // Count opening and closing braces/brackets
    int braceCount = 0;
    int bracketCount = 0;
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < incompleteJson.length; i++) {
      final char = incompleteJson[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '"' && !escaped) {
        inString = !inString;
        continue;
      }

      if (!inString) {
        if (char == '{') braceCount++;
        if (char == '}') braceCount--;
        if (char == '[') bracketCount++;
        if (char == ']') bracketCount--;
      }
    }

    // If we're still in a string, close it
    if (inString) {
      repaired.write('"');
    }

    // Close unclosed arrays
    while (bracketCount > 0) {
      repaired.write(']');
      bracketCount--;
    }

    // Close unclosed objects
    while (braceCount > 0) {
      repaired.write('}');
      braceCount--;
    }

    return repaired.toString();
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
