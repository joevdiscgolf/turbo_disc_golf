import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/components/score_distribution_bar.dart';

/// Card displaying round metadata with KPI stats.
/// Design matches ScoreKPICard with isDetailScreen: false (without scorecard).
class RoundMetadataCard extends StatelessWidget {
  const RoundMetadataCard({
    super.key,
    required this.potentialRound,
    required this.totalScore,
    required this.totalPar,
    required this.relativeScore,
  });

  final PotentialDGRound potentialRound;
  final int totalScore;
  final int totalPar;
  final int relativeScore;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course name
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  potentialRound.courseName ?? 'Unknown Course',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // KPI Row (matching ScoreKPICard design)
          Row(
            children: [
              Expanded(
                child: _buildScoreKPIStat(
                  context,
                  'Score',
                  relativeScore >= 0 ? '+$relativeScore' : '$relativeScore',
                  _getScoreColor(relativeScore),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreKPIStat(
                  context,
                  'Throws',
                  '$totalScore',
                  const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreKPIStat(
                  context,
                  'Par',
                  '$totalPar',
                  const Color(0xFFFFA726),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Score distribution bar (if we have a valid round)
          if (potentialRound.holes != null &&
              potentialRound.holes!.isNotEmpty &&
              _hasCompleteHoles())
            ScoreDistributionBar(
              round: potentialRound.toDGRound(),
              height: 24,
            ),
        ],
      ),
    );
  }

  bool _hasCompleteHoles() {
    // Check if we have at least some complete holes to show distribution
    return potentialRound.holes!.any((h) =>
        h.hasRequiredFields &&
        h.throws != null &&
        h.throws!.isNotEmpty);
  }

  Widget _buildScoreKPIStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
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
