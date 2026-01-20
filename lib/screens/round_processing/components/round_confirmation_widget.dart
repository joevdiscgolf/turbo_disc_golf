import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/confirmation_holes_grid.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/description_quality_card.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_hole_detail_panel.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/round_metadata_card.dart';
import 'package:turbo_disc_golf/screens/round_processing/panels/record_single_hole_panel.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/state/round_confirmation_cubit.dart';
import 'package:turbo_disc_golf/state/round_confirmation_state.dart';
import 'package:turbo_disc_golf/utils/description_quality_analyzer.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

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

    // Defer state change until after the first frame is built
    // to avoid "setState() called during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _roundConfirmationCubit.startRoundConfirmation(
        context,
        widget.potentialRound,
      );
    });
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
      color: const Color(0xFFF5F0FA), // Lighter purple-gray background
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
                top: widget.topViewPadding + 64,
              ),
              children: [
                // Course metadata header
                RoundMetadataCard(
                  potentialRound: currentRound,
                  totalScore: totalScore,
                  totalPar: totalPar,
                  relativeScore: relativeScore,
                ),
                const SizedBox(height: 8),
                // Warning banner for missing data
                if (validationIssues.isNotEmpty)
                  _buildWarningBanner(
                    context,
                    currentRound,
                    validationIssues,
                    missingHoles,
                    hasRequiredFields,
                  ),

                // Quality feedback card
                _buildQualityFeedbackCard(currentRound),

                // Instructions
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 12),
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
                ConfirmationHolesGrid(potentialRound: currentRound),
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

  // Future<void> _openWalkthroughDialog(
  //   BuildContext context,
  //   PotentialDGRound currentRound,
  // ) async {
  //   displayBottomSheet(
  //     context,
  //     IncompleteHoleWalkthroughPanel(
  //       potentialRound: currentRound,
  //       bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
  //     ),
  //   );
  // }

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
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF7A7A).withValues(alpha: 0.25),
                    const Color(0xFFFF7A7A).withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FlutterRemix.error_warning_fill,
                    size: 18,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$holesToAddress ${holesToAddress == 1 ? 'hole needs' : 'holes need'} attention',
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
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
              label: 'Finalize',
              backgroundColor: Colors.green,
              icon: Icons.check,
              width: double.infinity,
              height: 56,
              fontSize: 16,
              disabled: !hasRequiredFields,
              onPressed: () {
                locator.get<LoggingService>().track(
                  'Finalize Round Button Tapped',
                  properties: {
                    'screen_name': 'Round Confirmation',
                    'course_name': widget.potentialRound.courseName ?? 'Unknown',
                    'hole_count': widget.potentialRound.holes?.length ?? 0,
                  },
                );
                widget.onConfirm();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualityFeedbackCard(PotentialDGRound round) {
    final DescriptionQualityReport report =
        DescriptionQualityAnalyzer.analyzeRound(round);

    return DescriptionQualityCard(
      report: report,
      onHoleTap: (holeIndex) => _showEditableHoleSheet(context, holeIndex),
    );
  }

  void _showEditableHoleSheet(BuildContext context, int holeIndex) {
    // Track Modal Opened event
    locator.get<LoggingService>().track('Modal Opened', properties: {
      'screen_name': 'Round Confirmation',
      'modal_type': 'bottom_sheet',
      'modal_name': 'Editable Hole Detail Panel',
      'hole_index': holeIndex,
    });

    // Set the current editing hole when opening the panel
    _roundConfirmationCubit.setCurrentEditingHole(holeIndex);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (builderContext) =>
          BlocBuilder<RoundConfirmationCubit, RoundConfirmationState>(
            builder: (context, state) {
              if (state is! ConfirmingRoundActive) {
                return const SizedBox();
              }
              final PotentialDGHole? currentHole = state.currentEditingHole;
              if (currentHole == null) {
                return const SizedBox();
              }

              return EditableHoleDetailPanel(
                potentialHole: currentHole,
                holeIndex: holeIndex,
                onMetadataChanged: ({int? newPar, int? newDistance}) =>
                    _handleMetadataChanged(
                      holeIndex,
                      newPar: newPar,
                      newDistance: newDistance,
                    ),
                onThrowAdded: (throw_, {int? addThrowAtIndex}) =>
                    _roundConfirmationCubit.addThrow(
                      holeIndex,
                      throw_,
                      addAfterThrowIndex: addThrowAtIndex,
                    ),
                onThrowEdited: (throwIndex, updatedThrow) =>
                    _roundConfirmationCubit.updateThrow(
                      holeIndex,
                      throwIndex,
                      updatedThrow,
                    ),
                onThrowDeleted: (throwIndex) =>
                    _roundConfirmationCubit.deleteThrow(holeIndex, throwIndex),
                onReorder: (oldIndex, newIndex) =>
                    _roundConfirmationCubit.reorderThrows(
                      holeIndex,
                      oldIndex,
                      newIndex,
                    ),
                onVoiceRecord: () => _handleVoiceRecord(currentHole, holeIndex),
              );
            },
          ),
    ).then((_) {
      _roundConfirmationCubit.clearCurrentEditingHole();
    });
  }

  void _handleMetadataChanged(
    int holeIndex, {
    int? newPar,
    int? newDistance,
  }) {
    final RoundConfirmationState state = _roundConfirmationCubit.state;
    if (state is! ConfirmingRoundActive) {
      return;
    }

    final PotentialDGHole? currentHole =
        state.potentialRound.holes?[holeIndex];
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
    _roundConfirmationCubit.updatePotentialHole(holeIndex, updatedHole);
  }

  void _handleVoiceRecord(PotentialDGHole currentHole, int holeIndex) {
    final RoundConfirmationState state = _roundConfirmationCubit.state;
    final String courseName = (state is ConfirmingRoundActive)
        ? (state.potentialRound.courseName ?? 'Unknown Course')
        : 'Unknown Course';

    displayBottomSheet(
      context,
      RecordSingleHolePanel(
        holeNumber: currentHole.number ?? holeIndex + 1,
        holePar: currentHole.par,
        holeFeet: currentHole.feet,
        courseName: courseName,
        showTestButton: true,
        onParseComplete: (parsedHole) =>
            _handleParseComplete(parsedHole, holeIndex),
        bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
      ),
    );
  }

  void _handleParseComplete(PotentialDGHole? parsedHole, int holeIndex) {
    if (parsedHole == null) {
      locator.get<ToastService>().showError('Failed to parse hole');
      return;
    }

    _roundConfirmationCubit.updatePotentialHole(holeIndex, parsedHole);

    locator.get<ToastService>().showSuccess('Hole updated successfully!');
  }

  /// Get holes that have all required fields
  /// These are the only holes that can be finalized
  List<PotentialDGHole> _completeHoles(PotentialDGRound round) =>
      round.holes!.where((hole) => hole.hasRequiredFields).toList();

  int _calculateTotalScoreForValidHoles(PotentialDGRound round) {
    if (round.holes == null) return 0;

    // Calculate score ONLY for complete holes (have par, feet, throws with basket)
    // This matches what will be finalized - incomplete holes shouldn't be counted
    return _completeHoles(round).fold<int>(0, (sum, hole) {
      // Calculate hole score: throws count + penalty strokes
      final int throwsCount = hole.throws?.length ?? 0;
      final int penaltyStrokes =
          hole.throws?.fold<int>(
            0,
            (prev, discThrow) => prev + (discThrow.penaltyStrokes),
          ) ??
          0;

      return sum + throwsCount + penaltyStrokes;
    });
  }

  int _calculateTotalParForValidHoles(PotentialDGRound round) {
    if (round.holes == null) return 0;

    // Calculate par ONLY for complete holes (have par, feet, throws with basket)
    // No defaulting needed since all complete holes have par defined
    return _completeHoles(round).fold(
      0,
      (sum, hole) => sum + (hole.par!), // Complete holes always have par
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
