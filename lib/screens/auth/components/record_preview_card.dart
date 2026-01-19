import 'package:flutter/material.dart';

class RecordPreviewCard extends StatelessWidget {
  const RecordPreviewCard({super.key});

  static const Color accentColor = Color(0xFFE74C3C);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.mic,
                color: accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Voice Recording',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Just talk, we\'ll track it',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _buildWaveformIndicator(),
      ],
    );
  }

  Widget _buildWaveformIndicator() {
    final List<double> barHeights = [0.3, 0.6, 0.9, 0.7, 0.4, 0.8, 0.5, 0.3];

    return Row(
      children: barHeights.map((height) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            width: 4,
            height: 24 * height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  accentColor,
                  accentColor.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }).toList(),
    );
  }
}
