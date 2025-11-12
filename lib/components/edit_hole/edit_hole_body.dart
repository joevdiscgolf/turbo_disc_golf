import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/edit_hole/edit_par_distance_row.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_throw_timeline.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/hole_re_record_dialog.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_edit_dialog.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class EditableHoleBody extends StatefulWidget {
  const EditableHoleBody({
    super.key,
    required this.potentialHole,
    required this.holeIndex,
    required this.roundParser,
    required this.bottomViewPadding,

    this.inWalkthroughSheet = false,
  });

  final PotentialDGHole potentialHole;
  final int holeIndex;
  final RoundParser roundParser;
  final double bottomViewPadding;
  final bool inWalkthroughSheet;

  @override
  State<EditableHoleBody> createState() => _EditableHoleBodyState();
}

class _EditableHoleBodyState extends State<EditableHoleBody> {
  late PotentialDGHole _currentHole;
  late TextEditingController _holeNumberController;
  late TextEditingController _parController;
  late TextEditingController _distanceController;
  late FocusNode _holeNumberFocus;
  late FocusNode _parFocus;
  late FocusNode _distanceFocus;

  bool get _hasRequiredFields => widget.potentialHole.hasRequiredFields == true;

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
    final double borderRadius = widget.inWalkthroughSheet ? 0 : 16;

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside text fields
        FocusScope.of(context).unfocus();
      },
      child: Container(
        padding: EdgeInsets.only(bottom: widget.bottomViewPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Theme.of(context).colorScheme.surface,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (matching _HoleDetailDialog design)
            _holeNumberBanner(borderRadius),
            EditParDistanceRow(
              par: _currentHole.par ?? 0,
              distance: _currentHole.feet ?? 0,
              strokes: _currentHole.throws?.length ?? 0,
              onParChanged: (int newPar) {
                _updatePotentialHoleMetadata();
              },
              onDistanceChanged: (int newDistance) {
                _updatePotentialHoleMetadata();
              },
              parFocusNode: _parFocus,
              distanceFocusNode: _distanceFocus,
              parController: _parController,
              distanceController: _distanceController,
            ),

            // Throws timeline
            Expanded(
              child:
                  _currentHole.throws != null && _currentHole.throws!.isNotEmpty
                  ? EditableThrowTimeline(
                      throws: _currentHole.throws!
                          .where((t) => t.hasRequiredFields)
                          .map((t) => t.toDiscThrow())
                          .toList(),
                      onEditThrow: _editThrow,
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
                          onPressed: _addThrow,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryButton(
                          height: 56,
                          width: double.infinity,
                          label: 'Voice',
                          onPressed: _reRecordWithVoice,
                          backgroundColor: const Color(0xFF9D4EDD),
                          icon: Icons.mic,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  PrimaryButton(
                    height: 56,
                    width: double.infinity,
                    label: 'Done',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
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

  Widget _holeNumberBanner(double borderRadius) {
    final Color scoreColor = _getScoreColor();
    final int? score = _getScore();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scoreColor.withValues(
          alpha: !_currentHole.hasRequiredFields ? 0.2 : 0.1,
        ),
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
                color: _hasRequiredFields ? scoreColor : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                'Hole ${_currentHole.number ?? '?'}',
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
                      color: _hasRequiredFields ? Colors.white : Colors.black,
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

  void _updatePotentialHoleMetadata() {
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

  void _reRecordWithVoice() {
    showDialog(
      context: context,
      builder: (context) => HoleReRecordDialog(
        holeNumber: _currentHole.number ?? widget.holeIndex + 1,
        holeIndex: widget.holeIndex,
        holePar: _currentHole.par,
        holeFeet: _currentHole.feet,
        onReProcessed: () {
          // The hole data will be automatically updated via the _onRoundUpdated listener
          // No need to manually update state here
        },
      ),
    );
  }

  int? _getScore() {
    return _currentHole.hasRequiredFields &&
            _currentHole.throws != null &&
            _currentHole.throws!.isNotEmpty
        ? _currentHole.toDGHole().holeScore
        : null;
  }

  Color _getScoreColor() {
    if (!_currentHole.hasRequiredFields) {
      return const Color(0xFFFFEB3B); // Bright yellow for incomplete
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
