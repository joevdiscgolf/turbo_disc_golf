import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/round_review_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/round_review_screen_v2.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

class RoundHistoryRow extends StatelessWidget {
  const RoundHistoryRow({super.key, required this.round});

  final DGRound round;

  @override
  Widget build(BuildContext context) {
    final int totalScore = round.holes.fold<int>(
      0,
      (sum, hole) => sum + hole.holeScore,
    );
    final int totalPar = round.holes.fold<int>(
      0,
      (sum, hole) => sum + hole.par,
    );
    final int relativeToPar = totalScore - totalPar;
    final String relativeToParText = relativeToPar == 0
        ? 'E'
        : relativeToPar > 0
        ? '+$relativeToPar'
        : '$relativeToPar';

    // Get statistics from analysis
    final int birdies = round.analysis?.scoringStats.birdies ?? 0;
    final double c1InRegPct = round.analysis?.coreStats.c1InRegPct ?? 0.0;
    final double c1xPuttingPct =
        round.analysis?.puttingStats.c1xPercentage ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: GestureDetector(
        onTap: () {
          // Set the existing round so the parser can calculate stats
          locator.get<RoundParser>().setRound(round);

          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => useRoundReviewScreenV2
                  ? RoundReviewScreenV2(round: round)
                  : RoundReviewScreen(round: round),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Course name and score badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course name and hole count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          round.courseName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.pin_drop,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${round.holes.length} holes',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Score badge
                  _ScoreBadge(
                    scoreText: relativeToParText,
                    relativeToPar: relativeToPar,
                    totalStrokes: totalScore,
                  ),
                ],
              ),
              // const SizedBox(height: 12),
              // Divider
              // Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 16),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    icon: '🕊️',
                    value: '$birdies',
                    label: birdies == 1 ? 'Birdie' : 'Birdies',
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.grey[300]?.withValues(alpha: 0.5),
                  ),
                  _StatItem(
                    icon: '🎯',
                    value: '${c1InRegPct.toStringAsFixed(0)}%',
                    label: 'C1 in Reg',
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.grey[300]?.withValues(alpha: 0.5),
                  ),
                  _StatItem(
                    icon: '🥏',
                    value: '${c1xPuttingPct.toStringAsFixed(0)}%',
                    label: 'C1X Putting',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Score badge with gradient background based on performance
class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.scoreText,
    required this.relativeToPar,
    required this.totalStrokes,
  });

  final String scoreText;
  final int relativeToPar;
  final int totalStrokes;

  Color _getGradientColor1(int relativeToPar) {
    if (relativeToPar <= -10) {
      return const Color(0xFF1B5E20); // Dark green for amazing rounds
    } else if (relativeToPar <= -5) {
      return const Color(0xFF2E7D32); // Green for great rounds
    } else if (relativeToPar < 0) {
      return const Color(0xFF43A047); // Light green for good rounds
    } else if (relativeToPar == 0) {
      return const Color(0xFF757575); // Gray for even par
    } else if (relativeToPar <= 3) {
      return const Color(0xFFFF6F00); // Orange for slightly over
    } else {
      return const Color(0xFFC62828); // Red for way over
    }
  }

  Color _getGradientColor2(int relativeToPar) {
    if (relativeToPar <= -10) {
      return const Color(0xFF2E7D32);
    } else if (relativeToPar <= -5) {
      return const Color(0xFF43A047);
    } else if (relativeToPar < 0) {
      return const Color(0xFF66BB6A);
    } else if (relativeToPar == 0) {
      return const Color(0xFF9E9E9E);
    } else if (relativeToPar <= 3) {
      return const Color(0xFFFF8F00);
    } else {
      return const Color(0xFFD32F2F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getGradientColor1(relativeToPar),
            _getGradientColor2(relativeToPar),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getGradientColor1(relativeToPar).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            scoreText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($totalStrokes)',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual stat item with icon, value, and label
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
