import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/custom_cupertino_action_sheet.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/form_analysis_history_card.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/form_analysis_welcome_empty_state.dart';
import 'package:turbo_disc_golf/screens/form_analysis/form_analysis_detail_screen.dart';
import 'package:turbo_disc_golf/screens/form_analysis/form_analysis_recording_screen.dart';
import 'package:turbo_disc_golf/screens/form_analysis/form_analysis_recording_screen_v2.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_cubit.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_state.dart';
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';

class FormAnalysisHistoryScreen extends StatefulWidget {
  const FormAnalysisHistoryScreen({
    super.key,
    required this.bottomViewPadding,
    required this.topViewPadding,
  });

  static const String screenName = 'Form Analysis History';
  static const String routeName = '/form-analysis-history';

  final double bottomViewPadding;
  final double topViewPadding;

  @override
  State<FormAnalysisHistoryScreen> createState() =>
      FormAnalysisHistoryScreenState();
}

class FormAnalysisHistoryScreenState extends State<FormAnalysisHistoryScreen> {
  late FormAnalysisHistoryCubit _historyCubit;
  late final LoggingServiceBase _logger;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _historyCubit = BlocProvider.of<FormAnalysisHistoryCubit>(context);

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': FormAnalysisHistoryScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('FormAnalysisHistoryScreen');

    // Load analyses on initial screen load
    _historyCubit.loadHistory();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if scrolled near bottom (within 200 pixels)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _historyCubit.loadMore();
    }
  }

  /// Scroll to the top of the list with animation.
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showRecordingScreen() async {
    _logger.track('New Form Analysis Button Tapped');

    final FeatureFlagService flags = locator.get<FeatureFlagService>();
    final Widget screen = flags.useFormAnalysisRecordingScreenV2
        ? FormAnalysisRecordingScreenV2(topViewPadding: widget.topViewPadding)
        : FormAnalysisRecordingScreen(topViewPadding: widget.topViewPadding);

    await pushCupertinoRoute(context, screen, pushFromBottom: true);
    // Note: New analyses are automatically added to the history cubit
    // by VideoFormAnalysisCubit when analysis completes - no refresh needed
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: Stack(
        children: [
          BlocBuilder<FormAnalysisHistoryCubit, FormAnalysisHistoryState>(
            builder: (context, state) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: const SystemUiOverlayStyle(
                  statusBarBrightness: Brightness.light,
                ),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: () => _historyCubit.refreshHistory(),
                    ),
                    _buildContent(state),
                  ],
                ),
              );
            },
          ),
          if (kDebugMode) _buildDeleteButton(),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildContent(FormAnalysisHistoryState state) {
    if (state is FormAnalysisHistoryLoading) {
      // Initial loading - show shimmer skeletons
      const int shimmerCount = 4;
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return Column(
              children: [
                const FormAnalysisHistoryCardShimmer(),
                if (index < shimmerCount - 1) const SizedBox(height: 8),
              ],
            );
          }, childCount: shimmerCount),
        ),
      );
    } else if (state is FormAnalysisHistoryError) {
      // Error state
      return SliverFillRemaining(child: _buildErrorState(state.message));
    } else if (state is FormAnalysisHistoryLoaded) {
      // Loaded state
      if (state.analyses.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: FormAnalysisWelcomeEmptyState(
            onStartAnalysis: _showRecordingScreen,
            logger: _logger,
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            // Show list items
            if (index < state.analyses.length) {
              final analysis = state.analyses[index];
              return Column(
                children: [
                  FormAnalysisHistoryCard(
                    key: ValueKey(analysis.id),
                    analysis: analysis,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _logger.track(
                        'Form Analysis Card Tapped',
                        properties: {
                          'analysis_id': analysis.id,
                          'item_index': index,
                        },
                      );
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: _historyCubit,
                            child: FormAnalysisDetailScreen(analysis: analysis),
                          ),
                        ),
                      );
                    },
                  ),
                  if (index < state.analyses.length - 1)
                    const SizedBox(height: 8),
                ],
              );
            }
            // Show loading indicator at bottom when loading more
            else if (state.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CupertinoActivityIndicator()),
              );
            }
            return const SizedBox.shrink();
          }, childCount: state.analyses.length + (state.isLoadingMore ? 1 : 0)),
        ),
      );
    } else {
      // Initial state - show shimmer skeletons
      const int shimmerCount = 4;
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return Column(
              children: [
                const FormAnalysisHistoryCardShimmer(),
                if (index < shimmerCount - 1) const SizedBox(height: 8),
              ],
            );
          }, childCount: shimmerCount),
        ),
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
            'Error loading analyses',
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
            onPressed: () {
              _logger.track('Retry Load History Button Tapped');
              _historyCubit.loadHistory();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return BlocBuilder<FormAnalysisHistoryCubit, FormAnalysisHistoryState>(
      builder: (context, state) {
        // Hide FAB when showing empty state
        final bool isEmptyState =
            state is FormAnalysisHistoryLoaded && state.analyses.isEmpty;
        if (isEmptyState) {
          return const SizedBox.shrink();
        }

        final double bottomViewPadding = MediaQuery.of(
          context,
        ).viewPadding.bottom;

        // When bottom nav bar is present, body ends at nav bar - just need 20px margin
        // When no nav bar, need to account for safe area
        final double bottomMargin =
            locator.get<FeatureFlagService>().useFormAnalysisTab
            ? 20
            : (bottomViewPadding + 20);

        return Positioned(
          right: 20,
          bottom: bottomMargin,
          child: _buildNewAnalysisButton(),
        );
      },
    );
  }

  Widget _buildNewAnalysisButton() {
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
                const Color(0xFF6B4EFF).withValues(alpha: 0.9),
                const Color(0xFF8B5CF6).withValues(alpha: 0.95),
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
                color: const Color(0xFF6B4EFF).withValues(alpha: 0.4),
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
                HapticFeedback.lightImpact();
                _showRecordingScreen();
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

  Widget _buildDeleteButton() {
    return BlocBuilder<FormAnalysisHistoryCubit, FormAnalysisHistoryState>(
      builder: (context, state) {
        final double bottomViewPadding = MediaQuery.of(
          context,
        ).viewPadding.bottom;

        final double bottomMargin =
            locator.get<FeatureFlagService>().useFormAnalysisTab
            ? 20
            : (bottomViewPadding + 20);

        return Positioned(
          left: 20,
          bottom: bottomMargin,
          child: _buildDeleteButtonContent(),
        );
      },
    );
  }

  Widget _buildDeleteButtonContent() {
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
                const Color(0xFFDC2626).withValues(alpha: 0.9),
                const Color(0xFFEF4444).withValues(alpha: 0.95),
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
                color: const Color(0xFFDC2626).withValues(alpha: 0.4),
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
                HapticFeedback.lightImpact();
                _showDeleteConfirmation();
              },
              customBorder: const CircleBorder(),
              splashColor: Colors.white.withValues(alpha: 0.3),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              child: const Center(
                child: Icon(
                  Icons.delete_forever,
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

  void _showDeleteConfirmation() {
    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'action_sheet',
        'modal_name': 'Delete All Analyses Confirmation',
      },
    );

    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => CustomCupertinoActionSheet(
        title: 'Delete all analysis data?',
        message:
            'This will permanently delete all form analysis records and Cloud Storage images. This cannot be undone. (DEBUG MODE ONLY)',
        destructiveActionLabel: 'Delete all',
        onDestructiveActionPressed: () {
          _logger.track('Delete All Analyses Confirmed');
          Navigator.pop(dialogContext);
          _historyCubit.deleteAllAnalyses();
        },
        onCancelPressed: () {
          _logger.track('Delete All Analyses Cancelled');
          Navigator.pop(dialogContext);
        },
      ),
    );
  }
}
