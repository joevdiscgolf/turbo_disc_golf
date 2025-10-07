import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class CoreStatsCard extends StatelessWidget {
  final CoreStats coreStats;

  const CoreStatsCard({super.key, required this.coreStats});

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
            'Core Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            context,
            'C1 in Regulation',
            coreStats.c1InRegPct,
            const Color(0xFF00F5D4),
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            'C2 in Regulation',
            coreStats.c2InRegPct,
            const Color(0xFF10E5FF),
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            'Fairway Hit',
            coreStats.fairwayHitPct,
            const Color(0xFF9D4EDD),
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            'Parked',
            coreStats.parkedPct,
            const Color(0xFFFFB800),
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            'Out of Bounds',
            coreStats.obPct,
            const Color(0xFFFF7A7A),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    double percentage,
    Color accentColor,
  ) {
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
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
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
