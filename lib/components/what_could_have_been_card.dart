import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/components/story_section_header.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

/// "What Could Have Been" hero card showing potential score improvements
///
/// Displays:
/// - Current score vs potential score comparison
/// - List of improvement scenarios with stroke savings
/// - Encouraging message about the path forward
class WhatCouldHaveBeenCard extends StatelessWidget {
  const WhatCouldHaveBeenCard({
    super.key,
    required this.data,
  });

  final WhatCouldHaveBeen data;

  @override
  Widget build(BuildContext context) {
    // Parse current score for coloring
    final int currentScore = _parseScore(data.currentScore);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                flattenedOverWhite(const Color(0xFF7B1FA2), 0.0),
                Colors.white,
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StorySectionHeader(
                title: 'What could have been',
                icon: Icons.auto_awesome,
                accentColor: const Color(0xFF7B1FA2),
              ),
              const SizedBox(height: 8),
              // Score comparison
              Row(
                children: [
                  Expanded(
                    child: _buildScoreBox(
                      label: 'You shot',
                      score: data.currentScore,
                      color: currentScore < 0
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF7043),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildScoreBox(
                      label: 'Could be',
                      score: data.potentialScore,
                      color: const Color(0xFF7B1FA2),
                      highlight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Improvement scenarios - clean table layout
              if (data.scenarios.isNotEmpty) ...[
                _buildScenariosTable(),
              ],
              // Encouragement message (conditional)
              if (showWhatCouldHaveBeenEncouragement) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: Color(0xFF7B1FA2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data.encouragement,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Color(0xFF4A148C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build the scenarios table with clean column alignment
  Widget _buildScenariosTable() {
    // Separate individual scenarios from the "all" total row
    final List<ImprovementScenario> individualScenarios = data.scenarios
        .where((s) => !s.fix.toLowerCase().contains('all'))
        .toList();
    final List<ImprovementScenario> totalScenarios = data.scenarios
        .where((s) => s.fix.toLowerCase().contains('all'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'If you fixed...',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        // Column headers
        _buildHeaderRow(),
        const SizedBox(height: 4),
        // Individual scenarios
        ...individualScenarios.map(
          (s) => _buildScenarioRow(s, isTotal: false),
        ),
        // Divider before total
        if (totalScenarios.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Divider(
              color: Colors.grey.shade300,
              height: 1,
            ),
          ),
          // Total row (highlighted)
          ...totalScenarios.map(
            (s) => _buildScenarioRow(s, isTotal: true),
          ),
        ],
      ],
    );
  }

  /// Build the column header row
  Widget _buildHeaderRow() {
    const TextStyle headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: Colors.grey,
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Expanded(child: SizedBox()), // Empty space for fix name
          SizedBox(
            width: 60,
            child: Text(
              'SAVE',
              textAlign: TextAlign.right,
              style: headerStyle,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 50,
            child: Text(
              'SCORE',
              textAlign: TextAlign.right,
              style: headerStyle,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a single scenario row with aligned columns
  Widget _buildScenarioRow(ImprovementScenario scenario, {required bool isTotal}) {
    const Color purpleColor = Color(0xFF7B1FA2);
    const Color greenColor = Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          // Fix name (flex)
          Expanded(
            child: Row(
              children: [
                if (isTotal) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: purpleColor,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    scenario.fix,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Strokes saved (fixed width)
          SizedBox(
            width: 60,
            child: Text(
              '-${scenario.strokesSaved}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: greenColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Result score (fixed width)
          SizedBox(
            width: 50,
            child: Text(
              scenario.resultScore,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isTotal ? purpleColor : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parse a score string like "+5" or "-2" into an integer
  int _parseScore(String scoreStr) {
    final String cleaned = scoreStr.replaceAll('+', '').trim();
    return int.tryParse(cleaned) ?? 0;
  }

  /// Build a compact score box for the comparison row
  Widget _buildScoreBox({
    required String label,
    required String score,
    required Color color,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? color : Colors.grey.shade300,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            score,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
