import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_holes_grid.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/incomplete_hole_walkthrough_dialog.dart';
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
  });

  final PotentialDGRound potentialRound;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  State<RoundConfirmationWidget> createState() =>
      _RoundConfirmationWidgetState();
}

class _RoundConfirmationWidgetState extends State<RoundConfirmationWidget> {
  late RoundParser _roundParser;
  late PotentialDGRound _currentRound;

  @override
  void initState() {
    super.initState();
    _roundParser = locator.get<RoundParser>();
    _currentRound = widget.potentialRound;
  }

  void _refreshRoundData() {
    if (_roundParser.potentialRound != null) {
      setState(() {
        _currentRound = _roundParser.potentialRound!;
      });
    }
  }

  int _calculateTotalScore() {
    if (_currentRound.holes == null) return 0;

    return _currentRound.holes!.fold<int>(0, (sum, hole) {
      // Calculate hole score: throws count + penalty strokes
      final int throwsCount = hole.throws?.length ?? 0;
      final int penaltyStrokes = hole.throws?.fold<int>(
            0,
            (prev, discThrow) => prev + (discThrow.penaltyStrokes ?? 0),
          ) ??
          0;
      return sum + throwsCount + penaltyStrokes;
    });
  }

  int _calculateTotalPar() {
    if (_currentRound.holes == null) return 0;

    return _currentRound.holes!.fold(
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
      final List<int> holeNumbers = _currentRound.holes!
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
    final int totalScore = _calculateTotalScore();
    final int totalPar = _calculateTotalPar();
    final int relativeScore = totalScore - totalPar;
    final Map<String, dynamic> validation = _validateRound();
    final List<String> validationIssues = validation['issues'] as List<String>;
    final Set<int> missingHoles = validation['missingHoles'] as Set<int>;
    final bool hasRequiredFields = validation['hasRequiredFields'] as bool;

    return Scaffold(
      backgroundColor: const Color(0xFFEEE8F5), // Light purple-gray background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Confirm Round'),
      ),
      body: Column(
        children: [
          // Course metadata header
          _buildMetadataCard(context, totalScore, totalPar, relativeScore),
          const SizedBox(height: 16),

          // Warning banner for missing data
          _buildWarningBanner(
            context,
            validationIssues,
            missingHoles,
            hasRequiredFields,
          ),
          if (validationIssues.isNotEmpty) const SizedBox(height: 16),

          // Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tap any hole to review and edit throws',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 12),

          // Scrollable holes grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: EditableHolesGrid(
                potentialRound: _currentRound,
                roundParser: _roundParser,
              ),
            ),
          ),
        ],
      ),
      // Continue button at bottom
      bottomSheet: _buildBottomBar(context, hasRequiredFields),
    );
  }

  Widget _buildMetadataCard(
    BuildContext context,
    int totalScore,
    int totalPar,
    int relativeScore,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course name
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentRound.courseName ?? 'Unknown Course',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Holes',
                '${_currentRound.holes?.length ?? 0}',
                Icons.golf_course,
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              _buildStatItem(
                context,
                'Score',
                '$totalScore',
                Icons.sports_score,
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              _buildStatItem(
                context,
                'Par',
                '$totalPar',
                Icons.flag_outlined,
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              _buildStatItem(
                context,
                'Total',
                relativeScore >= 0 ? '+$relativeScore' : '$relativeScore',
                Icons.trending_up,
                color: relativeScore < 0
                    ? const Color(0xFF137e66)
                    : relativeScore == 0
                        ? Colors.grey
                        : const Color(0xFFFF7A7A),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final Color displayColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Icon(icon, size: 20, color: displayColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
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

  int _getIncompleteHoleCount() {
    if (_currentRound.holes == null) return 0;
    // Count holes that are missing required fields OR have no throws
    return _currentRound.holes!
        .where((hole) =>
            !hole.hasRequiredFields ||
            hole.throws == null ||
            hole.throws!.isEmpty)
        .length;
  }

  Future<void> _openWalkthroughDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => IncompleteHoleWalkthroughDialog(
        potentialRound: _currentRound,
      ),
    );

    // Refresh the UI after dialog closes
    _refreshRoundData();
  }

  Widget _buildWarningBanner(
    BuildContext context,
    List<String> issues,
    Set<int> missingHoles,
    bool hasRequiredFields,
  ) {
    if (issues.isEmpty) return const SizedBox.shrink();

    final int incompleteHoleCount = _getIncompleteHoleCount();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasRequiredFields
                    ? Icons.info_outline
                    : Icons.warning_amber_rounded,
                color: hasRequiredFields
                    ? const Color(0xFF2196F3)
                    : const Color(0xFFFFA726),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasRequiredFields
                      ? 'Review Round Data'
                      : 'Action Required',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Issues summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasRequiredFields
                  ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                  : const Color(0xFFFFA726).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (missingHoles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${missingHoles.length} ${missingHoles.length == 1 ? 'hole' : 'holes'} missing from sequence',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                if (incompleteHoleCount > 0)
                  Text(
                    '$incompleteHoleCount ${incompleteHoleCount == 1 ? 'hole needs' : 'holes need'} additional information',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              if (missingHoles.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Add the missing holes to potential round
                      _roundParser.addEmptyHolesToPotentialRound(missingHoles);

                      // Refresh the UI
                      _refreshRoundData();

                      // Then open the walkthrough to guide user through filling them in
                      await _openWalkthroughDialog();
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Add Holes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137e66),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (missingHoles.isNotEmpty && incompleteHoleCount > 0)
                const SizedBox(width: 12),
              if (incompleteHoleCount > 0)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openWalkthroughDialog,
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Fix Info'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9D4EDD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool hasRequiredFields) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning text if required fields missing
            if (!hasRequiredFields)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFD32F2F),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please fix missing required fields before continuing',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFD32F2F),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasRequiredFields ? widget.onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9D4EDD), // Purple accent
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Continue to Results',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
