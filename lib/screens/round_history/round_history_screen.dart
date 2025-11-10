import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_history/components/record_round_sheet.dart';
import 'package:turbo_disc_golf/screens/round_history/components/round_history_row.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';

class RoundHistoryScreen extends StatelessWidget {
  const RoundHistoryScreen({super.key});

  void _showRecordRoundSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RecordRoundSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<DGRound>>(
          future: locator.get<FirestoreRoundService>().getRounds(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
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

            final List<DGRound> rounds = snapshot.data ?? [];

            // Sort rounds by date (most recent first)
            // Priority: playedRoundAt > createdAt > id
            rounds.sort((a, b) {
              final String? aDate = a.playedRoundAt ?? a.createdAt;
              final String? bDate = b.playedRoundAt ?? b.createdAt;

              if (aDate != null && bDate != null) {
                // Both have dates, compare them (most recent first)
                return bDate.compareTo(aDate);
              } else if (aDate != null) {
                // a has a date, b doesn't - a comes first
                return -1;
              } else if (bDate != null) {
                // b has a date, a doesn't - b comes first
                return 1;
              } else {
                // Neither has a date, fall back to ID comparison
                return b.id.compareTo(a.id);
              }
            });

            if (rounds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.golf_course,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.5),
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
                final DGRound round = rounds[index];
                return RoundHistoryRow(round: round);
              },
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showRecordRoundSheet(context),
                  customBorder: const CircleBorder(),
                  child: const Center(
                    child: Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// OLD IMPLEMENTATION - Preserved for reference
// Use RoundHistoryRow from components/round_history_row.dart instead
// class _RoundHistoryRowOld extends StatelessWidget {
//   const _RoundHistoryRowOld({required this.round});

//   final DGRound round;

//   @override
//   Widget build(BuildContext context) {
//     final totalScore = round.holes.fold<int>(
//       0,
//       (sum, hole) => sum + hole.holeScore,
//     );
//     final totalPar = round.holes.fold<int>(0, (sum, hole) => sum + hole.par);
//     final relativeToPar = totalScore - totalPar;
//     final relativeToParText = relativeToPar == 0
//         ? 'E'
//         : relativeToPar > 0
//         ? '+$relativeToPar'
//         : '$relativeToPar';

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: InkWell(
//         onTap: () {
//           // Set the existing round so the parser can calculate stats
//           locator.get<RoundParser>().setRound(round);

//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => useRoundReviewScreenV2
//                   ? RoundReviewScreenV2(round: round)
//                   : RoundReviewScreen(round: round),
//             ),
//           );
//         },
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       round.courseName,
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: _getScoreColor(relativeToPar),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       relativeToParText,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Icon(
//                     Icons.pin_drop,
//                     size: 16,
//                     color: Theme.of(context).textTheme.bodySmall?.color,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${round.holes.length} holes',
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                   const SizedBox(width: 16),
//                   Icon(
//                     Icons.sports_golf,
//                     size: 16,
//                     color: Theme.of(context).textTheme.bodySmall?.color,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     'Score: $totalScore',
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     '(Par: $totalPar)',
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getScoreColor(int relativeToPar) {
//     if (relativeToPar <= -3) {
//       return Colors.purple; // Eagle or better
//     } else if (relativeToPar < 0) {
//       return Colors.blue; // Under par
//     } else if (relativeToPar == 0) {
//       return Colors.green; // Even par
//     } else if (relativeToPar <= 3) {
//       return Colors.orange; // Slightly over par
//     } else {
//       return Colors.red; // Way over par
//     }
//   }
// }

