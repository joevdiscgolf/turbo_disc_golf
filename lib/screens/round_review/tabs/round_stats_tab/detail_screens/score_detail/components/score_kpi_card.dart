import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:turbo_disc_golf/components/compact_scorecard.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/score_detail/components/score_distribution_bar.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/score_detail/score_detail_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/helpers/score_color_helper.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/score_helpers.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

class ScoreKPICard extends StatelessWidget {
  const ScoreKPICard({
    super.key,
    required this.round,
    required this.isDetailScreen,
    this.onTap,
    this.showMetadata = false,
  });

  final DGRound round;
  final bool isDetailScreen;
  final VoidCallback? onTap;
  final bool showMetadata;

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
            CupertinoPageRoute(
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
        child: Column(
          children: [
            if (showMetadata) ...[
              _buildMetadataWithArrow(),
              Divider(
                height: 8,
                thickness: 1,
                color: SenseiColors.gray.shade100,
              ),
              const SizedBox(height: 12),
            ] else if (!isDetailScreen) ...[
              // Arrow icon in top-right corner when no metadata
              Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.chevron_right, color: Colors.black, size: 20),
              ),
            ],
            _kpiRow(context),
            const SizedBox(height: 12),
            if (!isDetailScreen) ...[
              CompactScorecard(holes: round.holes),
              const SizedBox(height: 16),
            ],
            locator.get<FeatureFlagService>().useHeroAnimationsForRoundReview
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
      ),
    );
  }

  Widget _kpiRow(BuildContext context) {
    final int relativeScore = round.getRelativeToPar();

    return Row(
      children: [
        Expanded(
          child:
              locator.get<FeatureFlagService>().useHeroAnimationsForRoundReview
              ? Hero(
                  tag: 'score_kpi_score',
                  child: Material(
                    color: Colors.transparent,
                    child: _relativeScoreStat(context, relativeScore),
                  ),
                )
              : _relativeScoreStat(context, relativeScore),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              locator.get<FeatureFlagService>().useHeroAnimationsForRoundReview
              ? Hero(
                  tag: 'score_kpi_throws',
                  child: Material(
                    color: Colors.transparent,
                    child: _totalScoreStat(context),
                  ),
                )
              : _totalScoreStat(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              locator.get<FeatureFlagService>().useHeroAnimationsForRoundReview
              ? Hero(
                  tag: 'score_kpi_par',
                  child: Material(
                    color: Colors.transparent,
                    child: _totalParStat(context),
                  ),
                )
              : _totalParStat(context),
        ),
      ],
    );
  }

  Widget _relativeScoreStat(BuildContext context, int relativeScore) {
    return _buildScoreKPIStat(
      context,
      'Score',
      getRelativeScoreString(relativeScore),
      getScoreColor(relativeScore),
    );
  }

  Widget _totalScoreStat(BuildContext context) {
    return _buildScoreKPIStat(
      context,
      'Throws',
      '${round.getTotalScore()}',
      SenseiColors.gray[600]!,
    );
  }

  Widget _totalParStat(BuildContext context) {
    return _buildScoreKPIStat(
      context,
      'Par',
      '${round.getTotalPar()}',
      SenseiColors.gray[600]!,
    );
  }

  Widget _buildScoreKPIStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
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
    );
  }

  Widget _buildMetadataWithArrow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildMetadataContent()),
          if (!isDetailScreen) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.black, size: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataContent() {
    final layout = round.playedLayout;
    final playedDate = DateTime.parse(round.playedRoundAt);
    final formattedDate = DateFormat('MMM d, yyyy').format(playedDate);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          round.courseName,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: SenseiColors.darkGray,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '•',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ),
        Text(
          layout.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Colors.grey[600],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '•',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ),
        Text(
          formattedDate,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
