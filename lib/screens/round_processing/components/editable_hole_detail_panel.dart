import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/edit_hole/edit_hole_body.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_edit_dialog.dart';
import 'package:turbo_disc_golf/state/round_confirmation_cubit.dart';
import 'package:turbo_disc_golf/state/round_confirmation_state.dart';

/// Bottom sheet showing hole details with editable metadata and throws.
///
/// This is a generic component that displays and edits hole data, but doesn't handle
/// the business logic of saving changes. The parent component is responsible for
/// providing callbacks that handle the actual save logic.
///
/// Displays hole metadata with inline editing and a timeline of throws with edit/delete buttons.
/// Includes an "Add Throw" button to manually add new throws and a "Voice" button for voice recording.
/// Uses Provider for state management.
class EditableHoleDetailPanel extends StatefulWidget {
  const EditableHoleDetailPanel({
    super.key,
    required this.potentialHole,
    required this.holeIndex,
    required this.onMetadataChanged,
    required this.onThrowAdded,
    required this.onThrowEdited,
    required this.onThrowDeleted,
    required this.onVoiceRecord,
    this.onRoundUpdated,
  });

  final PotentialDGHole potentialHole;
  final int holeIndex;

  // Callbacks for handling edits (parent handles the business logic)
  final void Function({required int? newPar, required int? newDistance})
  onMetadataChanged;
  final void Function(DiscThrow throw_, {int? addThrowAtIndex}) onThrowAdded;
  final void Function(int throwIndex, DiscThrow updatedThrow) onThrowEdited;
  final void Function(int throwIndex) onThrowDeleted;
  final VoidCallback onVoiceRecord;
  final VoidCallback? onRoundUpdated;

  @override
  State<EditableHoleDetailPanel> createState() =>
      _EditableHoleDetailPanelState();
}

class _EditableHoleDetailPanelState extends State<EditableHoleDetailPanel> {
  late final FocusNode _parFocusNode;
  late final FocusNode _distanceFocusNode;
  RoundConfirmationCubit? _roundConfirmationCubit;
  late PotentialDGHole _localHole;

  @override
  void initState() {
    super.initState();
    _parFocusNode = FocusNode();
    _distanceFocusNode = FocusNode();
    _localHole = widget.potentialHole;

    // Try to get the cubit if it exists (for round confirmation flow)
    try {
      _roundConfirmationCubit = BlocProvider.of<RoundConfirmationCubit>(context);

      // Set current editing hole in post frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _roundConfirmationCubit?.setCurrentEditingHole(widget.holeIndex);
        }
      });
    } catch (e) {
      // No cubit available - using local state (for completed rounds in course tab)
      _roundConfirmationCubit = null;
    }
  }

  @override
  void dispose() {
    _parFocusNode.dispose();
    _distanceFocusNode.dispose();
    // Clear the current editing hole when disposing
    _roundConfirmationCubit?.clearCurrentEditingHole();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If we have a cubit, use it for state management
    if (_roundConfirmationCubit != null) {
      return BlocBuilder<RoundConfirmationCubit, RoundConfirmationState>(
        builder: (context, state) {
          if (state is! ConfirmingRoundActive) {
            return const SizedBox();
          }
          final PotentialDGHole? currentHole = state.currentEditingHole;

          if (currentHole == null) {
            return const SizedBox();
          }

          return _buildEditHoleBody(currentHole);
        },
      );
    }

    // Otherwise, use local state
    return _buildEditHoleBody(_localHole);
  }

  Widget _buildEditHoleBody(PotentialDGHole currentHole) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 64,
      child: EditHoleBody(
        holeNumber: currentHole.number ?? widget.holeIndex + 1,
        par: currentHole.par,
        distance: currentHole.feet,
        throws: currentHole.throws ?? [],
        parFocusNode: _parFocusNode,
        distanceFocusNode: _distanceFocusNode,
        bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
        hasRequiredFields: currentHole.hasRequiredFields,
        onParChanged: (int newPar) => _handleMetadataChanged(
          currentHole: currentHole,
          newPar: newPar,
          newDistance: null,
        ),
        onDistanceChanged: (int newDistance) => _handleMetadataChanged(
          currentHole: currentHole,
          newPar: null,
          newDistance: newDistance,
        ),
        onThrowAdded: ({int? addThrowAtIndex}) =>
            _handleAddThrow(currentHole, addAtIndex: addThrowAtIndex),
        onThrowEdited: (throwIndex) =>
            _handleEditThrow(currentHole, throwIndex),
        onVoiceRecord: () => _handleVoiceRecord(currentHole),
        onDone: () => _handleDone(currentHole),
      ),
    );
  }

  void _handleMetadataChanged({
    required PotentialDGHole currentHole,
    required int? newPar,
    required int? newDistance,
  }) {
    // Update local state if not using cubit
    if (_roundConfirmationCubit == null) {
      setState(() {
        _localHole = PotentialDGHole(
          number: currentHole.number,
          par: newPar ?? currentHole.par,
          feet: newDistance ?? currentHole.feet,
          throws: currentHole.throws,
          holeType: currentHole.holeType,
        );
      });
    }

    // Call parent callback to update the source
    widget.onMetadataChanged(
      newPar: newPar ?? currentHole.par,
      newDistance: newDistance ?? currentHole.feet,
    );
  }

  void _handleDone(PotentialDGHole currentHole) {
    // For completed rounds (no cubit), validate before closing
    if (_roundConfirmationCubit == null) {
      // Check if hole has required fields
      if (!_isValidForSave(_localHole)) {
        _showValidationError(_localHole);
        return;
      }
    }

    // Close the panel
    Navigator.of(context).pop();
  }

  bool _isValidForSave(PotentialDGHole hole) {
    // Check all required fields for saving a completed round
    return hole.number != null &&
        hole.par != null &&
        hole.par! > 0 &&
        hole.feet != null && // Distance is required for completed rounds
        hole.throws != null &&
        hole.throws!.isNotEmpty &&
        hole.hasThrowInBasket;
  }

  void _showValidationError(PotentialDGHole hole) {
    final List<String> missingFields = [];
    if (hole.number == null) missingFields.add('hole number');
    if (hole.par == null || hole.par == 0) missingFields.add('par');
    if (hole.feet == null) missingFields.add('distance');
    if (hole.throws == null || hole.throws!.isEmpty) {
      missingFields.add('throws');
    } else if (!hole.hasThrowInBasket) {
      missingFields.add('basket throw');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cannot save: Missing ${missingFields.join(', ')}',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleAddThrow(
    PotentialDGHole currentHole, {
    required int? addAtIndex,
  }) async {
    // Unfocus any active fields before showing dialog
    _parFocusNode.unfocus();
    _distanceFocusNode.unfocus();

    // Calculate the display throw number for the dialog
    // Semantic convention: addAtIndex represents "insert AFTER throw at this index"
    // - addAtIndex=0 means insert after throw 0, so new throw will be throw 1
    // - addAtIndex=null means append to end
    // The actual insertion logic is handled by the parent component
    final int currentThrowCount = currentHole.throws?.length ?? 0;
    final int displayThrowNumber = addAtIndex != null
        ? addAtIndex + 1
        : currentThrowCount;

    // Create a new throw with default values
    // The index is only for dialog display; parent will recalculate during insertion
    final DiscThrow newThrow = DiscThrow(
      index: displayThrowNumber,
      purpose: ThrowPurpose.other,
      technique: ThrowTechnique.backhand,
    );

    await showDialog(
      context: context,
      builder: (context) => ThrowEditDialog(
        throw_: newThrow,
        throwIndex: displayThrowNumber,
        holeNumber: currentHole.number ?? widget.holeIndex + 1,
        isNewThrow: true,
        onSave: (savedThrow) {
          // Update local state if not using cubit
          if (_roundConfirmationCubit == null) {
            setState(() {
              final List<DiscThrow> updatedThrows = List<DiscThrow>.from(
                _localHole.throws ?? [],
              );
              final int insertIndex = addAtIndex != null
                  ? addAtIndex + 1
                  : updatedThrows.length;
              updatedThrows.insert(insertIndex, savedThrow);

              // Reindex throws
              final List<DiscThrow> reindexedThrows = updatedThrows
                  .asMap()
                  .entries
                  .map((entry) => DiscThrow(
                        index: entry.key,
                        purpose: entry.value.purpose,
                        technique: entry.value.technique,
                        puttStyle: entry.value.puttStyle,
                        shotShape: entry.value.shotShape,
                        stance: entry.value.stance,
                        power: entry.value.power,
                        distanceFeetBeforeThrow: entry.value.distanceFeetBeforeThrow,
                        distanceFeetAfterThrow: entry.value.distanceFeetAfterThrow,
                        elevationChangeFeet: entry.value.elevationChangeFeet,
                        windDirection: entry.value.windDirection,
                        windStrength: entry.value.windStrength,
                        resultRating: entry.value.resultRating,
                        landingSpot: entry.value.landingSpot,
                        fairwayWidth: entry.value.fairwayWidth,
                        penaltyStrokes: entry.value.penaltyStrokes,
                        notes: entry.value.notes,
                        rawText: entry.value.rawText,
                        parseConfidence: entry.value.parseConfidence,
                        discName: entry.value.discName,
                        disc: entry.value.disc,
                      ))
                  .toList();

              _localHole = PotentialDGHole(
                number: _localHole.number,
                par: _localHole.par,
                feet: _localHole.feet,
                throws: reindexedThrows,
                holeType: _localHole.holeType,
              );
            });
          }

          // Pass the original addAtIndex to parent - it handles actual insertion
          widget.onThrowAdded(savedThrow, addThrowAtIndex: addAtIndex);
          Navigator.of(context).pop();
        },
        onDelete: null, // No delete for new throws
      ),
    );

    // Unfocus again after dialog closes to prevent keyboard from popping up
    if (mounted) {
      _parFocusNode.unfocus();
      _distanceFocusNode.unfocus();
    }
  }

  Future<void> _handleEditThrow(
    PotentialDGHole currentHole,
    int throwIndex,
  ) async {
    // Unfocus any active fields before showing dialog
    _parFocusNode.unfocus();
    _distanceFocusNode.unfocus();

    // Convert to DiscThrow from DiscThrow if needed
    final DiscThrow? currentThrow = currentHole.throws?[throwIndex];
    if (currentThrow == null) {
      return; // Can't edit incomplete throw
    }

    await showDialog(
      context: context,
      builder: (context) => ThrowEditDialog(
        throw_: currentThrow,
        throwIndex: throwIndex,
        holeNumber: currentHole.number ?? widget.holeIndex + 1,
        onSave: (updatedThrow) {
          // Update local state if not using cubit
          if (_roundConfirmationCubit == null) {
            setState(() {
              final List<DiscThrow> updatedThrows = List<DiscThrow>.from(
                _localHole.throws ?? [],
              );
              updatedThrows[throwIndex] = updatedThrow;

              _localHole = PotentialDGHole(
                number: _localHole.number,
                par: _localHole.par,
                feet: _localHole.feet,
                throws: updatedThrows,
                holeType: _localHole.holeType,
              );
            });
          }

          widget.onThrowEdited(throwIndex, updatedThrow);
          Navigator.of(context).pop();
        },
        onDelete: () {
          // Update local state if not using cubit
          if (_roundConfirmationCubit == null) {
            setState(() {
              final List<DiscThrow> updatedThrows = List<DiscThrow>.from(
                _localHole.throws ?? [],
              );
              updatedThrows.removeAt(throwIndex);

              // Reindex remaining throws
              final List<DiscThrow> reindexedThrows = updatedThrows
                  .asMap()
                  .entries
                  .map((entry) => DiscThrow(
                        index: entry.key,
                        purpose: entry.value.purpose,
                        technique: entry.value.technique,
                        puttStyle: entry.value.puttStyle,
                        shotShape: entry.value.shotShape,
                        stance: entry.value.stance,
                        power: entry.value.power,
                        distanceFeetBeforeThrow: entry.value.distanceFeetBeforeThrow,
                        distanceFeetAfterThrow: entry.value.distanceFeetAfterThrow,
                        elevationChangeFeet: entry.value.elevationChangeFeet,
                        windDirection: entry.value.windDirection,
                        windStrength: entry.value.windStrength,
                        resultRating: entry.value.resultRating,
                        landingSpot: entry.value.landingSpot,
                        fairwayWidth: entry.value.fairwayWidth,
                        penaltyStrokes: entry.value.penaltyStrokes,
                        notes: entry.value.notes,
                        rawText: entry.value.rawText,
                        parseConfidence: entry.value.parseConfidence,
                        discName: entry.value.discName,
                        disc: entry.value.disc,
                      ))
                  .toList();

              _localHole = PotentialDGHole(
                number: _localHole.number,
                par: _localHole.par,
                feet: _localHole.feet,
                throws: reindexedThrows,
                holeType: _localHole.holeType,
              );
            });
          }

          widget.onThrowDeleted(throwIndex);
          Navigator.of(context).pop();
        },
      ),
    );

    // Unfocus again after dialog closes to prevent keyboard from popping up
    if (mounted) {
      _parFocusNode.unfocus();
      _distanceFocusNode.unfocus();
    }
  }

  void _handleVoiceRecord(PotentialDGHole currentHole) {
    widget.onVoiceRecord();
  }
}
