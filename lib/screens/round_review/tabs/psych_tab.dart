import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/psych_tab/components/conditioning_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/psych_tab/components/flow_state_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/psych_tab/components/insights_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/psych_tab/components/psych_metrics_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/psych_tab/components/psych_overview_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/psych_tab/components/transition_matrix_card.dart';
import 'package:turbo_disc_golf/services/round_analysis/psych_analysis_service.dart';

class PsychTab extends StatelessWidget {
  final DGRound round;

  const PsychTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    // Calculate momentum stats
    final psychStats = locator.get<PsychAnalysisService>().getPsychStats(round);

    // Check if we have enough data
    if (psychStats.mentalProfile == 'Insufficient Data') {
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
          PsychOverviewCard(stats: psychStats),

          const SizedBox(height: 16),

          // Flow State card (if available)
          if (psychStats.flowStateAnalysis != null)
            FlowStateCard(
              flowAnalysis: psychStats.flowStateAnalysis!,
              totalHoles: round.holes.length,
            ),

          if (psychStats.flowStateAnalysis != null) const SizedBox(height: 16),

          // Transition matrix
          TransitionMatrixCard(stats: psychStats),

          const SizedBox(height: 16),

          // Key metrics
          PsychMetricsCard(stats: psychStats),

          const SizedBox(height: 16),

          // Conditioning & Focus
          ConditioningCard(stats: psychStats, round: round),

          const SizedBox(height: 16),

          // Insights
          InsightsCard(stats: psychStats),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
