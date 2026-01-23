import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';

/// Enhanced throw type card with compact grid layout (Layout Option B)
/// Shows: Birdie%, C1 Reg%, Parked%, Fairway%, OB%, Avg Throw Distance
/// Plus shot shape distribution and expandable detailed breakdown
class EnhancedThrowTypeCard extends StatefulWidget {
  const EnhancedThrowTypeCard({
    super.key,
    required this.throwType,
    required this.statisticsService,
    this.badge,
    required this.onTap,
  });

  final ThrowTypeStats throwType;
  final RoundStatisticsService statisticsService;
  final String? badge;
  final VoidCallback onTap;

  @override
  State<EnhancedThrowTypeCard> createState() => _EnhancedThrowTypeCardState();
}

class _EnhancedThrowTypeCardState extends State<EnhancedThrowTypeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildCompactMetricsGrid(context),
                  const SizedBox(height: 12),
                  if (widget.throwType.shotShapeDistribution.isNotEmpty)
                    _buildShotShapeChips(context),
                  const SizedBox(height: 8),
                  _buildExpandButton(context),
                ],
              ),
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),
                    _buildExpandedBreakdown(context),
                  ],
                ),
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
            widget.throwType.displayName.toUpperCase(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        if (widget.throwType.averageThrowDistance != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.straighten,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.throwType.averageThrowDistance!.round()} ft',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (widget.badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.badge == 'Best'
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.badge!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: widget.badge == 'Best'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Icon(
          _isExpanded ? Icons.expand_less : Icons.chevron_right,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  /// Layout Option B: Compact grid showing 6 key metrics
  Widget _buildCompactMetricsGrid(BuildContext context) {
    return Column(
      children: [
        // Row 1: Birdie, C1 in Reg, Parked
        Row(
          children: [
            Expanded(
              child: _buildCompactMetric(
                context,
                icon: '🏆',
                label: 'Birdie',
                percentage: widget.throwType.birdieRate,
                count: widget.throwType.birdieCount,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactMetric(
                context,
                icon: '🎯',
                label: 'C1 Reg',
                percentage: widget.throwType.c1InRegPct,
                count: widget.throwType.c1Count,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactMetric(
                context,
                icon: '📍',
                label: 'Parked',
                percentage: widget.throwType.parkedPct,
                count: widget.throwType.parkedCount,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Fairway, OB, Throw Distance (or placeholder)
        Row(
          children: [
            Expanded(
              child: _buildCompactMetric(
                context,
                icon: '🛣',
                label: 'Fairway',
                percentage: widget.throwType.fairwayPct,
                count: widget.throwType.fairwayCount,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactMetric(
                context,
                icon: '❌',
                label: 'OB',
                percentage: widget.throwType.obPct,
                count: widget.throwType.obCount,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactMetric(
                context,
                icon: '⚡',
                label: 'Avg Throw',
                percentage: widget.throwType.averageThrowDistance ?? 0,
                count: widget.throwType.totalHoles,
                isDistance: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Compact metric box (icon, label, percentage or distance)
  Widget _buildCompactMetric(
    BuildContext context, {
    required String icon,
    required String label,
    required double percentage,
    required int count,
    bool isDistance = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          isDistance
              ? '${percentage.round()} ft'
              : '${percentage.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            color: const Color(0xFF9CA3AF),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Shot shape distribution as chips/pills
  Widget _buildShotShapeChips(BuildContext context) {
    final shapes = widget.throwType.shotShapeDistribution.entries
        .map((e) {
          final total = widget.throwType.shotShapeDistribution.values
              .fold<int>(0, (a, b) => a + b);
          final pct =
              total > 0 ? ((e.value.toDouble() / total) * 100) : 0.0;
          return _ShapeChip(
            label: e.key,
            percentage: pct,
            count: e.value,
          );
        })
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shapes:',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: shapes,
        ),
      ],
    );
  }

  /// Expand/collapse button
  Widget _buildExpandButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Row(
        children: [
          Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 18,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(
            _isExpanded ? 'Hide detailed breakdown' : 'Show detailed breakdown',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// Expanded breakdown section with detailed stats
  Widget _buildExpandedBreakdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full progress bars for main metrics
        _buildMetricRow(
          context,
          icon: '🏆',
          label: 'Birdie',
          percentage: widget.throwType.birdieRate,
          count: widget.throwType.birdieCount,
          total: widget.throwType.totalHoles,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 12),
        _buildMetricRow(
          context,
          icon: '🎯',
          label: 'C1 in Regulation',
          percentage: widget.throwType.c1InRegPct,
          count: widget.throwType.c1Count,
          total: widget.throwType.c1Total,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 12),
        _buildMetricRow(
          context,
          icon: '📍',
          label: 'Parked',
          percentage: widget.throwType.parkedPct,
          count: widget.throwType.parkedCount,
          total: widget.throwType.totalHoles,
          color: const Color(0xFFFFA726),
        ),
      ],
    );
  }

  /// Full-width metric row with progress bar
  Widget _buildMetricRow(
    BuildContext context, {
    required String icon,
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
            Text(icon, style: const TextStyle(fontSize: 14)),
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
                fontSize: 14,
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

/// Small chip/pill for shot shape display
class _ShapeChip extends StatelessWidget {
  const _ShapeChip({
    required this.label,
    required this.percentage,
    required this.count,
  });

  final String label;
  final double percentage;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Text(
        '$label ${percentage.toStringAsFixed(0)}%',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}
