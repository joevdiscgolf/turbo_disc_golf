import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';

/// Single-stat widget showing Out of Bounds rate
///
/// Displays percentage of throws that went OB in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight penalty avoidance and course management.
class OBRateStoryCard extends StatelessWidget {
  const OBRateStoryCard({
    super.key,
    required this.round,
    required this.renderMode,
    this.showIcon = true,
  });

  final DGRound round;
  final StatRenderMode renderMode;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    // Calculate OB rate based on throws, not holes
    int totalThrows = 0;
    int obThrows = 0;

    for (final hole in round.holes) {
      for (final discThrow in hole.throws) {
        totalThrows++;
        if (discThrow.landingSpot == LandingSpot.outOfBounds) {
          obThrows++;
        }
      }
    }

    final double percentage =
        totalThrows > 0 ? (obThrows / totalThrows) * 100 : 0.0;
    final int count = obThrows;
    final int total = totalThrows;

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'Out of Bounds',
        color: const Color(0xFFFF7A7A),
        icon: Icons.warning_rounded,
        count: count,
        total: total,
        roundId: round.id,
        showIcon: showIcon,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'Out of Bounds',
        color: const Color(0xFFFF7A7A),
        icon: Icons.warning_rounded,
        count: count,
        total: total,
        useColorForHeading: true,
        showIcon: showIcon,
        showContainer: false,
      );
    }
  }
}
