import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/hole_grid_item.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_hole_detail_panel.dart';
import 'package:turbo_disc_golf/screens/round_processing/panels/record_single_hole_panel.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/state/round_review_cubit.dart';
import 'package:turbo_disc_golf/state/round_review_state.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

class HolesGrid extends StatelessWidget {
  const HolesGrid({super.key, required this.round});

  final DGRound round;

  @override
  Widget build(BuildContext context) {
    // Calculate width for 3 columns with no spacing
    final double screenWidth =
        MediaQuery.of(context).size.width - 32; // minus horizontal margin
    final double itemWidth = screenWidth / 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 0,
        runSpacing: 0,
        children: round.holes.asMap().entries.map((entry) {
          final int holeIndex = entry.key;
          final DGHole hole = entry.value;
          return SizedBox(
            width: itemWidth,
            child: _HoleGridItem(
              hole: hole,
              holeIndex: holeIndex,
              round: round,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HoleGridItem extends StatelessWidget {
  const _HoleGridItem({
    required this.hole,
    required this.holeIndex,
    required this.round,
  });

  final DGHole hole;
  final int holeIndex;
  final DGRound round;

  @override
  Widget build(BuildContext context) {
    return HoleGridItem(
      holeNumber: hole.number,
      holePar: hole.par,
      holeFeet: hole.feet,
      score: hole.holeScore,
      relativeScore: hole.relativeHoleScore,
      isIncomplete: false, // Completed rounds are never incomplete
      onTap: () => _showHoleDetailSheet(context),
      heroTag: 'hole_${hole.number}',
    );
  }

  void _showHoleDetailSheet(BuildContext context) {
    final RoundReviewCubit roundReviewCubit = BlocProvider.of<RoundReviewCubit>(
      context,
    );

    // Set the current editing hole when opening the panel
    roundReviewCubit.setCurrentEditingHole(holeIndex);

    displayBottomSheet(
      context,
      // Wrap with BlocProvider.value to pass the cubit to the modal's context
      // since modals are rendered in a separate route that doesn't inherit
      // from the MultiBlocProvider in main.dart
      BlocProvider<RoundReviewCubit>.value(
        value: roundReviewCubit,
        child: BlocBuilder<RoundReviewCubit, RoundReviewState>(
          builder: (context, state) {
            if (state is! ReviewingRoundActive) {
              return const SizedBox();
            }
            final DGHole? currentHole = state.currentEditingHole;
            if (currentHole == null) {
              return const SizedBox();
            }

          // Convert DGHole to PotentialDGHole for editing
          final PotentialDGHole potentialHole = PotentialDGHole(
            number: currentHole.number,
            par: currentHole.par,
            feet: currentHole.feet,
            throws: currentHole.throws
                .map(
                  (t) => DiscThrow(
                    index: t.index,
                    purpose: t.purpose,
                    technique: t.technique,
                    puttStyle: t.puttStyle,
                    shotShape: t.shotShape,
                    stance: t.stance,
                    power: t.power,
                    distanceFeetBeforeThrow: t.distanceFeetBeforeThrow,
                    distanceFeetAfterThrow: t.distanceFeetAfterThrow,
                    elevationChangeFeet: t.elevationChangeFeet,
                    windDirection: t.windDirection,
                    windStrength: t.windStrength,
                    resultRating: t.resultRating,
                    landingSpot: t.landingSpot,
                    fairwayWidth: t.fairwayWidth,
                    customPenaltyStrokes: t.customPenaltyStrokes,
                    notes: t.notes,
                    rawText: t.rawText,
                    parseConfidence: t.parseConfidence,
                    discName: t.discName,
                    disc: t.disc,
                  ),
                )
                .toList(),
            holeType: currentHole.holeType,
          );

          return EditableHoleDetailPanel(
            potentialHole: potentialHole,
            holeIndex: holeIndex,
            onMetadataChanged: ({int? newPar, int? newDistance}) =>
                roundReviewCubit.updateHoleMetadata(
                  holeIndex,
                  par: newPar,
                  feet: newDistance,
                ),
            onThrowAdded: (throw_, {int? addThrowAtIndex}) =>
                roundReviewCubit.addThrow(
                  holeIndex,
                  throw_,
                  addAfterThrowIndex: addThrowAtIndex,
                ),
            onThrowEdited: (throwIndex, updatedThrow) => roundReviewCubit
                .updateThrow(holeIndex, throwIndex, updatedThrow),
            onThrowDeleted: (throwIndex) =>
                roundReviewCubit.deleteThrow(holeIndex, throwIndex),
            onReorder: (oldIndex, newIndex) =>
                roundReviewCubit.reorderThrows(holeIndex, oldIndex, newIndex),
            onVoiceRecord: () {
              displayBottomSheet(
                context,
                RecordSingleHolePanel(
                  holeNumber: currentHole.number,
                  holePar: currentHole.par,
                  holeFeet: currentHole.feet,
                  courseName: round.courseName,
                  showTestButton: true,
                  onParseComplete: (parsedHole) =>
                      _handleParsedVoiceHole(context, parsedHole),
                  bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
                ),
              );
            },
            onRoundUpdated: () => roundReviewCubit.saveToFirestore(),
          );
        },
        ),
      ),
      onDismiss: () {
        // Clear the current editing hole when the panel is closed
        roundReviewCubit.clearCurrentEditingHole();
      },
    );
  }

  void _handleParsedVoiceHole(
    BuildContext context,
    PotentialDGHole? parsedHole,
  ) {
    final RoundReviewCubit roundReviewCubit = BlocProvider.of<RoundReviewCubit>(
      context,
    );

    if (parsedHole == null) {
      locator.get<ToastService>().showError('Failed to parse hole');
      return;
    }

    try {
      debugPrint('✅ Received parsed hole from voice panel');
      debugPrint(
        '   Hole: ${parsedHole.number}, Throws: ${parsedHole.throws?.length ?? 0}',
      );

      // Convert to DGHole and update
      final DGHole updatedHole = parsedHole.toDGHole();
      roundReviewCubit.updateHole(holeIndex, updatedHole);

      // Show success
      locator.get<ToastService>().showSuccess('Hole updated successfully!');
    } catch (e, trace) {
      debugPrint('❌ Error updating hole: $e');
      debugPrint(trace.toString());

      locator.get<ToastService>().showError('Error updating hole');
    }
  }
}
