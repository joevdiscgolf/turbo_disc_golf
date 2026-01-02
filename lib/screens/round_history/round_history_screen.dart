import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/animations/page_transitions.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_history/components/continue_recording_banner.dart';
import 'package:turbo_disc_golf/screens/round_history/components/record_round_panel.dart';
import 'package:turbo_disc_golf/screens/round_history/components/record_round_steps_screen.dart';
import 'package:turbo_disc_golf/screens/round_history/components/round_history_row.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';
import 'package:turbo_disc_golf/state/round_history_cubit.dart';
import 'package:turbo_disc_golf/state/round_history_state.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

class RoundHistoryScreen extends StatefulWidget {
  const RoundHistoryScreen({super.key, required this.bottomViewPadding});

  final double bottomViewPadding;

  @override
  State<RoundHistoryScreen> createState() => _RoundHistoryScreenState();
}

class _RoundHistoryScreenState extends State<RoundHistoryScreen> {
  late RoundHistoryCubit _roundHistoryCubit;

  @override
  void initState() {
    super.initState();
    _roundHistoryCubit = BlocProvider.of<RoundHistoryCubit>(context);
    // Load rounds on initial screen load
    _roundHistoryCubit.loadRounds();
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
        return SliverFillRemaining(child: _buildEmptyState());
      }
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final DGRound round = sortedRounds[index];
            return RoundHistoryRow(round: round);
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.golf_course,
            size: 80,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No rounds yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first round to get started!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
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
    return BlocBuilder<RecordRoundCubit, RecordRoundState>(
      builder: (context, recordRoundState) {
        if (recordRoundState is RecordRoundActive) {
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

        return Positioned(
          right: 16,
          bottom: 16,
          child: _buildNewRoundButton(),
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
              onTap: _showRecordRoundSheet,
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
