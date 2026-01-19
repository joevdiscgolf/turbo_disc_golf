import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/judge_round_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_overview_body.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab.dart';
import 'package:turbo_disc_golf/services/animation_state_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/state/round_history_cubit.dart';
import 'package:turbo_disc_golf/state/round_review_cubit.dart';
import 'package:turbo_disc_golf/state/round_review_state.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

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
    _logger.track('Delete Round Button Tapped', properties: {
      'round_id': round.id,
      'course_name': round.courseName,
    });

    // Track modal opened
    _logger.track('Modal Opened', properties: {
      'modal_type': 'dialog',
      'modal_name': 'Delete Round Confirmation',
      'round_id': round.id,
    });

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Round'),
          content: Text(
            'Are you sure you want to delete this round from ${round.courseName}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                _logger.track('Delete Round Cancelled', properties: {
                  'round_id': round.id,
                });
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _logger.track('Delete Round Confirmed', properties: {
                  'round_id': round.id,
                });
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Round deleted successfully')),
        );
      }
    } else {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete round. Please try again.'),
            backgroundColor: Colors.red,
          ),
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
              title: showRoundMetadataInfoBar
                  ? 'Round overview'
                  : round.courseName,
              bottomWidget: _tabBar(),
              bottomWidgetHeight: 40,
              rightWidget: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete Round',
                onPressed: () => _handleDeleteRound(round),
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
                RoundOverviewBody(
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
