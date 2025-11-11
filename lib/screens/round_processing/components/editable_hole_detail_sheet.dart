import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_throw_timeline.dart';
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
    final int? holeNumber = int.tryParse(_holeNumberController.text);
    final int? par = int.tryParse(_parController.text);
    final int? distance = int.tryParse(_distanceController.text);

    widget.roundParser.updatePotentialHoleMetadata(
      widget.holeIndex,
      number: holeNumber,
      par: par,
      feet: distance,
    );
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

  @override
  Widget build(BuildContext context) {
    final Color scoreColor = _getScoreColor();
    final int? score =
        _currentHole.hasRequiredFields &&
            _currentHole.throws != null &&
            _currentHole.throws!.isNotEmpty
        ? _currentHole.toDGHole().holeScore
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,

      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (matching _HoleDetailDialog design)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.golf_course, size: 24, color: scoreColor),
                        const SizedBox(width: 8),
                        Text(
                          'Hole ${_currentHole.number ?? '?'}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (score != null)
                      Container(
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
                      )
                    else
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(Icons.edit, color: scoreColor, size: 20),
                        ),
                      ),
                  ],
                ),
              ),

              // Hole info with editable fields (matching _HoleDetailDialog layout)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEditableInfoItem(
                      context,
                      'Par',
                      _parController,
                      _parFocus,
                      Icons.flag_outlined,
                    ),
                    _buildEditableInfoItem(
                      context,
                      'Distance',
                      _distanceController,
                      _distanceFocus,
                      Icons.straighten,
                      suffix: 'ft',
                    ),
                    _buildInfoItem(
                      context,
                      'Throws',
                      '${_currentHole.throws?.length ?? 0}',
                      Icons.sports_golf,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Throws timeline
              Flexible(
                child:
                    _currentHole.throws != null &&
                        _currentHole.throws!.isNotEmpty
                    ? EditableThrowTimeline(
                        throws: _currentHole.throws!
                            .where((t) => t.hasRequiredFields)
                            .map((t) => t.toDiscThrow())
                            .toList(),
                        onEditThrow: _editThrow,
                      )
                    : SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No throws recorded',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                        ),
                      ),
              ),

              // Add throw button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addThrow,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Throw'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),

              // Close button
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditableInfoItem(
    BuildContext context,
    String label,
    TextEditingController controller,
    FocusNode focusNode,
    IconData icon, {
    String? suffix,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        IntrinsicWidth(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              suffix: suffix != null
                  ? Text(suffix, style: Theme.of(context).textTheme.bodySmall)
                  : null,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _saveMetadata(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
