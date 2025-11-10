import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';

/// Visual timeline showing round progression with color-coded holes
class RoundTimeline extends StatelessWidget {
  final DGRound round;
  final List<String>? highlightedMoments; // e.g., ["Hot streak on holes 4-6"]

  const RoundTimeline({
    super.key,
    required this.round,
    this.highlightedMoments,
  });

  Color _getColorForScore(int relativeScore) {
    if (relativeScore <= -2) {
      return const Color(0xFF9C27B0); // Purple for eagle or better
    } else if (relativeScore == -1) {
      return const Color(0xFF4CAF50); // Green for birdie
    } else if (relativeScore == 0) {
      return const Color(0xFF2196F3); // Blue for par
    } else if (relativeScore == 1) {
      return const Color(0xFFFFB800); // Yellow for bogey
    } else {
      return const Color(0xFFFF7A7A); // Red for double bogey or worse
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Round Timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _LegendItem(
                  color: const Color(0xFF9C27B0),
                  label: 'Eagle+',
                ),
                _LegendItem(
                  color: const Color(0xFF4CAF50),
                  label: 'Birdie',
                ),
                _LegendItem(
                  color: const Color(0xFF2196F3),
                  label: 'Par',
                ),
                _LegendItem(
                  color: const Color(0xFFFFB800),
                  label: 'Bogey',
                ),
                _LegendItem(
                  color: const Color(0xFFFF7A7A),
                  label: 'Double+',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Timeline
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: round.holes.map((hole) {
                  final Color color = _getColorForScore(hole.relativeHoleScore);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _TimelineDot(
                      holeNumber: hole.number,
                      color: color,
                      score: hole.holeScore,
                      par: hole.par,
                      relativeScore: hole.relativeHoleScore,
                    ),
                  );
                }).toList(),
              ),
            ),
            // Highlighted moments
            if (highlightedMoments != null && highlightedMoments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Key Moments',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 8),
              ...highlightedMoments!.map((moment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFFFB800),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          moment,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// Individual dot on the timeline
class _TimelineDot extends StatelessWidget {
  final int holeNumber;
  final Color color;
  final int score;
  final int par;
  final int relativeScore;

  const _TimelineDot({
    required this.holeNumber,
    required this.color,
    required this.score,
    required this.par,
    required this.relativeScore,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Hole $holeNumber: $score (Par $par)',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$holeNumber',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                relativeScore > 0
                    ? '+$relativeScore'
                    : relativeScore == 0
                        ? 'E'
                        : '$relativeScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Legend item showing color and label
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
