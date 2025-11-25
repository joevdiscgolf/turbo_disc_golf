import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/hole_grid_item.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_hole_detail_panel.dart';
import 'package:turbo_disc_golf/screens/round_processing/panels/record_single_hole_panel_v2.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
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
      BlocBuilder<RoundReviewCubit, RoundReviewState>(
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
                    penaltyStrokes: t.penaltyStrokes,
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
              // displayBottomSheet(
              //   context,
              //   RecordSingleHolePanel(
              //     holeNumber: hole.number,
              //     onContinuePressed: (transcript) {
              //       debugPrint('transcript');
              //     },
              //   ),
              // );

              displayBottomSheet(
                context,
                RecordSingleHolePanelV2(
                  holeNumber: currentHole.number,
                  holePar: currentHole.par,
                  holeFeet: currentHole.feet,
                  isProcessing: false,
                  showTestButton: true,
                  onContinuePressed: (transcript) =>
                      _handleContinueOnVoiceSheet(context, transcript),
                  onTestingPressed: (transcript) =>
                      _handleContinueOnVoiceSheet(context, transcript),
                ),
              );
            },
          );
        },
      ),
      onDismiss: () {
        // Clear the current editing hole when the panel is closed
        roundReviewCubit.clearCurrentEditingHole();
      },
    );
  }

  Future<void> _handleContinueOnVoiceSheet(
    BuildContext context,
    String transcript,
  ) async {
    final RoundReviewCubit roundReviewCubit = BlocProvider.of<RoundReviewCubit>(
      context,
    );
    final PotentialDGHole? potentialHole = await locator
        .get<AiParsingService>()
        .parseSingleHole(
          voiceTranscript: transcript,
          userBag: [],
          holeNumber: hole.number,
          holePar: hole.par,
          holeFeet: hole.feet,
          courseName: round.courseName,
        );

    try {
      if (!context.mounted) return;
      if (potentialHole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transcript available')),
        );
        return;
      }
      final DGHole updatedHole = potentialHole.toDGHole();

      roundReviewCubit.updateHole(holeIndex, updatedHole);
      Navigator.of(context).pop();
    } catch (e, trace) {
      debugPrint(e.toString());
      debugPrint(trace.toString());
    }
  }
}
