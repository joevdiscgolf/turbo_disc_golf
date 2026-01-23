import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/shot_detail.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/components/metric_row.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/components/shot_details_list.dart';

/// Card showing individual shot shape stats
class ShotShapeCard extends StatelessWidget {
  const ShotShapeCard({
    required this.shape,
    required this.shotDetails,
    required this.isExpanded,
    required this.onToggleExpand,
    super.key,
  });

  final ShotShapeStats shape;
  final List<ShotDetail> shotDetails;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggleExpand,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    shape.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
            const SizedBox(height: 16),
            MetricRow(
              label: 'Birdie Rate',
              percentage: shape.birdieRate,
              count: shape.birdieCount,
              total: shape.totalAttempts,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            MetricRow(
              label: 'C1 in Reg',
              percentage: shape.c1InRegPct,
              count: shape.c1Count,
              total: shape.c1Total,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            MetricRow(
              label: 'C2 in Reg',
              percentage: shape.c2InRegPct,
              count: shape.c2Count,
              total: shape.c2Total,
              color: const Color(0xFF8B5CF6),
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
              ShotDetailsList(shotDetails: shotDetails),
            ],
          ],
        ),
      ),
    );
  }
}
