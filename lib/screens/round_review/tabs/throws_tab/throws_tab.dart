import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/throws_tab/components/holes_list.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/throws_tab/components/score_kpi_card.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/utils/naming_constants.dart';

class ThrowsTab extends StatefulWidget {
  final DGRound round;

  const ThrowsTab({super.key, required this.round});

  @override
  State<ThrowsTab> createState() => _ThrowsTabState();
}

class _ThrowsTabState extends State<ThrowsTab> {
  late DGRound _round;
  late RoundParser _roundParser;

  @override
  void initState() {
    super.initState();
    _round = widget.round;
    _roundParser = locator.get<RoundParser>();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = _getListViewChildren();
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  List<Widget> _getListViewChildren() {
    return [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
        child: ScoreKPICard(roundParser: _roundParser),
      ),
      HolesList(round: _round, showAddThrowDialog: _showAddThrowDialog),
    ];
  }

  void _showAddThrowDialog(BuildContext context, DGHole hole) {
    final distanceController = TextEditingController();
    final notesController = TextEditingController();
    ThrowPurpose? selectedPurpose;
    ThrowTechnique? selectedTechnique;
    LandingSpot? selectedLandingSpot;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Throw to Hole ${hole.number}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Distance input
                    TextField(
                      controller: distanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Distance (feet)',
                        hintText: 'e.g., 350',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Purpose dropdown
                    DropdownButtonFormField<ThrowPurpose>(
                      value: selectedPurpose,
                      decoration: const InputDecoration(
                        labelText: 'Throw Purpose',
                      ),
                      items: ThrowPurpose.values.map((purpose) {
                        return DropdownMenuItem(
                          value: purpose,
                          child: Text(
                            throwPurposeToName[purpose] ?? purpose.name,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPurpose = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Technique dropdown
                    DropdownButtonFormField<ThrowTechnique>(
                      value: selectedTechnique,
                      decoration: const InputDecoration(labelText: 'Technique'),
                      items: ThrowTechnique.values.map((technique) {
                        return DropdownMenuItem(
                          value: technique,
                          child: Text(
                            throwTechniqueToName[technique] ?? technique.name,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedTechnique = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Landing spot dropdown
                    DropdownButtonFormField<LandingSpot>(
                      value: selectedLandingSpot,
                      decoration: const InputDecoration(
                        labelText: 'Where it Landed',
                      ),
                      items: LandingSpot.values.map((spot) {
                        return DropdownMenuItem(
                          value: spot,
                          child: Text(landingSpotToName[spot] ?? spot.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedLandingSpot = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes input
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Any additional details...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Create new throw
                    final newThrow = DiscThrow(
                      index: hole.throws.length,
                      distanceFeetBeforeThrow:
                          distanceController.text.isNotEmpty
                          ? int.tryParse(distanceController.text)
                          : null,
                      purpose: selectedPurpose,
                      technique: selectedTechnique,
                      landingSpot: selectedLandingSpot,
                      notes: notesController.text.isNotEmpty
                          ? notesController.text
                          : null,
                    );

                    // Add throw to hole
                    setState(() {
                      hole.throws.add(newThrow);
                    });

                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Throw added successfully')),
                    );
                  },
                  child: const Text('Add Throw'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
