import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/hole_grid_item.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_hole_detail_sheet.dart';

class HolesGrid extends StatelessWidget {
  const HolesGrid({
    super.key,
    required this.round,
    required this.onRoundUpdated,
  });

  final DGRound round;
  final void Function(DGRound updatedRound) onRoundUpdated;

  @override
  Widget build(BuildContext context) {
    // Calculate width for 3 columns with no spacing
    final double screenWidth =
        MediaQuery.of(context).size.width - 32; // minus horizontal margin
    final double itemWidth = screenWidth / 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 0,
        runSpacing: 0,
        children: round.holes.asMap().entries.map((entry) {
          final int holeIndex = entry.key;
          final DGHole hole = entry.value;
          return SizedBox(
            width: itemWidth,
            child: _HoleGridItem(
              hole: hole,
              holeIndex: holeIndex,
              round: round,
              onRoundUpdated: onRoundUpdated,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HoleGridItem extends StatelessWidget {
  const _HoleGridItem({
    required this.hole,
    required this.holeIndex,
    required this.round,
    required this.onRoundUpdated,
  });

  final DGHole hole;
  final int holeIndex;
  final DGRound round;
  final void Function(DGRound updatedRound) onRoundUpdated;

  void _showHoleDetailSheet(BuildContext context) {
    // Convert DGHole to PotentialDGHole for editing
    final PotentialDGHole potentialHole = PotentialDGHole(
      number: hole.number,
      par: hole.par,
      feet: hole.feet,
      throws: hole.throws
          .map(
            (t) => DiscThrow(
              index: t.index,
              purpose: t.purpose,
              technique: t.technique,
              puttStyle: t.puttStyle,
              shotShape: t.shotShape,
              stance: t.stance,
              power: t.power,
              distanceFeetBeforeThrow: t.distanceFeetBeforeThrow,
              distanceFeetAfterThrow: t.distanceFeetAfterThrow,
              elevationChangeFeet: t.elevationChangeFeet,
              windDirection: t.windDirection,
              windStrength: t.windStrength,
              resultRating: t.resultRating,
              landingSpot: t.landingSpot,
              fairwayWidth: t.fairwayWidth,
              penaltyStrokes: t.penaltyStrokes,
              notes: t.notes,
              rawText: t.rawText,
              parseConfidence: t.parseConfidence,
              discName: t.discName,
              disc: t.disc,
            ),
          )
          .toList(),
      holeType: hole.holeType,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditableHoleDetailSheet(
        potentialHole: potentialHole,
        holeIndex: holeIndex,
        onMetadataChanged: ({int? newPar, int? newDistance}) =>
            _handleMetadataChanged(newPar: newPar, newDistance: newDistance),
        onThrowAdded: (throw_, {int? addThrowAtIndex}) =>
            _handleThrowAdded(throw_, addThrowAtIndex),
        onThrowEdited: (throwIndex, updatedThrow) =>
            _handleThrowEdited(throwIndex, updatedThrow),
        onThrowDeleted: (throwIndex) => _handleThrowDeleted(throwIndex),
        onVoiceRecord: () => _handleVoiceRecord(),
      ),
    );
  }

  // Handler methods for EditableHoleDetailSheet callbacks
  void _handleMetadataChanged({int? newPar, int? newDistance}) {
    final DGHole updatedHole = DGHole(
      number: hole.number,
      par: newPar ?? hole.par,
      feet: newDistance ?? hole.feet,
      throws: hole.throws,
      holeType: hole.holeType,
    );

    final List<DGHole> updatedHoles = List<DGHole>.from(round.holes);
    updatedHoles[holeIndex] = updatedHole;

    final DGRound updatedRound = round.copyWith(
      holes: updatedHoles,
      versionId: round.versionId + 1,
    );

    onRoundUpdated(updatedRound);
  }

  void _handleThrowAdded(DiscThrow newThrow, int? addThrowAtIndex) {
    final List<DiscThrow> updatedThrows = List<DiscThrow>.from(hole.throws);

    // Determine insertion index: if null, append at end; otherwise insert after the specified index
    final int insertIndex = addThrowAtIndex != null
        ? addThrowAtIndex + 1
        : updatedThrows.length;
    updatedThrows.insert(insertIndex, newThrow);

    // Reindex all throws after insertion
    final List<DiscThrow> reindexedThrows = updatedThrows.asMap().entries.map((
      entry,
    ) {
      final DiscThrow throw_ = entry.value;
      return DiscThrow(
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
    }).toList();

    final DGHole updatedHole = DGHole(
      number: hole.number,
      par: hole.par,
      feet: hole.feet,
      throws: reindexedThrows,
      holeType: hole.holeType,
    );

    final List<DGHole> updatedHoles = List<DGHole>.from(round.holes);
    updatedHoles[holeIndex] = updatedHole;

    final DGRound updatedRound = round.copyWith(
      holes: updatedHoles,
      versionId: round.versionId + 1,
    );

    onRoundUpdated(updatedRound);
  }

  void _handleThrowEdited(int throwIndex, DiscThrow updatedThrow) {
    final List<DiscThrow> updatedThrows = List<DiscThrow>.from(hole.throws);
    updatedThrows[throwIndex] = updatedThrow;

    final DGHole updatedHole = DGHole(
      number: hole.number,
      par: hole.par,
      feet: hole.feet,
      throws: updatedThrows,
      holeType: hole.holeType,
    );

    final List<DGHole> updatedHoles = List<DGHole>.from(round.holes);
    updatedHoles[holeIndex] = updatedHole;

    final DGRound updatedRound = round.copyWith(
      holes: updatedHoles,
      versionId: round.versionId + 1,
    );

    onRoundUpdated(updatedRound);
  }

  void _handleThrowDeleted(int throwIndex) {
    final List<DiscThrow> updatedThrows = List<DiscThrow>.from(hole.throws);
    updatedThrows.removeAt(throwIndex);

    // Reindex remaining throws
    final List<DiscThrow> reindexedThrows = updatedThrows.asMap().entries.map((
      entry,
    ) {
      final DiscThrow throw_ = entry.value;
      return DiscThrow(
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
    }).toList();

    final DGHole updatedHole = DGHole(
      number: hole.number,
      par: hole.par,
      feet: hole.feet,
      throws: reindexedThrows,
      holeType: hole.holeType,
    );

    final List<DGHole> updatedHoles = List<DGHole>.from(round.holes);
    updatedHoles[holeIndex] = updatedHole;

    final DGRound updatedRound = round.copyWith(
      holes: updatedHoles,
      versionId: round.versionId + 1,
    );

    onRoundUpdated(updatedRound);
  }

  void _handleVoiceRecord() {
    // Voice recording is not supported for completed rounds
    // Could be implemented in the future
  }

  @override
  Widget build(BuildContext context) {
    return HoleGridItem(
      holeNumber: hole.number,
      holePar: hole.par,
      holeFeet: hole.feet,
      score: hole.holeScore,
      relativeScore: hole.relativeHoleScore,
      isIncomplete: false, // Completed rounds are never incomplete
      onTap: () => _showHoleDetailSheet(context),
      heroTag: 'hole_${hole.number}',
    );
  }
}
