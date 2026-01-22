import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/psych_detail/components/mood_row.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

/// Mood Rings design - A dynamic, emotionally expressive visualization of mental state
class PsychOverviewCard extends StatelessWidget {
  final PsychStats stats;

  const PsychOverviewCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final bool useRedesign = locator
        .get<FeatureFlagService>()
        .useRedesignedMentalGameCard;

    if (useRedesign) {
      return _buildRedesignedCard(context);
    } else {
      return _buildOriginalCard(context);
    }
  }

  Widget _buildOriginalCard(BuildContext context) {
    // Get key transition stats - find best and worst scores that occurred
    final bestScoreKey = _findBestScore(stats.transitionMatrix);
    final worstScoreKey = _findWorstScore(stats.transitionMatrix);

    final ScoringTransition? bestTransition = bestScoreKey != null
        ? stats.transitionMatrix[bestScoreKey]
        : null;
    final ScoringTransition? worstTransition = worstScoreKey != null
        ? stats.transitionMatrix[worstScoreKey]
        : null;

    final double hotStreakEnergy = bestTransition?.toBirdiePercent ?? 0.0;
    final double coldStreakControl =
        worstTransition?.bogeyOrWorsePercent ?? 0.0;
    final double bounceBackDrive = stats.bounceBackRate;

    // Calculate dynamic mindset state
    final MindsetState mindsetState = _calculateMindsetState(
      hotStreakEnergy,
      coldStreakControl,
      bounceBackDrive,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, mindsetState),

          const SizedBox(height: 20),

          // Three mood rows
          MoodRow(
            emoji: '🔥',
            label: 'HOT STREAK ENERGY',
            subtitle: 'Birdie after birdie rate',
            percentage: hotStreakEnergy,
            insight: _getHotStreakInsight(hotStreakEnergy),
            gradientColors: const [Color(0xFFFF7043), Color(0xFFFFB74D)],
            backgroundColor: const Color(0xFFFF6B35),
          ),

          MoodRow(
            emoji: '😡',
            label: 'TILT METER',
            subtitle: 'Bogey after bogey rate',
            percentage: coldStreakControl,
            insight: _getTiltMeterInsight(coldStreakControl),
            gradientColors: const [Color(0xFFEF5350), Color(0xFFFF8A80)],
            backgroundColor: const Color(0xFFD32F2F),
          ),

          MoodRow(
            emoji: '💪',
            label: 'BOUNCE-BACK',
            subtitle: 'Birdie after bogey rate',
            percentage: bounceBackDrive,
            insight: _getBounceBackInsight(bounceBackDrive),
            gradientColors: const [Color(0xFF81C784), Color(0xFFC8E6C9)],
            backgroundColor: const Color(0xFF4CAF50),
          ),

          const SizedBox(height: 16),

          // Summary line
          _buildSummaryLine(context, mindsetState),
        ],
      ),
    );
  }

  Widget _buildRedesignedCard(BuildContext context) {
    // Get key transition stats - find best and worst scores that occurred
    final bestScoreKey = _findBestScore(stats.transitionMatrix);
    final worstScoreKey = _findWorstScore(stats.transitionMatrix);

    final ScoringTransition? bestTransition = bestScoreKey != null
        ? stats.transitionMatrix[bestScoreKey]
        : null;
    final ScoringTransition? worstTransition = worstScoreKey != null
        ? stats.transitionMatrix[worstScoreKey]
        : null;

    final double hotStreakEnergy = bestTransition?.toBirdiePercent ?? 0.0;
    final double coldStreakControl =
        worstTransition?.bogeyOrWorsePercent ?? 0.0;
    final double bounceBackDrive = stats.bounceBackRate;

    // Calculate dynamic mindset state
    final MindsetState mindsetState = _calculateMindsetState(
      hotStreakEnergy,
      coldStreakControl,
      bounceBackDrive,
    );

    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '🧠 Mental profile',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // Three minimal mood rows
          _buildMinimalMoodRow(
            context: context,
            emoji: '🔥',
            label: 'Hot Streak',
            subtitle: 'Birdie after birdie rate',
            percentage: hotStreakEnergy,
            color: const Color(0xFFFF8A65),
          ),
          _buildMinimalMoodRow(
            context: context,
            emoji: '😡',
            label: 'Tilt Meter',
            subtitle: 'Bogey after bogey rate',
            percentage: coldStreakControl,
            color: const Color(0xFFEF5350),
          ),
          _buildMinimalMoodRow(
            context: context,
            emoji: '💪',
            label: 'Bounce-Back',
            subtitle: 'Birdie after bogey rate',
            percentage: bounceBackDrive,
            color: const Color(0xFF66BB6A),
          ),

          const SizedBox(height: 12),

          // Summary line
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              mindsetState.summaryText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w300,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalMoodRow({
    required BuildContext context,
    required String emoji,
    required String label,
    required String subtitle,
    required double percentage,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage / 100,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MindsetState mindsetState) {
    return Text(
      '🧠 Mental profile',
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSummaryLine(BuildContext context, MindsetState mindsetState) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Text(
        mindsetState.summaryText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w300,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Calculate dynamic mindset state based on thresholds
  MindsetState _calculateMindsetState(double hot, double cold, double bounce) {
    // Hot Mindset: High hot streak, low cold streak
    if (hot > 75 && cold < 30) {
      return MindsetState(
        type: MindsetType.hot,
        label: 'HOT MINDSET',
        emoji: '🔥',
        primaryColor: const Color(0xFFFF6B35),
        summaryText: 'Hot Momentum • Strong Recovery • On Fire',
      );
    }

    // On Tilt: High cold streak
    if (cold > 40) {
      return MindsetState(
        type: MindsetType.cold,
        label: 'ON TILT',
        emoji: '⚠️',
        primaryColor: const Color(0xFF2196F3),
        summaryText: 'Work on Resets • Stay Calm • Breathe',
      );
    }

    // Resilient Focus: High bounce-back
    if (bounce > 50) {
      return MindsetState(
        type: MindsetType.resilient,
        label: 'RESILIENT FOCUS',
        emoji: '💪',
        primaryColor: const Color(0xFF4CAF50),
        summaryText: 'Strong Recovery • Mental Toughness • Keep It Up',
      );
    }

    // Even Keel: Balanced stats
    return MindsetState(
      type: MindsetType.balanced,
      label: 'EVEN KEEL',
      emoji: '🧘',
      primaryColor: const Color(0xFF26A69A),
      summaryText: 'Balanced Focus • Calm Resets • Confidence Rising',
    );
  }

  String _getHotStreakInsight(double percentage) {
    if (percentage > 75) {
      return 'You thrive on momentum. Keep it rolling!';
    } else if (percentage > 50) {
      return 'Good momentum player. Use your hot streaks!';
    } else if (percentage > 25) {
      return 'Moderate momentum. Focus on consistency.';
    } else {
      return 'Build momentum by stringing birdies together.';
    }
  }

  String _getTiltMeterInsight(double percentage) {
    if (percentage == 0) {
      return 'No tilt detected. Ice in your veins 🧊';
    } else if (percentage < 20) {
      return 'Excellent composure. You don\'t compound mistakes!';
    } else if (percentage < 40) {
      return 'Moderate tilt. Focus on resetting after bad holes.';
    } else {
      return 'High tilt risk. Take a breath after mistakes.';
    }
  }

  String _getBounceBackInsight(double percentage) {
    if (percentage > 60) {
      return 'You\'re learning to rebound faster each round!';
    } else if (percentage > 40) {
      return 'Solid recovery ability. Keep building on it.';
    } else if (percentage > 20) {
      return 'Room to grow. Focus on quick mental resets.';
    } else {
      return 'Practice bouncing back from adversity.';
    }
  }

  /// Find the best (lowest) score category in the transition matrix
  String? _findBestScore(Map<String, ScoringTransition> transitionMatrix) {
    const scoreOrder = [
      'Condor',
      'Albatross',
      'Eagle',
      'Birdie',
      'Par',
      'Bogey',
      'Double Bogey',
      'Triple Bogey+',
    ];

    for (var score in scoreOrder) {
      if (transitionMatrix.containsKey(score)) {
        return score;
      }
    }
    return null;
  }

  /// Find the worst (highest) score category in the transition matrix
  String? _findWorstScore(Map<String, ScoringTransition> transitionMatrix) {
    const scoreOrder = [
      'Triple Bogey+',
      'Double Bogey',
      'Bogey',
      'Par',
      'Birdie',
      'Eagle',
      'Albatross',
      'Condor',
    ];

    for (var score in scoreOrder) {
      if (transitionMatrix.containsKey(score)) {
        return score;
      }
    }
    return null;
  }
}

// Data class for mindset state
class MindsetState {
  final MindsetType type;
  final String label;
  final String emoji;
  final Color primaryColor;
  final String summaryText;

  MindsetState({
    required this.type,
    required this.label,
    required this.emoji,
    required this.primaryColor,
    required this.summaryText,
  });
}

enum MindsetType { hot, cold, resilient, balanced }
