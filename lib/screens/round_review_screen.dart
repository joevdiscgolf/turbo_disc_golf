import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/gpt_round_summary_screen.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/utils/naming_constants.dart';
import 'package:turbo_disc_golf/widgets/round_stats_tab.dart';
import 'package:turbo_disc_golf/widgets/round_analysis_tab.dart';

class RoundReviewScreen extends StatefulWidget {
  final DGRound round;
  final RoundParser roundParser;
  final BagService bagService;

  const RoundReviewScreen({
    super.key,
    required this.round,
    required this.roundParser,
    required this.bagService,
  });

  @override
  State<RoundReviewScreen> createState() => _RoundReviewScreenState();
}

class _RoundReviewScreenState extends State<RoundReviewScreen>
    with SingleTickerProviderStateMixin {
  static const bool showGptScreen = false;
  late DGRound _round;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _round = widget.round;
    _tabController = TabController(length: showGptScreen ? 2 : 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  IconData _getThrowTypeIcon(ThrowPurpose? type) {
    switch (type) {
      case ThrowPurpose.teeDrive:
        return Icons.sports_golf;
      case ThrowPurpose.fairwayDrive:
        return Icons.trending_flat;
      case ThrowPurpose.approach:
        return Icons.call_made;
      case ThrowPurpose.putt:
        return Icons.flag;
      case ThrowPurpose.scramble:
        return Icons.refresh;
      case ThrowPurpose.penalty:
        return Icons.warning;
      case ThrowPurpose.other:
        return Icons.sports;
      default:
        return Icons.sports;
    }
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
                      distanceFeet: distanceController.text.isNotEmpty
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

  Widget _buildThrowsTab() {
    return Column(
      children: [
        // Score summary card
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text('Total Score'),
                  Text(
                    '${widget.roundParser.getTotalScore()}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('Par'),
                  Text(
                    '${widget.roundParser.getTotalPar()}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('Score'),
                  Text(
                    widget.roundParser.getRelativeToPar() >= 0
                        ? '+${widget.roundParser.getRelativeToPar()}'
                        : '${widget.roundParser.getRelativeToPar()}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _getScoreColor(
                        widget.roundParser.getRelativeToPar(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Holes list
        Expanded(
          child: ListView.builder(
            itemCount: _round.holes.length,
            itemBuilder: (context, index) {
              final DGHole hole = _round.holes[index];
              final String scoreName = widget.roundParser.getScoreName(
                hole.relativeHoleScore,
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                            return ListTile(
                              leading: Icon(
                                _getThrowTypeIcon(discThrow.purpose),
                              ),
                              title: Text(
                                'Throw ${throwIndex + 1}${discThrow.technique != null ? ': ${throwTechniqueToName[discThrow.technique]}' : ''}',
                              ),
                              subtitle: discThrow.distanceFeet != null
                                  ? Text('${discThrow.distanceFeet} ft')
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  // TODO: Implement throw editing
                                },
                              ),
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
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
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_round.course ?? 'Unknown course'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: Implement save functionality
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Round saved!')));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          labelColor: Theme.of(context).colorScheme.secondary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.6),
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Throws'),
            if (!showGptScreen) Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
            Tab(icon: Icon(Icons.insights), text: 'Analysis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildThrowsTab(),
          if (!showGptScreen) RoundStatsTab(round: _round),
          if (!showGptScreen) RoundAnalysisTab(round: _round),
          if (showGptScreen) GPTRoundSummaryScreen(round: _round),
        ],
      ),
    );
  }
}
