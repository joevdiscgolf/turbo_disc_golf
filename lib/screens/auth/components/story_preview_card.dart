import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class StoryPreviewCard extends StatelessWidget {
  const StoryPreviewCard({super.key});

  static const Color accentColor = Color(0xFF9B59B6);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              '✨',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'Your Story',
              style: TextStyle(
                color: SenseiColors.gray[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            '"Your Destroyer is a birdie machine — 67% of your birdies come off backhand hyzers with this disc."',
            style: TextStyle(
              color: SenseiColors.gray[700],
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
