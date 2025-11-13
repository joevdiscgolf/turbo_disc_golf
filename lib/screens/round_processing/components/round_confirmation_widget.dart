import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_holes_grid.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/incomplete_hole_walkthrough_panel.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/round_metadata_card.dart';
import 'package:turbo_disc_golf/state/round_confirmation_cubit.dart';
import 'package:turbo_disc_golf/state/round_confirmation_state.dart';

class RoundConfirmationWidget extends StatefulWidget {
  const RoundConfirmationWidget({
    super.key,
    required this.potentialRound,
    required this.onBack,
    required this.onConfirm,
    required this.topViewPadding,
  });

  final PotentialDGRound potentialRound;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final double topViewPadding;

  @override
  State<RoundConfirmationWidget> createState() =>
      _RoundConfirmationWidgetState();
}

class _RoundConfirmationWidgetState extends State<RoundConfirmationWidget> {
  late final RoundConfirmationCubit _roundConfirmationCubit;

  @override
  void initState() {
    super.initState();
    _roundConfirmationCubit = BlocProvider.of<RoundConfirmationCubit>(context);
    _roundConfirmationCubit.startRoundConfirmation(
      context,
      widget.potentialRound,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoundConfirmationCubit, RoundConfirmationState>(
      builder: (context, state) {
        if (state is! ConfirmingRoundActive) {
          return const SizedBox();
        }
        final currentRound = state.potentialRound;
        final int totalScore = _calculateTotalScoreForValidHoles(currentRound);
        final int totalPar = _calculateTotalParForValidHoles(currentRound);
        final int relativeScore = totalScore - totalPar;
        final Map<String, dynamic> validation = _validateRound(currentRound);
        final List<String> validationIssues =
            validation['issues'] as List<String>;
        final Set<int> missingHoles = validation['missingHoles'] as Set<int>;
        final bool hasRequiredFields = validation['hasRequiredFields'] as bool;

        return _buildContent(
          context,
          currentRound,
          totalScore,
          totalPar,
          relativeScore,
          validationIssues,
          missingHoles,
          hasRequiredFields,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PotentialDGRound currentRound,
    int totalScore,
    int totalPar,
    int relativeScore,
    List<String> validationIssues,
    Set<int> missingHoles,
    bool hasRequiredFields,
  ) {
    return Container(
      color: const Color(0xFFEEE8F5), // Light purple-gray background
      // color: Colors.blue,
      child: Column(
        children: [
          // Scrollable content (everything except bottom bar)
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 48,
                top: widget.topViewPadding + 72,
              ),
              children: [
                // Course metadata header
                RoundMetadataCard(
                  potentialRound: currentRound,
                  totalScore: totalScore,
                  totalPar: totalPar,
                  relativeScore: relativeScore,
                ),
                const SizedBox(height: 12),
                // Warning banner for missing data
                if (validationIssues.isNotEmpty)
                  _buildWarningBanner(
                    context,
                    currentRound,
                    validationIssues,
                    missingHoles,
                    hasRequiredFields,
                  ),
                if (validationIssues.isNotEmpty) const SizedBox(height: 16),

                // Instructions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Review holes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Holes grid (no longer wrapped in Expanded)
                EditableHolesGrid(potentialRound: currentRound),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Continue button at bottom (fixed, doesn't scroll)
          _buildBottomBar(context, hasRequiredFields),
        ],
      ),
    );
  }

  int _getIncompleteHoleCount(PotentialDGRound round) {
    if (round.holes == null) return 0;
    // Count holes that are missing required fields OR have no throws OR no basket throw
    return round.holes!
        .where(
          (hole) =>
              !hole.hasRequiredFields ||
              hole.throws == null ||
              hole.throws!.isEmpty ||
              !_hasBasketThrow(hole),
        )
        .length;
  }

  bool _hasBasketThrow(PotentialDGHole hole) {
    if (hole.throws == null || hole.throws!.isEmpty) return false;
    return hole.throws!.any((t) => t.landingSpot == LandingSpot.inBasket);
  }

  Future<void> _openWalkthroughDialog(
    BuildContext context,
    PotentialDGRound currentRound,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (builderContext) => IncompleteHoleWalkthroughPanel(
        potentialRound: currentRound,
        bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
      ),
    );
  }

  Widget _buildWarningBanner(
    BuildContext context,
    PotentialDGRound currentRound,
    List<String> issues,
    Set<int> missingHoles,
    bool hasRequiredFields,
  ) {
    final int incompleteHoleCount = _getIncompleteHoleCount(currentRound);
    final int holesToAddress = incompleteHoleCount + missingHoles.length;

    return Row(
      children: [
        if (holesToAddress > 0)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Open the walkthrough to guide user through filling in incomplete holes
                await _openWalkthroughDialog(context, currentRound);
              },
              icon: const Icon(Icons.warning, size: 18),
              label: Text(
                '$holesToAddress ${holesToAddress == 1 ? 'hole needs' : 'holes need'} attention',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFEB3B),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool hasRequiredFields) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Center(
            child: PrimaryButton(
              label: 'Looks good!',
              backgroundColor: Colors.green,
              icon: Icons.check,
              width: double.infinity,
              height: 56,
              fontSize: 16,
              disabled: !hasRequiredFields,
              onPressed: widget.onConfirm,
            ),
          ),
        ),
      ),
    );
  }

  List<PotentialDGHole> _validHoles(PotentialDGRound round) =>
      round.holes!.where((hole) => hole.hasRequiredFields).toList();

  int _calculateTotalScoreForValidHoles(PotentialDGRound round) {
    if (round.holes == null) return 0;

    return _validHoles(round).fold<int>(0, (sum, hole) {
      // Calculate hole score: throws count + penalty strokes
      final int throwsCount = hole.throws?.length ?? 0;
      final int penaltyStrokes =
          hole.throws?.fold<int>(
            0,
            (prev, discThrow) => prev + (discThrow.penaltyStrokes ?? 0),
          ) ??
          0;
      return sum + throwsCount + penaltyStrokes;
    });
  }

  int _calculateTotalParForValidHoles(PotentialDGRound round) {
    if (round.holes == null) return 0;

    return _validHoles(round).fold(
      0,
      (sum, hole) => sum + (hole.par ?? 3), // Default to par 3 if missing
    );
  }

  Map<String, dynamic> _validateRound(PotentialDGRound round) {
    final List<String> issues = [];
    final Set<int> missingHoles = {};
    bool hasRequiredFields = true;

    // Use the built-in validation from PotentialDGRound
    final validationSummary = round.getValidationSummary();
    final List<dynamic> invalidHoles =
        validationSummary['invalidHoles'] as List<dynamic>;

    // Add issues from validation summary
    for (final invalidHole in invalidHoles) {
      final int? holeNumber = invalidHole['holeNumber'] as int?;
      final List<dynamic> missingFields =
          invalidHole['missingFields'] as List<dynamic>;

      if (holeNumber != null) {
        for (final field in missingFields) {
          issues.add('Hole $holeNumber: Missing $field');
        }
      } else {
        // Hole doesn't even have a number
        issues.add('A hole is missing its number: ${missingFields.join(', ')}');
      }
    }

    // If there are any invalid holes, the round doesn't have all required fields
    if (invalidHoles.isNotEmpty) {
      hasRequiredFields = false;
    }

    // Check if round itself is missing required fields
    if (!round.hasRequiredFields) {
      hasRequiredFields = false;
      final roundMissing = round.getMissingFields();
      for (final field in roundMissing) {
        if (!field.contains('hole')) {
          // Only show non-hole-specific issues (courseName, etc.)
          issues.add('Round: Missing $field');
        }
      }
    }

    // Check for missing holes in sequence
    if (round.holes != null && round.holes!.isNotEmpty) {
      final List<int> holeNumbers =
          round.holes!
              .where((h) => h.number != null)
              .map((h) => h.number!)
              .toList()
            ..sort();

      if (holeNumbers.isNotEmpty) {
        final int expectedHoles = holeNumbers.last;

        for (int i = 1; i <= expectedHoles; i++) {
          if (!holeNumbers.contains(i)) {
            missingHoles.add(i);
          }
        }

        if (missingHoles.isNotEmpty) {
          issues.add('Missing holes in sequence: ${missingHoles.join(', ')}');
          hasRequiredFields = false;
        }
      }
    }

    // Check each hole for additional issues
    if (round.holes != null) {
      for (final hole in round.holes!) {
        final String holeName = hole.number?.toString() ?? 'Unknown';

        // No throws recorded
        if (hole.throws == null || hole.throws!.isEmpty) {
          issues.add('Hole $holeName: No throws recorded');
          hasRequiredFields = false;
        } else {
          // Check if hole has a basket throw (required for completion)
          final bool hasBasketThrow = hole.throws!.any(
            (t) => t.landingSpot == LandingSpot.inBasket,
          );
          if (!hasBasketThrow) {
            issues.add('Hole $holeName: No basket throw recorded');
            hasRequiredFields = false;
          }
        }

        // Missing distance (optional but recommended)
        if (hole.feet == null) {
          issues.add('Hole $holeName: Missing distance (recommended)');
        }
      }
    }

    return {
      'issues': issues,
      'missingHoles': missingHoles,
      'hasRequiredFields': hasRequiredFields,
    };
  }
}
