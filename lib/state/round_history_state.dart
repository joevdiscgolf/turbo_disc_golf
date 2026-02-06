import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';

/// State for the round history workflow
@immutable
abstract class RoundHistoryState {
  const RoundHistoryState();
}

class RoundHistoryLoading extends RoundHistoryState {
  const RoundHistoryLoading();
}

class RoundHistoryLoaded extends RoundHistoryState {
  const RoundHistoryLoaded({
    required this.rounds,
    this.isRefreshing = false,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<DGRound> rounds;
  final bool isRefreshing;

  /// Whether there are more rounds to load.
  final bool hasMore;

  /// Whether currently loading more rounds (pagination).
  final bool isLoadingMore;

  /// Pre-sorted rounds by playedRoundAt descending (newest first)
  List<DGRound> get sortedRounds {
    final List<DGRound> sorted = List<DGRound>.from(rounds);
    sorted.sort((a, b) {
      final String aDate = a.playedRoundAt;
      final String bDate = b.playedRoundAt;
      return bDate.compareTo(aDate); // Descending order
    });
    return sorted;
  }
}

class RoundHistoryError extends RoundHistoryState {
  const RoundHistoryError({required this.error});

  final String error;
}
