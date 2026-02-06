import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/rounds_service.dart';
import 'package:turbo_disc_golf/state/round_history_state.dart';

/// Number of rounds to load per page.
const int _kPageSize = 10;

/// Cubit for managing round history state
/// Handles loading, refreshing, adding, and updating rounds in the history list
class RoundHistoryCubit extends Cubit<RoundHistoryState>
    implements ClearOnLogoutProtocol {
  RoundHistoryCubit() : super(const RoundHistoryLoading());

  /// Load rounds from Firestore (initial load)
  /// Shows full-screen loading spinner
  Future<void> loadRounds() async {
    try {
      emit(const RoundHistoryLoading());

      final result = await locator
          .get<RoundsService>()
          .loadRoundsPaginated(limit: _kPageSize);

      if (result != null) {
        final (List<DGRound> rounds, bool hasMore) = result;
        emit(RoundHistoryLoaded(rounds: rounds, hasMore: hasMore));
      } else {
        emit(RoundHistoryError(error: 'Something went wrong'));
      }
    } catch (e) {
      debugPrint('Error loading rounds: $e');
      emit(RoundHistoryError(error: e.toString()));
    }
  }

  /// Load more rounds (pagination).
  /// Loads the next page of rounds after the current list.
  Future<void> loadMore() async {
    final RoundHistoryState currentState = state;
    if (currentState is! RoundHistoryLoaded) return;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    try {
      // Set loading more state
      emit(RoundHistoryLoaded(
        rounds: currentState.rounds,
        hasMore: currentState.hasMore,
        isLoadingMore: true,
      ));

      // Get the timestamp of the last loaded round for pagination
      final String? lastTimestamp = currentState.sortedRounds.isNotEmpty
          ? currentState.sortedRounds.last.playedRoundAt
          : null;

      final result = await locator.get<RoundsService>().loadRoundsPaginated(
        limit: _kPageSize,
        startAfterTimestamp: lastTimestamp,
      );

      if (result != null) {
        final (List<DGRound> moreRounds, bool hasMore) = result;

        // Append new rounds to existing list
        final List<DGRound> allRounds = [
          ...currentState.rounds,
          ...moreRounds,
        ];

        emit(RoundHistoryLoaded(
          rounds: allRounds,
          hasMore: hasMore,
          isLoadingMore: false,
        ));
        debugPrint(
          'RoundHistoryCubit: Loaded ${moreRounds.length} more rounds, total: ${allRounds.length}, hasMore: $hasMore',
        );
      } else {
        // Restore previous state without loading flag
        emit(RoundHistoryLoaded(
          rounds: currentState.rounds,
          hasMore: currentState.hasMore,
          isLoadingMore: false,
        ));
      }
    } catch (e) {
      debugPrint('Error loading more rounds: $e');
      // Restore previous state without loading flag
      emit(RoundHistoryLoaded(
        rounds: currentState.rounds,
        hasMore: currentState.hasMore,
        isLoadingMore: false,
      ));
    }
  }

  /// Refresh rounds from Firestore (pull-to-refresh)
  /// Merges new rounds with existing paginated results, preserving scroll position.
  Future<void> refreshRounds() async {
    final RoundHistoryState currentState = state;

    try {
      // If we have loaded data, show refreshing state with current data
      if (currentState is RoundHistoryLoaded) {
        emit(RoundHistoryLoaded(
          rounds: currentState.rounds,
          isRefreshing: true,
          hasMore: currentState.hasMore,
        ));
      } else {
        // If no data yet, just show loading
        emit(const RoundHistoryLoading());
      }

      final result = await locator
          .get<RoundsService>()
          .loadRoundsPaginated(limit: _kPageSize);

      if (result != null) {
        final (List<DGRound> newRounds, bool hasMore) = result;

        // If we had existing data, merge new rounds with existing ones
        if (currentState is RoundHistoryLoaded) {
          final Set<String> newRoundIds = newRounds.map((r) => r.id).toSet();

          // Keep existing rounds that aren't in the new batch (they're further down)
          final List<DGRound> existingOnlyRounds = currentState.rounds
              .where((r) => !newRoundIds.contains(r.id))
              .toList();

          // Combine: new rounds first, then existing rounds not in new batch
          final List<DGRound> mergedRounds = [
            ...newRounds,
            ...existingOnlyRounds,
          ];

          emit(RoundHistoryLoaded(
            rounds: mergedRounds,
            hasMore: hasMore || existingOnlyRounds.isNotEmpty,
          ));
        } else {
          emit(RoundHistoryLoaded(rounds: newRounds, hasMore: hasMore));
        }
      }
    } catch (e) {
      debugPrint('Error refreshing rounds: $e');
      emit(RoundHistoryError(error: e.toString()));
    }
  }

  /// Add a new round to the history
  /// Called from RoundConfirmationCubit after finalizing a round
  void addRound(DGRound round) {
    if (state is RoundHistoryLoaded) {
      final List<DGRound> currentRounds = (state as RoundHistoryLoaded).rounds;
      final List<DGRound> updatedRounds = List<DGRound>.from(currentRounds);
      updatedRounds.add(round);

      emit(RoundHistoryLoaded(rounds: updatedRounds));
      debugPrint('Added round ${round.id} to history');
    } else {
      // If history isn't loaded yet, trigger a load to get all rounds
      debugPrint('History not loaded, triggering load after adding round');
      loadRounds();
    }
  }

  /// Update an existing round in the history
  /// Called from RoundReviewCubit after editing a round
  void updateRound(DGRound updatedRound) {
    if (state is RoundHistoryLoaded) {
      final List<DGRound> currentRounds = (state as RoundHistoryLoaded).rounds;
      final List<DGRound> updatedRounds = currentRounds.map((round) {
        // Replace the round with matching ID
        return round.id == updatedRound.id ? updatedRound : round;
      }).toList();

      emit(RoundHistoryLoaded(rounds: updatedRounds));
      // debugPrint('Updated round ${updatedRound.id} in history');
    } else {
      // If history isn't loaded yet, trigger a load to get all rounds
      debugPrint('History not loaded, triggering load after updating round');
      loadRounds();
    }
  }

  /// Delete a round from the history and Firestore
  Future<bool> deleteRound(String roundId) async {
    if (state is RoundHistoryLoaded) {
      final List<DGRound> currentRounds = (state as RoundHistoryLoaded).rounds;

      // Find the round to get the uid
      final DGRound? roundToDelete = currentRounds
          .where((round) => round.id == roundId)
          .firstOrNull;

      if (roundToDelete == null) {
        debugPrint('Round $roundId not found in history');
        return false;
      }

      // Delete from Firestore first
      final bool firestoreSuccess = await locator.get<RoundsService>().deleteRound(
        roundToDelete.uid,
        roundId,
      );

      if (!firestoreSuccess) {
        debugPrint('Failed to delete round $roundId from Firestore');
        return false;
      }

      // Then remove from local state
      final List<DGRound> updatedRounds = currentRounds
          .where((round) => round.id != roundId)
          .toList();

      emit(RoundHistoryLoaded(rounds: updatedRounds));
      debugPrint('Deleted round $roundId from Firestore and local history');
      return true;
    }
    return false;
  }

  @override
  Future<void> clearOnLogout() async {
    emit(const RoundHistoryLoading());
  }
}
