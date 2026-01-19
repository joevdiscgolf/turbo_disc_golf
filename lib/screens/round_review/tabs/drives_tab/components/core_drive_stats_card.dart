import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/components/indicators/circular_stat_indicator.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            useHeroAnimationsForRoundReview
                ? Hero(
                    tag: 'driving_c1_in_reg',
                    child: CircularStatIndicator(
                      label: 'C1 in Reg',
                      percentage: widget.coreStats.c1InRegPct,
                      color: const Color(0xFF137e66),
                      size: 70,
                      shouldAnimate: true,
                      shouldGlow: true,
                      onPressed: widget.onC1InRegPressed,
                    ),
                  )
                : CircularStatIndicator(
                    label: 'C1 in Reg',
                    percentage: widget.coreStats.c1InRegPct,
                    color: const Color(0xFF137e66),
                    size: 70,
                    shouldAnimate: true,
                    shouldGlow: true,
                    onPressed: widget.onC1InRegPressed,
                  ),
            // Temporarily hidden - C2 in Reg will be shown in detail views
            // CircularStatIndicator(
            //   label: 'C2 in Reg',
            //   percentage: widget.coreStats.c2InRegPct,
            //   color: const Color.fromARGB(255, 13, 21, 28),
            //   size: 70,
            //   shouldAnimate: true,
            //   shouldGlow: true,
            //   onPressed: widget.onC2InRegPressed,
            // ),
            useHeroAnimationsForRoundReview
                ? Hero(
                    tag: 'driving_fairway',
                    child: CircularStatIndicator(
                      label: 'Fairway',
                      percentage: widget.coreStats.fairwayHitPct,
                      color: const Color(0xFF4CAF50),
                      size: 70,
                      shouldAnimate: true,
                      shouldGlow: true,
                      onPressed: widget.onFairwayPressed,
                    ),
                  )
                : CircularStatIndicator(
                    label: 'Fairway',
                    percentage: widget.coreStats.fairwayHitPct,
                    color: const Color(0xFF4CAF50),
                    size: 70,
                    shouldAnimate: true,
                    shouldGlow: true,
                    onPressed: widget.onFairwayPressed,
                  ),
            useHeroAnimationsForRoundReview
                ? Hero(
                    tag: 'driving_ob',
                    child: CircularStatIndicator(
                      label: 'OB',
                      percentage: widget.coreStats.obPct,
                      color: const Color(0xFFFF7A7A),
                      size: 70,
                      shouldAnimate: true,
                      shouldGlow: true,
                      onPressed: widget.onOBPressed,
                    ),
                  )
                : CircularStatIndicator(
                    label: 'OB',
                    percentage: widget.coreStats.obPct,
                    color: const Color(0xFFFF7A7A),
                    size: 70,
                    shouldAnimate: true,
                    shouldGlow: true,
                    onPressed: widget.onOBPressed,
                  ),
            useHeroAnimationsForRoundReview
                ? Hero(
                    tag: 'driving_parked',
                    child: CircularStatIndicator(
                      label: 'Parked',
                      percentage: widget.coreStats.parkedPct,
                      color: const Color(0xFFFFA726),
                      size: 70,
                      shouldAnimate: true,
                      shouldGlow: true,
                      onPressed: widget.onParkedPressed,
                    ),
                  )
                : CircularStatIndicator(
                    label: 'Parked',
                    percentage: widget.coreStats.parkedPct,
                    color: const Color(0xFFFFA726),
                    size: 70,
                    shouldAnimate: true,
                    shouldGlow: true,
                    onPressed: widget.onParkedPressed,
                  ),
          ],
        ),
      ),
    );
  }
}
