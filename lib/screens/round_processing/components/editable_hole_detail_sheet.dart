import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/edit_hole/edit_hole_body.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_edit_dialog.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

/// Bottom sheet showing hole details with editable metadata and throws.
///
/// Displays hole metadata with inline editing and a timeline of throws with edit/delete buttons.
/// Includes an "Add Throw" button to manually add new throws.
/// Design matches _HoleDetailDialog from holes_grid.dart.
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
  late PotentialDGHole _currentHole;
  late TextEditingController _holeNumberController;
  late TextEditingController _parController;
  late TextEditingController _distanceController;
  late FocusNode _holeNumberFocus;
  late FocusNode _parFocus;
  late FocusNode _distanceFocus;

  @override
  void initState() {
    super.initState();
    _currentHole = widget.potentialHole;
    widget.roundParser.addListener(_onRoundUpdated);

    _holeNumberController = TextEditingController(
      text: _currentHole.number?.toString() ?? '',
    );
    _parController = TextEditingController(
      text: _currentHole.par?.toString() ?? '',
    );
    _distanceController = TextEditingController(
      text: _currentHole.feet?.toString() ?? '',
    );

    _holeNumberFocus = FocusNode();
    _parFocus = FocusNode();
    _distanceFocus = FocusNode();
  }

  @override
  void dispose() {
    widget.roundParser.removeListener(_onRoundUpdated);
    _holeNumberController.dispose();
    _parController.dispose();
    _distanceController.dispose();
    _holeNumberFocus.dispose();
    _parFocus.dispose();
    _distanceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 64,
      child: EditableHoleBody(
        holeIndex: widget.holeIndex,
        potentialHole: widget.potentialHole,
        roundParser: widget.roundParser,
        bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
      ),
    );
  }

  void _onRoundUpdated() {
    if (widget.roundParser.potentialRound != null) {
      final PotentialDGRound round = widget.roundParser.potentialRound!;
      if (round.holes != null && widget.holeIndex < round.holes!.length) {
        setState(() {
          _currentHole = round.holes![widget.holeIndex];
          // Only update controllers if they don't have focus (user not editing)
          if (!_holeNumberFocus.hasFocus) {
            _holeNumberController.text = _currentHole.number?.toString() ?? '';
          }
          if (!_parFocus.hasFocus) {
            _parController.text = _currentHole.par?.toString() ?? '';
          }
          if (!_distanceFocus.hasFocus) {
            _distanceController.text = _currentHole.feet?.toString() ?? '';
          }
        });
      }
    }
  }

  void _saveMetadata() {
    final int? holeNumber = _holeNumberController.text.isEmpty
        ? null
        : int.tryParse(_holeNumberController.text);
    final int? par = _parController.text.isEmpty
        ? null
        : int.tryParse(_parController.text);
    final int? distance = _distanceController.text.isEmpty
        ? null
        : int.tryParse(_distanceController.text);

    // Create updated hole with new metadata
    final PotentialDGHole updatedHole = PotentialDGHole(
      number: holeNumber,
      par: par,
      feet: distance,
      throws: _currentHole.throws,
      holeType: _currentHole.holeType,
    );

    widget.roundParser.updatePotentialHole(widget.holeIndex, updatedHole);
  }

  void _editThrow(int throwIndex) {
    // Convert to DiscThrow from PotentialDiscThrow if needed
    final PotentialDiscThrow? potentialThrow = _currentHole.throws?[throwIndex];
    if (potentialThrow == null || !potentialThrow.hasRequiredFields) {
      return; // Can't edit incomplete throw
    }
    final DiscThrow currentThrow = potentialThrow.toDiscThrow();

    showDialog(
      context: context,
      builder: (context) => ThrowEditDialog(
        throw_: currentThrow,
        throwIndex: throwIndex,
        holeNumber: _currentHole.number ?? widget.holeIndex + 1,
        onSave: (updatedThrow) {
          widget.roundParser.updateThrow(
            widget.holeIndex,
            throwIndex,
            updatedThrow,
          );
          Navigator.of(context).pop();
        },
        onDelete: () {
          _deleteThrow(throwIndex);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _deleteThrow(int throwIndex) {
    final List<PotentialDiscThrow> updatedThrows =
        List<PotentialDiscThrow>.from(_currentHole.throws ?? []);
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
      number: _currentHole.number,
      par: _currentHole.par,
      feet: _currentHole.feet,
      throws: reindexedThrows,
      holeType: _currentHole.holeType,
    );

    // Update the entire hole including throws
    widget.roundParser.updatePotentialHole(widget.holeIndex, updatedHole);
  }

  void _addThrow() {
    // Create a new throw with default values
    final DiscThrow newThrow = DiscThrow(
      index: _currentHole.throws?.length ?? 0,
      purpose: ThrowPurpose.other,
      technique: ThrowTechnique.backhand,
    );

    showDialog(
      context: context,
      builder: (context) => ThrowEditDialog(
        throw_: newThrow,
        throwIndex: _currentHole.throws?.length ?? 0,
        holeNumber: _currentHole.number ?? widget.holeIndex + 1,
        isNewThrow: true,
        onSave: (savedThrow) {
          final List<PotentialDiscThrow> updatedThrows =
              List<PotentialDiscThrow>.from(_currentHole.throws ?? []);
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
            number: _currentHole.number,
            par: _currentHole.par,
            feet: _currentHole.feet,
            throws: updatedThrows,
            holeType: _currentHole.holeType,
          );

          // Update the entire hole including throws
          widget.roundParser.updatePotentialHole(widget.holeIndex, updatedHole);
          Navigator.of(context).pop();
        },
        onDelete: null, // No delete for new throws
      ),
    );
  }

  Color _getScoreColor() {
    if (!_currentHole.hasRequiredFields ||
        _currentHole.throws == null ||
        _currentHole.throws!.isEmpty) {
      return const Color(0xFF137e66); // Green for incomplete
    }

    final DGHole completeHole = _currentHole.toDGHole();
    final int relativeScore = completeHole.relativeHoleScore;

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
