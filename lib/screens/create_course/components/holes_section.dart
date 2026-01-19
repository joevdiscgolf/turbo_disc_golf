import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/create_course/components/create_course_hole_card.dart';
import 'package:turbo_disc_golf/screens/create_course/components/quick_fill_holes_card.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Shared component for editing holes (QuickFill + hole cards).
/// Used by both CreateCourseSheet and CreateLayoutSheet.
class HolesSection extends StatelessWidget {
  const HolesSection({
    super.key,
    required this.holes,
    required this.onApplyDefaults,
    required this.onHoleParChanged,
    required this.onHoleFeetChanged,
    required this.onHoleTypeChanged,
    required this.onHoleShapeChanged,
    this.onSnapshotBeforeApply,
    this.onUndoQuickFill,
  });

  /// List of holes to display
  final List<CourseHole> holes;

  /// Callback for applying default values to all holes
  final void Function({
    required int defaultPar,
    required int defaultFeet,
    required HoleType defaultType,
    required HoleShape defaultShape,
  }) onApplyDefaults;

  /// Callback when a hole's par changes
  final void Function(int holeNumber, int par) onHoleParChanged;

  /// Callback when a hole's feet changes
  final void Function(int holeNumber, int feet) onHoleFeetChanged;

  /// Callback when a hole's type changes
  final void Function(int holeNumber, HoleType type) onHoleTypeChanged;

  /// Callback when a hole's shape changes
  final void Function(int holeNumber, HoleShape shape) onHoleShapeChanged;

  /// Callback to snapshot holes before applying quick fill (for undo)
  final VoidCallback? onSnapshotBeforeApply;

  /// Callback to undo quick fill
  final VoidCallback? onUndoQuickFill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Holes', Icons.sports_golf, Colors.orange),
        const SizedBox(height: 8),
        QuickFillHolesCard(
          onApplyDefaults: onApplyDefaults,
          onSnapshotBeforeApply: onSnapshotBeforeApply,
          onUndo: onUndoQuickFill,
        ),
        const SizedBox(height: 12),
        // Header row
        const CreateCourseHoleHeader(),
        // Hole rows with dividers between them
        ...addDividers(
          holes.map((hole) {
            return CreateCourseHoleCard(
              hole: hole,
              onParChanged: (v) => onHoleParChanged(hole.holeNumber, v),
              onFeetChanged: (v) => onHoleFeetChanged(hole.holeNumber, v),
              onTypeChanged: (type) => onHoleTypeChanged(hole.holeNumber, type),
              onShapeChanged: (shape) =>
                  onHoleShapeChanged(hole.holeNumber, shape),
            );
          }).toList(),
          height: 1,
          dividerColor: Colors.grey.shade200,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}
