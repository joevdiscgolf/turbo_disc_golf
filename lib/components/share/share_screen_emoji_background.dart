import 'dart:math';

import 'package:flutter/material.dart';

/// A generic emoji background layer for share preview screens.
///
/// Creates a grid of randomly positioned, rotated, and styled emojis
/// across the screen. Supports multiple emojis and deterministic
/// placement via randomSeed.
class ShareScreenEmojiBackground extends StatelessWidget {
  const ShareScreenEmojiBackground({
    super.key,
    required this.emojis,
    this.randomSeed,
    this.backgroundColor = Colors.transparent,
  });

  /// List of emojis to display in the background.
  /// Supports single or multiple emojis.
  final List<String> emojis;

  /// Optional seed for deterministic emoji placement.
  /// If null, uses truly random placement.
  final int? randomSeed;

  /// Background color behind the emojis.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    // Return empty container if no emojis to display
    if (emojis.isEmpty) {
      return Container(color: backgroundColor);
    }

    return Container(
      color: backgroundColor,
      height: double.infinity,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(children: _buildBackgroundEmojis(constraints));
        },
      ),
    );
  }

  /// Builds a 6×10 grid of randomly positioned emojis.
  List<Widget> _buildBackgroundEmojis(BoxConstraints constraints) {
    final Random random = randomSeed != null ? Random(randomSeed!) : Random();
    final List<Widget> emojiWidgets = [];

    // Grid-based distribution: 6 columns × 10 rows = 60 cells
    const int cols = 6;
    const int rows = 10;

    final double cellWidth = constraints.maxWidth / cols;
    final double cellHeight = constraints.maxHeight / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Random offset within each cell (0.1 to 0.9 to avoid edges)
        final double offsetX = 0.1 + random.nextDouble() * 0.8;
        final double offsetY = 0.1 + random.nextDouble() * 0.8;

        final double left = col * cellWidth + offsetX * cellWidth;
        final double top = row * cellHeight + offsetY * cellHeight;

        // Random rotation (±0.6 radians)
        final double rotation = (random.nextDouble() - 0.5) * 1.2;

        // Random opacity (0.08 to 0.18)
        final double opacity = 0.02 + random.nextDouble() * 0.1;

        // Random size (14 to 24px)
        final double size = 14 + random.nextDouble() * 10;

        // Select emoji (cycle through list if multiple)
        final String emoji = emojis[(row * cols + col) % emojis.length];

        emojiWidgets.add(
          Positioned(
            top: top,
            left: left,
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(
                opacity: opacity,
                child: Text(emoji, style: TextStyle(fontSize: size)),
              ),
            ),
          ),
        );
      }
    }

    return emojiWidgets;
  }
}
