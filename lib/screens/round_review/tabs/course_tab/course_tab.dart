import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/components/holes_grid.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/components/score_kpi_card.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

class CourseTab extends StatefulWidget {
  final DGRound round;

  const CourseTab({super.key, required this.round});

  @override
  State<CourseTab> createState() => _CourseTabState();
}

class _CourseTabState extends State<CourseTab> {
  late DGRound _round;
  late RoundParser _roundParser;

  @override
  void initState() {
    super.initState();
    _round = widget.round;
    _roundParser = locator.get<RoundParser>();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = _getListViewChildren();
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  List<Widget> _getListViewChildren() {
    return [
      ScoreKPICard(
        round: _round,
        roundParser: _roundParser,
        isDetailScreen: true,
      ),
      const SizedBox(height: 8),
      HolesGrid(round: _round),
      // HolesList(round: _round, showAddThrowDialog: _showAddThrowDialog),
    ];
  }
}
