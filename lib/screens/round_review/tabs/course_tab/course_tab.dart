import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/components/holes_grid.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/components/score_kpi_card.dart';
import 'package:turbo_disc_golf/state/round_review_cubit.dart';
import 'package:turbo_disc_golf/state/round_review_state.dart';

class CourseTab extends StatefulWidget {
  final DGRound round;
  final void Function(DGRound updatedRound)? onRoundUpdated;

  const CourseTab({super.key, required this.round, this.onRoundUpdated});

  @override
  State<CourseTab> createState() => _CourseTabState();
}

class _CourseTabState extends State<CourseTab> {
  late RoundReviewCubit _roundReviewCubit;

  @override
  void initState() {
    super.initState();
    _roundReviewCubit = BlocProvider.of<RoundReviewCubit>(context);

    // Start round review with the current round
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _roundReviewCubit.startRoundReview(widget.round);
      }
    });
  }

  @override
  void dispose() {
    // Clear round review when tab is disposed
    _roundReviewCubit.clearRoundReview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoundReviewCubit, RoundReviewState>(
      builder: (context, state) {
        if (state is! ReviewingRoundActive) {
          // Fallback to widget.round if state is not active yet
          final List<Widget> children = _getListViewChildren(context, widget.round);
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          );
        }

        final DGRound currentRound = state.round;

        // Notify parent of round updates when state changes
        if (widget.onRoundUpdated != null && currentRound != widget.round) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onRoundUpdated?.call(currentRound);
          });
        }

        final List<Widget> children = _getListViewChildren(context, currentRound);
        return ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 80),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  List<Widget> _getListViewChildren(BuildContext context, DGRound round) {
    return [
      ScoreKPICard(round: round, isDetailScreen: true),
      const SizedBox(height: 8),
      HolesGrid(round: round),
    ];
  }
}
