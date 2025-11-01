import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/throws_tab/components/hole_list_item.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class HolesList extends StatelessWidget {
  const HolesList({
    super.key,
    required this.round,
    required this.showAddThrowDialog,
  });

  final DGRound round;
  final Function showAddThrowDialog;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: addDividers(
          round.holes
              .mapIndexed(
                (index, hole) => HoleListItem(
                  hole: hole,
                  showAddThrowDialog: () {
                    showAddThrowDialog();
                  },
                  isFirst: index == 0,
                  isLast: index == round.holes.length - 1,
                ),
              )
              .toList(),
          horizontalPadding: 16,
          height: 0.5,
        ),
      ),
    );
  }
}
