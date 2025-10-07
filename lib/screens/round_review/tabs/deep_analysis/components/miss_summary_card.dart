import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/services/gpt_analysis_service.dart';

class MissSummaryCard extends StatelessWidget {
  final Map<LossReason, int> missSummary;

  const MissSummaryCard({super.key, required this.missSummary});

  @override
  Widget build(BuildContext context) {
    if (missSummary.isEmpty) return const SizedBox.shrink();

    final totalMisses = missSummary.values.fold<int>(0, (sum, count) => sum + count);
    final sortedEntries = missSummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            'Miss Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...sortedEntries.map((entry) {
            final percentage = (entry.value / totalMisses) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildMissRow(
                context,
                GPTAnalysisService.describeLossReason(entry.key),
                entry.value,
                percentage,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMissRow(
    BuildContext context,
    String label,
    int count,
    double percentage,
  ) {
    const accentColor = Color(0xFFFF7A7A);

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
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
