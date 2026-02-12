import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/observation_card.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Section displaying observations grouped by category
class ObservationCategorySection extends StatelessWidget {
  const ObservationCategorySection({
    super.key,
    required this.category,
    required this.observations,
    required this.onObservationTap,
    this.activeObservationId,
  });

  final ObservationCategory category;
  final List<FormObservation> observations;
  final void Function(FormObservation) onObservationTap;
  final String? activeObservationId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simple text category header
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
        LayoutBuilder(
          builder: (context, constraints) {
            const double spacing = 8.0;
            final double itemWidth = (constraints.maxWidth - spacing) / 2;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: observations.map((observation) {
                return SizedBox(
                  width: itemWidth,
                  child: ObservationCard(
                    observation: observation,
                    onTap: () => onObservationTap(observation),
                    isActive: observation.observationId == activeObservationId,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // Category header temporarily disabled
  // Widget _buildHeader() {
  //   final Color categoryColor = _getCategoryColor(category);
  //
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: SenseiColors.gray[100]!),
  //       boxShadow: defaultCardBoxShadow(),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           width: 36,
  //           height: 36,
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //               colors: [
  //                 categoryColor.withValues(alpha: 0.15),
  //                 categoryColor.withValues(alpha: 0.08),
  //               ],
  //             ),
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //           child: Icon(
  //             _getCategoryIcon(category),
  //             size: 20,
  //             color: categoryColor,
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Text(
  //             category.displayName,
  //             style: TextStyle(
  //               fontSize: 16,
  //               fontWeight: FontWeight.w600,
  //               color: SenseiColors.gray[800],
  //             ),
  //           ),
  //         ),
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //           decoration: BoxDecoration(
  //             color: categoryColor.withValues(alpha: 0.1),
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: Text(
  //             '${observations.length} ${observations.length == 1 ? 'item' : 'items'}',
  //             style: TextStyle(
  //               fontSize: 12,
  //               fontWeight: FontWeight.w600,
  //               color: categoryColor,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // Color _getCategoryColor(ObservationCategory category) {
  //   switch (category) {
  //     case ObservationCategory.footwork:
  //       return const Color(0xFF3B82F6); // Blue
  //     case ObservationCategory.armMechanics:
  //       return const Color(0xFF8B5CF6); // Purple
  //     case ObservationCategory.timing:
  //       return const Color(0xFFF59E0B); // Amber
  //     case ObservationCategory.balance:
  //       return const Color(0xFF10B981); // Green
  //     case ObservationCategory.rotation:
  //       return const Color(0xFFEF4444); // Red
  //   }
  // }
  //
  // IconData _getCategoryIcon(ObservationCategory category) {
  //   switch (category) {
  //     case ObservationCategory.footwork:
  //       return Icons.directions_walk;
  //     case ObservationCategory.armMechanics:
  //       return Icons.sports_handball;
  //     case ObservationCategory.timing:
  //       return Icons.timer;
  //     case ObservationCategory.balance:
  //       return Icons.balance;
  //     case ObservationCategory.rotation:
  //       return Icons.rotate_right;
  //   }
  // }
}
