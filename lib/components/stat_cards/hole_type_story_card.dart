import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Compact hole type performance card for story context
/// Shows scoring average and birdie rate for a specific hole type (Par 3, 4, 5)
class HoleTypeStoryCard extends StatelessWidget {
  const HoleTypeStoryCard({
    super.key,
    required this.holeType,
    required this.round,
  });

  final String holeType; // "Par 3", "Par 4", "Par 5"
  final DGRound round;

  @override
  Widget build(BuildContext context) {
    // Extract par number from hole type string
    final int? par = _extractParNumber(holeType);

    if (par == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SenseiColors.gray[100]!),
        ),
        child: Text(
          'Invalid hole type: $holeType',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final RoundAnalysis analysis = RoundAnalysisGenerator.generateAnalysis(
      round,
    );

    // Calculate stats for this hole type
    final List<DGHole> holes = round.holes
        .where((hole) => hole.par == par)
        .toList();

    if (holes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SenseiColors.gray[100]!),
        ),
        child: Text(
          'No $holeType holes in this round',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    // Calculate scoring average relative to par
    final int totalScore = holes.fold<int>(
      0,
      (sum, hole) => sum + hole.holeScore,
    );
    final int totalPar = holes.length * par;
    final double avgRelative = (totalScore - totalPar) / holes.length;

    // Get birdie rate
    final double birdieRate = analysis.birdieRateByPar[par] ?? 0.0;

    // Count birdies and better
    final int birdies = holes
        .where((hole) => hole.relativeHoleScore < 0)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SenseiColors.gray[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.golf_course, size: 20, color: SenseiColors.gray[500]),
              const SizedBox(width: 8),
              Text(
                holeType,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SenseiColors.gray[500],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SenseiColors.gray[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${holes.length} holes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: SenseiColors.gray[500],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Birdie Rate',
                  value: '${birdieRate.toStringAsFixed(0)}%',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Avg Score',
                  value: _formatAvgRelative(avgRelative),
                  color: _getScoreColor(avgRelative),
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Birdies',
                  value: '$birdies/${holes.length}',
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int? _extractParNumber(String holeType) {
    // Extract number from "Par 3", "Par 4", "Par 5"
    final RegExp regex = RegExp(r'Par (\d)');
    final Match? match = regex.firstMatch(holeType);
    if (match != null && match.groupCount > 0) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  Color _getScoreColor(double avgRelative) {
    if (avgRelative <= -1) return const Color(0xFF9C27B0); // Purple (great)
    if (avgRelative < 0) return const Color(0xFF4CAF50); // Green (good)
    if (avgRelative == 0) return const Color(0xFF2196F3); // Blue (par)
    if (avgRelative <= 0.5) return const Color(0xFFFFB800); // Yellow (okay)
    return const Color(0xFFFF7A7A); // Red (poor)
  }

  String _formatAvgRelative(double avgRelative) {
    if (avgRelative > 0) {
      return '+${avgRelative.toStringAsFixed(2)}';
    } else if (avgRelative == 0) {
      return 'E';
    } else {
      return avgRelative.toStringAsFixed(2);
    }
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
