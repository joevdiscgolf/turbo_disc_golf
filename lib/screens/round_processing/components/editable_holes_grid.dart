import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_hole_detail_sheet.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/hole_re_record_dialog.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

/// Grid of holes that opens editable dialogs when tapped.
///
/// Supports both complete holes (DGHole) and incomplete holes (PotentialDGHole).
class EditableHolesGrid extends StatelessWidget {
  const EditableHolesGrid({
    super.key,
    required this.potentialRound,
    required this.roundParser,
  });

  final PotentialDGRound potentialRound;
  final RoundParser roundParser;

  @override
  Widget build(BuildContext context) {
    if (potentialRound.holes == null || potentialRound.holes!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No holes found'),
        ),
      );
    }

    // Calculate width for 3 columns with no spacing
    final double screenWidth =
        MediaQuery.of(context).size.width - 32; // minus horizontal margin
    final double itemWidth = screenWidth / 3;

    // Determine the full range of holes (1 to max hole number)
    final int maxHoleNumber = potentialRound.holes!
        .map((h) => h.number ?? 0)
        .reduce((a, b) => a > b ? a : b);

    // Create a map of hole number to hole data and index for quick lookup
    final Map<int, PotentialDGHole> holeMap = {};
    final Map<int, int> holeIndexMap = {};
    for (int i = 0; i < potentialRound.holes!.length; i++) {
      final hole = potentialRound.holes![i];
      if (hole.number != null) {
        holeMap[hole.number!] = hole;
        holeIndexMap[hole.number!] = i;
      }
    }

    // Generate tiles for all holes from 1 to maxHoleNumber
    final List<Widget> holeTiles = [];
    for (int holeNum = 1; holeNum <= maxHoleNumber; holeNum++) {
      final PotentialDGHole? existingHole = holeMap[holeNum];
      final int? holeIndex = holeIndexMap[holeNum];

      // If hole doesn't exist in the round, create a minimal placeholder
      final PotentialDGHole hole =
          existingHole ??
          PotentialDGHole(
            number: holeNum,
            par: null, // Missing
            feet: null, // Missing
            throws: null, // Completely missing
          );

      holeTiles.add(
        SizedBox(
          width: itemWidth,
          child: _HoleGridItem(
            potentialHole: hole,
            holeIndex: holeIndex ?? -1, // -1 indicates hole doesn't exist yet
            roundParser: roundParser,
            isCompletelyMissing: existingHole == null,
          ),
        ),
      );
    }

    return Wrap(spacing: 0, runSpacing: 0, children: holeTiles);
  }
}

class _HoleGridItem extends StatelessWidget {
  const _HoleGridItem({
    required this.potentialHole,
    required this.holeIndex,
    required this.roundParser,
    this.isCompletelyMissing = false,
  });

  final PotentialDGHole potentialHole;
  final int holeIndex;
  final RoundParser roundParser;
  final bool isCompletelyMissing;

  void _showEditableHoleSheet(BuildContext context) {
    // If hole is completely missing, add it to the round first
    if (isCompletelyMissing && potentialHole.number != null) {
      // roundParser.addEmptyHolesToPotentialRound({potentialHole.number!});

      // Wait for the state to update, then find the new hole index and open dialog

      // Find the newly added hole's index
      final updatedRound = roundParser.potentialRound;
      if (updatedRound?.holes != null) {
        final newHoleIndex = updatedRound!.holes!.indexWhere(
          (h) => h.number == potentialHole.number,
        );

        if (newHoleIndex != -1 && context.mounted) {
          displayBottomSheet(
            context,
            EditableHoleDetailSheet(
              potentialHole: updatedRound.holes![newHoleIndex],
              holeIndex: newHoleIndex,
              onMetadataChanged: (par, distance) => _handleMetadataChanged(
                newHoleIndex,
                updatedRound.holes![newHoleIndex],
                par,
                distance,
              ),
              onThrowAdded: (throw_) => _handleThrowAdded(
                newHoleIndex,
                updatedRound.holes![newHoleIndex],
                throw_,
              ),
              onThrowEdited: (throwIndex, updatedThrow) =>
                  roundParser.updateThrow(newHoleIndex, throwIndex, updatedThrow),
              onThrowDeleted: (throwIndex) => _handleThrowDeleted(
                newHoleIndex,
                updatedRound.holes![newHoleIndex],
                throwIndex,
              ),
              onVoiceRecord: () => _handleVoiceRecord(
                context,
                updatedRound.holes![newHoleIndex],
                newHoleIndex,
              ),
            ),
          );
        }
      }

      return;
    }

    // Normal case: hole exists in the round
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditableHoleDetailSheet(
        potentialHole: potentialHole,
        holeIndex: holeIndex,
        onMetadataChanged: (par, distance) => _handleMetadataChanged(
          holeIndex,
          potentialHole,
          par,
          distance,
        ),
        onThrowAdded: (throw_) => _handleThrowAdded(
          holeIndex,
          potentialHole,
          throw_,
        ),
        onThrowEdited: (throwIndex, updatedThrow) =>
            roundParser.updateThrow(holeIndex, throwIndex, updatedThrow),
        onThrowDeleted: (throwIndex) => _handleThrowDeleted(
          holeIndex,
          potentialHole,
          throwIndex,
        ),
        onVoiceRecord: () => _handleVoiceRecord(
          context,
          potentialHole,
          holeIndex,
        ),
      ),
    );
  }

  Widget _incompleteHoleItem(BuildContext context) {
    const Color borderColor = Color(0xFFFFEB3B);
    const Color backgroundColor = Color(0xFFFFFDE7);

    return GestureDetector(
      onTap: () => _showEditableHoleSheet(context),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: borderColor,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with hole number and warning icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${potentialHole.number ?? '?'}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Warning badge
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: borderColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.priority_high,
                          size: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Par and distance
                Text(
                  'Par ${potentialHole.par ?? '—'}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  potentialHole.feet != null
                      ? '${potentialHole.feet} ft'
                      : '— ft',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                // Edit icon in bottom right
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.edit, size: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasBasketThrow() {
    if (potentialHole.throws == null || potentialHole.throws!.isEmpty) {
      return false;
    }
    return potentialHole.throws!.any(
      (t) => t.landingSpot == LandingSpot.inBasket,
    );
  }

  // Handler methods for EditableHoleDetailSheet callbacks
  void _handleMetadataChanged(
    int holeIndex,
    PotentialDGHole currentHole,
    int? par,
    int? distance,
  ) {
    final PotentialDGHole updatedHole = PotentialDGHole(
      number: currentHole.number,
      par: par,
      feet: distance,
      throws: currentHole.throws,
      holeType: currentHole.holeType,
    );
    roundParser.updatePotentialHole(holeIndex, updatedHole);
  }

  void _handleThrowAdded(
    int holeIndex,
    PotentialDGHole currentHole,
    DiscThrow newThrow,
  ) {
    final List<PotentialDiscThrow> updatedThrows =
        List<PotentialDiscThrow>.from(currentHole.throws ?? []);
    updatedThrows.add(
      PotentialDiscThrow(
        index: newThrow.index,
        purpose: newThrow.purpose,
        technique: newThrow.technique,
        puttStyle: newThrow.puttStyle,
        shotShape: newThrow.shotShape,
        stance: newThrow.stance,
        power: newThrow.power,
        distanceFeetBeforeThrow: newThrow.distanceFeetBeforeThrow,
        distanceFeetAfterThrow: newThrow.distanceFeetAfterThrow,
        elevationChangeFeet: newThrow.elevationChangeFeet,
        windDirection: newThrow.windDirection,
        windStrength: newThrow.windStrength,
        resultRating: newThrow.resultRating,
        landingSpot: newThrow.landingSpot,
        fairwayWidth: newThrow.fairwayWidth,
        penaltyStrokes: newThrow.penaltyStrokes,
        notes: newThrow.notes,
        rawText: newThrow.rawText,
        parseConfidence: newThrow.parseConfidence,
        discName: newThrow.discName,
        disc: newThrow.disc,
      ),
    );

    final PotentialDGHole updatedHole = PotentialDGHole(
      number: currentHole.number,
      par: currentHole.par,
      feet: currentHole.feet,
      throws: updatedThrows,
      holeType: currentHole.holeType,
    );

    roundParser.updatePotentialHole(holeIndex, updatedHole);
  }

  void _handleThrowDeleted(
    int holeIndex,
    PotentialDGHole currentHole,
    int throwIndex,
  ) {
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

    final PotentialDGHole updatedHole = PotentialDGHole(
      number: currentHole.number,
      par: currentHole.par,
      feet: currentHole.feet,
      throws: reindexedThrows,
      holeType: currentHole.holeType,
    );

    roundParser.updatePotentialHole(holeIndex, updatedHole);
  }

  void _handleVoiceRecord(
    BuildContext context,
    PotentialDGHole currentHole,
    int holeIndex,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => HoleReRecordDialog(
        holeNumber: currentHole.number ?? holeIndex + 1,
        holeIndex: holeIndex,
        holePar: currentHole.par,
        holeFeet: currentHole.feet,
        onReProcessed: () {
          // The hole data will be automatically updated via the roundParser listener
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Incomplete hole (missing required fields OR no throws OR no basket throw) - show more details
    final bool isIncomplete =
        !potentialHole.hasRequiredFields ||
        potentialHole.throws == null ||
        potentialHole.throws!.isEmpty ||
        !_hasBasketThrow();

    if (isIncomplete) {
      return _incompleteHoleItem(context);
    }

    // Regular/Complete hole styling
    // Calculate score manually since PotentialDGHole doesn't have computed properties
    final int throwsCount = potentialHole.throws?.length ?? 0;
    final int penaltyStrokes =
        potentialHole.throws?.fold<int>(
          0,
          (prev, t) => prev + (t.penaltyStrokes ?? 0),
        ) ??
        0;
    final int score = throwsCount + penaltyStrokes;
    final int par = potentialHole.par ?? 3;
    final int relativeScore = score - par;

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
      onTap: () => _showEditableHoleSheet(context),
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
                  tag: 'editable_hole_${potentialHole.number}',
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
                              '${potentialHole.number}',
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
                  'Par ${potentialHole.par}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                if (potentialHole.feet != null)
                  Text(
                    '${potentialHole.feet} ft',
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
