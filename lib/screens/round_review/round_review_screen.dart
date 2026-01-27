import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/custom_cupertino_action_sheet.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/juge_round_tab/judge_round_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/round_stats_body.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab.dart';
import 'package:turbo_disc_golf/services/animation_state_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/state/round_history_cubit.dart';
import 'package:turbo_disc_golf/state/round_review_cubit.dart';
import 'package:turbo_disc_golf/state/round_review_state.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

class RoundReviewScreen extends StatefulWidget {
  static const String routeName = '/round-review';
  static const String screenName = 'Round Review';

  final DGRound round;
  final bool showStoryOnLoad;

  const RoundReviewScreen({
    super.key,
    required this.round,
    this.showStoryOnLoad = false,
  });

  @override
  State<RoundReviewScreen> createState() => _RoundReviewScreenState();
}

class _RoundReviewScreenState extends State<RoundReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RoundReviewCubit _reviewCubit;
  late final LoggingServiceBase _logger;

  static const List<String> _tabNames = ['Stats', 'Story', 'Judge'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _reviewCubit = BlocProvider.of<RoundReviewCubit>(context);

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': RoundReviewScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('RoundReviewScreenV2');

    // Track tab changes
    _tabController.addListener(_onTabChanged);

    // Initialize the cubit with the round
    _reviewCubit.startRoundReview(widget.round);

    // Show story view if requested - navigate to Story tab instead
    if (widget.showStoryOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(1); // Navigate to Story tab
        }
      });
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _logger.track(
        'Tab Changed',
        properties: {
          'tab_index': _tabController.index,
          'tab_name': _tabNames[_tabController.index],
        },
      );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    // Clear animation state so animations play fresh when re-entering this screen
    AnimationStateService.instance.clearRound(widget.round.id);
    // Clear the cubit state when leaving the screen
    _reviewCubit.clearRoundReview();
    super.dispose();
  }

  Future<void> _handleDeleteRound(DGRound round) async {
    // Track button tap
    _logger.track(
      'Delete Round Button Tapped',
      properties: {'round_id': round.id, 'course_name': round.courseName},
    );

    // Track modal opened
    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'action_sheet',
        'modal_name': 'Delete Round Confirmation',
        'round_id': round.id,
      },
    );

    // Show confirmation action sheet
    final bool? confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) {
        return CustomCupertinoActionSheet(
          title: 'Delete Round from ${round.courseName}?',
          message: 'This action cannot be undone.',
          destructiveActionLabel: 'Delete',
          onDestructiveActionPressed: () {
            _logger.track(
              'Delete Round Confirmed',
              properties: {'round_id': round.id},
            );
            Navigator.of(context).pop(true);
          },
          onCancelPressed: () {
            _logger.track(
              'Delete Round Cancelled',
              properties: {'round_id': round.id},
            );
            Navigator.of(context).pop(false);
          },
        );
      },
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Delete the round
    final RoundHistoryCubit historyCubit = BlocProvider.of<RoundHistoryCubit>(
      context,
    );
    final bool success = await historyCubit.deleteRound(round.id);

    // Close loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (success) {
      // Navigate back to history
      if (mounted) {
        Navigator.of(context).pop();
        locator.get<ToastService>().showSuccess('Round deleted');
      }
    } else {
      // Show error
      if (mounted) {
        locator.get<ToastService>().showError(
          'Failed to delete round. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoundReviewCubit, RoundReviewState>(
      bloc: _reviewCubit,
      builder: (context, state) {
        // Get the round from the cubit state, or fall back to widget.round
        final DGRound round = state is ReviewingRoundActive
            ? state.round
            : widget.round;

        return Container(
          color: SenseiColors.gray[50],
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: GenericAppBar(
              topViewPadding: MediaQuery.of(context).viewPadding.top,
              title: locator.get<FeatureFlagService>().showRoundMetadataInfoBar
                  ? 'Round overview'
                  : round.courseName,
              bottomWidget: _tabBar(),
              bottomWidgetHeight: 40,
              rightWidget: PopupMenuButton(
                icon: const Icon(Icons.more_horiz),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    onTap: () => _handleDeleteRound(round),
                  ),
                ],
              ),
            ),
            // AppBar(
            //   backgroundColor: Colors.transparent,
            //   title: Text(round.courseName),
            //   actions: [
            // IconButton(
            //   icon: const Icon(Icons.auto_stories),
            //   tooltip: 'View Fullscreen Story',
            //   onPressed: () {
            //     Navigator.of(context).push(
            //       CupertinoPageRoute(
            //         builder: (context) => RoundStoryView(round: round),
            //         fullscreenDialog: true,
            //       ),
            //     );
            //   },
            // ),
            //   ],
            // bottom:
            //  TabBar(
            //   controller: _tabController,
            //   splashFactory: NoSplash.splashFactory,
            //   overlayColor: WidgetStateProperty.all(Colors.transparent),
            //   labelColor: Colors.black,
            //   unselectedLabelColor: Colors.black54,
            //   indicatorColor: Colors.black,
            //   indicatorWeight: 2,
            //   labelStyle: const TextStyle(
            //     fontSize: 14,
            //     fontWeight: FontWeight.w600,
            //   ),
            //   unselectedLabelStyle: const TextStyle(
            //     fontSize: 14,
            //     fontWeight: FontWeight.normal,
            //   ),
            //   labelPadding: const EdgeInsets.symmetric(vertical: 8),
            //   tabs: const [
            //     Tab(text: 'Stats'),
            //     Tab(text: 'Story'),
            //   ],
            // ),
            // ),
            body: TabBarView(
              controller: _tabController,
              children: [
                // Stats tab - with optional info bar at top
                RoundStatsBody(
                  round: round,
                  isReviewV2Screen: true,
                  tabController: _tabController,
                ),
                // Story tab - no info bar
                RoundStoryTab(round: round, tabController: _tabController),
                // Judge tab - no info bar
                JudgeRoundTab(round: round),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tabBar() {
    return TabBar(
      controller: _tabController,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      labelColor: Colors.black,
      unselectedLabelColor: Colors.black54,
      indicatorColor: Colors.black,
      indicatorWeight: 2,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      labelPadding: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      indicatorPadding: EdgeInsets.zero,
      onTap: (_) => HapticFeedback.lightImpact(),
      tabs: const [
        Tab(text: 'Stats'),
        Tab(text: 'Story'),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department, size: 16),
              SizedBox(width: 4),
              Text('Judge'),
            ],
          ),
        ),
      ],
    );
  }
}
