import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/hole_grid_item.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_hole_detail_panel.dart';
import 'package:turbo_disc_golf/screens/round_processing/panels/record_single_hole_panel_v2.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/state/round_confirmation_cubit.dart';
import 'package:turbo_disc_golf/state/round_confirmation_state.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

/// Grid of holes that opens editable dialogs when tapped.
///
/// Supports both complete holes (DGHole) and incomplete holes (PotentialDGHole).
class ConfirmationHolesGrid extends StatelessWidget {
  const ConfirmationHolesGrid({super.key, required this.potentialRound});

  final PotentialDGRound potentialRound;

  @override
  Widget build(BuildContext context) {
    if (potentialRound.holes == null || potentialRound.holes!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No holes found'),
        ),
      );
    }

    // Calculate width for 3 columns with no spacing
    final double screenWidth =
        MediaQuery.of(context).size.width - 32; // minus horizontal margin
    final double itemWidth = screenWidth / 3;

    // Determine the full range of holes (1 to max hole number)
    final int maxHoleNumber = potentialRound.holes!
        .map((h) => h.number ?? 0)
        .reduce((a, b) => a > b ? a : b);

    // Create a map of hole number to hole data and index for quick lookup
    final Map<int, PotentialDGHole> holeMap = {};
    final Map<int, int> holeIndexMap = {};
    for (int i = 0; i < potentialRound.holes!.length; i++) {
      final hole = potentialRound.holes![i];
      if (hole.number != null) {
        holeMap[hole.number!] = hole;
        holeIndexMap[hole.number!] = i;
      }
    }

    // Generate tiles for all holes from 1 to maxHoleNumber
    final List<Widget> holeTiles = [];
    for (int holeNum = 1; holeNum <= maxHoleNumber; holeNum++) {
      final PotentialDGHole? existingHole = holeMap[holeNum];
      final int? holeIndex = holeIndexMap[holeNum];

      // If hole doesn't exist in the round, create a minimal placeholder
      final PotentialDGHole hole =
          existingHole ??
          PotentialDGHole(
            number: holeNum,
            par: null, // Missing
            feet: null, // Missing
            throws: null, // Completely missing
          );

      holeTiles.add(
        SizedBox(
          width: itemWidth,
          child: _HoleGridItem(
            potentialHole: hole,
            holeIndex: holeIndex ?? -1, // -1 indicates hole doesn't exist yet
            isCompletelyMissing: existingHole == null,
          ),
        ),
      );
    }

    return Wrap(spacing: 0, runSpacing: 0, children: holeTiles);
  }
}

class _HoleGridItem extends StatefulWidget {
  const _HoleGridItem({
    required this.potentialHole,
    required this.holeIndex,
    this.isCompletelyMissing = false,
  });

  final PotentialDGHole potentialHole;
  final int holeIndex;
  final bool isCompletelyMissing;

  @override
  State<_HoleGridItem> createState() => _HoleGridItemState();
}

class _HoleGridItemState extends State<_HoleGridItem> {
  bool _isProcessing = false;

  void _showEditableHoleSheet(BuildContext context) {
    // If hole is completely missing, we can't edit it yet
    if (widget.isCompletelyMissing) {
      return;
    }

    final RoundConfirmationCubit roundConfirmationCubit =
        BlocProvider.of<RoundConfirmationCubit>(context);

    // Set the current editing hole when opening the panel
    roundConfirmationCubit.setCurrentEditingHole(widget.holeIndex);

    // Normal case: hole exists in the round
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (builderContext) =>
          BlocBuilder<RoundConfirmationCubit, RoundConfirmationState>(
            builder: (context, state) {
              if (state is! ConfirmingRoundActive) {
                return const SizedBox();
              }
              final PotentialDGHole? currentHole = state.currentEditingHole;
              if (currentHole == null) {
                return const SizedBox();
              }

              return EditableHoleDetailPanel(
                potentialHole: currentHole,
                holeIndex: widget.holeIndex,
                onMetadataChanged: ({int? newPar, int? newDistance}) =>
                    _handleMetadataChanged(
                      context,
                      widget.holeIndex,
                      newPar: newPar,
                      newDistance: newDistance,
                    ),
                onThrowAdded: (throw_, {int? addThrowAtIndex}) =>
                    roundConfirmationCubit.addThrow(
                      widget.holeIndex,
                      throw_,
                      addAfterThrowIndex: addThrowAtIndex,
                    ),
                onThrowEdited: (throwIndex, updatedThrow) =>
                    roundConfirmationCubit.updateThrow(
                      widget.holeIndex,
                      throwIndex,
                      updatedThrow,
                    ),
                onThrowDeleted: (throwIndex) => roundConfirmationCubit
                    .deleteThrow(widget.holeIndex, throwIndex),
                onReorder: (oldIndex, newIndex) => roundConfirmationCubit
                    .reorderThrows(widget.holeIndex, oldIndex, newIndex),
                onVoiceRecord: () =>
                    _handleVoiceRecord(context, currentHole, widget.holeIndex),
              );
            },
          ),
    ).then((_) {
      // Clear the current editing hole when the panel is closed
      roundConfirmationCubit.clearCurrentEditingHole();
    });
  }

  // Handler methods for EditableHoleDetailSheet callbacks
  void _handleMetadataChanged(
    BuildContext context,
    int holeIndex, {
    int? newPar,
    int? newDistance,
  }) {
    // Get the current hole from the cubit state to ensure we have the latest data
    final RoundConfirmationState state = context
        .read<RoundConfirmationCubit>()
        .state;
    if (state is! ConfirmingRoundActive) {
      return;
    }

    final PotentialDGHole? currentHole = state.potentialRound.holes?[holeIndex];
    if (currentHole == null) {
      return;
    }

    final PotentialDGHole updatedHole = PotentialDGHole(
      number: currentHole.number,
      par: newPar,
      feet: newDistance,
      throws: currentHole.throws,
      holeType: currentHole.holeType,
    );
    BlocProvider.of<RoundConfirmationCubit>(
      context,
    ).updatePotentialHole(holeIndex, updatedHole);
  }

  void _handleVoiceRecord(
    BuildContext contextToUse,
    PotentialDGHole currentHole,
    int holeIndex,
  ) {
    // displayBottomSheet(
    //   contextToUse,
    //   RecordSingleHolePanel(
    //     holeNumber: currentHole.number ?? holeIndex + 1,
    //     holePar: currentHole.par,
    //     holeFeet: currentHole.feet,
    //     isProcessing: _isProcessing,
    //     showTestButton: true,
    //     onContinuePressed: _handleContinueOnVoiceSheet,
    //     onTestingPressed: _handleContinueOnVoiceSheet,
    //   ),
    // );
    displayBottomSheet(
      contextToUse,
      RecordSingleHolePanelV2(
        holeNumber: currentHole.number ?? holeIndex + 1,
        holePar: currentHole.par,
        holeFeet: currentHole.feet,
        isProcessing: _isProcessing,
        showTestButton: true,
        onContinuePressed: _handleContinueOnVoiceSheet,
        onTestingPressed: _handleContinueOnVoiceSheet,
      ),
    );
  }

  Future<void> _handleContinueOnVoiceSheet(String transcript) async {
    setState(() {
      _isProcessing = true;
    });

    // Show loading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Re-processing hole with AI...')),
      );
    }

    // Call RoundParser to re-process the hole
    final RoundParser roundParser = locator.get<RoundParser>();
    final bool success = await roundParser.reProcessHole(
      holeIndex: widget.holeIndex,
      voiceTranscript: transcript,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    // Show result
    if (success) {
      // Sync the updated hole from RoundParser to RoundConfirmationCubit
      final PotentialDGHole? updatedHole =
          roundParser.potentialRound?.holes?[widget.holeIndex];

      if (updatedHole != null) {
        BlocProvider.of<RoundConfirmationCubit>(
          context,
        ).updatePotentialHole(widget.holeIndex, updatedHole);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hole re-processed successfully!'),
          backgroundColor: Color(0xFF137e66),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${roundParser.lastError.isNotEmpty ? roundParser.lastError : 'Failed to re-process hole'}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if hole is incomplete
    final bool isIncomplete = !widget.potentialHole.hasRequiredFields;

    // Calculate score for complete holes
    int? score;
    int? relativeScore;
    if (!isIncomplete) {
      final int throwsCount = widget.potentialHole.throws?.length ?? 0;
      final int penaltyStrokes =
          widget.potentialHole.throws?.fold<int>(
            0,
            (prev, t) => prev + (t.penaltyStrokes ?? 0),
          ) ??
          0;
      score = throwsCount + penaltyStrokes;
      final int par = widget.potentialHole.par ?? 3;
      relativeScore = score - par;
    }

    return HoleGridItem(
      holeNumber: widget.potentialHole.number ?? 0,
      holePar: widget.potentialHole.par,
      holeFeet: widget.potentialHole.feet,
      score: score,
      relativeScore: relativeScore,
      isIncomplete: isIncomplete,
      onTap: () => _showEditableHoleSheet(context),
      heroTag: 'editable_hole_${widget.potentialHole.number}',
    );
  }
}
