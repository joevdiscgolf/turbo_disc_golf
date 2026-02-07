import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/putt_practice/putt_practice_screen.dart';
import 'package:turbo_disc_golf/screens/putt_practice_history/components/putt_practice_welcome_empty_state.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/state/putt_practice_history_cubit.dart';
import 'package:turbo_disc_golf/state/putt_practice_history_state.dart';
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';

class PuttPracticeHistoryScreen extends StatefulWidget {
  const PuttPracticeHistoryScreen({
    super.key,
    required this.bottomViewPadding,
    required this.topViewPadding,
  });

  static const String screenName = 'Putt Practice History';
  static const String routeName = '/putt-practice-history';

  final double bottomViewPadding;
  final double topViewPadding;

  @override
  State<PuttPracticeHistoryScreen> createState() =>
      PuttPracticeHistoryScreenState();
}

class PuttPracticeHistoryScreenState extends State<PuttPracticeHistoryScreen> {
  late PuttPracticeHistoryCubit _historyCubit;
  late final LoggingServiceBase _logger;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _historyCubit = BlocProvider.of<PuttPracticeHistoryCubit>(context);

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': PuttPracticeHistoryScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('PuttPracticeHistoryScreen');

    // Load sessions on initial screen load
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

  Future<void> _showPracticeScreen() async {
    _logger.track('New Putt Practice Button Tapped');

    await pushCupertinoRoute(
      context,
      const PuttPracticeScreen(),
      pushFromBottom: true,
    );
    // Refresh history after returning from practice session
    _historyCubit.refreshHistory();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: Stack(
        children: [
          BlocBuilder<PuttPracticeHistoryCubit, PuttPracticeHistoryState>(
            builder: (context, state) {
              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: () => _historyCubit.refreshHistory(),
                  ),
                  _buildContent(state),
                ],
              );
            },
          ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildContent(PuttPracticeHistoryState state) {
    if (state is PuttPracticeHistoryLoading) {
      return const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator()),
      );
    } else if (state is PuttPracticeHistoryError) {
      return SliverFillRemaining(child: _buildErrorState(state.message));
    } else if (state is PuttPracticeHistoryLoaded) {
      if (state.sessions.isEmpty) {
        return SliverFillRemaining(
          child: PuttPracticeWelcomeEmptyState(
            onStartPractice: _showPracticeScreen,
            logger: _logger,
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index < state.sessions.length) {
              final session = state.sessions[index];
              return Column(
                children: [
                  _buildSessionCard(session, index),
                  if (index < state.sessions.length - 1)
                    const SizedBox(height: 8),
                ],
              );
            } else if (state.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CupertinoActivityIndicator()),
              );
            }
            return const SizedBox.shrink();
          }, childCount: state.sessions.length + (state.isLoadingMore ? 1 : 0)),
        ),
      );
    } else {
      return const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
  }

  Widget _buildSessionCard(dynamic session, int index) {
    // Placeholder session card - will be expanded when Firestore is connected
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _logger.track(
            'Putt Practice Session Card Tapped',
            properties: {'session_id': session.id, 'item_index': index},
          );
          // todo: Navigate to session detail screen
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(session.createdAt),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${session.makePercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getPercentageColor(session.makePercentage),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${session.makes}/${session.totalAttempts} putts made',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading sessions',
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
              _logger.track('Retry Load Putt Practice History Button Tapped');
              _historyCubit.loadHistory();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return BlocBuilder<PuttPracticeHistoryCubit, PuttPracticeHistoryState>(
      builder: (context, state) {
        // Hide FAB when showing empty state
        final bool isEmptyState =
            state is PuttPracticeHistoryLoaded && state.sessions.isEmpty;
        if (isEmptyState) {
          return const SizedBox.shrink();
        }

        final double bottomViewPadding = MediaQuery.of(
          context,
        ).viewPadding.bottom;

        // When bottom nav bar is present, body ends at nav bar - just need 20px margin
        final FeatureFlagService flags = locator.get<FeatureFlagService>();
        final double bottomMargin =
            (flags.useFormAnalysisTab || flags.usePuttPracticeTab)
            ? 20
            : (bottomViewPadding + 20);

        return Positioned(
          right: 20,
          bottom: bottomMargin,
          child: _buildNewSessionButton(),
        );
      },
    );
  }

  Widget _buildNewSessionButton() {
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
                const Color(0xFF10B981).withValues(alpha: 0.9),
                const Color(0xFF059669).withValues(alpha: 0.95),
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
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
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
                _showPracticeScreen();
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
}
