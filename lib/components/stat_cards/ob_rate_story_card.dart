import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/round_story_v2_content.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';

/// Single-stat widget showing Out of Bounds rate
///
/// Displays percentage of throws that went OB in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight penalty avoidance and course management.
///
/// When [scopedStats] is provided, displays those values instead of
/// whole-round stats, useful for showing stats for a specific hole range.
class OBRateStoryCard extends StatelessWidget {
  const OBRateStoryCard({
    super.key,
    required this.round,
    required this.renderMode,
    this.showIcon = true,
    this.scopedStats,
  });

  final DGRound round;
  final StatRenderMode renderMode;
  final bool showIcon;
  final ScopedStats? scopedStats;

  @override
  Widget build(BuildContext context) {
    // Use scoped stats if provided, otherwise compute from full round
    final double percentage;
    final int count;
    final int total;
    final String? scopeLabel;

    if (scopedStats != null && scopedStats!.percentage != null) {
      percentage = scopedStats!.percentage!;
      count = scopedStats!.made ?? 0;
      total = scopedStats!.attempts ?? 0;
      scopeLabel = scopedStats!.holeRange?.displayString;
    } else {
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

      percentage = totalThrows > 0 ? (obThrows / totalThrows) * 100 : 0.0;
      count = obThrows;
      total = totalThrows;
      scopeLabel = null;
    }

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
        subtitle: scopeLabel,
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
        subtitle: scopeLabel,
      );
    }
  }
}
