import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/observation_card.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observations_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Widget for rendering FormObservationsV2 data.
/// Displays all observations grouped by category.
class FormObservationsV2View extends StatelessWidget {
  const FormObservationsV2View({
    super.key,
    required this.observations,
    required this.onObservationTap,
    this.activeObservationId,
    this.showOverallScore = false,
  });

  final FormObservationsV2 observations;
  final void Function(FormObservation) onObservationTap;
  final String? activeObservationId;
  final bool showOverallScore;

  @override
  Widget build(BuildContext context) {
    final Map<ObservationCategory, List<FormObservation>> byCategory =
        observations.byCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall score card (optional)
        if (showOverallScore) ...[
          _buildOverallScoreCard(),
          if (byCategory.isNotEmpty) const SizedBox(height: 24),
        ],
        // Category sections
        if (byCategory.isNotEmpty) ..._buildCategorySections(byCategory),
      ],
    );
  }

  List<Widget> _buildCategorySections(
    Map<ObservationCategory, List<FormObservation>> byCategory,
  ) {
    // Sort categories for consistent display order
    final List<ObservationCategory> sortedCategories = byCategory.keys.toList()
      ..sort((a, b) => _categoryOrder(a).compareTo(_categoryOrder(b)));

    final List<Widget> sections = [];
    for (int i = 0; i < sortedCategories.length; i++) {
      sections.add(
        _buildCategorySection(
          sortedCategories[i],
          byCategory[sortedCategories[i]]!,
        ),
      );
      if (i < sortedCategories.length - 1) {
        sections.add(const SizedBox(height: 24));
      }
    }
    return sections;
  }

  Widget _buildOverallScoreCard() {
    final int scorePercent = (observations.overallScore * 100).round();
    final Color scoreColor = _getScoreColor(scorePercent);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SenseiColors.gray[100]!),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scoreColor.withValues(alpha: 0.15),
                  scoreColor.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$scorePercent',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Label and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall form score',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SenseiColors.gray[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${observations.observations.length} observations analyzed',
                  style: TextStyle(
                    fontSize: 13,
                    color: SenseiColors.gray[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int scorePercent) {
    if (scorePercent >= 80) {
      return const Color(0xFF10B981); // Green for excellent
    } else if (scorePercent >= 60) {
      return const Color(0xFFF59E0B); // Amber for good
    } else {
      return const Color(0xFFEF4444); // Red for needs work
    }
  }

  /// Returns the display order for a category (lower = displayed first)
  int _categoryOrder(ObservationCategory category) {
    return switch (category) {
      ObservationCategory.footwork => 0,
      ObservationCategory.armMechanics => 1,
      ObservationCategory.timing => 2,
      ObservationCategory.balance => 3,
      ObservationCategory.rotation => 4,
    };
  }

  Widget _buildCategorySection(
    ObservationCategory category,
    List<FormObservation> categoryObservations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            category.displayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SenseiColors.gray[500],
              letterSpacing: 0.3,
            ),
          ),
        ),
        // Observation cards
        ...categoryObservations.asMap().entries.map((entry) {
          final int index = entry.key;
          final FormObservation observation = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < categoryObservations.length - 1 ? 8 : 0,
            ),
            child: ObservationCard(
              observation: observation,
              onTap: () => onObservationTap(observation),
              isActive: observation.observationId == activeObservationId,
            ),
          );
        }),
      ],
    );
  }
}
