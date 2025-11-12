import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/edit_hole/edit_par_distance_row.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_throw_timeline.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// A reusable, stateless component for editing hole data.
///
/// This component is purely presentational and accepts all data via props.
/// Parent components are responsible for managing state and responding to callbacks.
class EditableHoleBody extends StatelessWidget {
  const EditableHoleBody({
    super.key,
    required this.holeNumber,
    required this.par,
    required this.distance,
    required this.throws,
    required this.parController,
    required this.distanceController,
    required this.parFocusNode,
    required this.distanceFocusNode,
    required this.bottomViewPadding,
    required this.onParChanged,
    required this.onDistanceChanged,
    required this.onThrowAdded,
    required this.onThrowEdited,
    required this.onVoiceRecord,
    required this.onDone,
    this.inWalkthroughSheet = false,
    this.hasRequiredFields = true,
  });

  final int? holeNumber;
  final int par;
  final int distance;
  final List<DiscThrow> throws;
  final TextEditingController parController;
  final TextEditingController distanceController;
  final FocusNode parFocusNode;
  final FocusNode distanceFocusNode;
  final double bottomViewPadding;
  final bool inWalkthroughSheet;
  final bool hasRequiredFields;

  // Callbacks
  final Function(int) onParChanged;
  final Function(int) onDistanceChanged;
  final Function({int? addThrowAtIndex}) onThrowAdded;
  final void Function(int throwIndex) onThrowEdited;
  final VoidCallback onVoiceRecord;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final double borderRadius = inWalkthroughSheet ? 0 : 16;

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside text fields
        FocusScope.of(context).unfocus();
      },
      child: Container(
        padding: EdgeInsets.only(bottom: bottomViewPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (matching _HoleDetailDialog design)
            _holeNumberBanner(context, borderRadius),
            EditParDistanceRow(
              par: par,
              distance: distance,
              strokes: throws.length,
              onParChanged: (int newPar) => onParChanged(newPar),
              onDistanceChanged: (int newDistance) =>
                  onDistanceChanged(newDistance),
              parFocusNode: parFocusNode,
              distanceFocusNode: distanceFocusNode,
              parController: parController,
              distanceController: distanceController,
            ),

            // Throws timeline
            Expanded(
              child: throws.isNotEmpty
                  ? EditableThrowTimeline(
                      throws: throws,
                      onEditThrow: onThrowEdited,
                      onAddThrowAt: (int addThrowAtIndex) {
                        print('on throw added from editable throws timeline.');
                        onThrowAdded(addThrowAtIndex: addThrowAtIndex);
                      },
                    )
                  : Center(
                      child: Text(
                        'No throws',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Add throw button
                      Expanded(
                        child: PrimaryButton(
                          icon: FlutterRemix.add_line,
                          height: 56,
                          width: double.infinity,
                          label: 'Add throw',
                          onPressed: onThrowAdded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryButton(
                          height: 56,
                          width: double.infinity,
                          label: 'Voice',
                          onPressed: onVoiceRecord,
                          backgroundColor: const Color(0xFF9D4EDD),
                          icon: Icons.mic,
                        ),
                      ),
                    ],
                  ),

                  // Only show Done button when NOT in walkthrough sheet
                  // In walkthrough, user navigates via the horizontal checklist
                  const SizedBox(height: 8),
                  PrimaryButton(
                    height: 56,
                    width: double.infinity,
                    label: 'Done',
                    onPressed: onDone,
                    labelColor: TurbColors.blue,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    borderColor: TurbColors.blue.withValues(alpha: 0.1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _holeNumberBanner(BuildContext context, double borderRadius) {
    final Color scoreColor = _getScoreColor();
    final int? score = _getScore();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: !hasRequiredFields ? 0.2 : 0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.golf_course,
                size: 24,
                color: hasRequiredFields ? scoreColor : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                'Hole ${holeNumber ?? '?'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Builder(
            builder: (context) {
              if (score != null) {
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scoreColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                );
              } else {
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scoreColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      FlutterRemix.error_warning_line,
                      color: hasRequiredFields ? Colors.white : Colors.black,
                      size: 24,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  int? _getScore() {
    return hasRequiredFields && throws.isNotEmpty ? throws.length : null;
  }

  Color _getScoreColor() {
    if (!hasRequiredFields) {
      return const Color(0xFFFFEB3B); // Bright yellow for incomplete
    }

    if (par == 0 || throws.isEmpty) {
      return Colors.grey;
    }

    final int relativeScore = throws.length - par;

    if (relativeScore < 0) {
      return const Color(0xFF137e66); // Birdie - green
    } else if (relativeScore == 0) {
      return Colors.grey; // Par - grey
    } else if (relativeScore == 1) {
      return const Color(0xFFFF7A7A); // Bogey - light red
    } else {
      return const Color(0xFFD32F2F); // Double bogey+ - dark red
    }
  }
}
