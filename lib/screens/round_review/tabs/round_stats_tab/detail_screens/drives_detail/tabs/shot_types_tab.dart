import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/components/throw_type_list_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/components/throw_type_radar_chart.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Tab widget for displaying shot type (throw technique) statistics
class ShotTypesTab extends StatelessWidget {
  const ShotTypesTab({
    super.key,
    required this.allThrowTypes,
    required this.shotShapeBirdieRates,
    required this.circleInRegByShape,
    required this.onThrowTypeTap,
  });

  final List<ThrowTypeStats> allThrowTypes;
  final Map<String, dynamic> shotShapeBirdieRates;
  final Map<String, Map<String, double>> circleInRegByShape;
  final Function(ThrowTypeStats) onThrowTypeTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
      children: addRunSpacing(
        [
          ThrowTypeRadarChart.buildLegendCard(context, allThrowTypes),
          ThrowTypeRadarChart(throwTypes: allThrowTypes),
          ThrowTypeListCard(
            throwTypes: allThrowTypes,
            onThrowTypeTap: onThrowTypeTap,
          ),
        ],
        runSpacing: 8,
        axis: Axis.vertical,
      ),
    );
  }
}
