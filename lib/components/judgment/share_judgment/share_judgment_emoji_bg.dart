import 'dart:math';

import 'package:flutter/material.dart';

class ShareJudgmentEmojiBg extends StatelessWidget {
  const ShareJudgmentEmojiBg({super.key, required this.isGlaze});

  final bool isGlaze;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(children: _getEmojis(constraints));
        },
      ),
    );
  }

  List<Widget> _getEmojis(BoxConstraints constraints) {
    final Random random = Random();
    final String bgEmoji = isGlaze ? '\u{1F369}' : '\u{1F525}';
    final List<Widget> emojis = [];

    // Grid-based distribution: 6 columns x 10 rows = 60 cells
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

        // Random rotation
        final double rotation = (random.nextDouble() - 0.5) * 1.2;

        // Random opacity (0.08 to 0.18)
        final double opacity = 0.08 + random.nextDouble() * 0.1;

        // Random size (14 to 24)
        final double size = 14 + random.nextDouble() * 10;

        emojis.add(
          Positioned(
            top: top,
            left: left,
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

    return emojis;
  }
}
