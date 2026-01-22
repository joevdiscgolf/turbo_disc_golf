import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/rounds_service.dart';
import 'package:turbo_disc_golf/state/round_history_state.dart';

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

      final List<DGRound>? rounds = await locator
          .get<RoundsService>()
          .loadRoundsForUser();

      if (rounds != null) {
        emit(RoundHistoryLoaded(rounds: rounds));
      } else {
        emit(RoundHistoryError(error: 'Something went wrong'));
      }
    } catch (e) {
      debugPrint('Error loading rounds: $e');
      emit(RoundHistoryError(error: e.toString()));
    }
  }

  /// Refresh rounds from Firestore (pull-to-refresh)
  /// Keeps showing existing data during refresh
  Future<void> refreshRounds() async {
    try {
      // If we have loaded data, show refreshing state with current data
      if (state is RoundHistoryLoaded) {
        final List<DGRound> currentRounds =
            (state as RoundHistoryLoaded).rounds;
        emit(RoundHistoryLoaded(rounds: currentRounds, isRefreshing: true));
      } else {
        // If no data yet, just show loading
        emit(const RoundHistoryLoading());
      }

      final List<DGRound>? rounds = await locator
          .get<RoundsService>()
          .loadRoundsForUser();

      if (rounds != null) {
        emit(RoundHistoryLoaded(rounds: rounds));
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
