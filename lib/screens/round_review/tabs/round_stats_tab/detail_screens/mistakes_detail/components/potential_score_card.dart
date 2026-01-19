import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class PotentialScoreCard extends StatelessWidget {
  final int currentScore;
  final List<dynamic> mistakeTypes;

  const PotentialScoreCard({
    super.key,
    required this.currentScore,
    required this.mistakeTypes,
  });

  String _formatScore(int score) {
    if (score == 0) return 'E';
    return score > 0 ? '+$score' : '$score';
  }

  Color _getScoreColor(BuildContext context, int score) {
    if (score < 0) {
      return const Color(0xFF137e66); // Green for under par
    } else if (score > 0) {
      return const Color(0xFFFF7A7A); // Red for over par
    }
    return Theme.of(context).colorScheme.onSurface; // Default for even
  }

  String _getImprovementLabel(String mistakeLabel) {
    // Convert mistake labels to positive improvement actions (shortened)
    if (mistakeLabel.toLowerCase().contains('missed c1x')) {
      return 'Make C1X';
    } else if (mistakeLabel.toLowerCase().contains('missed c2')) {
      return 'Make C2';
    } else if (mistakeLabel.toLowerCase().contains('missed c1 ')) {
      return 'Make C1';
    } else if (mistakeLabel.toLowerCase().contains('ob tee')) {
      return 'Eliminate OB';
    } else if (mistakeLabel.toLowerCase().contains('ob')) {
      return 'Eliminate OB';
    } else if (mistakeLabel.toLowerCase().contains('3-putt')) {
      return 'Eliminate 3-putts';
    } else if (mistakeLabel.toLowerCase().contains('roll away')) {
      return 'Prevent roll aways';
    } else if (mistakeLabel.toLowerCase().contains('hit first available')) {
      return 'Hit first available';
    } else {
      // Default: remove "missed" or "failed" and make positive
      return mistakeLabel
          .replaceAll('Missed', 'Make')
          .replaceAll('missed', 'make')
          .replaceAll('Failed', 'Complete')
          .replaceAll('failed', 'complete');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter out mistakes with count > 0
    final List<dynamic> nonZeroMistakes = mistakeTypes
        .where((mistake) => mistake.count > 0)
        .toList();

    if (nonZeroMistakes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate total mistakes for "perfect round" scenario
    final int totalMistakeCount = nonZeroMistakes.fold(
      0,
      (sum, mistake) => sum + (mistake.count as int),
    );

    final int perfectRoundScore = currentScore - totalMistakeCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current score header (left-aligned)
            Row(
              children: [
                Text(
                  'Your Score: ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatScore(currentScore),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(context, currentScore),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: SenseiColors.gray[100]),
            const SizedBox(height: 16),
            // Perfect round comparison (highlighted at top)
            _buildScenarioRow(
              context,
              improvementLabel: 'Mistake-Free',
              strokesSaved: totalMistakeCount,
              potentialScore: perfectRoundScore,
              isHighlight: true,
            ),
            const SizedBox(height: 16),
            Divider(color: SenseiColors.gray[100]),
            const SizedBox(height: 12),
            // Individual mistake type scenarios
            ...nonZeroMistakes.map((mistake) {
              final int mistakeCount = mistake.count;
              final String mistakeLabel = mistake.label;
              final int potentialScore = currentScore - mistakeCount;
              final String improvementLabel = _getImprovementLabel(
                mistakeLabel,
              );

              return _buildScenarioRow(
                context,
                improvementLabel: improvementLabel,
                strokesSaved: mistakeCount,
                potentialScore: potentialScore,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioRow(
    BuildContext context, {
    required String improvementLabel,
    required int strokesSaved,
    required int potentialScore,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isHighlight ? 4 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Scenario name (left) - fixed width to align arrows
          SizedBox(
            width: 110,
            child: Text(
              improvementLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Arrow - centered position
          Icon(
            Icons.arrow_forward,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 18,
          ),
          const SizedBox(width: 16),
          // Potential score - fixed width to align strokes saved
          SizedBox(
            width: 50,
            child: Text(
              _formatScore(potentialScore),
              style:
                  (isHighlight
                          ? Theme.of(context).textTheme.headlineMedium
                          : Theme.of(context).textTheme.titleLarge)
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(context, potentialScore),
                      ),
            ),
          ),
          const SizedBox(width: 12),
          // Strokes saved - aligned and flexible
          Expanded(
            child: Text(
              '(-${strokesSaved == 1 ? '1 stroke' : '$strokesSaved strokes'})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF137e66),
                fontWeight: FontWeight.w500,
                fontSize: isHighlight ? 13 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
