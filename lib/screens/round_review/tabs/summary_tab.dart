import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';

class SummaryTab extends StatelessWidget {
  final DGRound round;

  const SummaryTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Summary Tab'),
    );
  }
}
