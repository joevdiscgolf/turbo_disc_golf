import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/throw_list_item.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
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
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _round.holes.length + 1, // +1 for the summary card
      itemBuilder: (context, index) {
        // First item is the summary card
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildScoreKPICard(
                              context,
                              'Score',
                              _roundParser.getRelativeToPar() >= 0
                                  ? '+${_roundParser.getRelativeToPar()}'
                                  : '${_roundParser.getRelativeToPar()}',
                              _getScoreColor(_roundParser.getRelativeToPar()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildScoreKPICard(
                              context,
                              'Throws',
                              '${_roundParser.getTotalScore()}',
                              const Color(0xFF2196F3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildScoreKPICard(
                              context,
                              'Par',
                              '${_roundParser.getTotalPar()}',
                              const Color(0xFFFFA726),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Remaining items are hole cards
        final holeIndex = index - 1;
        final DGHole hole = _round.holes[holeIndex];
        final String scoreName = _roundParser.getScoreName(
          hole.relativeHoleScore,
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ExpansionTile(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    '${hole.number}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hole ${hole.number}'),
                      Text(
                        'Par ${hole.par} • ${hole.feet} ft',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${hole.holeScore}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      scoreName,
                      style: TextStyle(
                        color: _getScoreColor(hole.relativeHoleScore),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...hole.throws.asMap().entries.map((entry) {
                      final throwIndex = entry.key;
                      final discThrow = entry.value;

                      return ThrowListItem(
                        discThrow: discThrow,
                        throwIndex: throwIndex,
                        onEdit: () {
                          // todo: Implement throw editing
                        },
                      );
                    }),
                    // Add throw button
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showAddThrowDialog(context, hole);
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add Throw'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
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

  Widget _buildScoreKPICard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
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
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score < 0) {
      return const Color(0xFF00F5D4);
    } else if (score > 0) {
      return const Color(0xFFFF7A7A);
    } else {
      return const Color(0xFFF5F5F5);
    }
  }
}
