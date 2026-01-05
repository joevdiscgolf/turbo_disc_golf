import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/stat_cards/driving_stats_card.dart'
    as compact;
import 'package:turbo_disc_golf/components/stat_cards/putting_stats_card.dart'
    as compact;
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/components/score_kpi_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/score_detail_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/discs_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/drives_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/mistakes_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/psych_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/putting_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/roast_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/skills_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/summary_tab.dart';
import 'package:turbo_disc_golf/services/animation_state_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/psych_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/skills_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/constants/putting_constants.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/widgets/circular_stat_indicator.dart';

class RoundOverviewBody extends StatefulWidget {
  final DGRound round;
  final TabController? tabController;
  final bool isReviewV2Screen;

  const RoundOverviewBody({
    super.key,
    required this.round,
    this.tabController,
    this.isReviewV2Screen = false,
  });

  @override
  State<RoundOverviewBody> createState() => _RoundOverviewBodyState();
}

class _RoundOverviewBodyState extends State<RoundOverviewBody>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _navigateToDetailView(int tabIndex) {
    if (widget.isReviewV2Screen) {
      // V2: Push new screen based on tab index
      _pushDetailScreen(tabIndex);
    } else if (widget.tabController != null) {
      // V1: Navigate to tab
      widget.tabController!.animateTo(tabIndex);
    }
  }

  void _navigateToJudgeTab() {
    if (widget.tabController != null) {
      widget.tabController!.animateTo(2); // Navigate to Judge tab (index 2)
    }
  }

  void _pushDetailScreen(int tabIndex) {
    // Import detail screens at the top of the file
    // Tab indices from RoundReviewScreen:
    // 0: Overview, 1: Skills, 2: Course, 3: Scores, 4: Drives, 5: Putting,
    // 6: Discs, 7: Mistakes, 8: Psych, 9: Summary, 10: Coach, 11: Roast

    Widget? detailScreen;
    String title = '';

    switch (tabIndex) {
      case 1: // Skills
        detailScreen = SkillsTab(round: widget.round);
        title = 'Skills';
        break;
      case 4: // Drives
        detailScreen = DrivesTab(round: widget.round);
        title = 'Driving';
        break;
      case 5: // Putting
        detailScreen = PuttingTab(round: widget.round);
        title = 'Putting';
        break;
      case 6: // Discs
        detailScreen = DiscsTab(round: widget.round);
        title = 'Top Discs';
        break;
      case 7: // Mistakes
        detailScreen = MistakesTab(round: widget.round);
        title = 'Mistakes';
        break;
      case 8: // Psych
        detailScreen = PsychTab(round: widget.round);
        title = 'Mental Game';
        break;
      case 9: // Summary
        detailScreen = AiSummaryTab(round: widget.round);
        title = 'AI Insights';
        break;
      case 11: // Roast
        detailScreen = RoastTab(round: widget.round);
        title = 'AI Roast';
        break;
    }

    if (detailScreen != null && mounted) {
      final Widget screen = detailScreen;
      if (useCustomPageTransitionsForRoundReview) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                _DetailScreenWrapper(title: title, child: screen),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Fade + scale animation for card expansion effect
                  const begin = 0.92;
                  const end = 1.0;
                  const curve = Curves.easeInOut;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  final scaleAnimation = animation.drive(tween);

                  final fadeAnimation = animation.drive(
                    CurveTween(curve: curve),
                  );

                  return FadeTransition(
                    opacity: fadeAnimation,
                    child: ScaleTransition(scale: scaleAnimation, child: child),
                  );
                },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      } else {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) =>
                _DetailScreenWrapper(title: title, child: screen),
          ),
        );
      }
    }
  }

  void _navigateToScoreDetail() {
    if (!widget.isReviewV2Screen) {
      // V1: Navigate to Course tab (index 2)
      if (widget.tabController != null) {
        widget.tabController!.animateTo(2);
      }
      return;
    }

    // V2: Push ScoreDetailScreen with custom animation
    if (!mounted) return;

    final Widget screen = ScoreDetailScreen(round: widget.round);

    if (useCustomPageTransitionsForRoundReview) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade + scale animation for card expansion effect
            const begin = 0.92;
            const end = 1.0;
            const curve = Curves.easeInOut;

            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            final scaleAnimation = animation.drive(tween);

            final fadeAnimation = animation.drive(CurveTween(curve: curve));

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(scale: scaleAnimation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (context) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Determine if we should show banner
    final bool shouldShowBanner = widget.round.aiJudgment == null;

    // Check if this is first time seeing banner (for animation)
    final bool isFirstView = !AnimationStateService.instance.hasAnimated(
      widget.round.id,
      'judge_banner',
    );

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      children: [
        if (shouldShowBanner)
          _JudgeBanner(onTap: _navigateToJudgeTab, shouldAnimate: isFirstView),
        ScoreKPICard(
          round: widget.round,
          isDetailScreen: false,
          onTap: widget.isReviewV2Screen ? _navigateToScoreDetail : null,
        ),
        const SizedBox(height: 8),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16),
        //   child: SkillsOverviewCard(
        //     round: widget.round,
        //     onTap: () => _navigateToDetailView(1), // Skills tab
        //   ),
        // ),
        // const SizedBox(height: 8),
        // Scorecard now included in ScoreKPICard above
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16),
        //   child: _ScorecardCard(
        //     round: widget.round,
        //     onTap: () => _navigateToTab(2), // Course tab (moved down)
        //   ),
        // ),
        // const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: compact.DrivingStatsCard(
                  round: widget.round,
                  onTap: () => _navigateToDetailView(4), // Drives tab
                ),
              ),
              Expanded(
                child: compact.PuttingStatsCard(
                  round: widget.round,
                  onTap: () => _navigateToDetailView(5), // Putting tab
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _MistakesCard(
            round: widget.round,
            onTap: () => _navigateToDetailView(7), // Mistakes tab
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _MentalGameCard(
            round: widget.round,
            onTap: () => _navigateToDetailView(8), // Psych tab
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _DiscUsageCard(
            round: widget.round,
            onTap: () => _navigateToDetailView(6), // Discs tab
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _AICoachCard(
            round: widget.round,
            onTap: () => _navigateToDetailView(9), // Summary tab
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _AIRoastCard(
            round: widget.round,
            onTap: () => _navigateToDetailView(11), // Roast tab
          ),
        ),
      ],
    );
  }
}

// Driving Stats Card
class DrivingStatsCard extends StatefulWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const DrivingStatsCard({super.key, required this.round, this.onTap});

  @override
  State<DrivingStatsCard> createState() => _DrivingStatsCardState();
}

class _DrivingStatsCardState extends State<DrivingStatsCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic> _calculateDrivingStats() {
    final RoundStatisticsService statsService = RoundStatisticsService(
      widget.round,
    );
    final dynamic coreStats = statsService.getCoreStats();
    final Map<String, Map<String, double>> circleInRegByType = statsService
        .getCircleInRegByThrowType();

    // Get C1 in reg % by throw type
    final List<Map<String, dynamic>> throwTypeStats = [];
    circleInRegByType.forEach((String throwType, Map<String, double> stats) {
      final double c1Percentage = stats['c1Percentage'] ?? 0;
      final int totalAttempts = (stats['totalAttempts'] ?? 0).toInt();
      if (totalAttempts > 0) {
        throwTypeStats.add({
          'type': throwType,
          'c1Pct': c1Percentage,
          'attempts': totalAttempts,
        });
      }
    });

    // Sort by C1 percentage descending
    throwTypeStats.sort(
      (a, b) => (b['c1Pct'] as double).compareTo(a['c1Pct'] as double),
    );

    return {
      'fairwayPct': coreStats.fairwayHitPct,
      'c1InRegPct': coreStats.c1InRegPct,
      'obPct': coreStats.obPct,
      'parkedPct': coreStats.parkedPct,
      'hasData': widget.round.holes.isNotEmpty,
      'throwTypeStats': throwTypeStats,
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final Map<String, dynamic> stats = _calculateDrivingStats();
    final bool hasData = stats['hasData'] as bool;

    return Card(
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🎯 Driving',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      useHeroAnimationsForRoundReview
                          ? Hero(
                              tag: 'driving_c1_in_reg',
                              child: CircularStatIndicator(
                                key: ValueKey(
                                  'driving_c1_in_reg_${widget.round.id}',
                                ),
                                label: 'C1 in Reg',
                                percentage: hasData
                                    ? stats['c1InRegPct'] as double
                                    : 0.0,
                                color: const Color(0xFF137e66),
                                size: 70,
                                shouldAnimate: true,
                                shouldGlow: true,
                                roundId: widget.round.id,
                              ),
                            )
                          : CircularStatIndicator(
                              key: ValueKey(
                                'driving_c1_in_reg_${widget.round.id}',
                              ),
                              label: 'C1 in Reg',
                              percentage: hasData
                                  ? stats['c1InRegPct'] as double
                                  : 0.0,
                              color: const Color(0xFF137e66),
                              size: 70,
                              shouldAnimate: true,
                              shouldGlow: true,
                              roundId: widget.round.id,
                            ),
                      useHeroAnimationsForRoundReview
                          ? Hero(
                              tag: 'driving_fairway',
                              child: CircularStatIndicator(
                                key: ValueKey(
                                  'driving_fairway_${widget.round.id}',
                                ),
                                label: 'Fairway',
                                percentage: hasData
                                    ? stats['fairwayPct'] as double
                                    : 0.0,
                                color: const Color(0xFF4CAF50),
                                size: 70,
                                shouldAnimate: true,
                                shouldGlow: true,
                                roundId: widget.round.id,
                              ),
                            )
                          : CircularStatIndicator(
                              key: ValueKey(
                                'driving_fairway_${widget.round.id}',
                              ),
                              label: 'Fairway',
                              percentage: hasData
                                  ? stats['fairwayPct'] as double
                                  : 0.0,
                              color: const Color(0xFF4CAF50),
                              size: 70,
                              shouldAnimate: true,
                              shouldGlow: true,
                              roundId: widget.round.id,
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      useHeroAnimationsForRoundReview
                          ? Hero(
                              tag: 'driving_ob',
                              child: CircularStatIndicator(
                                key: ValueKey('driving_ob_${widget.round.id}'),
                                label: 'OB',
                                percentage: hasData
                                    ? stats['obPct'] as double
                                    : 0.0,
                                color: const Color(0xFFFF7A7A),
                                size: 70,
                                shouldAnimate: true,
                                shouldGlow: true,
                                roundId: widget.round.id,
                              ),
                            )
                          : CircularStatIndicator(
                              key: ValueKey('driving_ob_${widget.round.id}'),
                              label: 'OB',
                              percentage: hasData
                                  ? stats['obPct'] as double
                                  : 0.0,
                              color: const Color(0xFFFF7A7A),
                              size: 70,
                              shouldAnimate: true,
                              shouldGlow: true,
                              roundId: widget.round.id,
                            ),
                      useHeroAnimationsForRoundReview
                          ? Hero(
                              tag: 'driving_parked',
                              child: CircularStatIndicator(
                                key: ValueKey(
                                  'driving_parked_${widget.round.id}',
                                ),
                                label: 'Parked',
                                percentage: hasData
                                    ? stats['parkedPct'] as double
                                    : 0.0,
                                color: const Color(0xFFFFA726),
                                size: 70,
                                shouldAnimate: true,
                                shouldGlow: true,
                                roundId: widget.round.id,
                              ),
                            )
                          : CircularStatIndicator(
                              key: ValueKey(
                                'driving_parked_${widget.round.id}',
                              ),
                              label: 'Parked',
                              percentage: hasData
                                  ? stats['parkedPct'] as double
                                  : 0.0,
                              color: const Color(0xFFFFA726),
                              size: 70,
                              shouldAnimate: true,
                              shouldGlow: true,
                              roundId: widget.round.id,
                            ),
                    ],
                  ),
                ],
              ),
              // C1 in Reg by Throw Type section hidden for cleaner overview
              // if (throwTypeStats.isNotEmpty) ...[
              //   const SizedBox(height: 16),
              //   const Divider(),
              //   const SizedBox(height: 8),
              //   Text(
              //     'C1 in Reg by Throw Type',
              //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
              //           fontWeight: FontWeight.w600,
              //           color: Colors.grey[700],
              //         ),
              //   ),
              //   const SizedBox(height: 8),
              //   Wrap(
              //     spacing: 8,
              //     runSpacing: 8,
              //     children: throwTypeStats.map((typeStats) {
              //       return _buildThrowTypeChip(
              //         context,
              //         typeStats['type'] as String,
              //         typeStats['c1Pct'] as double,
              //         typeStats['attempts'] as int,
              //       );
              //     }).toList(),
              //   ),
              // ],
            ],
          ),
        ),
      ),
    );
  }
}

// Putting Stats Card
class PuttingStatsCard extends StatefulWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const PuttingStatsCard({super.key, required this.round, this.onTap});

  @override
  State<PuttingStatsCard> createState() => _PuttingStatsCardState();
}

class _PuttingStatsCardState extends State<PuttingStatsCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic> _calculatePuttingStats() {
    int c1Attempts = 0;
    int c1Makes = 0;
    int c1xAttempts = 0;
    int c1xMakes = 0;
    int c2Attempts = 0;
    int c2Makes = 0;
    int totalPutts = 0;
    int totalMakes = 0;
    int scrambles = 0;
    int scrambleAttempts = 0;
    final List<bool> allPutts = [];

    for (final DGHole hole in widget.round.holes) {
      for (final DiscThrow discThrow in hole.throws) {
        if (discThrow.purpose == ThrowPurpose.putt) {
          totalPutts++;
          final double? distance = discThrow.distanceFeetBeforeThrow
              ?.toDouble();
          final bool made = discThrow.landingSpot == LandingSpot.inBasket;
          allPutts.add(made);
          if (made) totalMakes++;

          if (distance != null) {
            // C1 stats (0-33 ft)
            if (distance >= c1MinDistance && distance <= c1MaxDistance) {
              c1Attempts++;
              if (made) c1Makes++;
            }

            // C1X stats (11-33 ft)
            if (distance >= c1xMinDistance && distance <= c1xMaxDistance) {
              c1xAttempts++;
              if (made) c1xMakes++;
            }

            // C2 stats (33-66 ft)
            if (distance > c2MinDistance && distance <= c2MaxDistance) {
              c2Attempts++;
              if (made) c2Makes++;
            }
          }
        }
      }

      // Scramble: saved par or better after missing fairway on drive
      if (hole.throws.isNotEmpty) {
        final DiscThrow drive = hole.throws.first;
        final bool missedFairway =
            drive.landingSpot == LandingSpot.offFairway ||
            drive.landingSpot == LandingSpot.outOfBounds;

        if (missedFairway) {
          scrambleAttempts++;
          if (hole.relativeHoleScore <= 0) {
            scrambles++;
          }
        }
      }
    }

    final double c1Pct = c1Attempts > 0 ? (c1Makes / c1Attempts * 100) : 0;
    final double c1xPct = c1xAttempts > 0 ? (c1xMakes / c1xAttempts * 100) : 0;
    final double c2Pct = c2Attempts > 0 ? (c2Makes / c2Attempts * 100) : 0;
    final double scramblePct = scrambleAttempts > 0
        ? (scrambles / scrambleAttempts * 100)
        : 0;

    return {
      'c1Makes': c1Makes,
      'c1Attempts': c1Attempts,
      'c1Pct': c1Pct,
      'c1xMakes': c1xMakes,
      'c1xAttempts': c1xAttempts,
      'c1xPct': c1xPct,
      'c2Makes': c2Makes,
      'c2Attempts': c2Attempts,
      'c2Pct': c2Pct,
      'totalPutts': totalPutts,
      'totalMakes': totalMakes,
      'scramblePct': scramblePct,
      'hasData': totalPutts > 0,
      'allPutts': allPutts,
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final Map<String, dynamic> stats = _calculatePuttingStats();
    final bool hasData = stats['hasData'] as bool;

    return Card(
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🥏 Putting',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              // Circular stat indicators in triangle formation (2 on top, 1 centered below)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      useHeroAnimationsForRoundReview
                          ? Hero(
                              tag: 'putting_c1',
                              child: CircularStatIndicator(
                                key: ValueKey('putting_c1_${widget.round.id}'),
                                label: 'C1',
                                percentage: hasData
                                    ? stats['c1Pct'] as double
                                    : 0.0,
                                color: const Color(0xFF137e66),
                                size: 70,
                                shouldAnimate: true,
                                shouldGlow: true,
                                roundId: widget.round.id,
                              ),
                            )
                          : CircularStatIndicator(
                              key: ValueKey('putting_c1_${widget.round.id}'),
                              label: 'C1',
                              percentage: hasData
                                  ? stats['c1Pct'] as double
                                  : 0.0,
                              color: const Color(0xFF137e66),
                              size: 70,
                              shouldAnimate: true,
                              shouldGlow: true,
                              roundId: widget.round.id,
                            ),
                      useHeroAnimationsForRoundReview
                          ? Hero(
                              tag: 'putting_c1x',
                              child: CircularStatIndicator(
                                key: ValueKey('putting_c1x_${widget.round.id}'),
                                label: 'C1X',
                                percentage: hasData
                                    ? stats['c1xPct'] as double
                                    : 0.0,
                                color: const Color(0xFF4CAF50),
                                size: 70,
                                shouldAnimate: true,
                                shouldGlow: true,
                                roundId: widget.round.id,
                              ),
                            )
                          : CircularStatIndicator(
                              key: ValueKey('putting_c1x_${widget.round.id}'),
                              label: 'C1X',
                              percentage: hasData
                                  ? stats['c1xPct'] as double
                                  : 0.0,
                              color: const Color(0xFF4CAF50),
                              size: 70,
                              shouldAnimate: true,
                              shouldGlow: true,
                              roundId: widget.round.id,
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      useHeroAnimationsForRoundReview
                          ? Hero(
                              tag: 'putting_c2',
                              child: CircularStatIndicator(
                                key: ValueKey('putting_c2_${widget.round.id}'),
                                label: 'C2',
                                percentage: hasData
                                    ? stats['c2Pct'] as double
                                    : 0.0,
                                color: const Color(0xFF2196F3),
                                size: 70,
                                shouldAnimate: true,
                                shouldGlow: true,
                                roundId: widget.round.id,
                              ),
                            )
                          : CircularStatIndicator(
                              key: ValueKey('putting_c2_${widget.round.id}'),
                              label: 'C2',
                              percentage: hasData
                                  ? stats['c2Pct'] as double
                                  : 0.0,
                              color: const Color(0xFF2196F3),
                              size: 70,
                              shouldAnimate: true,
                              shouldGlow: true,
                              roundId: widget.round.id,
                            ),
                    ],
                  ),
                ],
              ),
              // Heat maps hidden for now
              // if (hasData) ...[
              //   const SizedBox(height: 16),
              //   // Side-by-side heat maps
              //   Row(
              //     children: [
              //       Expanded(
              //         child: _CompactHeatMap(showCircle1: true, round: round),
              //       ),
              //       const SizedBox(width: 12),
              //       Expanded(
              //         child: _CompactHeatMap(showCircle1: false, round: round),
              //       ),
              //     ],
              //   ),
              //   const SizedBox(height: 8),
              //   Center(
              //     child: Text(
              //       '${stats['totalMakes']}/${stats['totalPutts']} putts made',
              //       style: Theme.of(context).textTheme.bodySmall?.copyWith(
              //         color: Theme.of(
              //           context,
              //         ).colorScheme.onSurface.withValues(alpha: 0.6),
              //       ),
              //     ),
              //   ),
              // ],
            ],
          ),
        ),
      ),
    );
  }
}

// // Compact stat indicator for overview
// class _CompactStatIndicator extends StatelessWidget {
//   const _CompactStatIndicator({
//     required this.label,
//     required this.percentage,
//     required this.makes,
//     required this.attempts,
//     required this.color,
//   });

//   final String label;
//   final double percentage;
//   final int makes;
//   final int attempts;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: Theme.of(context).textTheme.bodySmall?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           '${percentage.toStringAsFixed(0)}%',
//           style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           '$makes/$attempts',
//           style: Theme.of(context).textTheme.bodySmall?.copyWith(
//             color: Theme.of(
//               context,
//             ).colorScheme.onSurface.withValues(alpha: 0.6),
//             fontSize: 11,
//           ),
//         ),
//       ],
//     );
//   }
// }

// Compact heat map with dots and animation
class _CompactHeatMap extends StatefulWidget {
  const _CompactHeatMap({required this.showCircle1, required this.round});

  final bool showCircle1;
  final DGRound round;

  @override
  State<_CompactHeatMap> createState() => _CompactHeatMapState();
}

class _CompactHeatMapState extends State<_CompactHeatMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PuttingAnalysisService puttingService = locator
        .get<PuttingAnalysisService>();
    final List<Map<String, dynamic>> allPutts = puttingService.getPuttAttempts(
      widget.round,
    );

    // Filter putts by circle
    final List<Map<String, dynamic>> putts = allPutts.where((putt) {
      final double? distance = putt['distance'] as double?;
      if (distance == null) return false;

      if (widget.showCircle1) {
        return distance <= c1MaxDistance;
      } else {
        return distance > c2MinDistance && distance <= c2MaxDistance;
      }
    }).toList();

    return Column(
      children: [
        Text(
          widget.showCircle1 ? 'C1' : 'C2',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _CompactHeatMapPainter(
                  showCircle1: widget.showCircle1,
                  putts: putts,
                  animationValue: _animation.value,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Painter for compact heat map with dots
class _CompactHeatMapPainter extends CustomPainter {
  _CompactHeatMapPainter({
    required this.showCircle1,
    required this.putts,
    this.animationValue = 1.0,
  });

  final bool showCircle1;
  final List<Map<String, dynamic>> putts;
  final double animationValue;

  // Same colors as full heat map
  static const List<Color> segmentColors = [
    Color(0xFFE8F5E9), // Very light green
    Color(0xFFF1F8F0), // Extra light green (weaker)
    Colors.white, // White
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;

    // Define circle radii
    final double basketRadius = maxRadius * 0.05;
    final double circle1InnerRadius = maxRadius * 0.15;
    final double circle1OuterRadiusSmall = maxRadius * 0.5;
    final double outerRadius = maxRadius;

    // Paint for filled circles
    final Paint closestSegmentPaint = Paint()
      ..color = segmentColors[0]
      ..style = PaintingStyle.fill;

    final Paint middleSegmentPaint = Paint()
      ..color = segmentColors[1]
      ..style = PaintingStyle.fill;

    final Paint farthestSegmentPaint = Paint()
      ..color = segmentColors[2]
      ..style = PaintingStyle.fill;

    // Paint for circle outlines
    final Paint strokePaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (showCircle1) {
      // Circle 1 visualization
      canvas.drawCircle(center, outerRadius, farthestSegmentPaint);

      final double segment2Radius =
          circle1InnerRadius + (outerRadius - circle1InnerRadius) * (2 / 3);
      canvas.drawCircle(center, segment2Radius, middleSegmentPaint);

      final double segment1Radius =
          circle1InnerRadius + (outerRadius - circle1InnerRadius) * (1 / 3);
      canvas.drawCircle(center, segment1Radius, closestSegmentPaint);

      canvas.drawCircle(center, outerRadius, strokePaint);
      canvas.drawCircle(center, segment2Radius, strokePaint);
      canvas.drawCircle(center, segment1Radius, strokePaint);

      final Paint basketPaint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, basketRadius, basketPaint);
    } else {
      // Circle 2 visualization
      canvas.drawCircle(center, outerRadius, farthestSegmentPaint);

      final double c2Segment2Radius =
          circle1OuterRadiusSmall +
          (outerRadius - circle1OuterRadiusSmall) * (2 / 3);
      canvas.drawCircle(center, c2Segment2Radius, middleSegmentPaint);

      final double c2Segment1Radius =
          circle1OuterRadiusSmall +
          (outerRadius - circle1OuterRadiusSmall) * (1 / 3);
      canvas.drawCircle(center, c2Segment1Radius, closestSegmentPaint);

      canvas.drawCircle(center, circle1OuterRadiusSmall, farthestSegmentPaint);

      // Add hash pattern to Circle 1 area
      _drawHashPattern(
        canvas,
        center,
        circle1OuterRadiusSmall,
        Colors.grey[300]!,
      );

      canvas.drawCircle(center, c2Segment2Radius, strokePaint);
      canvas.drawCircle(center, c2Segment1Radius, strokePaint);
      canvas.drawCircle(center, circle1OuterRadiusSmall, strokePaint);
      canvas.drawCircle(center, outerRadius, strokePaint);

      final Paint basketPaint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, basketRadius, basketPaint);
    }

    // Draw putt dots - same logic as full heat map
    const double angularSpacing = 0.2;

    // Add order index to each putt
    final List<Map<String, dynamic>> puttsWithIndex = [];
    for (int idx = 0; idx < putts.length; idx++) {
      final Map<String, dynamic> putt = putts[idx];
      final double? distance = putt['distance'] as double?;
      if (distance == null) continue;

      final Map<String, dynamic> puttWithIndex = Map<String, dynamic>.from(
        putt,
      );
      puttWithIndex['orderIndex'] = idx;
      puttsWithIndex.add(puttWithIndex);
    }

    // Group putts by distance buckets
    final Map<int, List<Map<String, dynamic>>> buckets = {};

    for (var putt in puttsWithIndex) {
      final double distance = putt['distance'] as double;
      final int bucketKey = (distance / 2).floor();
      buckets.putIfAbsent(bucketKey, () => []).add(putt);
    }

    final int totalDots = puttsWithIndex.length;

    // Process each bucket and arrange dots symmetrically
    for (var bucket in buckets.values) {
      final int count = bucket.length;
      const double baseAngle = pi / 2;

      for (int i = 0; i < count; i++) {
        final Map<String, dynamic> putt = bucket[i];
        final int orderIndex = putt['orderIndex'] as int;
        final double distance = putt['distance'] as double;
        final bool made = putt['made'] as bool? ?? false;

        // Calculate when this dot appears
        final double dotAppearTime = (orderIndex / totalDots) * 0.85;

        if (animationValue < dotAppearTime) continue;

        // Calculate bounce animation
        final double bounceTime = (animationValue - dotAppearTime) / 0.15;
        final double dotBounceProgress = bounceTime.clamp(0.0, 1.0);

        double bounceScale;
        if (dotBounceProgress <= 0.5) {
          bounceScale = dotBounceProgress * 3.0;
        } else {
          bounceScale = 1.5 - (dotBounceProgress - 0.5) * 1.0;
        }

        if (dotBounceProgress >= 1.0) {
          bounceScale = 1.0;
        }

        // Use green for made putts, red for missed putts
        final Paint dotPaint = Paint()
          ..color = made ? const Color(0xFF4CAF50) : const Color(0xFFEF5350)
          ..style = PaintingStyle.fill;

        // Calculate exact radius based on distance
        double radius;
        if (showCircle1) {
          radius =
              circle1InnerRadius +
              (distance / c1MaxDistance) * (outerRadius - circle1InnerRadius);
        } else {
          final double normalizedDistance =
              (distance - c2MinDistance) / c1MaxDistance;
          radius =
              circle1OuterRadiusSmall +
              normalizedDistance * (outerRadius - circle1OuterRadiusSmall);
        }

        // Calculate angle offset for symmetrical arrangement
        double angleOffset;
        if (count % 2 == 1) {
          final int centerIndex = count ~/ 2;
          angleOffset = (i - centerIndex) * angularSpacing;
        } else {
          final double centerOffset = count / 2 - 0.5;
          angleOffset = (i - centerOffset) * angularSpacing;
        }

        final double angle = baseAngle + angleOffset;

        // Calculate position
        final double x = center.dx + radius * cos(angle);
        final double y = center.dy + radius * sin(angle);

        // Draw with expand-then-shrink scale effect (smaller dots for compact view)
        canvas.drawCircle(Offset(x, y), 2.5 * bounceScale, dotPaint);
      }
    }
  }

  void _drawHashPattern(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final Paint hashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.save();

    final Path path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(path);

    const double spacing = 6.0;
    final double diameter = radius * 2;
    final int numLines = (diameter * 1.414 / spacing).ceil();

    for (int i = -numLines; i <= numLines; i++) {
      final double offset = i * spacing;
      canvas.drawLine(
        Offset(center.dx - diameter + offset, center.dy - diameter),
        Offset(center.dx + diameter + offset, center.dy + diameter),
        hashPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CompactHeatMapPainter oldDelegate) {
    return oldDelegate.showCircle1 != showCircle1 ||
        oldDelegate.putts != putts ||
        oldDelegate.animationValue != animationValue;
  }
}

// Disc Usage Card
class _DiscUsageCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _DiscUsageCard({required this.round, this.onTap});

  Map<String, dynamic> _calculateDiscStats() {
    final Map<String, int> discCounts = {};
    final Map<String, int> discC1InReg = {};
    final Map<String, int> discC1Attempts = {};
    int totalThrows = 0;

    for (final DGHole hole in round.holes) {
      for (int i = 0; i < hole.throws.length; i++) {
        final DiscThrow discThrow = hole.throws[i];
        final String discName =
            discThrow.disc?.name ?? discThrow.discName ?? 'Unknown';

        // Skip unknown discs
        if (discName == 'Unknown') continue;

        totalThrows++;
        discCounts[discName] = (discCounts[discName] ?? 0) + 1;

        // Track C1 in regulation (first throw that lands in C1)
        if (i == 0) {
          discC1Attempts[discName] = (discC1Attempts[discName] ?? 0) + 1;
          if (discThrow.landingSpot == LandingSpot.parked ||
              discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.inBasket) {
            discC1InReg[discName] = (discC1InReg[discName] ?? 0) + 1;
          }
        }
      }
    }

    // Calculate C1 in Reg percentage for each disc
    final Map<String, double> discC1Percentages = {};
    for (final discName in discCounts.keys) {
      final int attempts = discC1Attempts[discName] ?? 0;
      final int makes = discC1InReg[discName] ?? 0;
      discC1Percentages[discName] = attempts > 0
          ? (makes / attempts * 100)
          : 0.0;
    }

    // Sort by C1 in Reg % (primary), then by throw count (secondary)
    final List<MapEntry<String, double>> sortedDiscs =
        discC1Percentages.entries.toList()..sort((a, b) {
          final c1Comparison = b.value.compareTo(a.value);
          if (c1Comparison != 0) return c1Comparison;
          return (discCounts[b.key] ?? 0).compareTo(discCounts[a.key] ?? 0);
        });

    // Get top 3 discs
    final List<Map<String, dynamic>> topDiscs = sortedDiscs.take(3).map((
      entry,
    ) {
      return {
        'name': entry.key,
        'c1InRegPct': entry.value,
        'throwCount': discCounts[entry.key] ?? 0,
      };
    }).toList();

    return {
      'topDiscs': topDiscs,
      'totalThrows': totalThrows,
      'uniqueDiscs': discCounts.length,
      'hasData': totalThrows > 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> stats = _calculateDiscStats();
    final bool hasData = stats['hasData'] as bool;
    final List<Map<String, dynamic>> topDiscs =
        stats['topDiscs'] as List<Map<String, dynamic>>;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🥏 Top Discs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 4),
              if (!hasData)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'No disc data available',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else ...[
                const Text(
                  'C1 in Reg %',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                if (topDiscs.isNotEmpty)
                  ...topDiscs.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final Map<String, dynamic> disc = entry.value;
                    final String discName = disc['name'] as String;
                    final double c1InRegPct = disc['c1InRegPct'] as double;
                    final int throwCount = disc['throwCount'] as int;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < topDiscs.length - 1 ? 8 : 0,
                      ),
                      child: _MiniMedalCard(
                        rank: index + 1,
                        discName: discName,
                        c1InRegPct: c1InRegPct,
                        throwCount: throwCount,
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Mini medal card for overview
class _MiniMedalCard extends StatelessWidget {
  final int rank;
  final String discName;
  final double c1InRegPct;
  final int throwCount;

  const _MiniMedalCard({
    required this.rank,
    required this.discName,
    required this.c1InRegPct,
    required this.throwCount,
  });

  @override
  Widget build(BuildContext context) {
    final String medal = rank == 1
        ? '🥇'
        : rank == 2
        ? '🥈'
        : '🥉';
    final Color gradientColor1 = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
        ? const Color(0xFFC0C0C0)
        : const Color(0xFFCD7F32);
    final Color gradientColor2 = rank == 1
        ? const Color(0xFFDAA520)
        : rank == 2
        ? const Color(0xFFE8E8E8)
        : const Color(0xFFFFE4D0);

    final Widget cardContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColor1.withValues(alpha: 0.15),
            gradientColor2.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: gradientColor1.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              discName,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF137e66).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${c1InRegPct.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF137e66),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$throwCount×',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );

    return useHeroAnimationsForRoundReview
        ? Hero(
            tag: 'top_disc_$rank',
            child: Material(color: Colors.transparent, child: cardContent),
          )
        : cardContent;
  }
}

// Mistakes Card
class _MistakesCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _MistakesCard({required this.round, this.onTap});

  Color _getColorForIndex(int index) {
    final List<Color> colors = [
      const Color(0xFFFF7A7A), // Red for top mistake
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFFA726), // Orange
      const Color(0xFF66BB6A), // Green
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final MistakesAnalysisService mistakesService = locator
        .get<MistakesAnalysisService>();
    final int totalMistakes = mistakesService.getTotalMistakesCount(round);
    final List<dynamic> mistakeTypes = mistakesService.getMistakeTypes(round);

    // Filter out mistakes with count > 0
    final List<dynamic> topMistakes = mistakeTypes
        .where((mistake) => mistake.count > 0)
        .toList();

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '⚠️ Mistakes Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              if (totalMistakes == 0)
                const Text(
                  'No mistakes detected - perfect round!',
                  style: TextStyle(color: Colors.grey),
                )
              else ...[
                useHeroAnimationsForRoundReview
                    ? Hero(
                        tag: 'mistakes_count',
                        child: Material(
                          color: Colors.transparent,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$totalMistakes',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF7A7A),
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'mistakes',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$totalMistakes',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF7A7A),
                                ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'mistakes',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                if (topMistakes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...topMistakes.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final dynamic mistake = entry.value;
                    final int maxCount = topMistakes.first.count;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < topMistakes.length - 1 ? 12 : 0,
                      ),
                      child: _buildBarItem(
                        context,
                        label: mistake.label,
                        count: mistake.count,
                        maxCount: maxCount,
                        color: _getColorForIndex(index),
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarItem(
    BuildContext context, {
    required String label,
    required int count,
    required int maxCount,
    required Color color,
  }) {
    final double barWidth = maxCount > 0 ? count / maxCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Background bar
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Foreground bar (actual value)
            FractionallySizedBox(
              widthFactor: barWidth,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: count > 0
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Mental Game Card
class _MentalGameCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _MentalGameCard({required this.round, this.onTap});

  String _getHotStreakInsight(double percentage) {
    if (percentage > 75) {
      return 'You thrive on momentum!';
    } else if (percentage > 50) {
      return 'Good momentum player.';
    } else if (percentage > 25) {
      return 'Moderate momentum.';
    } else {
      return 'Build momentum together.';
    }
  }

  String _getTiltMeterInsight(double percentage) {
    if (percentage == 0) {
      return 'Ice in your veins 🧊';
    } else if (percentage < 20) {
      return 'Excellent composure!';
    } else if (percentage < 40) {
      return 'Moderate tilt control.';
    } else {
      return 'High tilt. Take a breath.';
    }
  }

  String _getBounceBackInsight(double percentage) {
    if (percentage > 60) {
      return 'Excellent recovery!';
    } else if (percentage > 40) {
      return 'Solid bounce-back.';
    } else if (percentage > 20) {
      return 'Room to grow.';
    } else {
      return 'Practice recovering.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final PsychAnalysisService psychService = locator
        .get<PsychAnalysisService>();
    final psychStats = psychService.getPsychStats(round);

    // Check if we have enough data
    final bool hasData = psychStats.mentalProfile != 'Insufficient Data';

    // Get key transition stats
    final ScoringTransition? birdieTransition =
        psychStats.transitionMatrix['Birdie'];
    final ScoringTransition? bogeyTransition =
        psychStats.transitionMatrix['Bogey'];

    final double hotStreakEnergy = birdieTransition?.toBirdiePercent ?? 0.0;
    final double tiltMeter = bogeyTransition?.bogeyOrWorsePercent ?? 0.0;
    final double bounceBack = psychStats.bounceBackRate;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🧠 Mental Game',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              if (!hasData)
                const Text(
                  'Play at least 3 holes to see your mental game analysis.',
                  style: TextStyle(color: Colors.grey),
                )
              else ...[
                _buildCompactMoodRow(
                  context,
                  emoji: '🔥',
                  label: 'Hot Streak',
                  percentage: hotStreakEnergy,
                  insight: _getHotStreakInsight(hotStreakEnergy),
                  color: const Color(0xFFFF6B35),
                ),
                const SizedBox(height: 8),
                _buildCompactMoodRow(
                  context,
                  emoji: '😡',
                  label: 'Tilt Meter',
                  percentage: tiltMeter,
                  insight: _getTiltMeterInsight(tiltMeter),
                  color: const Color(0xFFD32F2F),
                ),
                const SizedBox(height: 8),
                _buildCompactMoodRow(
                  context,
                  emoji: '💪',
                  label: 'Bounce-Back',
                  percentage: bounceBack,
                  insight: _getBounceBackInsight(bounceBack),
                  color: const Color(0xFF4CAF50),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMoodRow(
    BuildContext context, {
    required String emoji,
    required String label,
    required double percentage,
    required String insight,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '➜ $insight',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// AI Coach Card
class _AICoachCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _AICoachCard({required this.round, this.onTap});

  String _getFirstSentences(String content, int maxLength) {
    // Remove markdown headers and get clean text
    final List<String> lines = content.split('\n');
    final StringBuffer text = StringBuffer();

    for (final String line in lines) {
      final String trimmed = line.trim();
      // Skip headers and empty lines
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      // Remove markdown formatting (bold, italic, etc.)
      String cleaned = trimmed
          .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1') // bold
          .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1') // italic
          .replaceAll(RegExp(r'__([^_]+)__'), r'$1') // bold
          .replaceAll(RegExp(r'_([^_]+)_'), r'$1'); // italic

      text.write(cleaned);
      text.write(' ');

      // Stop if we have enough content
      if (text.length >= maxLength) break;
    }

    return text.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSummary =
        round.aiSummary != null && round.aiSummary!.content.isNotEmpty;
    final String? preview = hasSummary
        ? _getFirstSentences(round.aiSummary!.content, 150)
        : null;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🤖 AI Insights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              if (hasSummary && preview != null && preview.isNotEmpty) ...[
                Text(
                  preview,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to read full analysis',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ] else
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'AI-powered analysis and coaching advice',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Skills Overview Card
class SkillsOverviewCard extends StatefulWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const SkillsOverviewCard({super.key, required this.round, this.onTap});

  @override
  State<SkillsOverviewCard> createState() => _SkillsOverviewCardState();
}

class _SkillsOverviewCardState extends State<SkillsOverviewCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final SkillsAnalysisService service = SkillsAnalysisService();
    final SkillsAnalysis analysis = service.getSkillsAnalysis(widget.round);

    return Card(
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 4,
            top: 16,
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '⭐ Skills Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Overall score and spider chart
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Overall score (left side, very compact)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${analysis.overallScore.toStringAsFixed(0)}%',
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF137e66),
                              fontSize: 28,
                            ),
                      ),
                      Text(
                        'Overall',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  // Spider chart (right side, more space)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.15,
                      child: useHeroAnimationsForRoundReview
                          ? Hero(
                              tag: 'skills_spider_chart',
                              child: _CompactSkillsSpiderChart(
                                key: ValueKey(
                                  'spider_chart_${widget.round.id}',
                                ),
                                analysis: analysis,
                                roundId: widget.round.id,
                                shouldAnimate: true,
                              ),
                            )
                          : _CompactSkillsSpiderChart(
                              key: ValueKey('spider_chart_${widget.round.id}'),
                              analysis: analysis,
                              roundId: widget.round.id,
                              shouldAnimate: true,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Compact Spider Chart for Overview Card
class _CompactSkillsSpiderChart extends StatefulWidget {
  const _CompactSkillsSpiderChart({
    super.key,
    required this.analysis,
    required this.roundId,
    this.shouldAnimate = false,
  });

  final SkillsAnalysis analysis;
  final String roundId;
  final bool shouldAnimate;

  @override
  State<_CompactSkillsSpiderChart> createState() =>
      _CompactSkillsSpiderChartState();
}

class _CompactSkillsSpiderChartState extends State<_CompactSkillsSpiderChart>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    // Check if animation should play using AnimationStateService
    if (widget.shouldAnimate) {
      const String widgetKey = 'spider_chart';
      final bool hasAnimated = AnimationStateService.instance.hasAnimated(
        widget.roundId,
        widgetKey,
      );

      if (!hasAnimated) {
        // Play animation and mark as animated
        _animationController.forward();
        AnimationStateService.instance.markAnimated(widget.roundId, widgetKey);
      } else {
        // Skip animation, jump to end state
        _animationController.value = 1.0;
      }
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _CompactSkillsSpiderChartPainter(
            skills: widget.analysis.allSkills,
            animationValue: widget.shouldAnimate ? _animation.value : 1.0,
          ),
        );
      },
    );
  }
}

class _CompactSkillsSpiderChartPainter extends CustomPainter {
  _CompactSkillsSpiderChartPainter({
    required this.skills,
    this.animationValue = 1.0,
  });

  final List<SkillScore> skills;
  final double animationValue;

  static const Color gridColor = Color(0xFFE0E0E0);
  static const Color dataColor = Color(0xFF137e66);
  static const Color dataFillColor = Color(0x33137e66);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) / 2 * 0.55;
    final int numSkills = skills.length;

    // Draw grid circles
    _drawGridCircles(canvas, center, radius);

    // Draw axes
    _drawAxes(canvas, center, radius, numSkills);

    // Draw labels
    _drawLabels(canvas, center, radius, numSkills);

    // Draw data polygon
    _drawDataPolygon(canvas, center, radius, numSkills);
  }

  void _drawGridCircles(Canvas canvas, Offset center, double radius) {
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw 5 concentric circles at 20%, 40%, 60%, 80%, 100%
    for (int i = 1; i <= 5; i++) {
      final double currentRadius = radius * (i / 5);
      canvas.drawCircle(center, currentRadius, gridPaint);
    }
  }

  void _drawAxes(Canvas canvas, Offset center, double radius, int numSkills) {
    final Paint axisPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < numSkills; i++) {
      final double angle = (2 * pi / numSkills) * i - (pi / 2);
      final double x = center.dx + radius * cos(angle);
      final double y = center.dy + radius * sin(angle);

      canvas.drawLine(center, Offset(x, y), axisPaint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, int numSkills) {
    for (int i = 0; i < numSkills; i++) {
      final double angle = (2 * pi / numSkills) * i - (pi / 2);
      final double labelRadius = radius * 1.30;
      final double x = center.dx + labelRadius * cos(angle);
      final double y = center.dy + labelRadius * sin(angle);

      final String label = _getShortLabel(skills[i].skillName);
      final String percentage = '${skills[i].percentage.toStringAsFixed(0)}%';

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();

      final TextPainter percentagePainter = TextPainter(
        text: TextSpan(
          text: percentage,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: dataColor,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      percentagePainter.layout();

      // Position label
      double labelX = x - labelPainter.width / 2;
      double labelY = y - labelPainter.height / 2;

      // Adjust for corner positions to prevent overlap
      if (angle < -pi / 4 && angle > -3 * pi / 4) {
        // Top
        labelY -= 14;
      } else if (angle > pi / 4 && angle < 3 * pi / 4) {
        // Bottom
        labelY += 14;
      } else if (angle >= -pi / 4 && angle <= pi / 4) {
        // Right side
        labelX += 6;
      } else {
        // Left side
        labelX -= 6;
      }

      labelPainter.paint(canvas, Offset(labelX, labelY));

      // Paint percentage below label
      final double percentageX = x - percentagePainter.width / 2;
      final double percentageY = labelY + labelPainter.height + 1;
      percentagePainter.paint(canvas, Offset(percentageX, percentageY));
    }
  }

  String _getShortLabel(String fullLabel) {
    switch (fullLabel) {
      case 'Backhand Driving':
        return 'Backhand';
      case 'Forehand Driving':
        return 'Forehand';
      case 'Approaching':
        return 'Approach';
      case 'Putting':
        return 'Putting';
      case 'Mental Focus':
        return 'Mental';
      default:
        return fullLabel;
    }
  }

  void _drawDataPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    int numSkills,
  ) {
    final Path dataPath = Path();
    final List<Offset> points = [];

    // Calculate points with animation - arms start from center and extend outward
    // Each arm has a different speed/delay for a staggered effect
    for (int i = 0; i < numSkills; i++) {
      final double angle = (2 * pi / numSkills) * i - (pi / 2);
      final double percentage = skills[i].percentage / 100;

      // Stagger each arm's animation - each arm starts slightly later and moves at different speed
      final double delay =
          i * 0.08; // Each arm delayed by 8% of total animation
      final double armProgress = ((animationValue - delay) / (1.0 - delay))
          .clamp(0.0, 1.0);

      // Animate from 0 (center) to full percentage with staggered timing
      final double animatedPercentage = percentage * armProgress;
      final double pointRadius = radius * animatedPercentage;
      final double x = center.dx + pointRadius * cos(angle);
      final double y = center.dy + pointRadius * sin(angle);

      points.add(Offset(x, y));

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }

    dataPath.close();

    // Draw filled polygon
    final Paint fillPaint = Paint()
      ..color = dataFillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Draw polygon outline
    final Paint strokePaint = Paint()
      ..color = dataColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(dataPath, strokePaint);

    // Draw points
    final Paint pointPaint = Paint()
      ..color = dataColor
      ..style = PaintingStyle.fill;

    for (final Offset point in points) {
      canvas.drawCircle(point, 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_CompactSkillsSpiderChartPainter oldDelegate) {
    return oldDelegate.skills != skills ||
        oldDelegate.animationValue != animationValue;
  }
}

// AI Roast Card
class _AIRoastCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _AIRoastCard({required this.round, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🔥 AI Roast',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'AI roast coming soon...',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Detail Screen Wrapper for V2 navigation
class _DetailScreenWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailScreenWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEEE8F5), // Light gray with faint purple tint
            Color(0xFFECECEE), // Light gray
            Color(0xFFE8F4E8), // Light gray with faint green tint
            Color(0xFFEAE8F0), // Light gray with subtle purple
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GenericAppBar(
          topViewPadding: MediaQuery.of(context).viewPadding.top,
          title: title,
          backgroundColor: Colors.transparent,
        ),
        body: child,
      ),
    );
  }
}

/// Promotional banner that appears at top of Stats tab
/// Encourages users to try the Judge feature
class _JudgeBanner extends StatefulWidget {
  final VoidCallback onTap;
  final bool shouldAnimate;

  const _JudgeBanner({required this.onTap, this.shouldAnimate = false});

  @override
  State<_JudgeBanner> createState() => _JudgeBannerState();
}

class _JudgeBannerState extends State<_JudgeBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.shouldAnimate) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );

      _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      );

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

      // Start animation after short delay
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    if (widget.shouldAnimate) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget banner = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF6B6B),
              Color(0xFF2196F3),
            ], // Roast red to glaze blue
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Get Judged',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Glaze or brutal roast',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );

    // Wrap with animation if enabled
    if (widget.shouldAnimate) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(scale: _scaleAnimation, child: banner),
      );
    }

    return banner;
  }
}
