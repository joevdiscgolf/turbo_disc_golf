import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_holes_grid.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/incomplete_hole_walkthrough_sheet.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/round_metadata_card.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

/// Confirmation widget that shows parsed round data for review and editing.
///
/// Displays course metadata and a grid of holes that can be tapped to view
/// and edit individual throws. User can go back or continue to the animation.
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
  List<PotentialDGHole> get _validHoles =>
      _currentRound.holes!.where((hole) => hole.hasRequiredFields).toList();

  late RoundParser _roundParser;
  late PotentialDGRound _currentRound;

  @override
  void initState() {
    super.initState();
    _roundParser = locator.get<RoundParser>();
    _currentRound = widget.potentialRound;
    _roundParser.addListener(_refreshRoundData);
  }

  @override
  void dispose() {
    _roundParser.removeListener(_refreshRoundData);
    super.dispose();
  }

  void _refreshRoundData() {
    if (_roundParser.potentialRound != null) {
      setState(() {
        _currentRound = _roundParser.potentialRound!;
      });
    }
  }

  int _calculateTotalScoreForValidHoles() {
    if (_currentRound.holes == null) return 0;

    return _validHoles.fold<int>(0, (sum, hole) {
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

  int _calculateTotalParForValidHoles() {
    if (_currentRound.holes == null) return 0;

    return _validHoles.fold(
      0,
      (sum, hole) => sum + (hole.par ?? 3), // Default to par 3 if missing
    );
  }

  Map<String, dynamic> _validateRound() {
    final List<String> issues = [];
    final Set<int> missingHoles = {};
    bool hasRequiredFields = true;

    // Use the built-in validation from PotentialDGRound
    final validationSummary = _currentRound.getValidationSummary();
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
    if (!_currentRound.hasRequiredFields) {
      hasRequiredFields = false;
      final roundMissing = _currentRound.getMissingFields();
      for (final field in roundMissing) {
        if (!field.contains('hole')) {
          // Only show non-hole-specific issues (courseName, etc.)
          issues.add('Round: Missing $field');
        }
      }
    }

    // Check for missing holes in sequence
    if (_currentRound.holes != null && _currentRound.holes!.isNotEmpty) {
      final List<int> holeNumbers =
          _currentRound.holes!
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
    if (_currentRound.holes != null) {
      for (final hole in _currentRound.holes!) {
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

  @override
  Widget build(BuildContext context) {
    final int totalScore = _calculateTotalScoreForValidHoles();
    final int totalPar = _calculateTotalParForValidHoles();
    final int relativeScore = totalScore - totalPar;
    final Map<String, dynamic> validation = _validateRound();
    final List<String> validationIssues = validation['issues'] as List<String>;
    final Set<int> missingHoles = validation['missingHoles'] as Set<int>;
    final bool hasRequiredFields = validation['hasRequiredFields'] as bool;

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
                  potentialRound: _currentRound,
                  totalScore: totalScore,
                  totalPar: totalPar,
                  relativeScore: relativeScore,
                ),
                const SizedBox(height: 12),
                // Warning banner for missing data
                if (validationIssues.isNotEmpty)
                  _buildWarningBanner(
                    context,
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
                EditableHolesGrid(
                  potentialRound: _currentRound,
                  roundParser: _roundParser,
                ),
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

  int _getIncompleteHoleCount() {
    if (_currentRound.holes == null) return 0;
    // Count holes that are missing required fields OR have no throws
    return _currentRound.holes!
        .where(
          (hole) =>
              !hole.hasRequiredFields ||
              hole.throws == null ||
              hole.throws!.isEmpty,
        )
        .length;
  }

  Future<void> _openWalkthroughDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncompleteHoleWalkthroughSheet(
        potentialRound: _currentRound,
        bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
      ),
    );

    // Refresh the UI after bottom sheet closes
    _refreshRoundData();
  }

  Widget _buildWarningBanner(
    BuildContext context,
    List<String> issues,
    Set<int> missingHoles,
    bool hasRequiredFields,
  ) {
    final int incompleteHoleCount = _getIncompleteHoleCount();
    final int holesToAddress = incompleteHoleCount + missingHoles.length;

    return Row(
      children: [
        if (holesToAddress > 0)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Add the missing holes to potential round
                // if (missingHoles.isNotEmpty) {
                //   _roundParser.addEmptyHolesToPotentialRound(missingHoles);
                // }

                // Refresh the UI
                _refreshRoundData();

                // Then open the walkthrough to guide user through filling them in
                await _openWalkthroughDialog();
              },
              icon: const Icon(Icons.warning, size: 18),
              label: Text(
                '$holesToAddress holes ${holesToAddress == 1 ? 'needs' : 'need'} attention',
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
}
