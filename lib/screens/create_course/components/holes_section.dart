import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turbo_disc_golf/components/education/parse_scorecard_education_panel.dart';
import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/create_course/components/create_course_hole_card.dart';
import 'package:turbo_disc_golf/screens/create_course/components/quick_fill_holes_card.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

const String _hasSeenScorecardParsingEducationKey =
    'hasSeenScorecardParsingEducation';

/// Shared component for editing holes (QuickFill + hole cards).
/// Used by both CreateCourseSheet and CreateLayoutSheet.
class HolesSection extends StatefulWidget {
  const HolesSection({
    super.key,
    required this.holes,
    required this.onApplyDefaults,
    required this.onHoleParChanged,
    required this.onHoleFeetChanged,
    required this.onHoleTypeChanged,
    required this.onHoleShapeChanged,
    required this.isParsingImage,
    required this.onParseImage,
    this.parseError,
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
  })
  onApplyDefaults;

  /// Callback when a hole's par changes
  final void Function(int holeNumber, int par) onHoleParChanged;

  /// Callback when a hole's feet changes
  final void Function(int holeNumber, int feet) onHoleFeetChanged;

  /// Callback when a hole's type changes
  final void Function(int holeNumber, HoleType type) onHoleTypeChanged;

  /// Callback when a hole's shape changes
  final void Function(int holeNumber, HoleShape shape) onHoleShapeChanged;

  /// Whether image parsing is in progress
  final bool isParsingImage;

  /// Callback to trigger image parsing
  final VoidCallback onParseImage;

  /// Error message from image parsing
  final String? parseError;

  /// Callback to snapshot holes before applying quick fill (for undo)
  final VoidCallback? onSnapshotBeforeApply;

  /// Callback to undo quick fill
  final VoidCallback? onUndoQuickFill;

  @override
  State<HolesSection> createState() => _HolesSectionState();
}

class _HolesSectionState extends State<HolesSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSectionHeader('Holes'),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildImageParserButton(context),
        ),
        if (widget.parseError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: Text(
              widget.parseError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: QuickFillHolesCard(
            onApplyDefaults: widget.onApplyDefaults,
            onSnapshotBeforeApply: widget.onSnapshotBeforeApply,
            onUndo: widget.onUndoQuickFill,
          ),
        ),
        const SizedBox(height: 12),
        // Header row (edge-to-edge with internal 16px padding)
        const CreateCourseHoleHeader(),
        // Hole rows with dividers between them (edge-to-edge with internal 16px padding)
        ...addDividers(
          widget.holes.map((hole) {
            return CreateCourseHoleCard(
              hole: hole,
              onParChanged: (v) => widget.onHoleParChanged(hole.holeNumber, v),
              onFeetChanged: (v) =>
                  widget.onHoleFeetChanged(hole.holeNumber, v),
              onTypeChanged: (type) =>
                  widget.onHoleTypeChanged(hole.holeNumber, type),
              onShapeChanged: (shape) =>
                  widget.onHoleShapeChanged(hole.holeNumber, shape),
            );
          }).toList(),
          height: 1,
          dividerColor: Colors.grey.shade200,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }

  Widget _buildImageParserButton(BuildContext context) {
    return GestureDetector(
      onTap: widget.isParsingImage ? null : _handleImageParserTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SenseiColors.gray.shade100, width: 1),
          boxShadow: defaultCardBoxShadow(),
        ),
        child: Row(
          children: [
            Icon(
              widget.isParsingImage ? Icons.hourglass_empty : Icons.camera_alt,
              color: SenseiColors.gray.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isParsingImage
                        ? 'Parsing image...'
                        : 'Upload scorecard image',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: SenseiColors.gray.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Auto-fill par & distance from photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: SenseiColors.gray.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isParsingImage)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (!widget.isParsingImage)
              GestureDetector(
                onTap: _showScorecardEducation,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SenseiColors.gray.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Colors.amber.shade600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageParserTap() async {
    await _checkFirstTimeScorecardEducation();
    widget.onParseImage();
  }

  Future<void> _checkFirstTimeScorecardEducation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasSeenEducation =
        prefs.getBool(_hasSeenScorecardParsingEducationKey) ?? false;

    if (!hasSeenEducation && mounted) {
      await _showScorecardEducation();
      await prefs.setBool(_hasSeenScorecardParsingEducationKey, true);
    }
  }

  Future<void> _showScorecardEducation() async {
    if (!mounted) return;
    await EducationPanel.show(
      context,
      title: 'Upload scorecard image',
      modalName: 'Parse Scorecard Education',
      accentColor: Colors.blue,
      contentBuilder: (_) => const ParseScorecardEducationPanel(),
    );
  }
}
