import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/models/throw_type_stats.dart';

class ShotShapeBreakdownPanel extends StatelessWidget {
  const ShotShapeBreakdownPanel({
    super.key,
    required this.throwType,
    required this.overallStats,
    required this.shotShapeStats,
  });

  final String throwType;
  final ThrowTypeStats overallStats;
  final List<ShotShapeStats> shotShapeStats;

  @override
  Widget build(BuildContext context) {
    // Find best and worst performers
    ShotShapeStats? bestShape;
    ShotShapeStats? worstShape;
    double bestBirdieRate = -1;
    double worstBirdieRate = 101;

    for (final ShotShapeStats shape in shotShapeStats) {
      if (shape.birdieRate > bestBirdieRate) {
        bestBirdieRate = shape.birdieRate;
        bestShape = shape;
      }
      if (shape.birdieRate < worstBirdieRate) {
        worstBirdieRate = shape.birdieRate;
        worstShape = shape;
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${overallStats.displayName.toUpperCase()} BREAKDOWN',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Overall: ${overallStats.birdieRate.toStringAsFixed(0)}% Birdie Rate (${overallStats.birdieCount}/${overallStats.totalHoles} holes)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Shot shape list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: shotShapeStats.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final ShotShapeStats shape = shotShapeStats[index];
                    String? badge;
                    if (shotShapeStats.length > 1) {
                      if (shape == bestShape) {
                        badge = 'BEST';
                      } else if (shape == worstShape) {
                        badge = 'WORST';
                      }
                    }

                    return _ShotShapeCard(shape: shape, badge: badge);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShotShapeCard extends StatelessWidget {
  const _ShotShapeCard({required this.shape, this.badge});

  final ShotShapeStats shape;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF137e66).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.disc_full,
                  size: 18,
                  color: Color(0xFF137e66),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${shape.throwType} ${shape.displayName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badge == 'BEST'
                        ? const Color(0xFF137e66).withValues(alpha: 0.15)
                        : const Color(0xFFFF7A7A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: badge == 'BEST'
                          ? const Color(0xFF137e66)
                          : const Color(0xFFFF7A7A),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _StatRow(
            label: 'Birdie Rate',
            percentage: shape.birdieRate,
            count: shape.birdieCount,
            total: shape.totalAttempts,
            color: const Color(0xFF137e66),
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: 'C1 in Reg',
            percentage: shape.c1InRegPct,
            count: shape.c1Count,
            total: shape.c1Total,
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: 'C2 in Reg',
            percentage: shape.c2InRegPct,
            count: shape.c2Count,
            total: shape.c2Total,
            color: const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.percentage,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final double percentage;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}% ($count/$total)',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
