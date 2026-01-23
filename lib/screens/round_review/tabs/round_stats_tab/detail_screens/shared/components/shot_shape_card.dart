import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/shot_detail.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/components/metric_row.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/components/shot_details_list.dart';

/// A unified stats card that calculates and displays metrics from shot details.
/// Can be used for both overall throw type stats and individual shot shape stats.
class ThrowStatsCard extends StatelessWidget {
  const ThrowStatsCard({
    required this.title,
    required this.shotDetails,
    this.averageDistance,
    required this.isExpanded,
    required this.animationController,
    required this.onToggleExpand,
    this.showThrowTechnique = true,
    this.useLandingSpotAbbreviations = true,
    super.key,
  });

  final String title;
  final List<ShotDetail> shotDetails;
  final int? averageDistance;
  final bool isExpanded;
  final AnimationController animationController;
  final VoidCallback onToggleExpand;
  final bool showThrowTechnique;
  final bool useLandingSpotAbbreviations;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onToggleExpand();
      },
      behavior: HitTestBehavior.opaque,
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildMetrics(context),
            ClipRect(
              child: SizeTransition(
                axisAlignment: -1,
                sizeFactor: animationController,
                child: _buildThrowsList(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          if (averageDistance != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$averageDistance ft avg',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetrics(BuildContext context) {
    // Calculate stats from shotDetails
    final int total = shotDetails.length;

    // C1 in Reg
    final int c1Count = shotDetails.where((s) => s.shotOutcome.wasC1InReg).length;
    final double c1Pct = total > 0 ? (c1Count / total) * 100 : 0;

    // Parked
    final int parkedCount = shotDetails.where((s) =>
      s.discThrow.landingSpot == LandingSpot.parked).length;
    final double parkedPct = total > 0 ? (parkedCount / total) * 100 : 0;

    // OB
    final int obCount = shotDetails.where((s) =>
      s.discThrow.landingSpot == LandingSpot.outOfBounds).length;
    final double obPct = total > 0 ? (obCount / total) * 100 : 0;

    // Birdie Rate
    final int birdieCount = shotDetails.where((s) => s.shotOutcome.wasBirdie).length;
    final double birdieRate = total > 0 ? (birdieCount / total) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetricRow(
            label: 'C1 in Reg',
            percentage: c1Pct,
            count: c1Count,
            total: total,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 8),
          MetricRow(
            label: 'Parked',
            percentage: parkedPct,
            count: parkedCount,
            total: total,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 8),
          MetricRow(
            label: 'OB',
            percentage: obPct,
            count: obCount,
            total: total,
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 8),
          MetricRow(
            label: 'Birdie Rate',
            percentage: birdieRate,
            count: birdieCount,
            total: total,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildViewAllLabel(context),
        ],
      ),
    );
  }

  Widget _buildViewAllLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            'View all',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThrowsList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          ShotDetailsList(
            shotDetails: shotDetails,
            showThrowTechnique: showThrowTechnique,
            useLandingSpotAbbreviations: useLandingSpotAbbreviations,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Legacy alias - kept for backwards compatibility during migration
/// @deprecated Use ThrowStatsCard instead
typedef ShotShapeCard = ThrowStatsCard;
