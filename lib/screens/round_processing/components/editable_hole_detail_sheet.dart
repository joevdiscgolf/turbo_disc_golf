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
class EditableHoleDetailSheet extends StatefulWidget {
  const EditableHoleDetailSheet({
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
  final void Function(DiscThrow throw_) onThrowAdded;
  final void Function(int throwIndex, DiscThrow updatedThrow) onThrowEdited;
  final void Function(int throwIndex) onThrowDeleted;
  final VoidCallback onVoiceRecord;
  final VoidCallback? onRoundUpdated;

  @override
  State<EditableHoleDetailSheet> createState() =>
      _EditableHoleDetailSheetState();
}

class _EditableHoleDetailSheetState extends State<EditableHoleDetailSheet> {
  late final FocusNode _parFocusNode;
  late final FocusNode _distanceFocusNode;
  late final RoundConfirmationCubit _roundConfirmationCubit;

  @override
  void initState() {
    super.initState();
    _roundConfirmationCubit = BlocProvider.of<RoundConfirmationCubit>(context);
    _parFocusNode = FocusNode();
    _distanceFocusNode = FocusNode();

    // Set current editing hole in post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _roundConfirmationCubit.setCurrentEditingHole(widget.holeIndex);
      }
    });
  }

  @override
  void dispose() {
    _parFocusNode.dispose();
    _distanceFocusNode.dispose();
    // Clear the current editing hole when disposing
    _roundConfirmationCubit.clearCurrentEditingHole();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoundConfirmationCubit, RoundConfirmationState>(
      builder: (context, state) {
        if (state is! ConfirmingRoundActive) {
          return const SizedBox();
        }
        final PotentialDGHole? currentHole = state.currentEditingHole;

        if (currentHole == null) {
          return const SizedBox();
        }

        return SizedBox(
          height: MediaQuery.of(context).size.height - 64,
          child: EditHoleBody(
            holeNumber: currentHole.number ?? widget.holeIndex + 1,
            par: currentHole.par,
            distance: currentHole.feet,
            throws:
                currentHole.throws
                    ?.where((t) => t.hasRequiredFields)
                    .map((t) => t.toDiscThrow())
                    .toList() ??
                [],
            parFocusNode: _parFocusNode,
            distanceFocusNode: _distanceFocusNode,
            bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
            hasRequiredFields: currentHole.hasRequiredFields,
            onParChanged: (int newPar) =>
                _handleMetadataChanged(newPar: newPar, newDistance: null),
            onDistanceChanged: (int newDistance) =>
                _handleMetadataChanged(newPar: null, newDistance: newDistance),
            onThrowAdded: ({int? addThrowAtIndex}) =>
                _handleAddThrow(currentHole, addAtIndex: addThrowAtIndex),
            onThrowEdited: (throwIndex) =>
                _handleEditThrow(currentHole, throwIndex),
            onVoiceRecord: () => _handleVoiceRecord(currentHole),
            onDone: () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }

  void _handleMetadataChanged({
    required int? newPar,
    required int? newDistance,
  }) {
    widget.onMetadataChanged(newPar: newPar, newDistance: newDistance);
  }

  Future<void> _handleAddThrow(
    PotentialDGHole currentHole, {
    required int? addAtIndex,
  }) async {
    // Unfocus any active fields before showing dialog
    _parFocusNode.unfocus();
    _distanceFocusNode.unfocus();

    // Create a new throw with default values
    final DiscThrow newThrow = DiscThrow(
      index: currentHole.throws?.length ?? 0,
      purpose: ThrowPurpose.other,
      technique: ThrowTechnique.backhand,
    );

    await showDialog(
      context: context,
      builder: (context) => ThrowEditDialog(
        throw_: newThrow,
        throwIndex: currentHole.throws?.length ?? 0,
        holeNumber: currentHole.number ?? widget.holeIndex + 1,
        isNewThrow: true,
        onSave: (savedThrow) {
          widget.onThrowAdded(savedThrow);
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

    // Convert to DiscThrow from PotentialDiscThrow if needed
    final PotentialDiscThrow? potentialThrow = currentHole.throws?[throwIndex];
    if (potentialThrow == null || !potentialThrow.hasRequiredFields) {
      return; // Can't edit incomplete throw
    }
    final DiscThrow currentThrow = potentialThrow.toDiscThrow();

    await showDialog(
      context: context,
      builder: (context) => ThrowEditDialog(
        throw_: currentThrow,
        throwIndex: throwIndex,
        holeNumber: currentHole.number ?? widget.holeIndex + 1,
        onSave: (updatedThrow) {
          widget.onThrowEdited(throwIndex, updatedThrow);
          Navigator.of(context).pop();
        },
        onDelete: () {
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
