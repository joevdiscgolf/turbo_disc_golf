import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// "What Could Have Been" section showing potential score improvements (V3 design)
///
/// Displays:
/// - Current score vs potential score comparison
/// - List of improvement scenarios with stroke savings (vertical bar style)
/// - Encouraging message about the path forward
///
/// This component uses the cleaner V3 design without gradients.
class WhatCouldHaveBeenCard extends StatelessWidget {
  const WhatCouldHaveBeenCard({
    super.key,
    required this.currentScore,
    required this.potentialScore,
    required this.scenarios,
  });

  final String currentScore;
  final String potentialScore;
  final List<WhatCouldHaveBeenScenario> scenarios;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.insights, color: Color(0xFF6366F1), size: 20),
            const SizedBox(width: 8),
            Text(
              'What could have been',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Current vs Potential Score
        _buildScoreComparison(currentScore, potentialScore),

        const SizedBox(height: 16),

        // Improvement scenarios
        ...scenarios.map((scenario) => _buildScenarioRow(scenario)),
      ],
    );
  }

  Widget _buildScoreComparison(String current, String potential) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildScoreBox('Current Score', current, SenseiColors.gray[600]!),
        Icon(Icons.arrow_forward, color: SenseiColors.gray[400]),
        _buildScoreBox('Potential Score', potential, const Color(0xFF4CAF50)),
      ],
    );
  }

  Widget _buildScoreBox(String label, String score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: SenseiColors.gray[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioRow(WhatCouldHaveBeenScenario scenario) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario.fix,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Result: ${scenario.resultScore} (${scenario.strokesSaved} strokes saved)',
                  style: TextStyle(fontSize: 12, color: SenseiColors.gray[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Data model for an improvement scenario
class WhatCouldHaveBeenScenario {
  final String fix;
  final String resultScore;
  final String strokesSaved;

  const WhatCouldHaveBeenScenario({
    required this.fix,
    required this.resultScore,
    required this.strokesSaved,
  });
}
