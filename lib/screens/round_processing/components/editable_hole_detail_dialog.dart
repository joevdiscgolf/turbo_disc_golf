import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_throw_timeline.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/incomplete_hole_detail_content.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_edit_dialog.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

/// Dialog showing hole details with editable throws.
///
/// Displays hole metadata and a timeline of throws with edit/delete buttons.
/// Includes an "Add Throw" button to manually add new throws.
/// If the hole is incomplete, shows the IncompleteHoleDetailContent instead.
class EditableHoleDetailDialog extends StatefulWidget {
  const EditableHoleDetailDialog({
    super.key,
    required this.potentialHole,
    required this.holeIndex,
    required this.roundParser,
  });

  final PotentialDGHole potentialHole;
  final int holeIndex;
  final RoundParser roundParser;

  @override
  State<EditableHoleDetailDialog> createState() =>
      _EditableHoleDetailDialogState();
}

class _EditableHoleDetailDialogState extends State<EditableHoleDetailDialog> {
  late PotentialDGHole _currentHole;

  @override
  void initState() {
    super.initState();
    _currentHole = widget.potentialHole;
    widget.roundParser.addListener(_onRoundUpdated);
  }

  @override
  void dispose() {
    widget.roundParser.removeListener(_onRoundUpdated);
    super.dispose();
  }

  void _onRoundUpdated() {
    if (widget.roundParser.potentialRound != null) {
      final PotentialDGRound round = widget.roundParser.potentialRound!;
      if (round.holes != null && widget.holeIndex < round.holes!.length) {
        setState(() {
          _currentHole = round.holes![widget.holeIndex];
        });
      }
    }
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
        holeNumber: _currentHole.number!,
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

    // Update via metadata method which handles conversion if complete
    widget.roundParser.updatePotentialHoleMetadata(
      widget.holeIndex,
      number: updatedHole.number,
      par: updatedHole.par,
      feet: updatedHole.feet,
    );
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
        holeNumber: _currentHole.number!,
        isNewThrow: true,
        onSave: (savedThrow) {
          final List<PotentialDiscThrow> updatedThrows =
              List<PotentialDiscThrow>.from(_currentHole.throws ?? []);
          updatedThrows.add(PotentialDiscThrow(
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
          ));

          final PotentialDGHole updatedHole = PotentialDGHole(
            number: _currentHole.number,
            par: _currentHole.par,
            feet: _currentHole.feet,
            throws: updatedThrows,
            holeType: _currentHole.holeType,
          );

          // Update via metadata method which handles conversion if complete
          widget.roundParser.updatePotentialHoleMetadata(
            widget.holeIndex,
            number: updatedHole.number,
            par: updatedHole.par,
            feet: updatedHole.feet,
          );
          Navigator.of(context).pop();
        },
        onDelete: null, // No delete for new throws
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if hole is incomplete
    if (!_currentHole.hasRequiredFields) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height - 64,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFD32F2F),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Incomplete Hole ${_currentHole.number ?? '?'}',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: IncompleteHoleDetailContent(
                        potentialHole: _currentHole,
                        holeIndex: widget.holeIndex,
                        roundParser: widget.roundParser,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Complete hole - convert to DGHole for display
    final DGHole completeHole = _currentHole.toDGHole();
    final int relativeScore = completeHole.relativeHoleScore;

    // Determine score color
    Color scoreColor;
    if (relativeScore < 0) {
      scoreColor = const Color(0xFF137e66); // Birdie - green
    } else if (relativeScore == 0) {
      scoreColor = Colors.grey; // Par - grey
    } else if (relativeScore == 1) {
      scoreColor = const Color(0xFFFF7A7A); // Bogey - light red
    } else {
      scoreColor = const Color(0xFFD32F2F); // Double bogey+ - dark red
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height - 64,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Hero(
                    tag: 'editable_hole_${completeHole.number}',
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.golf_course,
                                size: 24,
                                color: scoreColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hole ${completeHole.number}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: scoreColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${completeHole.holeScore}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Hole info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        context,
                        'Par',
                        '${completeHole.par}',
                        Icons.flag_outlined,
                      ),
                      if (completeHole.feet != null)
                        _buildInfoItem(
                          context,
                          'Distance',
                          '${completeHole.feet} ft',
                          Icons.straighten,
                        ),
                      _buildInfoItem(
                        context,
                        'Throws',
                        '${completeHole.throws.length}',
                        Icons.sports_golf,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Editable throws timeline
                Flexible(
                  child: EditableThrowTimeline(
                    throws: completeHole.throws,
                    onEditThrow: _editThrow,
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
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
