import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_holes_grid.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

/// Confirmation widget that shows parsed round data for review and editing.
///
/// Displays course metadata and a grid of holes that can be tapped to view
/// and edit individual throws. User can go back or continue to the animation.
class RoundConfirmationWidget extends StatefulWidget {
  const RoundConfirmationWidget({
    super.key,
    required this.round,
    required this.onBack,
    required this.onConfirm,
  });

  final DGRound round;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  State<RoundConfirmationWidget> createState() =>
      _RoundConfirmationWidgetState();
}

class _RoundConfirmationWidgetState extends State<RoundConfirmationWidget> {
  late RoundParser _roundParser;
  late DGRound _currentRound;

  @override
  void initState() {
    super.initState();
    _roundParser = locator.get<RoundParser>();
    _currentRound = widget.round;

    // Listen to round parser changes to update UI
    _roundParser.addListener(_onRoundUpdated);
  }

  @override
  void dispose() {
    _roundParser.removeListener(_onRoundUpdated);
    super.dispose();
  }

  void _onRoundUpdated() {
    if (_roundParser.parsedRound != null) {
      setState(() {
        _currentRound = _roundParser.parsedRound!;
      });
    }
  }

  int _calculateTotalScore() {
    return _currentRound.holes.fold(
      0,
      (sum, hole) => sum + hole.holeScore,
    );
  }

  int _calculateTotalPar() {
    return _currentRound.holes.fold(
      0,
      (sum, hole) => sum + hole.par,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalScore = _calculateTotalScore();
    final int totalPar = _calculateTotalPar();
    final int relativeScore = totalScore - totalPar;

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
                round: _currentRound,
                roundParser: _roundParser,
              ),
            ),
          ),
        ],
      ),
      // Continue button at bottom
      bottomSheet: _buildBottomBar(context),
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
                  _currentRound.courseName,
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
                '${_currentRound.holes.length}',
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

  Widget _buildBottomBar(BuildContext context) {
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9D4EDD), // Purple accent
              foregroundColor: Colors.white,
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
      ),
    );
  }
}
