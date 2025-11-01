import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/components/score_distribution_bar.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

class ScoreKPICard extends StatelessWidget {
  const ScoreKPICard({
    super.key,
    required this.round,
    required this.roundParser,
  });

  final DGRound round;
  final RoundParser roundParser;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          _kpiRow(context),
          const SizedBox(height: 12),
          ScoreDistributionBar(round: round),
        ],
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
                    child: _buildScoreKPIStat(
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
                    child: _buildScoreKPIStat(
                      context,
                      'Throws',
                      '${roundParser.getTotalScore()}',
                      const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildScoreKPIStat(
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
}
