import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/constants/putting_constants.dart';
import 'package:turbo_disc_golf/widgets/circular_stat_indicator.dart';

/// Compact horizontal putting stats card showing 3 putting zones in a single row
///
/// Optimized for story tab with horizontal layout to better utilize space.
/// Displays:
/// - C1 (0-33 feet) - teal
/// - C1X (11-33 feet) - green
/// - C2 (33-66 feet) - blue
class HorizontalPuttingStatsCard extends StatefulWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const HorizontalPuttingStatsCard({
    super.key,
    required this.round,
    this.onTap,
  });

  @override
  State<HorizontalPuttingStatsCard> createState() =>
      _HorizontalPuttingStatsCardState();
}

class _HorizontalPuttingStatsCardState
    extends State<HorizontalPuttingStatsCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic> _calculatePuttingStats() {
    int c1Attempts = 0;
    int c1Makes = 0;
    int c1xAttempts = 0;
    int c1xMakes = 0;
    int c2Attempts = 0;
    int c2Makes = 0;

    for (final DGHole hole in widget.round.holes) {
      for (final DiscThrow discThrow in hole.throws) {
        if (discThrow.purpose == ThrowPurpose.putt) {
          final double? distance = discThrow.distanceFeetBeforeThrow
              ?.toDouble();
          final bool made = discThrow.landingSpot == LandingSpot.inBasket;

          if (distance != null) {
            if (distance >= c1MinDistance && distance <= c1MaxDistance) {
              c1Attempts++;
              if (made) c1Makes++;
            }

            if (distance >= c1xMinDistance && distance <= c1xMaxDistance) {
              c1xAttempts++;
              if (made) c1xMakes++;
            }

            if (distance > c2MinDistance && distance <= c2MaxDistance) {
              c2Attempts++;
              if (made) c2Makes++;
            }
          }
        }
      }
    }

    final double c1Pct = c1Attempts > 0 ? (c1Makes / c1Attempts * 100) : 0;
    final double c1xPct = c1xAttempts > 0 ? (c1xMakes / c1xAttempts * 100) : 0;
    final double c2Pct = c2Attempts > 0 ? (c2Makes / c2Attempts * 100) : 0;

    return {
      'c1Pct': c1Pct,
      'c1xPct': c1xPct,
      'c2Pct': c2Pct,
      'hasData': c1Attempts > 0 || c1xAttempts > 0 || c2Attempts > 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Map<String, dynamic> stats = _calculatePuttingStats();
    final bool hasData = stats['hasData'] as bool;

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCircularIndicator(
              key: ValueKey('horizontal_putting_c1_${widget.round.id}'),
              label: 'C1',
              percentage: hasData ? stats['c1Pct'] as double : 0.0,
              color: const Color(0xFF137e66),
            ),
            _buildCircularIndicator(
              key: ValueKey('horizontal_putting_c1x_${widget.round.id}'),
              label: 'C1X',
              percentage: hasData ? stats['c1xPct'] as double : 0.0,
              color: const Color(0xFF4CAF50),
            ),
            _buildCircularIndicator(
              key: ValueKey('horizontal_putting_c2_${widget.round.id}'),
              label: 'C2',
              percentage: hasData ? stats['c2Pct'] as double : 0.0,
              color: const Color(0xFF2196F3),
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
