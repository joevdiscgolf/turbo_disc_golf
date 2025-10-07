import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class MistakeTypesCard extends StatelessWidget {
  final List<MistakeTypeSummary> mistakeTypes;

  const MistakeTypesCard({super.key, required this.mistakeTypes});

  @override
  Widget build(BuildContext context) {
    if (mistakeTypes.isEmpty) return const SizedBox.shrink();

    final topMistakes = mistakeTypes.take(5).toList();

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
            'Top Mistakes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...topMistakes.map((mistake) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildMistakeRow(
                context,
                mistake.label,
                mistake.count,
                mistake.percentage,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMistakeRow(
    BuildContext context,
    String label,
    int count,
    double percentage,
  ) {
    const accentColor = Color(0xFF9D4EDD);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
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
          width: 60,
          child: Text(
            '$count (${percentage.toStringAsFixed(0)}%)',
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
