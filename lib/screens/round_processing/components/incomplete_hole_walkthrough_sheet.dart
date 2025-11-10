import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_throw_timeline.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/hole_re_record_dialog.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_edit_dialog.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

/// Bottom sheet that guides user through fixing each incomplete hole sequentially.
/// Shows progress and allows navigation between incomplete holes.
/// Includes direct editing of hole metadata and throw management.
class IncompleteHoleWalkthroughSheet extends StatefulWidget {
  const IncompleteHoleWalkthroughSheet({
    super.key,
    required this.potentialRound,
  });

  final PotentialDGRound potentialRound;

  @override
  State<IncompleteHoleWalkthroughSheet> createState() =>
      _IncompleteHoleWalkthroughSheetState();
}

class _IncompleteHoleWalkthroughSheetState
    extends State<IncompleteHoleWalkthroughSheet> {
  late RoundParser _roundParser;
  late List<int> _incompleteHoleIndices;
  int _currentIndex = 0;

  // Controllers for inline editing
  late TextEditingController _holeNumberController;
  late TextEditingController _parController;
  late TextEditingController _distanceController;

  @override
  void initState() {
    super.initState();
    _roundParser = locator.get<RoundParser>();
    _roundParser.addListener(_onRoundUpdated);
    _incompleteHoleIndices = _getIncompleteHoleIndices();
    _initializeControllers();
  }

  @override
  void dispose() {
    _roundParser.removeListener(_onRoundUpdated);
    _holeNumberController.dispose();
    _parController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    if (_incompleteHoleIndices.isEmpty) return;

    final int currentHoleIndex = _incompleteHoleIndices[_currentIndex];
    final PotentialDGHole currentHole =
        _roundParser.potentialRound!.holes![currentHoleIndex];

    _holeNumberController = TextEditingController(
      text: currentHole.number?.toString() ?? '',
    );
    _parController = TextEditingController(
      text: currentHole.par?.toString() ?? '',
    );
    _distanceController = TextEditingController(
      text: currentHole.feet?.toString() ?? '',
    );

    // Add listeners to save changes on edit
    _holeNumberController.addListener(_saveMetadata);
    _parController.addListener(_saveMetadata);
    _distanceController.addListener(_saveMetadata);
  }

  void _onRoundUpdated() {
    if (mounted) {
      setState(() {
        _refreshIncompleteHoles();
      });
    }
  }

  void _saveMetadata() {
    if (_incompleteHoleIndices.isEmpty) return;

    final int? holeNumber = int.tryParse(_holeNumberController.text);
    final int? par = int.tryParse(_parController.text);
    final int? distance = int.tryParse(_distanceController.text);

    final int currentHoleIndex = _incompleteHoleIndices[_currentIndex];

    _roundParser.updatePotentialHoleMetadata(
      currentHoleIndex,
      number: holeNumber,
      par: par,
      feet: distance,
    );
  }

  void _refreshIncompleteHoles() {
    final newIncompleteIndices = _getIncompleteHoleIndices();
    _incompleteHoleIndices = newIncompleteIndices;

    // If current hole is now complete, don't advance (let user see success)
    // But if they navigate, adjust the index
    if (_currentIndex >= _incompleteHoleIndices.length &&
        _incompleteHoleIndices.isNotEmpty) {
      _currentIndex = _incompleteHoleIndices.length - 1;
    }

    // Update controllers for new current hole
    if (_incompleteHoleIndices.isNotEmpty) {
      _updateControllersForCurrentHole();
    }

    // If all holes are now complete, close bottom sheet
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
  }

  void _updateControllersForCurrentHole() {
    final int currentHoleIndex = _incompleteHoleIndices[_currentIndex];
    final PotentialDGHole currentHole =
        _roundParser.potentialRound!.holes![currentHoleIndex];

    _holeNumberController.text = currentHole.number?.toString() ?? '';
    _parController.text = currentHole.par?.toString() ?? '';
    _distanceController.text = currentHole.feet?.toString() ?? '';
  }

  List<int> _getIncompleteHoleIndices() {
    if (_roundParser.potentialRound?.holes == null) return [];

    final List<int> indices = [];
    for (int i = 0; i < _roundParser.potentialRound!.holes!.length; i++) {
      final hole = _roundParser.potentialRound!.holes![i];
      // Consider a hole incomplete if it's missing required fields OR has no throws
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

  bool _canProceed() {
    if (_incompleteHoleIndices.isEmpty) return true;

    final int currentHoleIndex = _incompleteHoleIndices[_currentIndex];
    final PotentialDGHole currentHole =
        _roundParser.potentialRound!.holes![currentHoleIndex];

    // Check if hole has required metadata
    final bool hasMetadata =
        currentHole.number != null &&
        currentHole.par != null &&
        currentHole.feet != null;

    // Check if hole has at least one basket throw
    final bool hasBasketThrow = _hasBasketThrow(currentHole);

    return hasMetadata && hasBasketThrow;
  }

  void _handleNext() {
    if (_currentIndex < _incompleteHoleIndices.length - 1) {
      setState(() {
        _currentIndex++;
        _updateControllersForCurrentHole();
      });
    } else {
      // At the end, close bottom sheet
      Navigator.of(context).pop();
    }
  }

  void _handlePrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _updateControllersForCurrentHole();
      });
    }
  }

  void _handleSkip() {
    _handleNext(); // Same as next for now
  }

  void _handleReRecord() {
    if (_incompleteHoleIndices.isEmpty) return;

    final int currentHoleIndex = _incompleteHoleIndices[_currentIndex];
    final PotentialDGHole currentHole =
        _roundParser.potentialRound!.holes![currentHoleIndex];

    showDialog<void>(
      context: context,
      builder: (context) => HoleReRecordDialog(
        holeNumber: currentHole.number ?? currentHoleIndex + 1,
        holePar: currentHole.par,
        holeFeet: currentHole.feet,
        holeIndex: currentHoleIndex,
        onReProcessed: () {
          // Refresh after re-recording
          _refreshIncompleteHoles();
        },
      ),
    );
  }

  void _addThrow() {
    if (_incompleteHoleIndices.isEmpty) return;

    final int currentHoleIndex = _incompleteHoleIndices[_currentIndex];
    final PotentialDGHole currentHole =
        _roundParser.potentialRound!.holes![currentHoleIndex];

    // Create a new throw with default values
    final DiscThrow newThrow = DiscThrow(
      index: currentHole.throws?.length ?? 0,
      purpose: ThrowPurpose.other,
      technique: ThrowTechnique.backhand,
    );

    showDialog(
      context: context,
      builder: (context) => ThrowEditDialog(
        throw_: newThrow,
        throwIndex: currentHole.throws?.length ?? 0,
        holeNumber: currentHole.number ?? currentHoleIndex + 1,
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

          // Update via metadata method which handles conversion if complete
          _roundParser.updatePotentialHoleMetadata(
            currentHoleIndex,
            number: updatedHole.number,
            par: updatedHole.par,
            feet: updatedHole.feet,
          );
          Navigator.of(context).pop();
        },
        onDelete: null, // No delete for new throws
      ),
    );
  }

  void _editThrow(int throwIndex) {
    if (_incompleteHoleIndices.isEmpty) return;

    final int currentHoleIndex = _incompleteHoleIndices[_currentIndex];
    final PotentialDGHole currentHole =
        _roundParser.potentialRound!.holes![currentHoleIndex];

    // Convert to DiscThrow from PotentialDiscThrow if needed
    final PotentialDiscThrow? potentialThrow = currentHole.throws?[throwIndex];
    if (potentialThrow == null || !potentialThrow.hasRequiredFields) {
      return; // Can't edit incomplete throw
    }
    final DiscThrow currentThrow = potentialThrow.toDiscThrow();

    showDialog(
      context: context,
      builder: (context) => ThrowEditDialog(
        throw_: currentThrow,
        throwIndex: throwIndex,
        holeNumber: currentHole.number ?? currentHoleIndex + 1,
        onSave: (updatedThrow) {
          _roundParser.updateThrow(currentHoleIndex, throwIndex, updatedThrow);
          Navigator.of(context).pop();
        },
        onDelete: () {
          _deleteThrow(throwIndex);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _deleteThrow(int throwIndex) {
    if (_incompleteHoleIndices.isEmpty) return;

    final int currentHoleIndex = _incompleteHoleIndices[_currentIndex];
    final PotentialDGHole currentHole =
        _roundParser.potentialRound!.holes![currentHoleIndex];

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

    // Update via metadata method which handles conversion if complete
    _roundParser.updatePotentialHoleMetadata(
      currentHoleIndex,
      number: updatedHole.number,
      par: updatedHole.par,
      feet: updatedHole.feet,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If no incomplete holes, show completion message
    if (_incompleteHoleIndices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF137e66), size: 64),
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
      );
    }

    final int currentHoleIndex = _incompleteHoleIndices[_currentIndex];
    final PotentialDGHole currentHole =
        _roundParser.potentialRound!.holes![currentHoleIndex];
    final int totalIncomplete = _incompleteHoleIndices.length;
    final int currentPosition = _currentIndex + 1;
    final bool canProceed = _canProceed();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with progress
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF9D4EDD).withValues(alpha: 0.1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fact_check,
                      color: Color(0xFF9D4EDD),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fix Holes',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Hole $currentPosition of $totalIncomplete',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
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
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hole metadata section with inline editing
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF9D4EDD,
                          ).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFF9D4EDD,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.golf_course,
                                  color: Color(0xFF9D4EDD),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hole Information',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNumberField(
                                    label: 'Hole #',
                                    controller: _holeNumberController,
                                    icon: Icons.golf_course,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildNumberField(
                                    label: 'Par',
                                    controller: _parController,
                                    icon: Icons.flag_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildNumberField(
                                    label: 'Distance (ft)',
                                    controller: _distanceController,
                                    icon: Icons.straighten,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Throws section header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Throws',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (!_hasBasketThrow(currentHole))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFD32F2F,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Need basket throw',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFFD32F2F),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Throws timeline (if any)
                      if (currentHole.throws != null &&
                          currentHole.throws!.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: EditableThrowTimeline(
                            throws: currentHole.throws!
                                .where((t) => t.hasRequiredFields)
                                .map((t) => t.toDiscThrow())
                                .toList(),
                            onEditThrow: _editThrow,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'No throws recorded yet',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Add throw button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addThrow,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Throw'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Re-record button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleReRecord,
                          icon: const Icon(Icons.mic, size: 18),
                          label: const Text('Re-record Hole'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9D4EDD),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
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

                    // Skip button
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
                        onPressed: canProceed ? _handleNext : null,
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
                          disabledBackgroundColor: Colors.grey.withValues(
                            alpha: 0.3,
                          ),
                          disabledForegroundColor: Colors.grey.withValues(
                            alpha: 0.5,
                          ),
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
        );
      },
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }
}
