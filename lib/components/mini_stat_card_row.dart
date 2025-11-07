import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/widgets/circular_stat_indicator.dart';

/// Configuration for a single stat in the row
class MiniStat {
  final String label;
  final double percentage;
  final Color color;

  const MiniStat({
    required this.label,
    required this.percentage,
    required this.color,
  });
}

/// Compact row of circular stat indicators for story tab
class MiniStatCardRow extends StatelessWidget {
  final List<MiniStat> stats;
  final String? roundId;
  final EdgeInsets? padding;

  const MiniStatCardRow({
    super.key,
    required this.stats,
    this.roundId,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Show max 3 stats to avoid overcrowding
    final List<MiniStat> displayStats = stats.take(3).toList();

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: displayStats.map((stat) {
          return CircularStatIndicator(
            label: stat.label,
            percentage: stat.percentage,
            color: stat.color,
            size: 70,
            labelFontSize: 10,
            labelSpacing: 4,
            shouldAnimate: true,
            shouldGlow: true,
            roundId: roundId,
          );
        }).toList(),
      ),
    );
  }
}
