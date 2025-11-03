import 'package:flutter/material.dart';

/// A subtle card that highlights key insights from the throw type data
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.bestThrowType,
    required this.bestPercentage,
    required this.worstThrowType,
    required this.worstPercentage,
  });

  final String bestThrowType;
  final double bestPercentage;
  final String worstThrowType;
  final double worstPercentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F6), // Light green background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF137e66).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF137e66).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 20,
              color: Color(0xFF137e66),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Insight',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF137e66),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$bestThrowType performs best — ${bestPercentage.toStringAsFixed(0)}% birdie rate vs ${worstPercentage.toStringAsFixed(0)}% for $worstThrowType',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: const Color(0xFF0D1518),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
