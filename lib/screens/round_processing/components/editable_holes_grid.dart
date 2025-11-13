import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_hole_detail_sheet.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/record_single_hole_panel.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/state/round_confirmation_cubit.dart';
import 'package:turbo_disc_golf/state/round_confirmation_state.dart';

/// Grid of holes that opens editable dialogs when tapped.
///
/// Supports both complete holes (DGHole) and incomplete holes (PotentialDGHole).
class EditableHolesGrid extends StatelessWidget {
  const EditableHolesGrid({super.key, required this.potentialRound});

  final PotentialDGRound potentialRound;

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
    this.isCompletelyMissing = false,
  });

  final PotentialDGHole potentialHole;
  final int holeIndex;
  final bool isCompletelyMissing;

  void _showEditableHoleSheet(BuildContext context) {
    // If hole is completely missing, we can't edit it yet
    if (isCompletelyMissing) {
      return;
    }

    final RoundConfirmationCubit roundConfirmationCubit =
        BlocProvider.of<RoundConfirmationCubit>(context);

    // Normal case: hole exists in the round
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (builderContext) => EditableHoleDetailSheet(
        potentialHole: potentialHole,
        holeIndex: holeIndex,
        onMetadataChanged: ({int? newPar, int? newDistance}) =>
            _handleMetadataChanged(
              context,
              holeIndex,
              newPar: newPar,
              newDistance: newDistance,
            ),
        onThrowAdded: (throw_, {int? addThrowAtIndex}) => roundConfirmationCubit
            .addThrow(holeIndex, throw_, addAfterThrowIndex: addThrowAtIndex),
        onThrowEdited: (throwIndex, updatedThrow) => roundConfirmationCubit
            .updateThrow(holeIndex, throwIndex, updatedThrow),
        onThrowDeleted: (throwIndex) =>
            roundConfirmationCubit.deleteThrow(holeIndex, throwIndex),
        onVoiceRecord: () =>
            _handleVoiceRecord(context, potentialHole, holeIndex),
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
    BuildContext context,
    int holeIndex, {
    int? newPar,
    int? newDistance,
  }) {
    // Get the current hole from the cubit state to ensure we have the latest data
    final RoundConfirmationState state = context
        .read<RoundConfirmationCubit>()
        .state;
    if (state is! ConfirmingRoundActive) {
      return;
    }

    final PotentialDGHole? currentHole = state.potentialRound.holes?[holeIndex];
    if (currentHole == null) {
      return;
    }

    final PotentialDGHole updatedHole = PotentialDGHole(
      number: currentHole.number,
      par: newPar,
      feet: newDistance,
      throws: currentHole.throws,
      holeType: currentHole.holeType,
    );
    BlocProvider.of<RoundConfirmationCubit>(
      context,
    ).updatePotentialHole(holeIndex, updatedHole);
  }

  void _handleVoiceRecord(
    BuildContext context,
    PotentialDGHole currentHole,
    int holeIndex,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VoiceRecordSheet(
        holeNumber: currentHole.number ?? holeIndex + 1,
        holeIndex: holeIndex,
        holePar: currentHole.par,
        holeFeet: currentHole.feet,
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

/// Stateful wrapper for RecordSingleHolePanel that handles processing state.
class _VoiceRecordSheet extends StatefulWidget {
  const _VoiceRecordSheet({
    required this.holeNumber,
    required this.holeIndex,
    this.holePar,
    this.holeFeet,
  });

  final int holeNumber;
  final int holeIndex;
  final int? holePar;
  final int? holeFeet;

  @override
  State<_VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

class _VoiceRecordSheetState extends State<_VoiceRecordSheet> {
  bool _isProcessing = false;

  Future<void> _handleContinue(String transcript) async {
    setState(() {
      _isProcessing = true;
    });

    // Show loading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Re-processing hole with AI...')),
      );
    }

    // Call RoundParser to re-process the hole
    final RoundParser roundParser = locator.get<RoundParser>();
    final bool success = await roundParser.reProcessHole(
      holeIndex: widget.holeIndex,
      voiceTranscript: transcript,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    // Show result
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hole re-processed successfully!'),
          backgroundColor: Color(0xFF137e66),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${roundParser.lastError.isNotEmpty ? roundParser.lastError : 'Failed to re-process hole'}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RecordSingleHolePanel(
      holeNumber: widget.holeNumber,
      holePar: widget.holePar,
      holeFeet: widget.holeFeet,
      isProcessing: _isProcessing,
      onContinuePressed: _handleContinue,
    );
  }
}
