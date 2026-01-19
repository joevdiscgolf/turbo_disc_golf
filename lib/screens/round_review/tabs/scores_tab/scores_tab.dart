import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/components/hole_score_scatterplot.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/scores_tab/components/insight_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/scores_tab/components/performance_comparison_card.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class ScoresTab extends StatelessWidget {
  static const String tabName = 'Scores';

  const ScoresTab({super.key, required this.round});

  final DGRound round;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator.get<LoggingService>().track('Screen Impression', properties: {
        'screen_name': ScoresTab.tabName,
        'screen_class': 'ScoresTab',
      });
    });

    final statsService = RoundStatisticsService(round);

    return ListView(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 16, bottom: 80),
      children: addRunSpacing(
        [
          _buildInsightCards(context, statsService),
          _buildPerformanceByPar(context, statsService),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HoleScoreScatterplot(round: round),
          ),
          _buildPerformanceByDistance(context, statsService),
          _buildPerformanceByHoleType(context, statsService),
          _buildPerformanceByFairwayWidth(context, statsService),
        ],
        runSpacing: 8,
        axis: Axis.vertical,
      ),
    );
  }

  Widget _buildInsightCards(
    BuildContext context,
    RoundStatisticsService statsService,
  ) {
    final strongestPerf = statsService.getStrongestPerformance();
    final weakestPerf = statsService.getWeakestPerformance();
    final opportunity = statsService.getKeyOpportunity();

    final insights = <Widget>[];

    // Add strength insight
    if (strongestPerf.isNotEmpty) {
      final avgScore = strongestPerf['avgScore'] as double;
      final birdieRate = strongestPerf['birdieRate'] as double;
      final category = strongestPerf['category'] as String;
      final holesPlayed = (strongestPerf['holesPlayed'] as double).toInt();

      insights.add(
        InsightCard(
          title: 'Your Strength',
          description:
              'You excel on $category (${avgScore >= 0 ? '+' : ''}${avgScore.toStringAsFixed(2)} avg, ${birdieRate.toStringAsFixed(0)}% birdies over $holesPlayed holes)',
          icon: Icons.emoji_events,
          type: InsightType.strength,
        ),
      );
    }

    // Add weakness insight
    if (weakestPerf.isNotEmpty) {
      final avgScore = weakestPerf['avgScore'] as double;
      final category = weakestPerf['category'] as String;
      final holesPlayed = (weakestPerf['holesPlayed'] as double).toInt();

      insights.add(
        InsightCard(
          title: 'Improvement Area',
          description:
              '$category are challenging for you (${avgScore >= 0 ? '+' : ''}${avgScore.toStringAsFixed(2)} avg over $holesPlayed holes)',
          icon: Icons.trending_up,
          type: InsightType.weakness,
        ),
      );
    }

    // Add opportunity insight
    if (opportunity.isNotEmpty) {
      final message = opportunity['message'] as String;

      insights.add(
        InsightCard(
          title: 'Key Opportunity',
          description: message,
          icon: Icons.lightbulb_outline,
          type: InsightType.opportunity,
        ),
      );
    }

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(children: insights);
  }

  Widget _buildPerformanceByPar(
    BuildContext context,
    RoundStatisticsService statsService,
  ) {
    final performanceByPar = statsService.getPerformanceByPar();

    if (performanceByPar.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = performanceByPar.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Show all par values, even if only 1 hole of that par exists
    final validEntries = sortedEntries;

    if (validEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find best and worst performing par
    double bestScore = double.infinity;
    int? bestPar;
    double worstScore = double.negativeInfinity;
    int? worstPar;

    for (final entry in validEntries) {
      final avgScore = entry.value['avgScore'] ?? 0.0;
      if (avgScore < bestScore) {
        bestScore = avgScore;
        bestPar = entry.key;
      }
      if (avgScore > worstScore) {
        worstScore = avgScore;
        worstPar = entry.key;
      }
    }

    final items = validEntries.map((entry) {
      final par = entry.key;
      final stats = entry.value;
      final avgScore = stats['avgScore'] ?? 0.0;
      final birdieRate = stats['birdieRate'] ?? 0.0;
      final parRate = stats['parRate'] ?? 0.0;
      final bogeyRate = stats['bogeyRate'] ?? 0.0;
      final doubleBogeyPlusRate = stats['doubleBogeyPlusRate'] ?? 0.0;
      final holesPlayed = (stats['holesPlayed'] ?? 0.0).toInt();

      String? badge;
      if (validEntries.length > 1) {
        if (par == bestPar) {
          badge = 'Best';
        } else if (par == worstPar) {
          badge = 'Worst';
        }
      }

      return PerformanceComparisonItem(
        label: 'Par $par',
        score: avgScore,
        valueLabel: '${avgScore >= 0 ? '+' : ''}${avgScore.toStringAsFixed(2)}',
        birdieRate: birdieRate,
        parRate: parRate,
        bogeyRate: bogeyRate,
        doubleBogeyPlusRate: doubleBogeyPlusRate,
        subLabel: '$holesPlayed holes played',
        badge: badge,
      );
    }).toList();

    return PerformanceComparisonCard(title: 'Scores by par', items: items);
  }

  Widget _buildPerformanceByHoleType(
    BuildContext context,
    RoundStatisticsService statsService,
  ) {
    final performanceByHoleType = statsService.getPerformanceByHoleType();

    if (performanceByHoleType.isEmpty) {
      return const SizedBox.shrink();
    }

    final validEntries = performanceByHoleType.entries
        .where((entry) => (entry.value['holesPlayed']?.toInt() ?? 0) >= 3)
        .toList();

    if (validEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find best and worst performing type
    double bestScore = double.infinity;
    String? bestType;
    double worstScore = double.negativeInfinity;
    String? worstType;

    for (final entry in validEntries) {
      final avgScore = entry.value['avgScore'] ?? 0.0;
      if (avgScore < bestScore) {
        bestScore = avgScore;
        bestType = entry.key;
      }
      if (avgScore > worstScore) {
        worstScore = avgScore;
        worstType = entry.key;
      }
    }

    final items = validEntries.map((entry) {
      final holeType = entry.key;
      final stats = entry.value;
      final avgScore = stats['avgScore'] ?? 0.0;
      final birdieRate = stats['birdieRate'] ?? 0.0;
      final parRate = stats['parRate'] ?? 0.0;
      final bogeyRate = stats['bogeyRate'] ?? 0.0;
      final doubleBogeyPlusRate = stats['doubleBogeyPlusRate'] ?? 0.0;
      final holesPlayed = (stats['holesPlayed'] ?? 0.0).toInt();

      String? badge;
      if (validEntries.length > 1) {
        if (holeType == bestType) {
          badge = 'Best';
        } else if (holeType == worstType) {
          badge = 'Worst';
        }
      }

      return PerformanceComparisonItem(
        label: _formatHoleTypeName(holeType),
        score: avgScore,
        valueLabel: '${avgScore >= 0 ? '+' : ''}${avgScore.toStringAsFixed(2)}',
        birdieRate: birdieRate,
        parRate: parRate,
        bogeyRate: bogeyRate,
        doubleBogeyPlusRate: doubleBogeyPlusRate,
        subLabel: '$holesPlayed holes played',
        badge: badge,
      );
    }).toList();

    return PerformanceComparisonCard(
      title: 'Performance by Hole Type',

      items: items,
    );
  }

  Widget _buildPerformanceByDistance(
    BuildContext context,
    RoundStatisticsService statsService,
  ) {
    final performanceByDistance = statsService.getPerformanceByDistance();

    if (performanceByDistance.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter out categories with less than 3 holes
    final validEntries = performanceByDistance.entries
        .where((entry) => (entry.value['holesPlayed']?.toInt() ?? 0) >= 3)
        .toList();

    if (validEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find best and worst performing distance
    double bestScore = double.infinity;
    String? bestDistance;
    double worstScore = double.negativeInfinity;
    String? worstDistance;

    for (final entry in validEntries) {
      final avgScore = entry.value['avgScore'] ?? 0.0;
      if (avgScore < bestScore) {
        bestScore = avgScore;
        bestDistance = entry.key;
      }
      if (avgScore > worstScore) {
        worstScore = avgScore;
        worstDistance = entry.key;
      }
    }

    // Order by distance (short to long)
    final orderedKeys = ['<250 ft', '250-400 ft', '400-550 ft', '550+ ft'];

    final orderedEntries = orderedKeys
        .where((key) => validEntries.any((e) => e.key == key))
        .map((key) => validEntries.firstWhere((e) => e.key == key))
        .toList();

    final items = orderedEntries.map((entry) {
      final distance = entry.key;
      final stats = entry.value;
      final avgScore = stats['avgScore'] ?? 0.0;
      final birdieRate = stats['birdieRate'] ?? 0.0;
      final parRate = stats['parRate'] ?? 0.0;
      final bogeyRate = stats['bogeyRate'] ?? 0.0;
      final doubleBogeyPlusRate = stats['doubleBogeyPlusRate'] ?? 0.0;
      final holesPlayed = (stats['holesPlayed'] ?? 0.0).toInt();

      String? badge;
      if (validEntries.length > 1) {
        if (distance == bestDistance) {
          badge = 'Best';
        } else if (distance == worstDistance) {
          badge = 'Worst';
        }
      }

      return PerformanceComparisonItem(
        label: distance,
        score: avgScore,
        valueLabel: '${avgScore >= 0 ? '+' : ''}${avgScore.toStringAsFixed(2)}',
        birdieRate: birdieRate,
        parRate: parRate,
        bogeyRate: bogeyRate,
        doubleBogeyPlusRate: doubleBogeyPlusRate,
        subLabel: '$holesPlayed holes played',
        badge: badge,
      );
    }).toList();

    return PerformanceComparisonCard(title: 'Scores by distance', items: items);
  }

  Widget _buildPerformanceByFairwayWidth(
    BuildContext context,
    RoundStatisticsService statsService,
  ) {
    final performanceByFairwayWidth = statsService
        .getPerformanceByFairwayWidth();

    if (performanceByFairwayWidth.isEmpty) {
      return _buildEmptyFairwayWidthState(context);
    }

    // Filter out categories with less than 3 holes
    final validEntries = performanceByFairwayWidth.entries
        .where((entry) => (entry.value['holesPlayed']?.toInt() ?? 0) >= 3)
        .toList();

    if (validEntries.isEmpty) {
      return _buildEmptyFairwayWidthState(context);
    }

    // Find best and worst performing width
    double bestScore = double.infinity;
    String? bestWidth;
    double worstScore = double.negativeInfinity;
    String? worstWidth;

    for (final entry in validEntries) {
      final avgScore = entry.value['avgScore'] ?? 0.0;
      if (avgScore < bestScore) {
        bestScore = avgScore;
        bestWidth = entry.key;
      }
      if (avgScore > worstScore) {
        worstScore = avgScore;
        worstWidth = entry.key;
      }
    }

    final items = validEntries.map((entry) {
      final width = entry.key;
      final stats = entry.value;
      final avgScore = stats['avgScore'] ?? 0.0;
      final birdieRate = stats['birdieRate'] ?? 0.0;
      final parRate = stats['parRate'] ?? 0.0;
      final bogeyRate = stats['bogeyRate'] ?? 0.0;
      final doubleBogeyPlusRate = stats['doubleBogeyPlusRate'] ?? 0.0;
      final holesPlayed = (stats['holesPlayed'] ?? 0.0).toInt();

      String? badge;
      if (validEntries.length > 1) {
        if (width == bestWidth) {
          badge = 'Best';
        } else if (width == worstWidth) {
          badge = 'Worst';
        }
      }

      return PerformanceComparisonItem(
        label: _formatFairwayWidthName(width),
        score: avgScore,
        valueLabel: '${avgScore >= 0 ? '+' : ''}${avgScore.toStringAsFixed(2)}',
        birdieRate: birdieRate,
        parRate: parRate,
        bogeyRate: bogeyRate,
        doubleBogeyPlusRate: doubleBogeyPlusRate,
        subLabel: '$holesPlayed holes played',
        badge: badge,
      );
    }).toList();

    return PerformanceComparisonCard(
      title: 'Performance by Fairway Width',
      items: items,
    );
  }

  Widget _buildEmptyFairwayWidthState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance by Fairway Width',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Fairway width data is not available for this round. Track fairway width information during your rounds to see performance breakdowns by fairway openness.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHoleTypeName(String holeType) {
    switch (holeType.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'slightlywooded':
        return 'Lightly Wooded';
      case 'wooded':
        return 'Wooded';
      default:
        return holeType;
    }
  }

  String _formatFairwayWidthName(String fairwayWidth) {
    switch (fairwayWidth.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'moderate':
        return 'Moderate';
      case 'tight':
        return 'Tight';
      case 'verytight':
        return 'Very Tight';
      default:
        return fairwayWidth;
    }
  }
}
