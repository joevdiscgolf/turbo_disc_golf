import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/components/throw_type_card.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class ThrowTypeListCard extends StatelessWidget {
  const ThrowTypeListCard({
    super.key,
    required this.throwTypes,
    required this.onThrowTypeTap,
  });

  final List<ThrowTypeStats> throwTypes;
  final Function(ThrowTypeStats) onThrowTypeTap;

  @override
  Widget build(BuildContext context) {
    if (throwTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: addRunSpacing(
        throwTypes.map((throwType) {
          return ThrowTypeCard(
            throwType: throwType,
            onTap: () => onThrowTypeTap(throwType),
          );
        }).toList(),
        runSpacing: 8,
        axis: Axis.vertical,
      ),
    );
  }
}
