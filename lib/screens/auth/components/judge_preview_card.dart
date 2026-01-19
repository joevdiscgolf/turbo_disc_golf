import 'package:flutter/material.dart';

class JudgePreviewCard extends StatelessWidget {
  const JudgePreviewCard({super.key});

  static const Color accentColor = Color(0xFFF39C12);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '⚖️',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'Judge Mode',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '"That putting performance was chef\'s kiss! 🤌"',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRatingDot(true),
            const SizedBox(width: 6),
            _buildRatingDot(true),
            const SizedBox(width: 6),
            _buildRatingDot(true),
            const SizedBox(width: 6),
            _buildRatingDot(false),
            const SizedBox(width: 6),
            _buildRatingDot(false),
            const SizedBox(width: 10),
            Text(
              'Glaze',
              style: TextStyle(
                color: accentColor.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingDot(bool filled) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: filled
            ? accentColor
            : Colors.white.withValues(alpha: 0.2),
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
