import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/momentum_tab/components/momentum_overview_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/momentum_tab/components/transition_matrix_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/momentum_tab/components/momentum_metrics_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/momentum_tab/components/conditioning_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/momentum_tab/components/insights_card.dart';

class MomentumTab extends StatelessWidget {
  final DGRound round;

  const MomentumTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    // Calculate momentum stats
    final statsService = RoundStatisticsService(round);
    final momentumStats = statsService.getMomentumStats();

    // Check if we have enough data
    if (momentumStats.mentalProfile == 'Insufficient Data') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Not Enough Data',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Play at least 3 holes to see your mental game analysis.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Overview card
          MomentumOverviewCard(stats: momentumStats),

          const SizedBox(height: 16),

          // Transition matrix
          TransitionMatrixCard(stats: momentumStats),

          const SizedBox(height: 16),

          // Key metrics
          MomentumMetricsCard(stats: momentumStats),

          const SizedBox(height: 16),

          // Conditioning & Focus
          ConditioningCard(stats: momentumStats),

          const SizedBox(height: 16),

          // Insights
          InsightsCard(stats: momentumStats),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
