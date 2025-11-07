import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/components/score_distribution_bar.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/score_detail_screen.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/utils/testing_constants.dart';

class ScoreKPICard extends StatelessWidget {
  const ScoreKPICard({
    super.key,
    required this.round,
    required this.roundParser,
    required this.isDetailScreen,
    this.onTap,
  });

  final DGRound round;
  final RoundParser roundParser;
  final bool isDetailScreen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isDetailScreen) {
          return;
        }

        // Use provided onTap callback if available, otherwise use default navigation
        if (onTap != null) {
          onTap!();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScoreDetailScreen(round: round),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
        child: Stack(
          children: [
            Column(
              children: [
                _kpiRow(context),
                const SizedBox(height: 12),
                if (!isDetailScreen) ...[
                  _buildCompactScorecard(),
                  const SizedBox(height: 16),
                ],
                useHeroAnimationsForRoundReview
                    ? Hero(
                        tag: 'score_distribution_bar',
                        child: Material(
                          color: Colors.transparent,
                          child: ScoreDistributionBar(
                            round: round,
                            height: isDetailScreen ? 32 : 24,
                          ),
                        ),
                      )
                    : ScoreDistributionBar(
                        round: round,
                        height: isDetailScreen ? 32 : 24,
                      ),
              ],
            ),
            if (!isDetailScreen) ...[
              // Arrow icon in top-right corner
              Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.chevron_right, color: Colors.black, size: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kpiRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: useHeroAnimationsForRoundReview
                        ? Hero(
                            tag: 'score_kpi_score',
                            child: Material(
                              color: Colors.transparent,
                              child: _buildScoreKPIStat(
                                context,
                                'Score',
                                roundParser.getRelativeToPar() >= 0
                                    ? '+${roundParser.getRelativeToPar()}'
                                    : '${roundParser.getRelativeToPar()}',
                                _getScoreColor(roundParser.getRelativeToPar()),
                              ),
                            ),
                          )
                        : _buildScoreKPIStat(
                            context,
                            'Score',
                            roundParser.getRelativeToPar() >= 0
                                ? '+${roundParser.getRelativeToPar()}'
                                : '${roundParser.getRelativeToPar()}',
                            _getScoreColor(roundParser.getRelativeToPar()),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: useHeroAnimationsForRoundReview
                        ? Hero(
                            tag: 'score_kpi_throws',
                            child: Material(
                              color: Colors.transparent,
                              child: _buildScoreKPIStat(
                                context,
                                'Throws',
                                '${roundParser.getTotalScore()}',
                                const Color(0xFF2196F3),
                              ),
                            ),
                          )
                        : _buildScoreKPIStat(
                            context,
                            'Throws',
                            '${roundParser.getTotalScore()}',
                            const Color(0xFF2196F3),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: useHeroAnimationsForRoundReview
                        ? Hero(
                            tag: 'score_kpi_par',
                            child: Material(
                              color: Colors.transparent,
                              child: _buildScoreKPIStat(
                                context,
                                'Par',
                                '${roundParser.getTotalPar()}',
                                const Color(0xFFFFA726),
                              ),
                            ),
                          )
                        : _buildScoreKPIStat(
                            context,
                            'Par',
                            '${roundParser.getTotalPar()}',
                            const Color(0xFFFFA726),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreKPIStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        // color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        // border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
      return const Color(0xFF137e66);
    } else if (score > 0) {
      return const Color(0xFFFF7A7A);
    } else {
      return const Color(0xFFF5F5F5);
    }
  }

  Widget _buildCompactScorecard() {
    // Split into two rows (first 9, second 9)
    final int halfLength = (round.holes.length / 2).ceil();
    final List<DGHole> firstNine = round.holes.take(halfLength).toList();
    final List<DGHole> secondNine = round.holes.skip(halfLength).toList();

    return Column(
      children: [
        _buildScoreRow(firstNine),
        const SizedBox(height: 12),
        _buildScoreRow(secondNine),
      ],
    );
  }

  Widget _buildScoreRow(List<DGHole> holes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: holes.map((hole) {
        final int score = hole.holeScore;
        final int scoreToPar = hole.relativeHoleScore;
        final Color color = scoreToPar == 0
            ? const Color(0xFFF5F5F5)
            : scoreToPar < 0
            ? const Color(0xFF137e66)
            : const Color(0xFFFF7A7A);
        final bool isPar = scoreToPar == 0;

        return Expanded(
          child: Column(
            children: [
              Text(
                '${hole.number}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              isPar
                  ? Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                      child: Center(
                        child: Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
