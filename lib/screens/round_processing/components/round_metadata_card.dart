import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/hole_score_colors.dart';
import 'package:turbo_disc_golf/utils/score_helpers.dart';

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
          // Course name and layout
          Row(
            children: [
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: potentialRound.courseName ?? 'Unknown Course',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) - 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (potentialRound.layoutId != null && potentialRound.course != null) ...[
                        TextSpan(
                          text: ' • ',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) - 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: _getLayoutName(potentialRound),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) - 2,
                            color: HoleScoreColors.parColor,
                          ),
                        ),
                      ],
                    ],
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
                  getRelativeScoreString(relativeScore),
                  _getScoreColor(relativeScore),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreKPIStat(
                  context,
                  'Throws',
                  '$totalScore',
                  SenseiColors.darkGray,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreKPIStat(
                  context,
                  'Par',
                  '$totalPar',
                  SenseiColors.darkGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreKPIStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
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

  String _getLayoutName(PotentialDGRound round) {
    if (round.layoutId == null || round.course == null) {
      return 'Unknown Layout';
    }

    final layout = round.course!.getLayoutById(round.layoutId!);
    return layout?.name ?? 'Unknown Layout';
  }

  Color _getScoreColor(int score) {
    if (score < 0) {
      return HoleScoreColors.birdieColor;
    } else if (score > 0) {
      return HoleScoreColors.bogeyColor;
    } else {
      return HoleScoreColors.parColor;
    }
  }
}
