import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/throw_analysis_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/disc_analysis_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

class DiscsDetailScreen extends StatelessWidget {
  static const String screenName = 'Discs Detail';

  final DGRound round;

  const DiscsDetailScreen({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    // Track screen impression
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator.get<LoggingService>().track(
        'Screen Impression',
        properties: {'screen_name': DiscsDetailScreen.screenName},
      );
    });

    final DiscAnalysisService discAnalysisService = locator
        .get<DiscAnalysisService>();

    final discBirdieRates = discAnalysisService.getDiscBirdieRates(round);
    final discAverageScores = discAnalysisService.getDiscAverageScores(round);
    final discPerformances = discAnalysisService.getDiscPerformanceSummaries(
      round,
    );
    final discThrowCounts = discAnalysisService.getDiscThrowCounts(round);
    final discC1InRegPercentages = discAnalysisService
        .getDiscC1InRegPercentages(round);

    if (discPerformances.isEmpty) {
      return const Center(child: Text('No disc data available'));
    }

    // Sort all discs by C1 in Reg % (primary), then by throw count (secondary)
    final sortedDiscs =
        discPerformances.map((perf) {
          final c1InRegPct = discC1InRegPercentages[perf.discName] ?? 0.0;
          return MapEntry(perf.discName, c1InRegPct);
        }).toList()..sort((a, b) {
          // First compare by C1 in Reg % (descending)
          final c1InRegComparison = b.value.compareTo(a.value);
          if (c1InRegComparison != 0) return c1InRegComparison;

          // If C1 in Reg % are equal, compare by throw count (descending)
          final aPerf = discPerformances.firstWhere((p) => p.discName == a.key);
          final bPerf = discPerformances.firstWhere((p) => p.discName == b.key);
          return bPerf.totalShots.compareTo(aPerf.totalShots);
        });

    // Split into top 3 and rest
    final topDiscs = sortedDiscs.take(3).toList();
    final otherDiscs = sortedDiscs.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
      children: addRunSpacing(
        [
          // Hero section - Top performing discs
          if (topDiscs.isNotEmpty)
            _buildTopPerformingDiscsSection(
              context,
              topDiscs,
              discBirdieRates,
              discAverageScores,
              discThrowCounts,
              discC1InRegPercentages,
              discPerformances,
            ),

          // Other discs section
          if (otherDiscs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'Other Discs',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...otherDiscs.map((entry) {
              final discName = entry.key;
              final c1InRegPct = entry.value;
              final avgScore = discAverageScores[discName] ?? 0.0;
              final throwCount = discThrowCounts[discName] ?? 0;
              final performance = discPerformances.firstWhere(
                (p) => p.discName == discName,
              );

              return _CompactDiscCard(
                discName: discName,
                c1InRegPct: c1InRegPct,
                avgScore: avgScore,
                throwCount: throwCount,
                performance: performance,
                round: round,
              );
            }),
          ],
        ],
        runSpacing: 12,
        axis: Axis.vertical,
      ),
    );
  }

  Widget _buildTopPerformingDiscsSection(
    BuildContext context,
    List<MapEntry<String, double>> topDiscs,
    Map<String, double> discBirdieRates,
    Map<String, double> discAverageScores,
    Map<String, int> discThrowCounts,
    Map<String, double> discC1InRegPercentages,
    List<dynamic> discPerformances,
  ) {
    final widgets = <Widget>[];

    // Add #1 disc (large featured card)
    if (topDiscs.isNotEmpty) {
      final discName = topDiscs[0].key;
      final c1InRegPct = topDiscs[0].value;
      final birdieRate = discBirdieRates[discName] ?? 0.0;
      final avgScore = discAverageScores[discName] ?? 0.0;
      final throwCount = discThrowCounts[discName] ?? 0;

      widgets.add(
        _TopPerformerCard(
          rank: 1,
          discName: discName,
          c1InRegPct: c1InRegPct,
          birdieRate: birdieRate,
          avgScore: avgScore,
          throwCount: throwCount,
        ),
      );
    }

    // Add #2 disc (compact card)
    if (topDiscs.length > 1) {
      final discName = topDiscs[1].key;
      final c1InRegPct = topDiscs[1].value;
      final avgScore = discAverageScores[discName] ?? 0.0;
      final throwCount = discThrowCounts[discName] ?? 0;

      widgets.add(
        _RunnerUpCard(
          rank: 2,
          discName: discName,
          c1InRegPct: c1InRegPct,
          avgScore: avgScore,
          throwCount: throwCount,
        ),
      );
    }

    // Add #3 disc (compact card)
    if (topDiscs.length > 2) {
      final discName = topDiscs[2].key;
      final c1InRegPct = topDiscs[2].value;
      final avgScore = discAverageScores[discName] ?? 0.0;
      final throwCount = discThrowCounts[discName] ?? 0;

      widgets.add(
        _RunnerUpCard(
          rank: 3,
          discName: discName,
          c1InRegPct: c1InRegPct,
          avgScore: avgScore,
          throwCount: throwCount,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: addRunSpacing(widgets, runSpacing: 12, axis: Axis.vertical),
    );
  }

  // Widget _buildTopPerformingDiscs(
  //   BuildContext context,
  //   List<MapEntry<String, double>> topDiscs,
  // ) {
  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Top Performing Discs',
  //             style: Theme.of(
  //               context,
  //             ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 4),
  //           Text(
  //             'Birdie Rate by Disc',
  //             style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //               color: Theme.of(context).colorScheme.onSurfaceVariant,
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           Wrap(
  //             spacing: 12,
  //             runSpacing: 12,
  //             children: topDiscs.map((entry) {
  //               return _buildTopDiscCard(
  //                 context,
  //                 entry.key,
  //                 entry.value,
  //                 const Color(0xFF137e66),
  //               );
  //             }).toList(),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildWorstPerformingDiscs(
  //   BuildContext context,
  //   List<MapEntry<String, double>> worstDiscs,
  // ) {
  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Worst Performing Discs',
  //             style: Theme.of(
  //               context,
  //             ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 4),
  //           Text(
  //             'Birdie Rate by Disc',
  //             style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //               color: Theme.of(context).colorScheme.onSurfaceVariant,
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           Wrap(
  //             spacing: 12,
  //             runSpacing: 12,
  //             children: worstDiscs.map((entry) {
  //               return _buildTopDiscCard(
  //                 context,
  //                 entry.key,
  //                 entry.value,
  //                 const Color(0xFFFF7A7A),
  //               );
  //             }).toList(),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildTopDiscCard(
  //   BuildContext context,
  //   String discName,
  //   double birdieRate,
  //   Color color,
  // ) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: color.withValues(alpha: 0.1),
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: color.withValues(alpha: 0.3)),
  //     ),
  //     child: Column(
  //       children: [
  //         Text(
  //           '${birdieRate.toStringAsFixed(0)}%',
  //           style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //             fontWeight: FontWeight.bold,
  //             color: color,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           discName,
  //           style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //             color: Theme.of(context).colorScheme.onSurfaceVariant,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

/// Top performer card - Large featured card for #1 disc
class _TopPerformerCard extends StatelessWidget {
  final int rank;
  final String discName;
  final double c1InRegPct;
  final double birdieRate;
  final double avgScore;
  final int throwCount;

  const _TopPerformerCard({
    required this.rank,
    required this.discName,
    required this.c1InRegPct,
    required this.birdieRate,
    required this.avgScore,
    required this.throwCount,
  });

  @override
  Widget build(BuildContext context) {
    final Widget cardContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.2),
            const Color(0xFFDAA520).withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🥇', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      discName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    context,
                    'C1 in Reg',
                    '${c1InRegPct.toStringAsFixed(0)}%',
                    const Color(0xFF137e66),
                  ),
                  _buildStat(
                    context,
                    'Birdie',
                    '${birdieRate.toStringAsFixed(0)}%',
                    const Color(0xFF4CAF50),
                  ),
                  _buildStat(
                    context,
                    'Avg',
                    '${avgScore >= 0 ? '+' : ''}${avgScore.toStringAsFixed(1)}',
                    avgScore < 0
                        ? const Color(0xFF137e66)
                        : const Color(0xFFFF7A7A),
                  ),
                  _buildStat(
                    context,
                    'Throws',
                    '$throwCount',
                    Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return locator.get<FeatureFlagService>().useHeroAnimationsForRoundReview
        ? Hero(
            tag: 'top_disc_$rank',
            child: Material(color: Colors.transparent, child: cardContent),
          )
        : cardContent;
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Runner-up card - Compact card for #2 and #3 discs
class _RunnerUpCard extends StatelessWidget {
  final int rank;
  final String discName;
  final double c1InRegPct;
  final double avgScore;
  final int throwCount;

  const _RunnerUpCard({
    required this.rank,
    required this.discName,
    required this.c1InRegPct,
    required this.avgScore,
    required this.throwCount,
  });

  @override
  Widget build(BuildContext context) {
    final String medal = rank == 2 ? '🥈' : '🥉';
    final Color gradientColor1 = rank == 2
        ? const Color(0xFFC0C0C0)
        : const Color(0xFFCD7F32);
    final Color gradientColor2 = rank == 2
        ? const Color(0xFFE8E8E8)
        : const Color(0xFFFFE4D0);

    // For runner-up cards, we need birdie rate from the parent
    // Since we don't have it, we'll just show 3 stats instead of 4
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColor1.withValues(alpha: 0.18),
            gradientColor2.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gradientColor1.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(medal, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      discName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    context,
                    'C1 in Reg',
                    '${c1InRegPct.toStringAsFixed(0)}%',
                    const Color(0xFF137e66),
                  ),
                  _buildStat(
                    context,
                    'Avg',
                    '${avgScore >= 0 ? '+' : ''}${avgScore.toStringAsFixed(1)}',
                    avgScore < 0
                        ? const Color(0xFF137e66)
                        : const Color(0xFFFF7A7A),
                  ),
                  _buildStat(
                    context,
                    'Throws',
                    '$throwCount',
                    Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Compact disc card for other discs (non-top 3)
class _CompactDiscCard extends StatelessWidget {
  final String discName;
  final double c1InRegPct;
  final double avgScore;
  final int throwCount;
  final dynamic performance;
  final DGRound round;

  const _CompactDiscCard({
    required this.discName,
    required this.c1InRegPct,
    required this.avgScore,
    required this.throwCount,
    required this.performance,
    required this.round,
  });

  /// Get gradient colors based on C1 percentage
  /// Green for high percentages, yellow/orange for medium, red for low
  List<Color> _getGradientColors() {
    if (c1InRegPct >= 60) {
      // Excellent - Green gradient
      return [
        const Color(0xFF137e66).withValues(alpha: 0.20),
        const Color(0xFF4CAF50).withValues(alpha: 0.15),
      ];
    } else if (c1InRegPct >= 40) {
      // Good - Teal/Blue gradient
      return [
        const Color(0xFF2196F3).withValues(alpha: 0.18),
        const Color(0xFF03A9F4).withValues(alpha: 0.12),
      ];
    } else if (c1InRegPct >= 20) {
      // Fair - Yellow/Orange gradient
      return [
        const Color(0xFFFFA726).withValues(alpha: 0.18),
        const Color(0xFFFFB74D).withValues(alpha: 0.12),
      ];
    } else {
      // Poor - Red/Orange gradient
      return [
        const Color(0xFFFF7A7A).withValues(alpha: 0.18),
        const Color(0xFFFFAB91).withValues(alpha: 0.12),
      ];
    }
  }

  /// Get border color based on C1 percentage
  Color _getBorderColor() {
    if (c1InRegPct >= 60) {
      return const Color(0xFF137e66).withValues(alpha: 0.35);
    } else if (c1InRegPct >= 40) {
      return const Color(0xFF2196F3).withValues(alpha: 0.35);
    } else if (c1InRegPct >= 20) {
      return const Color(0xFFFFA726).withValues(alpha: 0.35);
    } else {
      return const Color(0xFFFF7A7A).withValues(alpha: 0.35);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DiscAnalysisService discAnalysisService = locator
        .get<DiscAnalysisService>();
    final throws = discAnalysisService.getThrowsForDisc(discName, round);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(), width: 1),
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (_) => HapticFeedback.lightImpact(),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    discName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF137e66).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${c1InRegPct.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF137e66),
                            ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'C1',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF137e66),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Text(
                    'Avg: ${avgScore >= 0 ? '+' : ''}${avgScore.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: avgScore < 0
                          ? const Color(0xFF137e66)
                          : const Color(0xFFFF7A7A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    throwCount == 1 ? '1 throw' : '$throwCount throws',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Breakdown',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPerformanceStat(
                          context,
                          'Good',
                          '${performance.goodPercentage.toStringAsFixed(0)}%',
                          const Color(0xFF4CAF50),
                        ),
                        _buildPerformanceStat(
                          context,
                          'Okay',
                          '${performance.okayPercentage.toStringAsFixed(0)}%',
                          const Color(0xFFFFA726),
                        ),
                        _buildPerformanceStat(
                          context,
                          'Bad',
                          '${performance.badPercentage.toStringAsFixed(0)}%',
                          const Color(0xFFFF7A7A),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'All Throws (${throws.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...throws.map((throwData) {
                      final int holeNumber = throwData['holeNumber'];
                      final int throwIndex = throwData['throwIndex'];
                      final DiscThrow discThrow =
                          throwData['throw'] as DiscThrow;
                      final analysis = ThrowAnalysisService.analyzeThrow(
                        discThrow,
                      );

                      final List<String> subtitleParts = [];
                      subtitleParts.add('Shot ${throwIndex + 1}');
                      if (discThrow.distanceFeetBeforeThrow != null) {
                        subtitleParts.add(
                          '${discThrow.distanceFeetBeforeThrow} ft',
                        );
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getPerformanceColor(
                              analysis.execCategory,
                            ),
                            child: Text(
                              '$holeNumber',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                'Hole $holeNumber',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildPerformanceBadge(
                                context,
                                analysis.execCategory,
                              ),
                            ],
                          ),
                          subtitle: Text(subtitleParts.join(' • ')),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildPerformanceBadge(BuildContext context, ExecCategory category) {
    String label;
    Color color;

    switch (category) {
      case ExecCategory.good:
        label = 'Good';
        color = const Color(0xFF4CAF50);
        break;
      case ExecCategory.neutral:
        label = 'Okay';
        color = const Color(0xFFFFA726);
        break;
      case ExecCategory.bad:
      case ExecCategory.severe:
        label = 'Bad';
        color = const Color(0xFFFF7A7A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getPerformanceColor(ExecCategory category) {
    switch (category) {
      case ExecCategory.good:
        return const Color(0xFF4CAF50);
      case ExecCategory.neutral:
        return const Color(0xFFFFA726);
      case ExecCategory.bad:
      case ExecCategory.severe:
        return const Color(0xFFFF7A7A);
    }
  }
}
