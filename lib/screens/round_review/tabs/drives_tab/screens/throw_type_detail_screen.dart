import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/models/shot_detail.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/models/throw_type_stats.dart';

/// Detail screen showing shot shape breakdown for a specific throw type
class ThrowTypeDetailScreen extends StatefulWidget {
  const ThrowTypeDetailScreen({
    super.key,
    required this.throwType,
    required this.overallStats,
    required this.shotShapeStats,
    required this.overallShotDetails,
    required this.shotShapeDetails,
  });

  final String throwType;
  final ThrowTypeStats overallStats;
  final List<ShotShapeStats> shotShapeStats;
  final List<ShotDetail> overallShotDetails;
  final Map<String, List<ShotDetail>> shotShapeDetails;

  @override
  State<ThrowTypeDetailScreen> createState() => _ThrowTypeDetailScreenState();
}

class _ThrowTypeDetailScreenState extends State<ThrowTypeDetailScreen> {
  bool _isOverallExpanded = false;
  final Map<String, bool> _shotShapeExpanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.overallStats.displayName),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: 16),
          if (widget.shotShapeStats.isNotEmpty) ...[
            _buildSectionTitle(context, 'Shot Shape Breakdown'),
            const SizedBox(height: 12),
            ...widget.shotShapeStats.map((shape) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ShotShapeCard(
                    shape: shape,
                    shotDetails: widget.shotShapeDetails[shape.shapeName] ?? [],
                    isExpanded: _shotShapeExpanded[shape.shapeName] ?? false,
                    onToggleExpand: () {
                      setState(() {
                        _shotShapeExpanded[shape.shapeName] =
                            !(_shotShapeExpanded[shape.shapeName] ?? false);
                      });
                    },
                  ),
                )),
          ] else
            _buildEmptyState(context),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isOverallExpanded = !_isOverallExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.disc_full,
                  size: 28,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Performance',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.overallStats.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              if (widget.overallStats.averageDistance != null) ...[
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
                        widget.overallStats.distanceDisplay,
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
              Icon(
                _isOverallExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: const Color(0xFF6B7280),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StatPill(
            icon: Icons.emoji_events_outlined,
            label: 'Birdie Rate',
            value: '${widget.overallStats.birdieRate.toStringAsFixed(0)}%',
            detail: '${widget.overallStats.birdieCount}/${widget.overallStats.totalHoles} holes',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _StatPill(
            icon: Icons.my_location_outlined,
            label: 'C1 in Reg',
            value: '${widget.overallStats.c1InRegPct.toStringAsFixed(0)}%',
            detail: '${widget.overallStats.c1Count}/${widget.overallStats.c1Total} attempts',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _StatPill(
            icon: Icons.adjust,
            label: 'C2 in Reg',
            value: '${widget.overallStats.c2InRegPct.toStringAsFixed(0)}%',
            detail: '${widget.overallStats.c2Count}/${widget.overallStats.c2Total} attempts',
            color: const Color(0xFF8B5CF6),
          ),
          if (_isOverallExpanded) ...[
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            _buildShotDetailsList(widget.overallShotDetails),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildShotDetailsList(List<ShotDetail> shotDetails) {
    if (shotDetails.isEmpty) {
      return Text(
        'No shots found',
        style: TextStyle(
          fontSize: 13,
          color: const Color(0xFF6B7280),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: shotDetails.map((detail) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _getScoreColor(detail.relativeScore).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${detail.holeNumber}',
                    style: TextStyle(
                      color: _getScoreColor(detail.relativeScore),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Par ${detail.par}${detail.distance != null ? ' • ${detail.distance} ft' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              if (detail.shotOutcome.wasBirdie)
                _OutcomeBadge(
                  icon: Icons.emoji_events,
                  color: const Color(0xFF10B981),
                ),
              if (detail.shotOutcome.wasC1InReg)
                _OutcomeBadge(
                  icon: Icons.my_location,
                  color: const Color(0xFF3B82F6),
                ),
              if (detail.shotOutcome.wasC2InReg)
                _OutcomeBadge(
                  icon: Icons.adjust,
                  color: const Color(0xFF8B5CF6),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getScoreColor(int relativeScore) {
    if (relativeScore < 0) return const Color(0xFF10B981); // Birdie/Eagle - Green
    if (relativeScore == 0) return const Color(0xFF6B7280); // Par - Gray
    if (relativeScore == 1) return const Color(0xFFFB923C); // Bogey - Orange
    return const Color(0xFFEF4444); // Double+ - Red
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.insights_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No shot shape data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat pill display for header card
class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Extract percentage value from the value string
    final double percentage = double.tryParse(value.replaceAll('%', '')) ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: const Color(0xFF374151),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card showing individual shot shape stats
class _ShotShapeCard extends StatelessWidget {
  const _ShotShapeCard({
    required this.shape,
    required this.shotDetails,
    required this.isExpanded,
    required this.onToggleExpand,
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
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
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
          _MetricRow(
            icon: Icons.emoji_events_outlined,
            label: 'Birdie Rate',
            percentage: shape.birdieRate,
            count: shape.birdieCount,
            total: shape.totalAttempts,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            icon: Icons.my_location_outlined,
            label: 'C1 in Reg',
            percentage: shape.c1InRegPct,
            count: shape.c1Count,
            total: shape.c1Total,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            icon: Icons.adjust,
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
            _ShotShapeDetailsList(shotDetails: shotDetails),
          ],
        ],
      ),
      ),
    );
  }
}

/// Metric row with icon, label, progress bar, and percentage
class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.percentage,
    required this.count,
    required this.total,
    required this.color,
  });

  final IconData icon;
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
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
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

/// Widget showing the list of shots for a specific shot shape
class _ShotShapeDetailsList extends StatelessWidget {
  const _ShotShapeDetailsList({required this.shotDetails});

  final List<ShotDetail> shotDetails;

  @override
  Widget build(BuildContext context) {
    if (shotDetails.isEmpty) {
      return Text(
        'No shots found',
        style: TextStyle(
          fontSize: 13,
          color: const Color(0xFF6B7280),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: shotDetails.map((detail) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _getScoreColor(detail.relativeScore).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${detail.holeNumber}',
                    style: TextStyle(
                      color: _getScoreColor(detail.relativeScore),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Par ${detail.par}${detail.distance != null ? ' • ${detail.distance} ft' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              if (detail.shotOutcome.wasBirdie)
                _OutcomeBadge(
                  icon: Icons.emoji_events,
                  color: const Color(0xFF10B981),
                ),
              if (detail.shotOutcome.wasC1InReg)
                _OutcomeBadge(
                  icon: Icons.my_location,
                  color: const Color(0xFF3B82F6),
                ),
              if (detail.shotOutcome.wasC2InReg)
                _OutcomeBadge(
                  icon: Icons.adjust,
                  color: const Color(0xFF8B5CF6),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getScoreColor(int relativeScore) {
    if (relativeScore < 0) return const Color(0xFF10B981); // Birdie/Eagle - Green
    if (relativeScore == 0) return const Color(0xFF6B7280); // Par - Gray
    if (relativeScore == 1) return const Color(0xFFFB923C); // Bogey - Orange
    return const Color(0xFFEF4444); // Double+ - Red
  }
}

/// Small badge showing an outcome icon
class _OutcomeBadge extends StatelessWidget {
  const _OutcomeBadge({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: color,
        ),
      ),
    );
  }
}
