import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';

/// Service for generating AI-powered narrative stories about disc golf rounds
class StoryGeneratorService {
  final GeminiService _geminiService;

  StoryGeneratorService(this._geminiService);

  /// Generate a narrative story for a round with embedded stat visualizations
  Future<AIContent?> generateRoundStory(DGRound round) async {
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
        return null;
      }

      // Parse response into AIContent with segments
      final aiContent = _parseStoryResponse(response, round);

      return aiContent;
    } catch (e, trace) {
      debugPrint('Error generating round story: $e');
      debugPrint(trace.toString());
      return null;
    }
  }

  /// Build the prompt for story generation
  String _buildStoryPrompt(DGRound round, dynamic analysis) {
    final buffer = StringBuffer();

    // Calculate round totals
    final int totalScore = round.holes.fold(
      0,
      (sum, hole) => sum + hole.holeScore,
    );
    final int coursePar = round.holes.fold(
      0,
      (sum, hole) => sum + hole.par,
    );
    final int scoreRelativeToPar = totalScore - coursePar;
    final String scoreRelativeStr = scoreRelativeToPar > 0
        ? '+$scoreRelativeToPar'
        : '$scoreRelativeToPar';
    final String date = round.playedRoundAt ?? round.createdAt ?? 'Unknown';

    buffer.writeln('''
You are a friendly and insightful disc golf coach analyzing a player's round.
Your task is to create an engaging narrative that tells the story of their round,
weaving together statistics, key moments, and actionable insights.

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
      buffer.writeln(
        'Hole ${hole.number}: $score ($relativeStr) - Par $par',
      );
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
Create an engaging narrative story (300-500 words) that:

1. **Opens with the big picture**: How did the round go overall? Set the scene.

2. **Highlights key moments**:
   - What were the turning points?
   - Which holes were particularly good or challenging?
   - Any streaks (birdies, bogeys)?

3. **Weaves in statistics naturally**:
   - Don't just list stats - tell what they mean
   - Connect stats to specific holes or outcomes
   - Use stats to explain the score

4. **Identifies patterns**:
   - What was working well?
   - What held them back?
   - How did their game evolve through the round?

5. **Ends with actionable insights**:
   - What should they practice?
   - What could have the biggest impact on their score?
   - One specific thing to focus on next round

# Format Requirements

Write your response as **markdown text** with embedded stat card placeholders.

Use these placeholders to insert visual stat widgets:
- {{PUTTING_STATS}} - Circular putting percentages (C1, C1X, C2)
- {{DRIVING_STATS}} - Driving stats visualization
- {{SCORE_BREAKDOWN}} - Score distribution chart
- {{MISTAKES_CHART}} - Mistakes breakdown

Example format:
```markdown
# Your Round at Oak Grove

You shot +4 (71) today, which is...

{{DRIVING_STATS}}

Looking at your drives, you hit the fairway 67% of the time...

The turning point came on hole 12...

{{PUTTING_STATS}}

Your putting saved the round. That 89% C1 putting...

# What to Practice Next

Based on this round, here's what would have the biggest impact...
```

**Important**:
- Use markdown headers (# ## ###) to structure the story
- Keep paragraphs concise (2-3 sentences max)
- Place stat card placeholders on their own lines
- Be encouraging but honest
- Write in second person ("you", "your")
- Focus on storytelling, not just data reporting
''');

    return buffer.toString();
  }

  /// Parse the AI response into AIContent with segments
  AIContent _parseStoryResponse(String response, DGRound round) {
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
          AIContentSegment(
            type: AISegmentType.statCard,
            content: cardId,
          ),
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

    // Create AIContent with segments
    return AIContent(
      content: response, // Store raw response for fallback
      roundVersionId: round.versionId,
      segments: segments,
    );
  }
}
