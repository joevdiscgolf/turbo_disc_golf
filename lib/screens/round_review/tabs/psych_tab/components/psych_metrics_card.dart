import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class PsychMetricsCard extends StatelessWidget {
  final PsychStats stats;

  const PsychMetricsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
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
            'Key Metrics',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Momentum Multiplier
          _buildMetricRow(
            context,
            icon: Icons.trending_up,
            iconColor: const Color(0xFF9D4EDD),
            label: 'Momentum Multiplier',
            value: '${stats.momentumMultiplier.toStringAsFixed(1)}x',
            description: stats.momentumMultiplier > 2.0
                ? 'High - you ride momentum waves'
                : stats.momentumMultiplier < 1.5
                ? 'Low - very consistent mentally'
                : 'Moderate momentum effect',
          ),

          const SizedBox(height: 12),

          // Tilt Factor
          _buildMetricRow(
            context,
            icon: Icons.psychology,
            iconColor: stats.tiltFactor > 15
                ? const Color(0xFFFF7A7A)
                : const Color(0xFF4CAF50),
            label: 'Tilt Factor',
            value: stats.tiltFactor > 0
                ? '+${stats.tiltFactor.toStringAsFixed(0)}%'
                : '${stats.tiltFactor.toStringAsFixed(0)}%',
            description: stats.tiltFactor > 15
                ? 'High - work on composure'
                : 'Good - you stay composed',
            gaugeValue: stats.tiltFactor.clamp(0, 30) / 30,
          ),

          const SizedBox(height: 12),

          // Compound Error Rate
          _buildMetricRow(
            context,
            icon: Icons.link,
            iconColor: stats.compoundErrorRate < 20
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFFB800),
            label: 'Compound Error Rate',
            value: '${stats.compoundErrorRate.toStringAsFixed(0)}%',
            description: stats.compoundErrorRate < 20
                ? 'Low - excellent recovery'
                : 'Mistakes tend to cluster',
          ),

          const SizedBox(height: 12),

          // Longest Birdie Streak
          _buildMetricRow(
            context,
            icon: Icons.emoji_events,
            iconColor: const Color(0xFFFFB800),
            label: 'Longest Birdie+ Streak',
            value: '${stats.longestParStreak} holes',
            description: stats.longestParStreak >= 3
                ? 'Impressive birdie streak!'
                : 'Keep working on consistency',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String description,
    double? gaugeValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),

          // Optional gauge visualization
          if (gaugeValue != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: gaugeValue,
                minHeight: 8,
                backgroundColor: iconColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
