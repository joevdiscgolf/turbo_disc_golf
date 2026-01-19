import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/components/indicators/circular_stat_indicator.dart';

/// Compact driving stats card showing 4 key metrics in a 2x2 grid
///
/// Displays:
/// - C1 in Reg (teal)
/// - Fairway (green)
/// - OB (red)
/// - Parked (orange)
class DrivingStatsCard extends StatefulWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const DrivingStatsCard({super.key, required this.round, this.onTap});

  @override
  State<DrivingStatsCard> createState() => _DrivingStatsCardState();
}

class _DrivingStatsCardState extends State<DrivingStatsCard>
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

    return Card(
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🎯 Driving',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCircularIndicator(
                        key: ValueKey('driving_c1_in_reg_${widget.round.id}'),
                        heroTag: 'driving_c1_in_reg',
                        label: 'C1 in Reg',
                        percentage: hasData
                            ? stats['c1InRegPct'] as double
                            : 0.0,
                        color: const Color(0xFF137e66),
                      ),
                      const SizedBox(width: 8),
                      _buildCircularIndicator(
                        key: ValueKey('driving_fairway_${widget.round.id}'),
                        heroTag: 'driving_fairway',
                        label: 'Fairway',
                        percentage: hasData
                            ? stats['fairwayPct'] as double
                            : 0.0,
                        color: const Color(0xFF4CAF50),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCircularIndicator(
                        key: ValueKey('driving_ob_${widget.round.id}'),
                        heroTag: 'driving_ob',
                        label: 'OB',
                        percentage: hasData ? stats['obPct'] as double : 0.0,
                        color: const Color(0xFFFF7A7A),
                      ),
                      const SizedBox(width: 8),
                      _buildCircularIndicator(
                        key: ValueKey('driving_parked_${widget.round.id}'),
                        heroTag: 'driving_parked',
                        label: 'Parked',
                        percentage: hasData
                            ? stats['parkedPct'] as double
                            : 0.0,
                        color: const Color(0xFFFFA726),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularIndicator({
    required ValueKey<String> key,
    required String heroTag,
    required String label,
    required double percentage,
    required Color color,
  }) {
    final CircularStatIndicator indicator = CircularStatIndicator(
      key: key,
      label: label,
      percentage: percentage,
      color: color,
      size: 68,
      labelFontSize: 9,
      labelSpacing: 4,
      shouldAnimate: true,
      shouldGlow: true,
      roundId: widget.round.id,
    );

    if (locator.get<FeatureFlagService>().useHeroAnimationsForRoundReview) {
      return Hero(tag: heroTag, child: indicator);
    }

    return indicator;
  }
}
