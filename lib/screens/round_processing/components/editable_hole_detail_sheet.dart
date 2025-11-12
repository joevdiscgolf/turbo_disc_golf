import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turbo_disc_golf/components/edit_hole/edit_hole_body.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/hole_re_record_dialog.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_edit_dialog.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/state/hole_editing_state.dart';

/// Bottom sheet showing hole details with editable metadata and throws.
///
/// Displays hole metadata with inline editing and a timeline of throws with edit/delete buttons.
/// Includes an "Add Throw" button to manually add new throws.
/// Uses Provider for state management.
class EditableHoleDetailSheet extends StatefulWidget {
  const EditableHoleDetailSheet({
    super.key,
    required this.potentialHole,
    required this.holeIndex,
    required this.roundParser,
  });

  final PotentialDGHole potentialHole;
  final int holeIndex;
  final RoundParser roundParser;

  @override
  State<EditableHoleDetailSheet> createState() =>
      _EditableHoleDetailSheetState();
}

class _EditableHoleDetailSheetState extends State<EditableHoleDetailSheet> {
  @override
  void initState() {
    super.initState();
    widget.roundParser.addListener(_onRoundUpdated);
  }

  @override
  void dispose() {
    widget.roundParser.removeListener(_onRoundUpdated);
    super.dispose();
  }

  void _onRoundUpdated() {
    if (mounted &&
        widget.roundParser.potentialRound != null &&
        widget.roundParser.potentialRound!.holes != null &&
        widget.holeIndex < widget.roundParser.potentialRound!.holes!.length) {
      final PotentialDGHole updatedHole =
          widget.roundParser.potentialRound!.holes![widget.holeIndex];

      // Update the provider state
      context.read<HoleEditingState>().updateFromHole(updatedHole);
    }
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
    final PotentialDGHole currentHole = holeState.currentHole;

    // Create updated hole with new metadata
    final PotentialDGHole updatedHole = PotentialDGHole(
      number: currentHole.number,
      par: metadata['par'],
      feet: metadata['distance'],
      throws: currentHole.throws,
      holeType: currentHole.holeType,
    );

    widget.roundParser.updatePotentialHole(widget.holeIndex, updatedHole);
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
          final List<PotentialDiscThrow> updatedThrows =
              List<PotentialDiscThrow>.from(currentHole.throws ?? []);
          updatedThrows.add(
            PotentialDiscThrow(
              index: savedThrow.index,
              purpose: savedThrow.purpose,
              technique: savedThrow.technique,
              puttStyle: savedThrow.puttStyle,
              shotShape: savedThrow.shotShape,
              stance: savedThrow.stance,
              power: savedThrow.power,
              distanceFeetBeforeThrow: savedThrow.distanceFeetBeforeThrow,
              distanceFeetAfterThrow: savedThrow.distanceFeetAfterThrow,
              elevationChangeFeet: savedThrow.elevationChangeFeet,
              windDirection: savedThrow.windDirection,
              windStrength: savedThrow.windStrength,
              resultRating: savedThrow.resultRating,
              landingSpot: savedThrow.landingSpot,
              fairwayWidth: savedThrow.fairwayWidth,
              penaltyStrokes: savedThrow.penaltyStrokes,
              notes: savedThrow.notes,
              rawText: savedThrow.rawText,
              parseConfidence: savedThrow.parseConfidence,
              discName: savedThrow.discName,
              disc: savedThrow.disc,
            ),
          );

          final PotentialDGHole updatedHole = PotentialDGHole(
            number: currentHole.number,
            par: currentHole.par,
            feet: currentHole.feet,
            throws: updatedThrows,
            holeType: currentHole.holeType,
          );

          // Update the entire hole including throws
          widget.roundParser.updatePotentialHole(widget.holeIndex, updatedHole);
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
          widget.roundParser.updateThrow(
            widget.holeIndex,
            throwIndex,
            updatedThrow,
          );
          Navigator.of(context).pop();
        },
        onDelete: () {
          _handleDeleteThrow(currentHole, throwIndex);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _handleDeleteThrow(PotentialDGHole currentHole, int throwIndex) {
    final List<PotentialDiscThrow> updatedThrows =
        List<PotentialDiscThrow>.from(currentHole.throws ?? []);
    updatedThrows.removeAt(throwIndex);

    // Reindex remaining throws
    final List<PotentialDiscThrow> reindexedThrows = updatedThrows
        .asMap()
        .entries
        .map((entry) {
          final PotentialDiscThrow throw_ = entry.value;
          return PotentialDiscThrow(
            index: entry.key,
            purpose: throw_.purpose,
            technique: throw_.technique,
            puttStyle: throw_.puttStyle,
            shotShape: throw_.shotShape,
            stance: throw_.stance,
            power: throw_.power,
            distanceFeetBeforeThrow: throw_.distanceFeetBeforeThrow,
            distanceFeetAfterThrow: throw_.distanceFeetAfterThrow,
            elevationChangeFeet: throw_.elevationChangeFeet,
            windDirection: throw_.windDirection,
            windStrength: throw_.windStrength,
            resultRating: throw_.resultRating,
            landingSpot: throw_.landingSpot,
            fairwayWidth: throw_.fairwayWidth,
            penaltyStrokes: throw_.penaltyStrokes,
            notes: throw_.notes,
            rawText: throw_.rawText,
            parseConfidence: throw_.parseConfidence,
            discName: throw_.discName,
            disc: throw_.disc,
          );
        })
        .toList();

    // Update as potential hole
    final PotentialDGHole updatedHole = PotentialDGHole(
      number: currentHole.number,
      par: currentHole.par,
      feet: currentHole.feet,
      throws: reindexedThrows,
      holeType: currentHole.holeType,
    );

    // Update the entire hole including throws
    widget.roundParser.updatePotentialHole(widget.holeIndex, updatedHole);
  }

  void _handleVoiceRecord(PotentialDGHole currentHole) {
    showDialog(
      context: context,
      builder: (context) => HoleReRecordDialog(
        holeNumber: currentHole.number ?? widget.holeIndex + 1,
        holeIndex: widget.holeIndex,
        holePar: currentHole.par,
        holeFeet: currentHole.feet,
        onReProcessed: () {
          // The hole data will be automatically updated via the _onRoundUpdated listener
          // No need to manually update state here
        },
      ),
    );
  }
}
