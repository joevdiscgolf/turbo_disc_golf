import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/record_round/record_round_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/round_review_screen.dart';
import 'package:turbo_disc_golf/screens/test_ai_summary_screen.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  final FirestoreRoundService _roundService = locator
      .get<FirestoreRoundService>();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    switch (_selectedIndex) {
      case 0:
        appBarTitle = 'Add Round';
        break;
      case 1:
        appBarTitle = 'Round History';
        break;
      case 2:
        appBarTitle = 'Test AI Summary';
        break;
      default:
        appBarTitle = 'Add Round';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const RecordRoundScreen(),
          _buildRoundsTab(),
          const TestAiSummaryScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add Round',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Rounds',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Test AI',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildRoundsTab() {
    return FutureBuilder<List<DGRound>>(
      future: _roundService.getRounds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading rounds',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final rounds = snapshot.data ?? [];

        if (rounds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.golf_course,
                  size: 80,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No rounds yet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first round to get started!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rounds.length,
          itemBuilder: (context, index) {
            final round = rounds[index];
            return _buildRoundCard(round);
          },
        );
      },
    );
  }

  Widget _buildRoundCard(DGRound round) {
    final totalScore = round.holes.fold<int>(
      0,
      (sum, hole) => sum + hole.holeScore,
    );
    final totalPar = round.holes.fold<int>(0, (sum, hole) => sum + hole.par);
    final relativeToPar = totalScore - totalPar;
    final relativeToParText = relativeToPar == 0
        ? 'E'
        : relativeToPar > 0
        ? '+$relativeToPar'
        : '$relativeToPar';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Set the existing round so the parser can calculate stats
          locator.get<RoundParser>().setRound(round);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoundReviewScreen(round: round),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      round.courseName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(relativeToPar),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      relativeToParText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.pin_drop,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${round.holes.length} holes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.sports_golf,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Score: $totalScore',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(Par: $totalPar)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int relativeToPar) {
    if (relativeToPar <= -3) {
      return Colors.purple; // Eagle or better
    } else if (relativeToPar < 0) {
      return Colors.blue; // Under par
    } else if (relativeToPar == 0) {
      return Colors.green; // Even par
    } else if (relativeToPar <= 3) {
      return Colors.orange; // Slightly over par
    } else {
      return Colors.red; // Way over par
    }
  }
}
