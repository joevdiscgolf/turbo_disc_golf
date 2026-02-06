import 'dart:math';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/ai_content_renderer.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart'
    show flattenedOverWhite;
import 'package:turbo_disc_golf/utils/string_helpers.dart';

/// V3 design for judgment result content - clean, professional, full-width layout
class JudgmentResultContentV3 extends StatelessWidget {
  const JudgmentResultContentV3({
    super.key,
    required this.isGlaze,
    required this.headline,
    required this.content,
    required this.round,
    required this.analysis,
  });

  final bool isGlaze;
  final String headline;
  final String content;
  final DGRound round;
  final RoundAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final AIContent cleanAIContent = AIContent(
      content: content,
      roundVersionId: round.versionId,
    );

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVerdictHeader(context),
          const SizedBox(height: 16),
          _buildContent(context, cleanAIContent),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVerdictHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isGlaze
              ? [
                  const Color(0xFF137e66),
                  flattenedOverWhite(const Color(0xFF1a9f7f), 0.7),
                ]
              : [
                  const Color(0xFFFF6B6B),
                  flattenedOverWhite(const Color(0xFFFF8A8A), 0.7),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Emoji background pattern
          Positioned.fill(child: _buildEmojiBackground()),

          // Headline
          Center(
            child: Text(
              headline.capitalizeFirst(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiBackground() {
    final Random random = Random(42); // Fixed seed for consistency
    final String bgEmoji = isGlaze ? '\u{1F369}' : '\u{1F525}';
    final List<Widget> emojis = [];

    // Sparse grid for header: 4 columns x 2 rows
    const int cols = 4;
    const int rows = 2;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Random offset within each cell (0.2 to 0.8)
        final double offsetX = 0.2 + random.nextDouble() * 0.6;
        final double offsetY = 0.2 + random.nextDouble() * 0.6;

        // Convert to alignment (-1 to 1)
        final double alignX = ((col + offsetX) / cols) * 2 - 1;
        final double alignY = ((row + offsetY) / rows) * 2 - 1;

        // Random rotation
        final double rotation = (random.nextDouble() - 0.5) * 1.2;

        // Low opacity (0.18 to 0.25) - increased by 10%
        final double opacity = 0.18 + random.nextDouble() * 0.07;

        // Random size (16 to 22)
        final double size = 16 + random.nextDouble() * 6;

        emojis.add(
          Align(
            alignment: Alignment(alignX, alignY),
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(
                opacity: opacity,
                child: Text(bgEmoji, style: TextStyle(fontSize: size)),
              ),
            ),
          ),
        );
      }
    }

    return Stack(children: emojis);
  }

  Widget _buildContent(BuildContext context, AIContent cleanAIContent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.7,
        ),
        child: AIContentRenderer(
          aiContent: cleanAIContent,
          round: round,
          analysis: analysis,
        ),
      ),
    );
  }
}
