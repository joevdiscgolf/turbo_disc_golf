import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/components/edit_hole/edit_hole_body.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/hole_re_record_dialog.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_edit_dialog.dart';
import 'package:turbo_disc_golf/state/round_confirmation_cubit.dart';
import 'package:turbo_disc_golf/state/round_confirmation_state.dart';

/// Bottom sheet that guides user through fixing each incomplete hole sequentially.
/// Shows progress with tabs and horizontal checklist, allows inline editing.
class IncompleteHoleWalkthroughSheet extends StatefulWidget {
  const IncompleteHoleWalkthroughSheet({
    super.key,
    required this.potentialRound,
    required this.bottomViewPadding,
  });

  final PotentialDGRound potentialRound;
  final double bottomViewPadding;

  @override
  State<IncompleteHoleWalkthroughSheet> createState() =>
      _IncompleteHoleWalkthroughSheetState();
}

class _IncompleteHoleWalkthroughSheetState
    extends State<IncompleteHoleWalkthroughSheet> {
  late final FocusNode _parFocusNode;
  late final FocusNode _distanceFocusNode;
  late final RoundConfirmationCubit _roundConfirmationCubit;

  PotentialDGHole? _selectedPotentialHole(PotentialDGRound round) {
    try {
      final int actualHoleIndex =
          _incompleteHoleIndices[_incompleteHolesListIndex];
      return round.holes![actualHoleIndex];
    } catch (e) {
      return null;
    }
  }

  late List<int> _incompleteHoleIndices;
  int _incompleteHolesListIndex = 0;

  @override
  void initState() {
    super.initState();
    _roundConfirmationCubit = BlocProvider.of<RoundConfirmationCubit>(context);
    _parFocusNode = FocusNode();
    _distanceFocusNode = FocusNode();
    _incompleteHoleIndices = _getIncompleteHoleIndices();
    // Set the current editing hole to the first incomplete hole
    if (_incompleteHoleIndices.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _roundConfirmationCubit.setCurrentEditingHole(
            _incompleteHoleIndices[_incompleteHolesListIndex],
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _parFocusNode.dispose();
    _distanceFocusNode.dispose();
    // Clear the current editing hole when disposing
    _roundConfirmationCubit.clearCurrentEditingHole();
    super.dispose();
  }

  void _setCurrentEditingHole(int holeIndex) {
    _roundConfirmationCubit.setCurrentEditingHole(holeIndex);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoundConfirmationCubit, RoundConfirmationState>(
      builder: (context, state) {
        if (state is! ConfirmingRoundActive) {
          return const SizedBox();
        }
        return _buildContent(context, state);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ConfirmingRoundActive confirmingActiveState,
  ) {
    // If no incomplete holes, show completion message
    if (_incompleteHoleIndices.isEmpty) {
      return Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: widget.bottomViewPadding + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF137e66), size: 80),
            const SizedBox(height: 20),
            Text(
              'All holes complete!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF137e66),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'All holes now have the required information.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137e66),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final PotentialDGHole? potentialHole = _selectedPotentialHole(
      confirmingActiveState.potentialRound,
    );
    if (potentialHole == null) {
      return const SizedBox();
    }

    final int actualHoleIndex =
        _incompleteHoleIndices[_incompleteHolesListIndex];

    return SizedBox(
      height: MediaQuery.of(context).size.height - 64,
      child: Container(
        height: MediaQuery.of(context).size.height - 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _headerRow(),
            _buildHorizontalChecklist(confirmingActiveState),
            const SizedBox(height: 8),
            Expanded(
              child: EditHoleBody(
                key: ValueKey(potentialHole.number),
                holeNumber: potentialHole.number ?? actualHoleIndex + 1,
                par: potentialHole.par,
                distance: potentialHole.feet,
                throws:
                    potentialHole.throws
                        ?.where((t) => t.hasRequiredFields)
                        .map((t) => t.toDiscThrow())
                        .toList() ??
                    [],
                parFocusNode: _parFocusNode,
                distanceFocusNode: _distanceFocusNode,
                bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
                inWalkthroughSheet: true,
                hasRequiredFields: potentialHole.hasRequiredFields,
                onParChanged: (int newPar) => _updateHoleMetadata(
                  actualHoleIndex,
                  newPar: newPar,
                  newDistance: null,
                ),
                onDistanceChanged: (int newDistance) => _updateHoleMetadata(
                  actualHoleIndex,
                  newPar: null,
                  newDistance: newDistance,
                ),
                onThrowAdded: ({int? addThrowAtIndex}) => _handleAddThrow(
                  potentialHole,
                  actualHoleIndex,
                  addThrowAtIndex: addThrowAtIndex,
                ),
                onThrowEdited: (throwIndex) => _handleEditThrow(
                  potentialHole,
                  actualHoleIndex,
                  throwIndex,
                ),
                onVoiceRecord: () =>
                    _handleVoiceRecord(potentialHole, actualHoleIndex),
                onDone: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'Add missing data',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalChecklist(
    ConfirmingRoundActive confirmingActiveState,
  ) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _incompleteHoleIndices.length,
        itemBuilder: (context, index) {
          final int holeIndex = _incompleteHoleIndices[index];
          final PotentialDGHole hole =
              confirmingActiveState.potentialRound.holes![holeIndex];
          final bool isComplete = _isHoleComplete(index, confirmingActiveState);
          final bool isSelected = _incompleteHolesListIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _incompleteHolesListIndex = index;
                // Update the current editing hole when switching tabs
                final int newHoleIndex = _incompleteHoleIndices[index];
                _setCurrentEditingHole(newHoleIndex);
              });
            },
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isComplete
                    ? const Color(0xFF137e66).withValues(alpha: 0.15)
                    : const Color(0xFFFFEB3B).withValues(alpha: 0.15),
                border: Border.all(
                  color: isSelected
                      ? (isComplete
                            ? const Color(0xFF137e66)
                            : const Color(0xFFFFEB3B))
                      : Colors.transparent,
                  width: isSelected ? 2 : 0,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isComplete)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF137e66),
                      size: 18,
                    )
                  else
                    const Icon(
                      FlutterRemix.close_line,
                      color: Colors.black,
                      size: 18,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    'H${hole.number ?? '?'}',
                    style: TextStyle(
                      fontSize: 9,
                      color: isComplete
                          ? const Color(0xFF137e66)
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateHoleMetadata(
    int holeIndex, {
    required int? newPar,
    required int? newDistance,
  }) {
    _roundConfirmationCubit.updatePotentialHoleMetadata(
      holeIndex,
      par: newPar,
      feet: newDistance,
    );
  }

  Future<void> _handleAddThrow(
    PotentialDGHole currentHole,
    int holeIndex, {
    required int? addThrowAtIndex,
  }) async {
    // Unfocus any active fields before showing dialog
    _parFocusNode.unfocus();
    _distanceFocusNode.unfocus();

    // Create a new throw with default values
    final DiscThrow newThrow = DiscThrow(
      index: currentHole.throws?.length ?? 0,
      purpose: ThrowPurpose.other,
      technique: ThrowTechnique.backhand,
    );

    await showDialog(
      context: context,
      builder: (context) => ThrowEditDialog(
        throw_: newThrow,
        throwIndex: currentHole.throws?.length ?? 0,
        holeNumber: currentHole.number ?? holeIndex + 1,
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
          _roundConfirmationCubit.updatePotentialHole(holeIndex, updatedHole);
          Navigator.of(context).pop();
        },
        onDelete: null, // No delete for new throws
      ),
    );

    // Unfocus again after dialog closes to prevent keyboard from popping up
    if (mounted) {
      _parFocusNode.unfocus();
      _distanceFocusNode.unfocus();
    }
  }

  Future<void> _handleEditThrow(
    PotentialDGHole currentHole,
    int holeIndex,
    int throwIndex,
  ) async {
    // Unfocus any active fields before showing dialog
    _parFocusNode.unfocus();
    _distanceFocusNode.unfocus();

    // Convert to DiscThrow from PotentialDiscThrow if needed
    final PotentialDiscThrow? potentialThrow = currentHole.throws?[throwIndex];
    if (potentialThrow == null || !potentialThrow.hasRequiredFields) {
      return; // Can't edit incomplete throw
    }
    final DiscThrow currentThrow = potentialThrow.toDiscThrow();

    await showDialog(
      context: context,
      builder: (context) => ThrowEditDialog(
        throw_: currentThrow,
        throwIndex: throwIndex,
        holeNumber: currentHole.number ?? holeIndex + 1,
        onSave: (updatedThrow) {
          _roundConfirmationCubit.updateThrow(
            holeIndex,
            throwIndex,
            updatedThrow,
          );
          Navigator.of(context).pop();
        },
        onDelete: () {
          _handleDeleteThrow(currentHole, holeIndex, throwIndex);
          Navigator.of(context).pop();
        },
      ),
    );

    // Unfocus again after dialog closes to prevent keyboard from popping up
    if (mounted) {
      _parFocusNode.unfocus();
      _distanceFocusNode.unfocus();
    }
  }

  void _handleDeleteThrow(
    PotentialDGHole currentHole,
    int holeIndex,
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

    // Update as potential hole
    final PotentialDGHole updatedHole = PotentialDGHole(
      number: currentHole.number,
      par: currentHole.par,
      feet: currentHole.feet,
      throws: reindexedThrows,
      holeType: currentHole.holeType,
    );

    // Update the entire hole including throws
    _roundConfirmationCubit.updatePotentialHole(holeIndex, updatedHole);
  }

  void _handleVoiceRecord(PotentialDGHole currentHole, int holeIndex) {
    showDialog<void>(
      context: context,
      builder: (context) => HoleReRecordDialog(
        holeNumber: currentHole.number ?? holeIndex + 1,
        holePar: currentHole.par,
        holeFeet: currentHole.feet,
        holeIndex: holeIndex,
        onReProcessed: () {
          // Refresh after re-recording
          _refreshIncompleteHoles();
        },
      ),
    );
  }

  void _refreshIncompleteHoles() {
    final List<int> newIncompleteIndices = _getIncompleteHoleIndices();
    _incompleteHoleIndices = newIncompleteIndices;

    // Clamp the current index to be within bounds
    if (_incompleteHoleIndices.isNotEmpty &&
        _incompleteHolesListIndex >= _incompleteHoleIndices.length) {
      _incompleteHolesListIndex = _incompleteHoleIndices.length - 1;
    }

    // Update the current editing hole after refreshing
    if (_incompleteHoleIndices.isNotEmpty) {
      final int newHoleIndex =
          _incompleteHoleIndices[_incompleteHolesListIndex];
      _setCurrentEditingHole(newHoleIndex);
    }

    // Don't auto-close when all holes are complete - let user manually close
    // The completion UI will be shown with a Close button
  }

  List<int> _getIncompleteHoleIndices() {
    if (widget.potentialRound.holes == null) return [];

    final List<int> indices = [];
    for (int i = 0; i < widget.potentialRound.holes!.length; i++) {
      final PotentialDGHole hole = widget.potentialRound.holes![i];
      // Consider a hole incomplete if it's missing required fields OR has no throws OR no basket throw
      if (!hole.hasRequiredFields ||
          hole.throws == null ||
          hole.throws!.isEmpty ||
          !_hasBasketThrow(hole)) {
        indices.add(i);
      }
    }
    return indices;
  }

  bool _hasBasketThrow(PotentialDGHole hole) {
    if (hole.throws == null || hole.throws!.isEmpty) return false;
    return hole.throws!.any((t) => t.landingSpot == LandingSpot.inBasket);
  }

  bool _isHoleComplete(
    int tabIndex,
    ConfirmingRoundActive confirmingActiveState,
  ) {
    if (tabIndex >= _incompleteHoleIndices.length) return false;

    final int holeIndex = _incompleteHoleIndices[tabIndex];
    final PotentialDGHole hole =
        confirmingActiveState.potentialRound.holes![holeIndex];

    // Check if hole has required metadata
    final bool hasMetadata =
        hole.number != null && hole.par != null && hole.feet != null;

    // Check if hole has at least one basket throw
    final bool hasBasketThrow = _hasBasketThrow(hole);

    return hasMetadata && hasBasketThrow;
  }
}
