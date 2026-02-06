import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class JudgePreviewCard extends StatelessWidget {
  const JudgePreviewCard({super.key});

  static const Color accentColor = Color(0xFFF39C12);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              '⚖️',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'Judge Mode',
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
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"That putting performance was chef\'s kiss! 🤌"',
                style: TextStyle(
                  color: SenseiColors.gray[700],
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildRatingDot(true),
                  const SizedBox(width: 5),
                  _buildRatingDot(true),
                  const SizedBox(width: 5),
                  _buildRatingDot(true),
                  const SizedBox(width: 5),
                  _buildRatingDot(false),
                  const SizedBox(width: 5),
                  _buildRatingDot(false),
                  const SizedBox(width: 8),
                  Text(
                    'Glaze',
                    style: TextStyle(
                      color: accentColor.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDot(bool filled) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: filled
            ? accentColor
            : SenseiColors.gray[300],
        shape: BoxShape.circle,
        boxShadow: filled
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 3,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
    );
  }
}
