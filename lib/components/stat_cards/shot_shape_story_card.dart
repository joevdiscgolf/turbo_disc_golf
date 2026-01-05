import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';

/// Compact shot shape breakdown card for story context
/// Shows top-performing shot shapes with birdie rate and C1 in reg %
class ShotShapeStoryCard extends StatelessWidget {
  const ShotShapeStoryCard({super.key, required this.round});

  final DGRound round;

  @override
  Widget build(BuildContext context) {
    final RoundStatisticsService statsService = RoundStatisticsService(round);
    final Map<String, dynamic> shotShapeBirdieRates =
        statsService.getShotShapeByTechniqueBirdieRateStats();
    final Map<String, Map<String, double>> circleInRegByShape =
        statsService.getCircleInRegByShotShapeAndTechnique();

    // Get all shot shape stats
    final List<ShotShapeStats> allShapes =
        _getShotShapeStats(shotShapeBirdieRates, circleInRegByShape);

    // Take top 3 by birdie rate
    final List<ShotShapeStats> topShapes = allShapes.take(3).toList();

    if (topShapes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          'Not enough data for shot shape analysis',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Shot Shapes',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          ...topShapes.map(
            (shape) => Padding(
              padding: EdgeInsets.only(
                bottom: shape != topShapes.last ? 12 : 0,
              ),
              child: _ShotShapeRow(shape: shape),
            ),
          ),
        ],
      ),
    );
  }

  List<ShotShapeStats> _getShotShapeStats(
    Map<String, dynamic> shotShapeBirdieRates,
    Map<String, Map<String, double>> circleInRegByShape,
  ) {
    final List<ShotShapeStats> stats = [];

    for (final entry in shotShapeBirdieRates.entries) {
      final String shapeName = entry.key;
      final dynamic birdieData = entry.value;
      final Map<String, double>? c1c2Data = circleInRegByShape[shapeName];

      // Determine throw type from shape name
      String throwType = 'backhand';
      if (shapeName.toLowerCase().startsWith('forehand')) {
        throwType = 'forehand';
      }

      if (birdieData != null && c1c2Data != null) {
        stats.add(
          ShotShapeStats(
            shapeName: shapeName,
            throwType: throwType,
            birdieRate: birdieData.percentage,
            birdieCount: birdieData.birdieCount,
            totalAttempts: birdieData.totalAttempts,
            c1InRegPct: c1c2Data['c1Percentage'] ?? 0,
            c1Count: (c1c2Data['c1Count'] ?? 0).toInt(),
            c1Total: (c1c2Data['totalAttempts'] ?? 0).toInt(),
            c2InRegPct: c1c2Data['c2Percentage'] ?? 0,
            c2Count: (c1c2Data['c2Count'] ?? 0).toInt(),
            c2Total: (c1c2Data['totalAttempts'] ?? 0).toInt(),
          ),
        );
      }
    }

    // Sort by birdie rate descending
    stats.sort((a, b) => b.birdieRate.compareTo(a.birdieRate));

    return stats;
  }
}

class _ShotShapeRow extends StatelessWidget {
  const _ShotShapeRow({required this.shape});

  final ShotShapeStats shape;

  @override
  Widget build(BuildContext context) {
    // Format the shape name for display
    final String formattedName = _formatShapeName(shape.shapeName);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '${shape.totalAttempts} attempts',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _StatBadge(
            label: 'Birdie',
            value: shape.birdieRate,
            color: const Color(0xFF137e66),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBadge(
            label: 'C1 Reg',
            value: shape.c1InRegPct,
            color: const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  String _formatShapeName(String shapeName) {
    // Remove underscores and capitalize properly
    // e.g., "backhand_hyzer" -> "Backhand Hyzer"
    final String cleaned = shapeName.replaceAll('_', ' ');
    final List<String> words = cleaned.split(' ');
    final List<String> capitalized = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).toList();
    return capitalized.join(' ');
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
