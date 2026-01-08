import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/models/throw_type_stats.dart';

class ThrowTypeComparisonCard extends StatelessWidget {
  const ThrowTypeComparisonCard({
    super.key,
    required this.forehandStats,
    required this.backhandStats,
    required this.onForehandBreakdownTap,
    required this.onBackhandBreakdownTap,
  });

  final ThrowTypeStats forehandStats;
  final ThrowTypeStats backhandStats;
  final VoidCallback onForehandBreakdownTap;
  final VoidCallback onBackhandBreakdownTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Throw Type Performance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const Divider(height: 1),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ThrowTypeColumn(
                    stats: forehandStats,
                    onBreakdownTap: onForehandBreakdownTap,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _ThrowTypeColumn(
                    stats: backhandStats,
                    onBreakdownTap: onBackhandBreakdownTap,
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

class _ThrowTypeColumn extends StatelessWidget {
  const _ThrowTypeColumn({
    required this.stats,
    required this.onBreakdownTap,
  });

  final ThrowTypeStats stats;
  final VoidCallback onBreakdownTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.displayName.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _buildBirdieRate(context),
          const SizedBox(height: 20),
          _buildStatRow(
            context,
            label: 'C1 in Reg',
            percentage: stats.c1InRegPct,
            count: stats.c1Count,
            total: stats.c1Total,
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            context,
            label: 'C2 in Reg',
            percentage: stats.c2InRegPct,
            count: stats.c2Count,
            total: stats.c2Total,
            color: const Color(0xFF9C27B0),
          ),
          const SizedBox(height: 20),
          _buildBreakdownButton(context),
        ],
      ),
    );
  }

  Widget _buildBirdieRate(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF137e66).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF137e66),
              width: 3,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_golf,
                  color: const Color(0xFF137e66),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.birdieRate.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF137e66),
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Birdie Rate',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          '${stats.birdieCount} of ${stats.totalHoles} holes',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required String label,
    required double percentage,
    required int count,
    required int total,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '($count/$total attempts)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _buildBreakdownButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onBreakdownTap();
        },
        icon: const Icon(Icons.expand_more, size: 18),
        label: const Text('View Breakdown'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
