import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/incomplete_hole_detail_content.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

/// Dialog that guides user through fixing each incomplete hole sequentially.
/// Shows progress and allows navigation between incomplete holes.
class IncompleteHoleWalkthroughDialog extends StatefulWidget {
  const IncompleteHoleWalkthroughDialog({
    super.key,
    required this.potentialRound,
  });

  final PotentialDGRound potentialRound;

  @override
  State<IncompleteHoleWalkthroughDialog> createState() =>
      _IncompleteHoleWalkthroughDialogState();
}

class _IncompleteHoleWalkthroughDialogState
    extends State<IncompleteHoleWalkthroughDialog> {
  late RoundParser _roundParser;
  late List<int> _incompleteHoleIndices;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _roundParser = locator.get<RoundParser>();
    _incompleteHoleIndices = _getIncompleteHoleIndices();
  }

  void _refreshIncompleteHoles() {
    setState(() {
      final newIncompleteIndices = _getIncompleteHoleIndices();
      _incompleteHoleIndices = newIncompleteIndices;

      // If current hole is now complete, don't advance (let user see success)
      // But if they navigate, adjust the index
      if (_currentIndex >= _incompleteHoleIndices.length &&
          _incompleteHoleIndices.isNotEmpty) {
        _currentIndex = _incompleteHoleIndices.length - 1;
      }

      // If all holes are now complete, close dialog
      if (_incompleteHoleIndices.isEmpty) {
        Future.microtask(() {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All holes fixed! ✓'),
                backgroundColor: Color(0xFF137e66),
              ),
            );
          }
        });
      }
    });
  }

  List<int> _getIncompleteHoleIndices() {
    if (_roundParser.potentialRound?.holes == null) return [];

    final List<int> indices = [];
    for (int i = 0; i < _roundParser.potentialRound!.holes!.length; i++) {
      final hole = _roundParser.potentialRound!.holes![i];
      // Consider a hole incomplete if it's missing required fields OR has no throws
      if (!hole.hasRequiredFields || hole.throws == null || hole.throws!.isEmpty) {
        indices.add(i);
      }
    }
    return indices;
  }

  void _handleNext() {
    if (_currentIndex < _incompleteHoleIndices.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // At the end, close dialog
      Navigator.of(context).pop();
    }
  }

  void _handlePrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _handleSkip() {
    _handleNext(); // Same as next for now
  }

  void _handleHoleFixed() {
    // Refresh the list of incomplete holes
    _refreshIncompleteHoles();

    // When a hole is fixed, auto-advance to next after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _handleNext();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If no incomplete holes, show a message
    if (_incompleteHoleIndices.isEmpty) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF137e66),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'All holes are complete!',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9D4EDD),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final int currentHoleIndex = _incompleteHoleIndices[_currentIndex];
    final PotentialDGHole currentHole =
        _roundParser.potentialRound!.holes![currentHoleIndex];
    final int totalIncomplete = _incompleteHoleIndices.length;
    final int currentPosition = _currentIndex + 1;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with progress
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF9D4EDD).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fact_check,
                    color: Color(0xFF9D4EDD),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fixing Incomplete Holes',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Hole $currentPosition of $totalIncomplete',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF9D4EDD),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Progress bar
            LinearProgressIndicator(
              value: currentPosition / totalIncomplete,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF9D4EDD),
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: IncompleteHoleDetailContent(
                  potentialHole: currentHole,
                  holeIndex: currentHoleIndex,
                  roundParser: _roundParser,
                  onHoleFixed: _handleHoleFixed,
                ),
              ),
            ),

            // Navigation buttons
            Container(
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
              child: Row(
                children: [
                  // Previous button
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handlePrevious,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Previous'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 8),

                  // Skip button (or space)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _handleSkip,
                      icon: const Icon(Icons.skip_next, size: 18),
                      label: const Text('Skip'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Next/Done button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _handleNext,
                      icon: Icon(
                        _currentIndex < _incompleteHoleIndices.length - 1
                            ? Icons.arrow_forward
                            : Icons.check,
                        size: 18,
                      ),
                      label: Text(
                        _currentIndex < _incompleteHoleIndices.length - 1
                            ? 'Next'
                            : 'Done',
                      ),
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
            ),
          ],
        ),
      ),
    );
  }
}
