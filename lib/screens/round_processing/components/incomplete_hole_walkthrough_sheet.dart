import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_throw_timeline.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/hole_re_record_dialog.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_edit_dialog.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

/// Bottom sheet that guides user through fixing each incomplete hole sequentially.
/// Shows progress with tabs and horizontal checklist, allows inline editing.
/// Design matches _HoleDetailDialog from holes_grid.dart.
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
    extends State<IncompleteHoleWalkthroughSheet>
    with SingleTickerProviderStateMixin {
  late RoundParser _roundParser;
  late List<int> _incompleteHoleIndices;

  // Controllers for inline editing
  late List<TextEditingController> _holeNumberControllers;
  late List<TextEditingController> _parControllers;
  late List<TextEditingController> _distanceControllers;
  late List<FocusNode> _holeNumberFocusNodes;
  late List<FocusNode> _parFocusNodes;
  late List<FocusNode> _distanceFocusNodes;
  int _currentHoleIndex = 0;

  @override
  void initState() {
    super.initState();
    _roundParser = locator.get<RoundParser>();
    _roundParser.addListener(_onRoundUpdated);
    _incompleteHoleIndices = _getIncompleteHoleIndices();

    if (_incompleteHoleIndices.isNotEmpty) {
      _initializeTextControllers();
    }
  }

  @override
  void dispose() {
    _roundParser.removeListener(_onRoundUpdated);
    if (_incompleteHoleIndices.isNotEmpty) {
      for (var controller in _holeNumberControllers) {
        controller.dispose();
      }
      for (var controller in _parControllers) {
        controller.dispose();
      }
      for (var controller in _distanceControllers) {
        controller.dispose();
      }
      for (var focusNode in _holeNumberFocusNodes) {
        focusNode.dispose();
      }
      for (var focusNode in _parFocusNodes) {
        focusNode.dispose();
      }
      for (var focusNode in _distanceFocusNodes) {
        focusNode.dispose();
      }
    }
    super.dispose();
  }

  void _initializeTextControllers() {
    _holeNumberControllers = [];
    _parControllers = [];
    _distanceControllers = [];
    _holeNumberFocusNodes = [];
    _parFocusNodes = [];
    _distanceFocusNodes = [];

    for (int i = 0; i < _incompleteHoleIndices.length; i++) {
      final int holeIndex = _incompleteHoleIndices[i];
      final PotentialDGHole hole =
          _roundParser.potentialRound!.holes![holeIndex];

      final holeNumController = TextEditingController(
        text: hole.number?.toString() ?? '',
      );
      final parController = TextEditingController(
        text: hole.par?.toString() ?? '',
      );
      final distController = TextEditingController(
        text: hole.feet?.toString() ?? '',
      );

      _holeNumberControllers.add(holeNumController);
      _parControllers.add(parController);
      _distanceControllers.add(distController);
      _holeNumberFocusNodes.add(FocusNode());
      _parFocusNodes.add(FocusNode());
      _distanceFocusNodes.add(FocusNode());
    }
  }

  void _onRoundUpdated() {
    if (mounted) {
      setState(() {
        final previousLength = _incompleteHoleIndices.length;
        _refreshIncompleteHoles();

        // If the number of incomplete holes changed, reinitialize
        if (_incompleteHoleIndices.length != previousLength) {
          if (_incompleteHoleIndices.isEmpty) {
            return; // Will be handled by _refreshIncompleteHoles
          }

          for (var controller in _holeNumberControllers) {
            controller.dispose();
          }
          for (var controller in _parControllers) {
            controller.dispose();
          }
          for (var controller in _distanceControllers) {
            controller.dispose();
          }
          for (var focusNode in _holeNumberFocusNodes) {
            focusNode.dispose();
          }
          for (var focusNode in _parFocusNodes) {
            focusNode.dispose();
          }
          for (var focusNode in _distanceFocusNodes) {
            focusNode.dispose();
          }

          // Reinitialize

          _initializeTextControllers();
        } else {
          // Just update the controller values
          _updateControllers();
        }
      });
    }
  }

  void _updateControllers() {
    for (int i = 0; i < _incompleteHoleIndices.length; i++) {
      final int holeIndex = _incompleteHoleIndices[i];
      final PotentialDGHole hole =
          _roundParser.potentialRound!.holes![holeIndex];

      // Only update controllers if they don't have focus (user not editing)
      if (!_holeNumberFocusNodes[i].hasFocus) {
        _holeNumberControllers[i].text = hole.number?.toString() ?? '';
      }
      if (!_parFocusNodes[i].hasFocus) {
        _parControllers[i].text = hole.par?.toString() ?? '';
      }
      if (!_distanceFocusNodes[i].hasFocus) {
        _distanceControllers[i].text = hole.feet?.toString() ?? '';
      }
    }
  }

  void _saveMetadata(int tabIndex) {
    if (tabIndex >= _incompleteHoleIndices.length) return;

    final int holeIndex = _incompleteHoleIndices[tabIndex];
    final int? holeNumber = _holeNumberControllers[tabIndex].text.isEmpty
        ? null
        : int.tryParse(_holeNumberControllers[tabIndex].text);
    final int? par = _parControllers[tabIndex].text.isEmpty
        ? null
        : int.tryParse(_parControllers[tabIndex].text);
    final int? distance = _distanceControllers[tabIndex].text.isEmpty
        ? null
        : int.tryParse(_distanceControllers[tabIndex].text);

    _roundParser.updatePotentialHoleMetadata(
      holeIndex,
      number: holeNumber,
      par: par,
      feet: distance,
    );
  }

  void _refreshIncompleteHoles() {
    final newIncompleteIndices = _getIncompleteHoleIndices();
    _incompleteHoleIndices = newIncompleteIndices;

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

  List<int> _getIncompleteHoleIndices() {
    if (_roundParser.potentialRound?.holes == null) return [];

    final List<int> indices = [];
    for (int i = 0; i < _roundParser.potentialRound!.holes!.length; i++) {
      final hole = _roundParser.potentialRound!.holes![i];
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

  bool _isHoleComplete(int tabIndex) {
    if (tabIndex >= _incompleteHoleIndices.length) return false;

    final int holeIndex = _incompleteHoleIndices[tabIndex];
    final PotentialDGHole hole = _roundParser.potentialRound!.holes![holeIndex];

    // Check if hole has required metadata
    final bool hasMetadata =
        hole.number != null && hole.par != null && hole.feet != null;

    // Check if hole has at least one basket throw
    final bool hasBasketThrow = _hasBasketThrow(hole);

    return hasMetadata && hasBasketThrow;
  }

  void _handleReRecord(int tabIndex) {
    if (tabIndex >= _incompleteHoleIndices.length) return;

    final int holeIndex = _incompleteHoleIndices[tabIndex];
    final PotentialDGHole hole = _roundParser.potentialRound!.holes![holeIndex];

    showDialog<void>(
      context: context,
      builder: (context) => HoleReRecordDialog(
        holeNumber: hole.number ?? holeIndex + 1,
        holePar: hole.par,
        holeFeet: hole.feet,
        holeIndex: holeIndex,
        onReProcessed: () {
          // Refresh after re-recording
          _refreshIncompleteHoles();
        },
      ),
    );
  }

  void _addThrow(int tabIndex) {
    if (tabIndex >= _incompleteHoleIndices.length) return;

    final int holeIndex = _incompleteHoleIndices[tabIndex];
    final PotentialDGHole hole = _roundParser.potentialRound!.holes![holeIndex];

    // Create a new throw with default values
    final DiscThrow newThrow = DiscThrow(
      index: hole.throws?.length ?? 0,
      purpose: ThrowPurpose.other,
      technique: ThrowTechnique.backhand,
    );

    showDialog(
      context: context,
      builder: (context) => ThrowEditDialog(
        throw_: newThrow,
        throwIndex: hole.throws?.length ?? 0,
        holeNumber: hole.number ?? holeIndex + 1,
        isNewThrow: true,
        onSave: (savedThrow) {
          final List<PotentialDiscThrow> updatedThrows =
              List<PotentialDiscThrow>.from(hole.throws ?? []);
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
            number: hole.number,
            par: hole.par,
            feet: hole.feet,
            throws: updatedThrows,
            holeType: hole.holeType,
          );

          // Update the entire hole including throws
          _roundParser.updatePotentialHole(holeIndex, updatedHole);
          Navigator.of(context).pop();
        },
        onDelete: null, // No delete for new throws
      ),
    );
  }

  void _editThrow(int tabIndex, int throwIndex) {
    if (tabIndex >= _incompleteHoleIndices.length) return;

    final int holeIndex = _incompleteHoleIndices[tabIndex];
    final PotentialDGHole hole = _roundParser.potentialRound!.holes![holeIndex];

    // Convert to DiscThrow from PotentialDiscThrow if needed
    final PotentialDiscThrow? potentialThrow = hole.throws?[throwIndex];
    if (potentialThrow == null || !potentialThrow.hasRequiredFields) {
      return; // Can't edit incomplete throw
    }
    final DiscThrow currentThrow = potentialThrow.toDiscThrow();

    showDialog(
      context: context,
      builder: (context) => ThrowEditDialog(
        throw_: currentThrow,
        throwIndex: throwIndex,
        holeNumber: hole.number ?? holeIndex + 1,
        onSave: (updatedThrow) {
          _roundParser.updateThrow(holeIndex, throwIndex, updatedThrow);
          Navigator.of(context).pop();
        },
        onDelete: () {
          _deleteThrow(holeIndex, throwIndex);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _deleteThrow(int holeIndex, int throwIndex) {
    final PotentialDGHole hole = _roundParser.potentialRound!.holes![holeIndex];

    final List<PotentialDiscThrow> updatedThrows =
        List<PotentialDiscThrow>.from(hole.throws ?? []);
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
      number: hole.number,
      par: hole.par,
      feet: hole.feet,
      throws: reindexedThrows,
      holeType: hole.holeType,
    );

    // Update the entire hole including throws
    _roundParser.updatePotentialHole(holeIndex, updatedHole);
  }

  Color _getScoreColor(PotentialDGHole hole) {
    if (!hole.hasRequiredFields ||
        hole.throws == null ||
        hole.throws!.isEmpty) {
      return const Color(0xFF137e66); // Green for incomplete
    }

    final DGHole completeHole = hole.toDGHole();
    final int relativeScore = completeHole.relativeHoleScore;

    if (relativeScore < 0) {
      return const Color(0xFF137e66); // Birdie - green
    } else if (relativeScore == 0) {
      return Colors.grey; // Par - grey
    } else if (relativeScore == 1) {
      return const Color(0xFFFF7A7A); // Bogey - light red
    } else {
      return const Color(0xFFD32F2F); // Double bogey+ - dark red
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no incomplete holes, show completion message
    if (_incompleteHoleIndices.isEmpty) {
      return Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: widget.bottomViewPadding,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
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
                backgroundColor: const Color(0xFF137e66),
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside text fields
            FocusScope.of(context).unfocus();
          },
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fact_check,
                        color: Color(0xFF137e66),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add missing data',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Horizontal checklist
                Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _incompleteHoleIndices.length,
                    itemBuilder: (context, index) {
                      final holeIndex = _incompleteHoleIndices[index];
                      final hole =
                          _roundParser.potentialRound!.holes![holeIndex];
                      final isComplete = _isHoleComplete(index);
                      final isSelected = _currentHoleIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            setState(() {
                              _currentHoleIndex = index;
                            });
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isComplete
                                ? const Color(0xFF137e66).withValues(alpha: 0.15)
                                : const Color(0xFFD32F2F).withValues(alpha: 0.15),
                            border: Border.all(
                              color: isSelected
                                  ? (isComplete
                                      ? const Color(0xFF137e66)
                                      : const Color(0xFFD32F2F))
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
                                  color: Color(0xFFD32F2F),
                                  size: 18,
                                ),
                              const SizedBox(height: 2),
                              Text(
                                'H${hole.number ?? '?'}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isComplete
                                      ? const Color(0xFF137e66)
                                      : const Color(0xFFD32F2F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Tab content
                Expanded(
                  child: _buildHoleContent(_currentHoleIndex, scrollController),
                ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoleContent(int tabIndex, ScrollController scrollController) {
    final int holeIndex = _incompleteHoleIndices[tabIndex];
    final PotentialDGHole hole = _roundParser.potentialRound!.holes![holeIndex];
    final Color scoreColor = _getScoreColor(hole);
    final int? score =
        hole.hasRequiredFields && hole.throws != null && hole.throws!.isNotEmpty
        ? hole.toDGHole().holeScore
        : null;

    return Column(
      children: [
        // Header (matching _HoleDetailDialog design)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: scoreColor.withValues(alpha: 0.1)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.golf_course, size: 24, color: scoreColor),
                  const SizedBox(width: 8),
                  Text(
                    'Hole ${hole.number ?? '?'}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (score != null)
                Container(
                  width: 48,
                  height: 48,
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
                        fontSize: 20,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.edit, color: scoreColor, size: 20),
                  ),
                ),
            ],
          ),
        ),

        // Hole info with editable fields (matching _HoleDetailDialog layout)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEditableInfoItem(
                context,
                'Par',
                _parControllers[tabIndex],
                _parFocusNodes[tabIndex],
                tabIndex,
                Icons.flag_outlined,
              ),
              _buildEditableInfoItem(
                context,
                'Distance',
                _distanceControllers[tabIndex],
                _distanceFocusNodes[tabIndex],
                tabIndex,
                Icons.straighten,
                suffix: 'ft',
              ),
              _buildInfoItem(
                context,
                'Throws',
                '${hole.throws?.length ?? 0}',
                Icons.sports_golf,
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Throws timeline
        Expanded(
          child: hole.throws != null && hole.throws!.isNotEmpty
              ? EditableThrowTimeline(
                  throws: hole.throws!
                      .where((t) => t.hasRequiredFields)
                      .map((t) => t.toDiscThrow())
                      .toList(),
                  onEditThrow: (throwIndex) => _editThrow(tabIndex, throwIndex),
                )
              : SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'No throws recorded',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                          if (!_hasBasketThrow(hole) &&
                              hole.throws?.isEmpty != true)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFD32F2F,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Hole must be completed.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFFD32F2F),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),

        // Action buttons
        Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: widget.bottomViewPadding,
          ),
          child: Column(
            children: [
              // Add throw button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _addThrow(tabIndex),
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: Text(
                    'Add Throw',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Re-record button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _handleReRecord(tabIndex),
                  icon: const Icon(Icons.mic, size: 18),
                  label: const Text('Re-record Hole'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137e66),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableInfoItem(
    BuildContext context,
    String label,
    TextEditingController controller,
    FocusNode focusNode,
    int tabIndex,
    IconData icon, {
    String? suffix,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        IntrinsicWidth(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              suffix: suffix != null
                  ? Text(suffix, style: Theme.of(context).textTheme.bodySmall)
                  : null,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _saveMetadata(tabIndex),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
}
