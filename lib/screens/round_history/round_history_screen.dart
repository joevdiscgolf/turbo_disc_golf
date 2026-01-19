import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/animations/page_transitions.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/courses/course_search_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_history/components/continue_recording_banner.dart';
import 'package:turbo_disc_golf/screens/round_history/components/record_round_panel.dart';
import 'package:turbo_disc_golf/screens/round_history/components/round_history_row.dart';
import 'package:turbo_disc_golf/screens/round_history/components/round_history_row_v2.dart';
import 'package:turbo_disc_golf/screens/round_history/components/welcome_empty_state.dart';
import 'package:turbo_disc_golf/screens/record_round/record_round_steps/record_round_steps_screen.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';
import 'package:turbo_disc_golf/state/round_history_cubit.dart';
import 'package:turbo_disc_golf/state/round_history_state.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

class RoundHistoryScreen extends StatefulWidget {
  const RoundHistoryScreen({super.key, required this.bottomViewPadding});

  static const String screenName = 'Round History';
  static const String routeName = '/round-history';

  final double bottomViewPadding;

  @override
  State<RoundHistoryScreen> createState() => _RoundHistoryScreenState();
}

class _RoundHistoryScreenState extends State<RoundHistoryScreen> {
  late RoundHistoryCubit _roundHistoryCubit;
  late final LoggingServiceBase _logger;

  @override
  void initState() {
    super.initState();

    // Create scoped logger with base properties
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'Screen Name': RoundHistoryScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('RoundHistoryScreen');

    _roundHistoryCubit = BlocProvider.of<RoundHistoryCubit>(context);
    // Load rounds on initial screen load
    _roundHistoryCubit.loadRounds();
    // Sync course cache from Firestore (fire and forget)
    _syncCourseCache();
  }

  /// Syncs the recent courses cache from Firestore.
  /// Called once on app startup to ensure cache is up-to-date with Firestore.
  Future<void> _syncCourseCache() async {
    try {
      await locator.get<CourseSearchService>().syncCacheFromFirestore();
    } catch (e) {
      debugPrint('[RoundHistoryScreen] Failed to sync course cache: $e');
    }
  }

  Future<void> _showRecordRoundSheet() async {
    if (useAddRoundStepsPanel) {
      // Start recording round in Cubit before showing panel
      BlocProvider.of<RecordRoundCubit>(context).startRecordingRound();

      Navigator.of(context).push(
        BannerExpandPageRoute(
          builder: (context) => RecordRoundStepsScreen(
            bottomViewPadding: widget.bottomViewPadding,
          ),
        ),
      );
    } else {
      // Track modal opened
      _logger.track('Modal Opened', properties: {
        'modal_type': 'bottom_sheet',
        'modal_name': 'Record Round Panel',
      });

      await displayBottomSheet(
        context,
        RecordRoundPanel(bottomViewPadding: widget.bottomViewPadding),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocBuilder<RoundHistoryCubit, RoundHistoryState>(
          builder: (context, state) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () => _roundHistoryCubit.refreshRounds(),
                ),
                _buildContent(state),
              ],
            );
          },
        ),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildContent(RoundHistoryState state) {
    if (state is RoundHistoryLoading) {
      // Initial loading - show full-screen spinner
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state is RoundHistoryError) {
      // Error state
      return SliverFillRemaining(child: _buildErrorState(state.error));
    } else if (state is RoundHistoryLoaded) {
      // Loaded state
      final List<DGRound> sortedRounds = state.sortedRounds;
      if (sortedRounds.isEmpty) {
        return SliverFillRemaining(
          child: WelcomeEmptyState(
            onAddRound: _showRecordRoundSheet,
            logger: _logger,
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final DGRound round = sortedRounds[index];
            return useRoundHistoryRowV2
                ? RoundHistoryRowV2(round: round, logger: _logger, index: index)
                : RoundHistoryRow(round: round, logger: _logger, index: index);
          }, childCount: sortedRounds.length),
        ),
      );
    } else {
      // Initial state - trigger load
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading rounds',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _roundHistoryCubit.loadRounds(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return BlocBuilder<RoundHistoryCubit, RoundHistoryState>(
      builder: (context, historyState) {
        // Hide FAB when showing empty state (WelcomeEmptyState has its own CTA)
        final bool isEmptyState =
            historyState is RoundHistoryLoaded &&
            historyState.sortedRounds.isEmpty;
        if (isEmptyState) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<RecordRoundCubit, RecordRoundState>(
          builder: (context, recordRoundState) {
            // Show continue banner only when recording is active AND course is selected
            if (recordRoundState is RecordRoundActive &&
                recordRoundState.selectedCourse != null) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ContinueRecordingBanner(
                  state: recordRoundState,
                  bottomViewPadding: widget.bottomViewPadding,
                ),
              );
            }

            final double bottomViewPadding = MediaQuery.of(
              context,
            ).viewPadding.bottom;

            // When bottom nav bar is present, body ends at nav bar - just need 20px margin
            // When no nav bar, need to account for safe area
            final double bottomMargin = useFormAnalysisTab
                ? 20
                : (bottomViewPadding + 20);

            return Positioned(
              right: 20,
              bottom: bottomMargin,
              child: _buildNewRoundButton(),
            );
          },
        );
      },
    );
  }

  Widget _buildNewRoundButton() {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF64B5F6).withValues(alpha: 0.9),
                const Color(0xFF1565C0).withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Track analytics using scoped logger (Screen Name already included!)
                _logger.track(
                  'Add Round Button Tapped',
                  properties: {'Button Location': 'Floating'},
                );

                HapticFeedback.lightImpact();
                _showRecordRoundSheet();
              },
              customBorder: const CircleBorder(),
              splashColor: Colors.white.withValues(alpha: 0.3),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              child: const Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                  shadows: [
                    Shadow(
                      color: Color(0xFF000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
