import 'package:flutter/material.dart';

class RecordPreviewCard extends StatelessWidget {
  const RecordPreviewCard({super.key});

  static const Color accentColor = Color(0xFFE74C3C);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.mic,
                color: accentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
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
        const SizedBox(height: 8),
        Text(
          'Just talk, we\'ll track it',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        _buildWaveformIndicator(),
      ],
    );
  }

  Widget _buildWaveformIndicator() {
    final List<double> barHeights = [
      0.3,
      0.5,
      0.7,
      0.9,
      0.75,
      0.5,
      0.8,
      0.95
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: barHeights.map((height) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            width: 3.5,
            height: 22 * height,
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
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 3,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
