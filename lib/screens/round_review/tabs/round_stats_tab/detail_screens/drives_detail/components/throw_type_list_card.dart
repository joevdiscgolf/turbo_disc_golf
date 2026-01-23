import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class ThrowTypeListCard extends StatelessWidget {
  const ThrowTypeListCard({
    super.key,
    required this.throwTypes,
    required this.onThrowTypeTap,
  });

  final List<ThrowTypeStats> throwTypes;
  final Function(ThrowTypeStats) onThrowTypeTap;

  @override
  Widget build(BuildContext context) {
    if (throwTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: addRunSpacing(
        throwTypes.map((throwType) {
          return _ThrowTypeCard(
            throwType: throwType,
            onTap: () => onThrowTypeTap(throwType),
          );
        }).toList(),
        runSpacing: 8,
        axis: Axis.vertical,
      ),
    );
  }
}

/// Individual throw type card with compact visual design
class _ThrowTypeCard extends StatelessWidget {
  const _ThrowTypeCard({required this.throwType, required this.onTap});

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
            _buildMetricRow(
              context,
              icon: Icons.emoji_events_outlined,
              label: 'Birdie Rate',
              percentage: throwType.birdieRate,
              count: throwType.birdieCount,
              total: throwType.totalHoles,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              context,
              icon: Icons.my_location_outlined,
              label: 'C1 in Reg',
              percentage: throwType.c1InRegPct,
              count: throwType.c1Count,
              total: throwType.c1Total,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              context,
              icon: Icons.adjust,
              label: 'C2 in Reg',
              percentage: throwType.c2InRegPct,
              count: throwType.c2Count,
              total: throwType.c2Total,
              color: const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Container(
        //   padding: const EdgeInsets.all(8),
        //   decoration: BoxDecoration(
        //     color: const Color(0xFF10B981).withValues(alpha: 0.1),
        //     borderRadius: BorderRadius.circular(8),
        //   ),
        //   child: const Icon(
        //     Icons.disc_full,
        //     size: 20,
        //     color: Color(0xFF10B981),
        //   ),
        // ),
        // const SizedBox(width: 12),
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

  Widget _buildMetricRow(
    BuildContext context, {
    required IconData icon,
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
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 6,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count/$total',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
