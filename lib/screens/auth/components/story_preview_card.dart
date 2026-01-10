import 'package:flutter/material.dart';

class StoryPreviewCard extends StatelessWidget {
  const StoryPreviewCard({super.key});

  static const Color accentColor = Color(0xFF9B59B6);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '✨',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'Your Story',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '"Your Destroyer is a birdie machine — 67% of your birdies come off backhand hyzers with this disc."',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 15,
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
