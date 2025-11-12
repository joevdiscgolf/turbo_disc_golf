import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turbo_disc_golf/components/edit_hole/edit_hole_body.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_edit_dialog.dart';
import 'package:turbo_disc_golf/state/hole_editing_state.dart';

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
  final void Function(int? par, int? distance) onMetadataChanged;
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
  @override
  void initState() {
    super.initState();
    // Call the optional callback if provided (parent may listen to round updates)
    if (widget.onRoundUpdated != null) {
      // Parent will handle round updates
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HoleEditingState(initialHole: widget.potentialHole),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 64,
        child: Consumer<HoleEditingState>(
          builder: (context, holeState, _) {
            final PotentialDGHole currentHole = holeState.currentHole;

            return EditableHoleBody(
              holeNumber: currentHole.number ?? widget.holeIndex + 1,
              par: currentHole.par ?? 0,
              distance: currentHole.feet ?? 0,
              throws: currentHole.throws
                      ?.where((t) => t.hasRequiredFields)
                      .map((t) => t.toDiscThrow())
                      .toList() ??
                  [],
              parController: holeState.parController,
              distanceController: holeState.distanceController,
              parFocusNode: holeState.parFocus,
              distanceFocusNode: holeState.distanceFocus,
              bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
              hasRequiredFields: currentHole.hasRequiredFields,
              onParChanged: () => _handleMetadataChanged(holeState),
              onDistanceChanged: () => _handleMetadataChanged(holeState),
              onThrowAdded: () => _handleAddThrow(currentHole),
              onThrowEdited: (throwIndex) =>
                  _handleEditThrow(currentHole, throwIndex),
              onVoiceRecord: () => _handleVoiceRecord(currentHole),
              onDone: () => Navigator.of(context).pop(),
            );
          },
        ),
      ),
    );
  }

  void _handleMetadataChanged(HoleEditingState holeState) {
    final Map<String, int?> metadata = holeState.getMetadataValues();
    widget.onMetadataChanged(metadata['par'], metadata['distance']);
  }

  void _handleAddThrow(PotentialDGHole currentHole) {
    // Create a new throw with default values
    final DiscThrow newThrow = DiscThrow(
      index: currentHole.throws?.length ?? 0,
      purpose: ThrowPurpose.other,
      technique: ThrowTechnique.backhand,
    );

    showDialog(
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
  }

  void _handleEditThrow(PotentialDGHole currentHole, int throwIndex) {
    // Convert to DiscThrow from PotentialDiscThrow if needed
    final PotentialDiscThrow? potentialThrow = currentHole.throws?[throwIndex];
    if (potentialThrow == null || !potentialThrow.hasRequiredFields) {
      return; // Can't edit incomplete throw
    }
    final DiscThrow currentThrow = potentialThrow.toDiscThrow();

    showDialog(
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
  }

  void _handleVoiceRecord(PotentialDGHole currentHole) {
    widget.onVoiceRecord();
  }
}
