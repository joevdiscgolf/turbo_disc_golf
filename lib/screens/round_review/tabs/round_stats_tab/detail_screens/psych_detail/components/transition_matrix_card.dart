import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class TransitionMatrixCard extends StatelessWidget {
  final PsychStats stats;

  const TransitionMatrixCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scoring Transitions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'How your next hole score depends on the current hole',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Matrix header row
          Row(
            children: [
              const SizedBox(width: 100), // Space for row labels
              Expanded(child: _buildHeaderCell(context, 'Birdie')),
              Expanded(child: _buildHeaderCell(context, 'Par')),
              Expanded(child: _buildHeaderCell(context, 'Bogey')),
              Expanded(child: _buildHeaderCell(context, 'Dbl+')),
            ],
          ),

          const SizedBox(height: 8),

          // Matrix rows
          ..._buildMatrixRows(context),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String label) {
    return Center(
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> _buildMatrixRows(BuildContext context) {
    final List<Widget> rows = [];

    final categories = ['Birdie', 'Par', 'Bogey', 'Double+'];
    final emojis = {
      'Birdie': '🔥',
      'Par': '⚖️',
      'Bogey': '⚠️',
      'Double+': '🆘',
    };
    final labels = {
      'Birdie': 'Riding high',
      'Par': 'Steady',
      'Bogey': 'Danger zone',
      'Double+': 'TILT!',
    };

    for (var category in categories) {
      final transition = stats.transitionMatrix[category];
      if (transition != null) {
        rows.add(
          _buildMatrixRow(
            context,
            emoji: emojis[category]!,
            label: 'After $category',
            description: labels[category]!,
            transition: transition,
          ),
        );
        rows.add(const SizedBox(height: 8));
      }
    }

    return rows;
  }

  Widget _buildMatrixRow(
    BuildContext context, {
    required String emoji,
    required String label,
    required String description,
    required ScoringTransition transition,
  }) {
    return Row(
      children: [
        // Row label
        SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Percentage cells
        Expanded(
          child: _buildPercentageCell(
            context,
            transition.toBirdiePercent,
            'Birdie',
          ),
        ),
        Expanded(
          child: _buildPercentageCell(context, transition.toParPercent, 'Par'),
        ),
        Expanded(
          child: _buildPercentageCell(
            context,
            transition.toBogeyPercent,
            'Bogey',
          ),
        ),
        Expanded(
          child: _buildPercentageCell(
            context,
            transition.toDoublePercent,
            'Double+',
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageCell(
    BuildContext context,
    double percentage,
    String toCategory,
  ) {
    // Determine cell color based on percentage and outcome type
    Color cellColor;
    if (toCategory == 'Birdie') {
      // Green scale for birdies
      if (percentage >= 20) {
        cellColor = const Color(0xFF4CAF50); // Dark green
      } else if (percentage >= 10) {
        cellColor = const Color(0xFF81C784); // Medium green
      } else {
        cellColor = const Color(0xFFC8E6C9); // Light green
      }
    } else if (toCategory == 'Par') {
      // Blue/neutral scale for pars
      if (percentage >= 65) {
        cellColor = const Color(0xFF2196F3); // Dark blue
      } else if (percentage >= 50) {
        cellColor = const Color(0xFF64B5F6); // Medium blue
      } else {
        cellColor = const Color(0xFFBBDEFB); // Light blue
      }
    } else {
      // Red/warning scale for bogey+
      if (percentage >= 25) {
        cellColor = const Color(0xFFFF7A7A); // Dark red
      } else if (percentage >= 15) {
        cellColor = const Color(0xFFFFAB91); // Medium red
      } else {
        cellColor = const Color(0xFFFFCCBC); // Light red
      }
    }

    // Adjust opacity for very low percentages
    if (percentage < 5) {
      cellColor = cellColor.withValues(alpha: 0.3);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '${percentage.toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
