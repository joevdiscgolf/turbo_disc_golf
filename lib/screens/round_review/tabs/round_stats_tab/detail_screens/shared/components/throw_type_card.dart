import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/components/metric_row.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Individual throw type card with compact visual design
class ThrowTypeCard extends StatelessWidget {
  const ThrowTypeCard({required this.throwType, required this.onTap, super.key});

  final ThrowTypeStats throwType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: defaultCardBoxShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            MetricRow(
              label: 'Birdie Rate',
              percentage: throwType.birdieRate,
              count: throwType.birdieCount,
              total: throwType.totalHoles,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            MetricRow(
              label: 'C1 in Reg',
              percentage: throwType.c1InRegPct,
              count: throwType.c1Count,
              total: throwType.c1Total,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            MetricRow(
              label: 'C2 in Reg',
              percentage: throwType.c2InRegPct,
              count: throwType.c2Count,
              total: throwType.c2Total,
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 12),
            MetricRow(
              label: 'Parked',
              percentage: throwType.parkedPct,
              count: throwType.parkedCount,
              total: throwType.totalHoles,
              color: const Color(0xFFFFA726),
            ),
            const SizedBox(height: 12),
            MetricRow(
              label: 'Fairway',
              percentage: throwType.fairwayPct,
              count: throwType.fairwayCount,
              total: throwType.totalHoles,
              color: const Color(0xFF4CAF50),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            throwType.displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        if (throwType.averageDistance != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              throwType.distanceDisplay,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Icon(
          Icons.chevron_right,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}
