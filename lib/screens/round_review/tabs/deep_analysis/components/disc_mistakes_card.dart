import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class DiscMistakesCard extends StatelessWidget {
  final List<DiscMistake> discMistakes;

  const DiscMistakesCard({super.key, required this.discMistakes});

  @override
  Widget build(BuildContext context) {
    if (discMistakes.isEmpty) return const SizedBox.shrink();

    final topMistakes = discMistakes.take(5).toList();
    final maxMistakes = topMistakes.isNotEmpty ? topMistakes.first.mistakeCount : 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mistakes by Disc',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...topMistakes.map((mistake) {
            final percentage = (mistake.mistakeCount / maxMistakes) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildDiscRow(
                context,
                mistake.discName,
                mistake.mistakeCount,
                percentage,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDiscRow(
    BuildContext context,
    String discName,
    int count,
    double percentage,
  ) {
    const accentColor = Color(0xFFFFB800);

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            discName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 12,
              backgroundColor: accentColor.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
          ),
        ),
      ],
    );
  }
}
