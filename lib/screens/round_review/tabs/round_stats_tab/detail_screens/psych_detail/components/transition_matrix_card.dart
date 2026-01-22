import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class TransitionMatrixCard extends StatelessWidget {
  final PsychStats stats;

  const TransitionMatrixCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    // Get all score categories that exist in the transition matrix
    final scoreCategories = _getSortedScoreCategories();

    if (scoreCategories.isEmpty) {
      return const SizedBox.shrink();
    }

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
          const SizedBox(height: 12),

          // Matrix header row
          Row(
            children: [
              const SizedBox(width: 80), // Space for row labels
              ...scoreCategories.map(
                (category) => Expanded(
                  child: _buildHeaderCell(context, _getShortLabel(category)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Matrix rows
          ..._buildMatrixRows(context, scoreCategories),
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

  List<Widget> _buildMatrixRows(
    BuildContext context,
    List<String> scoreCategories,
  ) {
    final List<Widget> rows = [];

    for (var category in scoreCategories) {
      final transition = stats.transitionMatrix[category];
      if (transition != null) {
        rows.add(
          _buildMatrixRow(
            context,
            label: _getRowLabel(category),
            category: category,
            scoreCategories: scoreCategories,
          ),
        );
        rows.add(const SizedBox(height: 8));
      }
    }

    return rows;
  }

  Widget _buildMatrixRow(
    BuildContext context, {
    required String label,
    required String category,
    required List<String> scoreCategories,
  }) {
    final transition = stats.transitionMatrix[category];
    if (transition == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Row label
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Percentage cells - dynamically show only categories that exist
        ...scoreCategories.map((toCategory) {
          final percentage = _getTransitionPercentage(
            transition,
            toCategory,
          );
          return Expanded(
            child: _buildPercentageCell(
              context,
              percentage,
              toCategory,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPercentageCell(
    BuildContext context,
    double percentage,
    String toCategory,
  ) {
    // Determine cell color based on outcome type
    Color cellColor;

    if (_isGoodScore(toCategory)) {
      // Green scale for good scores (birdie or better)
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
    if (percentage == 0) {
      cellColor = cellColor.withValues(alpha: 0.5); // 50% opacity for 0%
    } else if (percentage < 5) {
      cellColor = cellColor.withValues(alpha: 0.35); // 35% opacity for 1-4%
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

  /// Get sorted list of score categories that exist in the transition matrix
  List<String> _getSortedScoreCategories() {
    const scoreOrder = [
      'Condor',
      'Albatross',
      'Eagle',
      'Birdie',
      'Par',
      'Bogey',
      'Double Bogey',
      'Triple Bogey+',
    ];

    return scoreOrder
        .where((score) => stats.transitionMatrix.containsKey(score))
        .toList();
  }

  /// Get label for column headers
  String _getShortLabel(String category) {
    // Return full names, not abbreviations
    return category;
  }

  /// Get label for row (e.g., "After birdie")
  String _getRowLabel(String category) {
    // Convert to lowercase for second word
    final lowercase = category.toLowerCase();
    return 'After $lowercase';
  }

  /// Check if a score is good (birdie or better)
  bool _isGoodScore(String category) {
    return ['Condor', 'Albatross', 'Eagle', 'Birdie'].contains(category);
  }

  /// Get the transition percentage for a specific "to" category
  double _getTransitionPercentage(
    ScoringTransition transition,
    String toCategory,
  ) {
    // Map each category to the appropriate aggregated percentage field
    if (_isGoodScore(toCategory)) {
      return transition.toBirdiePercent;
    } else if (toCategory == 'Par') {
      return transition.toParPercent;
    } else if (toCategory == 'Bogey') {
      return transition.toBogeyPercent;
    } else {
      // Double Bogey or worse
      return transition.toDoublePercent;
    }
  }
}
