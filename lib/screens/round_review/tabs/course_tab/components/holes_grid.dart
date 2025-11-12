import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
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
            (t) => PotentialDiscThrow(
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
        onMetadataChanged: (par, distance) => _handleMetadataChanged(
          par,
          distance,
        ),
        onThrowAdded: (throw_) => _handleThrowAdded(throw_),
        onThrowEdited: (throwIndex, updatedThrow) => _handleThrowEdited(
          throwIndex,
          updatedThrow,
        ),
        onThrowDeleted: (throwIndex) => _handleThrowDeleted(throwIndex),
        onVoiceRecord: () => _handleVoiceRecord(),
      ),
    );
  }

  // Handler methods for EditableHoleDetailSheet callbacks
  void _handleMetadataChanged(int? par, int? distance) {
    final DGHole updatedHole = DGHole(
      number: hole.number,
      par: par ?? hole.par,
      feet: distance ?? hole.feet,
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

  void _handleThrowAdded(DiscThrow newThrow) {
    final List<DiscThrow> updatedThrows = List<DiscThrow>.from(hole.throws);
    updatedThrows.add(newThrow);

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
    final List<DiscThrow> reindexedThrows = updatedThrows
        .asMap()
        .entries
        .map((entry) {
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
        })
        .toList();

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
    final int score = hole.holeScore;
    final int relativeScore = hole.relativeHoleScore;

    // Determine gradient colors based on relative score
    List<Color> gradientColors;
    Color scoreColor;
    if (relativeScore < 0) {
      // Birdie - green gradient
      gradientColors = [
        const Color(0xFF137e66).withValues(alpha: 0.25),
        const Color(0xFF137e66).withValues(alpha: 0.15),
      ];
      scoreColor = const Color(0xFF137e66);
    } else if (relativeScore == 0) {
      // Par - darker grey gradient
      gradientColors = [
        Colors.grey.withValues(alpha: 0.35),
        Colors.grey.withValues(alpha: 0.25),
      ];
      scoreColor = Colors.grey;
    } else if (relativeScore == 1) {
      // Bogey - light red gradient
      gradientColors = [
        const Color(0xFFFF7A7A).withValues(alpha: 0.25),
        const Color(0xFFFF7A7A).withValues(alpha: 0.15),
      ];
      scoreColor = const Color(0xFFFF7A7A);
    } else {
      // Double bogey+ - dark red gradient
      gradientColors = [
        const Color(0xFFD32F2F).withValues(alpha: 0.25),
        const Color(0xFFD32F2F).withValues(alpha: 0.15),
      ];
      scoreColor = const Color(0xFFD32F2F);
    }

    return InkWell(
      onTap: () => _showHoleDetailSheet(context),
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with hole icon/number and score circle
                Hero(
                  tag: 'hole_${hole.number}',
                  child: Material(
                    color: Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.golf_course,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${hole.number}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        // Score circle (smaller, in top right)
                        Container(
                          width: 24,
                          height: 24,
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
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Par and distance
                Text(
                  'Par ${hole.par}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                if (hole.feet != null)
                  Text(
                    '${hole.feet} ft',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    size: 12,
                    FlutterRemix.arrow_right_s_line,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
