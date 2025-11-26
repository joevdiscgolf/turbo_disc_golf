import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_history/components/record_round_panel_v2.dart';
import 'package:turbo_disc_golf/screens/round_history/components/round_history_row.dart';
import 'package:turbo_disc_golf/state/round_history_cubit.dart';
import 'package:turbo_disc_golf/state/round_history_state.dart';
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
    await displayBottomSheet(
      context,
      RecordRoundPanelV2(bottomViewPadding: widget.bottomViewPadding),
    );
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
    } else if (state is RoundHistoryRefreshing) {
      // Refreshing state - show current data with refresh indicator
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
    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFBA68C8), Color(0xFF9C27B0)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showRecordRoundSheet,
              customBorder: const CircleBorder(),
              child: const Center(
                child: Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
