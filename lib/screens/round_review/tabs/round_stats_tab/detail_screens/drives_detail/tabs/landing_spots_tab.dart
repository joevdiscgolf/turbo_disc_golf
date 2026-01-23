import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/components/core_drive_stats_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/components/landing_spot_distribution_card.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Tab widget for displaying landing spot statistics
class LandingSpotsTab extends StatelessWidget {
  const LandingSpotsTab({
    super.key,
    required this.coreStats,
    required this.landingSpotDistributionByPar,
    required this.onC1InRegPressed,
    required this.onC2InRegPressed,
    required this.onFairwayPressed,
    required this.onOBPressed,
    required this.onParkedPressed,
  });

  final CoreStats coreStats;
  final Map<int, Map<String, Map<String, dynamic>>> landingSpotDistributionByPar;
  final VoidCallback onC1InRegPressed;
  final VoidCallback onC2InRegPressed;
  final VoidCallback onFairwayPressed;
  final VoidCallback onOBPressed;
  final VoidCallback onParkedPressed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
      children: addRunSpacing(
        [
          CoreDriveStatsCard(
            coreStats: coreStats,
            onC1InRegPressed: onC1InRegPressed,
            onC2InRegPressed: onC2InRegPressed,
            onFairwayPressed: onFairwayPressed,
            onOBPressed: onOBPressed,
            onParkedPressed: onParkedPressed,
          ),
          LandingSpotDistributionCard(
            landingSpotDistributionByPar: landingSpotDistributionByPar,
          ),
        ],
        runSpacing: 8,
        axis: Axis.vertical,
      ),
    );
  }
}
