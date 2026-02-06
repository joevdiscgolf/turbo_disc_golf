import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class ShotPreviewCard extends StatelessWidget {
  const ShotPreviewCard({super.key});

  static const Color accentColor = Color(0xFF3498DB);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              '🎯',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'Shot Analysis',
              style: TextStyle(
                color: SenseiColors.gray[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildShotRow('Backhand Hyzer', 0.73),
        const SizedBox(height: 7),
        _buildShotRow('Forehand', 0.21),
        const SizedBox(height: 7),
        _buildShotRow('Other', 0.06),
      ],
    );
  }

  Widget _buildShotRow(String label, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: SenseiColors.gray[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                color: SenseiColors.gray[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        _buildProgressBar(percentage),
      ],
    );
  }

  Widget _buildProgressBar(double percentage) {
    return Container(
      height: 7,
      decoration: BoxDecoration(
        color: SenseiColors.gray[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor,
                accentColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
