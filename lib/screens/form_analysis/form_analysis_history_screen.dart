import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/screens/form_analysis/components/form_analysis_card.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/form_analysis_welcome_empty_state.dart';
import 'package:turbo_disc_golf/screens/form_analysis/form_analysis_detail_screen.dart';
import 'package:turbo_disc_golf/screens/form_analysis/form_analysis_recording_screen.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_cubit.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_state.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';

class FormAnalysisHistoryScreen extends StatefulWidget {
  const FormAnalysisHistoryScreen({super.key, required this.bottomViewPadding});

  final double bottomViewPadding;

  @override
  State<FormAnalysisHistoryScreen> createState() =>
      _FormAnalysisHistoryScreenState();
}

class _FormAnalysisHistoryScreenState extends State<FormAnalysisHistoryScreen> {
  late FormAnalysisHistoryCubit _historyCubit;

  @override
  void initState() {
    super.initState();
    _historyCubit = BlocProvider.of<FormAnalysisHistoryCubit>(context);
    // Load analyses on initial screen load
    _historyCubit.loadHistory();
  }

  Future<void> _showRecordingScreen() async {
    pushCupertinoRoute(
      context,
      const FormAnalysisRecordingScreen(),
      pushFromBottom: true,
    );
    // Refresh list after returning from recording screen
    _historyCubit.refreshHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocBuilder<FormAnalysisHistoryCubit, FormAnalysisHistoryState>(
          builder: (context, state) {
            return CustomScrollView(
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
        // Debug delete button (only in debug mode)
        if (kDebugMode) _buildDebugDeleteButton(context),
      ],
    );
  }

  Widget _buildContent(FormAnalysisHistoryState state) {
    if (state is FormAnalysisHistoryLoading) {
      // Initial loading - show full-screen spinner
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state is FormAnalysisHistoryError) {
      // Error state
      return SliverFillRemaining(child: _buildErrorState(state.message));
    } else if (state is FormAnalysisHistoryLoaded) {
      // Loaded state
      if (state.analyses.isEmpty) {
        return SliverFillRemaining(
          child: FormAnalysisWelcomeEmptyState(
            onStartAnalysis: _showRecordingScreen,
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final analysis = state.analyses[index];
            return FormAnalysisCard(
              analysis: analysis,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) =>
                        FormAnalysisDetailScreen(analysis: analysis),
                  ),
                );
              },
            );
          }, childCount: state.analyses.length),
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
            onPressed: () => _historyCubit.loadHistory(),
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
        final double bottomMargin = useFormAnalysisTab
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
}
