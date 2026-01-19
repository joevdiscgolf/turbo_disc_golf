import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/add_throw_panel.dart';
import 'package:turbo_disc_golf/components/edit_hole/edit_hole_body.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_edit_dialog.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

/// Bottom sheet showing hole details with editable metadata and throws.
///
/// This is a generic component that displays and edits hole data, but doesn't handle
/// the business logic of saving changes. The parent component is responsible for
/// providing callbacks that handle the actual save logic.
///
/// Displays hole metadata with inline editing and a timeline of throws with edit/delete buttons.
/// Includes an "Add Throw" button to manually add new throws and a "Voice" button for voice recording.
/// This component is fully callback-driven and can be used in different contexts
/// (round confirmation, round review, etc.) by providing appropriate callbacks.
class EditableHoleDetailPanel extends StatefulWidget {
  const EditableHoleDetailPanel({
    super.key,
    required this.potentialHole,
    required this.holeIndex,
    required this.onMetadataChanged,
    required this.onThrowAdded,
    required this.onThrowEdited,
    required this.onThrowDeleted,
    required this.onReorder,
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
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onVoiceRecord;
  final VoidCallback? onRoundUpdated;

  @override
  State<EditableHoleDetailPanel> createState() =>
      _EditableHoleDetailPanelState();
}

class _EditableHoleDetailPanelState extends State<EditableHoleDetailPanel> {
  late final FocusNode _parFocusNode;
  late final FocusNode _distanceFocusNode;

  @override
  void initState() {
    super.initState();
    _parFocusNode = FocusNode();
    _distanceFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _parFocusNode.dispose();
    _distanceFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EditableHoleDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.potentialHole != widget.potentialHole) {
      debugPrint('🔄 EditableHoleDetailPanel received new potentialHole');
      debugPrint(
        '   Old throws: ${oldWidget.potentialHole.throws?.length ?? 0}',
      );
      debugPrint('   New throws: ${widget.potentialHole.throws?.length ?? 0}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final PotentialDGHole currentHole = widget.potentialHole;

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
        onVoiceRecord: () => widget.onVoiceRecord(),
        onDone: () => Navigator.of(context).pop(),
        onReorder: (oldIndex, newIndex) => widget.onReorder(oldIndex, newIndex),
      ),
    );
  }

  void _handleMetadataChanged({
    required PotentialDGHole currentHole,
    required int? newPar,
    required int? newDistance,
  }) {
    // Preserve the current value of whichever field isn't being changed
    widget.onMetadataChanged(
      newPar: newPar ?? currentHole.par,
      newDistance: newDistance ?? currentHole.feet,
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

    if (useAddThrowPanelV2) {
      // Determine the previous throw for smart auto-selection
      // If addAtIndex is null, previous throw is the last throw
      // If addAtIndex is a number, previous throw is the throw at that index
      final DiscThrow? previousThrow = addAtIndex != null
          ? (currentHole.throws != null && addAtIndex < currentHole.throws!.length
              ? currentHole.throws![addAtIndex]
              : null)
          : (currentHole.throws?.isNotEmpty ?? false
              ? currentHole.throws!.last
              : null);

      // Track modal opened
      locator.get<LoggingService>().track('Modal Opened', properties: {
        'modal_type': 'bottom_sheet',
        'modal_name': 'Add Throw Panel',
        'hole_number': currentHole.number ?? widget.holeIndex + 1,
        'is_new_throw': true,
      });

      // Show the panel
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddThrowPanel(
          existingThrow: null,
          previousThrow: previousThrow,
          throwIndex: 0,
          onSave: (savedThrow) {
            // Pass the original addAtIndex to parent - it handles actual insertion
            widget.onThrowAdded(savedThrow, addThrowAtIndex: addAtIndex);
            Navigator.of(context).pop();
          },
          onDelete: null, // No delete for new throws
          isNewThrow: true, // or false for editing
        ),
      );
    } else {
      // Track modal opened
      locator.get<LoggingService>().track('Modal Opened', properties: {
        'modal_type': 'dialog',
        'modal_name': 'Throw Edit Dialog',
        'hole_number': currentHole.number ?? widget.holeIndex + 1,
        'is_new_throw': true,
      });

      await showDialog(
        context: context,
        builder: (context) => ThrowEditDialog(
          throw_: newThrow,
          throwIndex: displayThrowNumber,
          isNewThrow: true,
          onSave: (savedThrow) {
            // Pass the original addAtIndex to parent - it handles actual insertion
            widget.onThrowAdded(savedThrow, addThrowAtIndex: addAtIndex);
            Navigator.of(context).pop();
          },
          onDelete: null, // No delete for new throws
        ),
      );
    }

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

    if (useAddThrowPanelV2) {
      // Determine the previous throw for smart auto-selection
      final DiscThrow? previousThrow = throwIndex > 0 &&
              currentHole.throws != null &&
              throwIndex - 1 < currentHole.throws!.length
          ? currentHole.throws![throwIndex - 1]
          : null;

      // Track modal opened
      locator.get<LoggingService>().track('Modal Opened', properties: {
        'modal_type': 'bottom_sheet',
        'modal_name': 'Add Throw Panel',
        'hole_number': currentHole.number ?? widget.holeIndex + 1,
        'throw_index': throwIndex,
        'is_new_throw': false,
      });

      // Show the panel
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddThrowPanel(
          existingThrow: currentThrow,
          previousThrow: previousThrow,
          throwIndex: throwIndex,
          onSave: (updatedThrow) {
            widget.onThrowEdited(throwIndex, updatedThrow);
            Navigator.of(context).pop();
          },
          onDelete: () {
            widget.onThrowDeleted(throwIndex);
            Navigator.of(context).pop();
          },
          isNewThrow: false,
        ),
      );
    } else {
      // Track modal opened
      locator.get<LoggingService>().track('Modal Opened', properties: {
        'modal_type': 'dialog',
        'modal_name': 'Throw Edit Dialog',
        'hole_number': currentHole.number ?? widget.holeIndex + 1,
        'throw_index': throwIndex,
        'is_new_throw': false,
      });

      await showDialog(
        context: context,
        builder: (context) => ThrowEditDialog(
          throw_: currentThrow,
          throwIndex: throwIndex,
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

    // Unfocus again after dialog closes to prevent keyboard from popping up
    if (mounted) {
      _parFocusNode.unfocus();
      _distanceFocusNode.unfocus();
    }
  }
}
