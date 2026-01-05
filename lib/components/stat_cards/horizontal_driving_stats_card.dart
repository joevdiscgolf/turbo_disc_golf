import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/widgets/circular_stat_indicator.dart';

/// Compact horizontal driving stats card showing 4 key metrics in a single row
///
/// Optimized for story tab with horizontal layout to better utilize space.
/// Displays:
/// - C1 in Reg (teal)
/// - Fairway (green)
/// - OB (red)
/// - Parked (orange)
class HorizontalDrivingStatsCard extends StatefulWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const HorizontalDrivingStatsCard({
    super.key,
    required this.round,
    this.onTap,
  });

  @override
  State<HorizontalDrivingStatsCard> createState() =>
      _HorizontalDrivingStatsCardState();
}

class _HorizontalDrivingStatsCardState
    extends State<HorizontalDrivingStatsCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic> _calculateDrivingStats() {
    final RoundStatisticsService statsService = RoundStatisticsService(
      widget.round,
    );
    final dynamic coreStats = statsService.getCoreStats();

    return {
      'fairwayPct': coreStats.fairwayHitPct,
      'c1InRegPct': coreStats.c1InRegPct,
      'obPct': coreStats.obPct,
      'parkedPct': coreStats.parkedPct,
      'hasData': widget.round.holes.isNotEmpty,
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Map<String, dynamic> stats = _calculateDrivingStats();
    final bool hasData = stats['hasData'] as bool;

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCircularIndicator(
              key: ValueKey('horizontal_driving_c1_in_reg_${widget.round.id}'),
              label: 'C1 in Reg',
              percentage: hasData ? stats['c1InRegPct'] as double : 0.0,
              color: const Color(0xFF137e66),
            ),
            _buildCircularIndicator(
              key: ValueKey('horizontal_driving_fairway_${widget.round.id}'),
              label: 'Fairway',
              percentage: hasData ? stats['fairwayPct'] as double : 0.0,
              color: const Color(0xFF4CAF50),
            ),
            _buildCircularIndicator(
              key: ValueKey('horizontal_driving_ob_${widget.round.id}'),
              label: 'OB',
              percentage: hasData ? stats['obPct'] as double : 0.0,
              color: const Color(0xFFFF7A7A),
            ),
            _buildCircularIndicator(
              key: ValueKey('horizontal_driving_parked_${widget.round.id}'),
              label: 'Parked',
              percentage: hasData ? stats['parkedPct'] as double : 0.0,
              color: const Color(0xFFFFA726),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularIndicator({
    required ValueKey<String> key,
    required String label,
    required double percentage,
    required Color color,
  }) {
    return CircularStatIndicator(
      key: key,
      label: label,
      percentage: percentage,
      color: color,
      size: 56,
      labelFontSize: 9,
      labelSpacing: 4,
      shouldAnimate: true,
      shouldGlow: true,
      roundId: widget.round.id,
    );
  }
}
