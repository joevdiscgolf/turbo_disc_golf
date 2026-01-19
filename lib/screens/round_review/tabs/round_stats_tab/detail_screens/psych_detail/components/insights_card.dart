import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class InsightsCard extends StatelessWidget {
  final PsychStats stats;

  const InsightsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFFFFB800), size: 24),
              const SizedBox(width: 8),
              Text(
                'Mental Game Insights',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List all insights
          ...stats.insights.asMap().entries.map((entry) {
            final index = entry.key;
            final insight = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < stats.insights.length - 1 ? 12 : 0,
              ),
              child: _buildInsightItem(context, insight, index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightItem(BuildContext context, String insight, int index) {
    // Determine icon and color based on insight content
    IconData icon;
    Color color;

    if (insight.contains('psych') || insight.contains('birdie')) {
      icon = Icons.trending_up;
      color = const Color(0xFF9D4EDD);
    } else if (insight.contains('tilt') || insight.contains('reset')) {
      icon = Icons.psychology;
      color = const Color(0xFFFF7A7A);
    } else if (insight.contains('bounce') || insight.contains('recovery')) {
      icon = Icons.fitness_center;
      color = const Color(0xFF4CAF50);
    } else if (insight.contains('compound') || insight.contains('mistakes')) {
      icon = Icons.link_off;
      color = const Color(0xFFFFB800);
    } else if (insight.contains('streak')) {
      icon = Icons.emoji_events;
      color = const Color(0xFFFFB800);
    } else if (insight.contains('Slow Starter')) {
      icon = Icons.schedule;
      color = const Color(0xFF2196F3);
    } else if (insight.contains('Clutch')) {
      icon = Icons.star;
      color = const Color(0xFF9D4EDD);
    } else {
      icon = Icons.check_circle;
      color = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(insight, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
