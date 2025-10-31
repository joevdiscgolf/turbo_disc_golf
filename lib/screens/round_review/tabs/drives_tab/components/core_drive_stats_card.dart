import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/widgets/circular_stat_indicator.dart';

class CoreDriveStatsCard extends StatefulWidget {
  final dynamic coreStats;
  final Function()? onC1InRegPressed;
  final Function()? onC2InRegPressed;
  final Function()? onFairwayPressed;
  final Function()? onOBPressed;
  final Function()? onParkedPressed;

  const CoreDriveStatsCard({
    super.key,
    required this.coreStats,
    this.onC1InRegPressed,
    this.onC2InRegPressed,
    this.onFairwayPressed,
    this.onOBPressed,
    this.onParkedPressed,
  });

  @override
  State<CoreDriveStatsCard> createState() => _CoreDriveStatsCardState();
}

class _CoreDriveStatsCardState extends State<CoreDriveStatsCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircularStatIndicator(
                  label: 'C1 in Reg',
                  percentage: widget.coreStats.c1InRegPct,
                  color: const Color(0xFF137e66),
                  shouldAnimate: true,
                  shouldGlow: true,
                  onPressed: widget.onC1InRegPressed,
                ),
                CircularStatIndicator(
                  label: 'C2 in Reg',
                  percentage: widget.coreStats.c2InRegPct,
                  color: const Color.fromARGB(255, 13, 21, 28),
                  shouldAnimate: true,
                  shouldGlow: true,
                  onPressed: widget.onC2InRegPressed,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircularStatIndicator(
                  label: 'Fairway',
                  percentage: widget.coreStats.fairwayHitPct,
                  color: const Color(0xFF4CAF50),
                  size: 80,
                  shouldAnimate: true,
                  shouldGlow: true,
                  onPressed: widget.onFairwayPressed,
                ),
                CircularStatIndicator(
                  label: 'OB',
                  percentage: widget.coreStats.obPct,
                  color: const Color(0xFFFF7A7A),
                  size: 80,
                  shouldAnimate: true,
                  shouldGlow: true,
                  onPressed: widget.onOBPressed,
                ),
                CircularStatIndicator(
                  label: 'Parked',
                  percentage: widget.coreStats.parkedPct,
                  color: const Color(0xFFFFA726),
                  size: 80,
                  shouldAnimate: true,
                  shouldGlow: true,
                  onPressed: widget.onParkedPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
