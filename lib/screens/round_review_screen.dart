import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

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

class _RoundReviewScreenState extends State<RoundReviewScreen> {
  late DGRound _round;

  @override
  void initState() {
    super.initState();
    _round = widget.round;
  }

  Color _getScoreColor(int score) {
    if (score < 0) return Colors.green;
    if (score > 0) return Colors.red;
    return Colors.black87;
  }

  IconData _getThrowTypeIcon(DiscThrowType? type) {
    switch (type) {
      case DiscThrowType.drive:
        return Icons.sports_golf;
      case DiscThrowType.fairway:
        return Icons.trending_flat;
      case DiscThrowType.approach:
      case DiscThrowType.upshot:
        return Icons.call_made;
      case DiscThrowType.putt:
        return Icons.flag;
      default:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalScore = widget.roundParser.getTotalScore();
    final totalPar = widget.roundParser.getTotalPar();
    final relativeToPar = widget.roundParser.getRelativeToPar();

    return Scaffold(
      appBar: AppBar(
        title: Text(_round.course ?? 'Unknown course'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
      ),
      body: Column(
        children: [
          // Score summary card
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Total Score'),
                    Text(
                      '$totalScore',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Par'),
                    Text(
                      '$totalPar',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Score'),
                    Text(
                      relativeToPar >= 0 ? '+$relativeToPar' : '$relativeToPar',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: _getScoreColor(relativeToPar)),
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
                final hole = _round.holes[index];
                final score = widget.roundParser.calculateScore(hole);
                final scoreName = widget.roundParser.getScoreName(score);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                              '${hole.throws.length}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              scoreName,
                              style: TextStyle(
                                color: _getScoreColor(score),
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
                                  _getThrowTypeIcon(discThrow.throwType),
                                ),
                                title: Text(
                                  'Throw ${throwIndex + 1}: ${discThrow.discName ?? "Unknown disc"}',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${discThrow.distance} ft'),
                                    if (discThrow.description != null)
                                      Text(
                                        discThrow.description!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    if (discThrow.result != null)
                                      Chip(
                                        label: Text(discThrow.result!),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    // TODO: Implement throw editing
                                  },
                                ),
                              );
                            }).toList(),
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
      ),
    );
  }
}
