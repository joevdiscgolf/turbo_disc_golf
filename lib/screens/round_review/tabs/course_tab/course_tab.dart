import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/components/holes_grid.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/components/score_kpi_card.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';

class CourseTab extends StatefulWidget {
  final DGRound round;
  final void Function(DGRound updatedRound)? onRoundUpdated;

  const CourseTab({super.key, required this.round, this.onRoundUpdated});

  @override
  State<CourseTab> createState() => _CourseTabState();
}

class _CourseTabState extends State<CourseTab> {
  late DGRound _round;
  late RoundStorageService _roundStorageService;

  @override
  void initState() {
    super.initState();
    _round = widget.round;
    _roundStorageService = RoundStorageService();
  }

  void _handleRoundUpdated(DGRound updatedRound) {
    setState(() {
      _round = updatedRound;
    });

    // Save to storage
    _roundStorageService.saveRound(updatedRound);

    // Notify parent if callback is provided
    widget.onRoundUpdated?.call(updatedRound);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = _getListViewChildren(context);
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  List<Widget> _getListViewChildren(BuildContext context) {
    return [
      ScoreKPICard(round: _round, isDetailScreen: true),
      const SizedBox(height: 8),
      HolesGrid(round: _round, onRoundUpdated: _handleRoundUpdated),
      // HolesList(round: _round, showAddThrowDialog: _showAddThrowDialog),
    ];
  }
}
