import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_form_analysis_data_loader.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_state.dart';

/// Cubit for managing form analysis history state.
/// Handles loading recent analyses and selecting historical analyses for viewing.
class FormAnalysisHistoryCubit extends Cubit<FormAnalysisHistoryState>
    implements ClearOnLogoutProtocol {
  FormAnalysisHistoryCubit() : super(const FormAnalysisHistoryInitial());

  /// Load recent form analyses from Firestore.
  /// Loads the first 15 analyses for the current user.
  Future<void> loadHistory() async {
    try {
      emit(const FormAnalysisHistoryLoading());

      final String? uid = locator.get<AuthService>().currentUid;
      if (uid == null) {
        debugPrint('[FormAnalysisHistoryCubit] No user logged in');
        emit(const FormAnalysisHistoryError(message: 'Not logged in'));
        return;
      }

      final (List<FormAnalysisResponseV2> analyses, bool hasMore) =
          await FBFormAnalysisDataLoader.loadRecentAnalyses(uid, limit: 10);

      emit(FormAnalysisHistoryLoaded(
        analyses: analyses,
        hasMore: hasMore,
      ));
      debugPrint(
          '[FormAnalysisHistoryCubit] Loaded ${analyses.length} analyses, hasMore: $hasMore');
    } catch (e) {
      debugPrint('[FormAnalysisHistoryCubit] Error loading history: $e');
      emit(FormAnalysisHistoryError(message: e.toString()));
    }
  }

  /// Load more analyses (pagination).
  /// Loads the next 15 analyses after the current list.
  Future<void> loadMore() async {
    final FormAnalysisHistoryState currentState = state;
    if (currentState is! FormAnalysisHistoryLoaded) return;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    try {
      // Set loading more state
      emit(FormAnalysisHistoryLoaded(
        analyses: currentState.analyses,
        selectedAnalysis: currentState.selectedAnalysis,
        hasMore: currentState.hasMore,
        isLoadingMore: true,
      ));

      final String? uid = locator.get<AuthService>().currentUid;
      if (uid == null) {
        debugPrint('[FormAnalysisHistoryCubit] No user logged in');
        return;
      }

      // Get the timestamp of the last loaded analysis for pagination
      final String? lastTimestamp = currentState.analyses.isNotEmpty
          ? currentState.analyses.last.createdAt
          : null;

      final (List<FormAnalysisResponseV2> moreAnalyses, bool hasMore) =
          await FBFormAnalysisDataLoader.loadRecentAnalyses(
        uid,
        limit: 10,
        startAfterTimestamp: lastTimestamp,
      );

      // Append new analyses to existing list
      final List<FormAnalysisResponseV2> allAnalyses = [
        ...currentState.analyses,
        ...moreAnalyses,
      ];

      emit(FormAnalysisHistoryLoaded(
        analyses: allAnalyses,
        selectedAnalysis: currentState.selectedAnalysis,
        hasMore: hasMore,
        isLoadingMore: false,
      ));
      debugPrint(
          '[FormAnalysisHistoryCubit] Loaded ${moreAnalyses.length} more analyses, total: ${allAnalyses.length}, hasMore: $hasMore');
    } catch (e) {
      debugPrint('[FormAnalysisHistoryCubit] Error loading more: $e');
      // Restore previous state without loading flag
      emit(FormAnalysisHistoryLoaded(
        analyses: currentState.analyses,
        selectedAnalysis: currentState.selectedAnalysis,
        hasMore: currentState.hasMore,
        isLoadingMore: false,
      ));
    }
  }

  /// Refresh the analysis history from Firestore without showing loading state.
  /// Merges new analyses with existing paginated results, preserving scroll position.
  Future<void> refreshHistory() async {
    final FormAnalysisHistoryState currentState = state;

    try {
      final String? uid = locator.get<AuthService>().currentUid;
      if (uid == null) {
        debugPrint('[FormAnalysisHistoryCubit] No user logged in');
        return;
      }

      final (List<FormAnalysisResponseV2> newAnalyses, bool hasMore) =
          await FBFormAnalysisDataLoader.loadRecentAnalyses(uid, limit: 10);

      // If we had existing data, merge new analyses with existing ones
      if (currentState is FormAnalysisHistoryLoaded) {
        final Set<String> newAnalysisIds =
            newAnalyses.map((a) => a.id).whereType<String>().toSet();

        // Keep existing analyses that aren't in the new batch (they're further down)
        final List<FormAnalysisResponseV2> existingOnlyAnalyses = currentState
            .analyses
            .where((a) => a.id != null && !newAnalysisIds.contains(a.id))
            .toList();

        // Combine: new analyses first, then existing analyses not in new batch
        final List<FormAnalysisResponseV2> mergedAnalyses = [
          ...newAnalyses,
          ...existingOnlyAnalyses,
        ];

        emit(FormAnalysisHistoryLoaded(
          analyses: mergedAnalyses,
          selectedAnalysis: currentState.selectedAnalysis,
          hasMore: hasMore || existingOnlyAnalyses.isNotEmpty,
        ));
        debugPrint(
          '[FormAnalysisHistoryCubit] Refreshed: ${newAnalyses.length} new, ${existingOnlyAnalyses.length} preserved, total: ${mergedAnalyses.length}',
        );
      } else {
        emit(FormAnalysisHistoryLoaded(
          analyses: newAnalyses,
          hasMore: hasMore,
        ));
        debugPrint(
          '[FormAnalysisHistoryCubit] Refreshed ${newAnalyses.length} analyses, hasMore: $hasMore',
        );
      }
    } catch (e) {
      debugPrint('[FormAnalysisHistoryCubit] Error refreshing history: $e');
      emit(FormAnalysisHistoryError(message: e.toString()));
    }
  }

  /// Select a historical analysis for viewing.
  /// Updates the state to include the selected analysis.
  void selectAnalysis(FormAnalysisResponseV2 analysis) {
    if (state is FormAnalysisHistoryLoaded) {
      final FormAnalysisHistoryLoaded loadedState =
          state as FormAnalysisHistoryLoaded;
      emit(FormAnalysisHistoryLoaded(
        analyses: loadedState.analyses,
        selectedAnalysis: analysis,
        hasMore: loadedState.hasMore,
        isLoadingMore: loadedState.isLoadingMore,
      ));
      debugPrint(
          '[FormAnalysisHistoryCubit] Selected analysis ${analysis.id}');
    }
  }

  /// Clear the selected analysis.
  void clearSelection() {
    if (state is FormAnalysisHistoryLoaded) {
      final FormAnalysisHistoryLoaded loadedState =
          state as FormAnalysisHistoryLoaded;
      emit(FormAnalysisHistoryLoaded(
        analyses: loadedState.analyses,
        selectedAnalysis: null,
        hasMore: loadedState.hasMore,
        isLoadingMore: loadedState.isLoadingMore,
      ));
      debugPrint('[FormAnalysisHistoryCubit] Cleared selection');
    }
  }

  /// Add a new analysis to the history (called after saving a new analysis).
  /// Adds to the front of the list since it's the most recent.
  void addAnalysis(FormAnalysisResponseV2 analysis) {
    if (state is FormAnalysisHistoryLoaded) {
      final FormAnalysisHistoryLoaded loadedState =
          state as FormAnalysisHistoryLoaded;
      final List<FormAnalysisResponseV2> updatedAnalyses = [
        analysis,
        ...loadedState.analyses,
      ];

      emit(FormAnalysisHistoryLoaded(
        analyses: updatedAnalyses,
        selectedAnalysis: loadedState.selectedAnalysis,
        hasMore: loadedState.hasMore,
        isLoadingMore: loadedState.isLoadingMore,
      ));
      debugPrint('[FormAnalysisHistoryCubit] Added analysis ${analysis.id}');
    } else {
      // If not loaded yet, just load everything
      loadHistory();
    }
  }

  /// Delete a specific form analysis optimistically.
  /// Removes from local state immediately, then deletes from Firestore/Storage
  /// in the background. Reverts and shows error toast on failure.
  Future<void> deleteAnalysis(String analysisId) async {
    // Save state for rollback
    FormAnalysisResponseV2? removedAnalysis;
    int? removedIndex;

    // Optimistically remove from local state
    if (state is FormAnalysisHistoryLoaded) {
      final FormAnalysisHistoryLoaded loadedState =
          state as FormAnalysisHistoryLoaded;
      removedIndex =
          loadedState.analyses.indexWhere((a) => a.id == analysisId);

      if (removedIndex != -1) {
        removedAnalysis = loadedState.analyses[removedIndex];
        final List<FormAnalysisResponseV2> updatedAnalyses =
            loadedState.analyses.where((a) => a.id != analysisId).toList();

        emit(FormAnalysisHistoryLoaded(
          analyses: updatedAnalyses,
          selectedAnalysis: null,
          hasMore: loadedState.hasMore,
          isLoadingMore: loadedState.isLoadingMore,
        ));
      }
    }

    try {
      final String? uid = locator.get<AuthService>().currentUid;
      if (uid == null) {
        debugPrint('[FormAnalysisHistoryCubit] No user logged in');
        _revertDelete(removedAnalysis, removedIndex);
        return;
      }

      debugPrint('[FormAnalysisHistoryCubit] Deleting analysis: $analysisId');

      final bool success = await FBFormAnalysisDataLoader.deleteAnalysis(
        uid: uid,
        analysisId: analysisId,
      );

      if (success) {
        debugPrint(
            '[FormAnalysisHistoryCubit] Analysis deleted: $analysisId');
      } else {
        debugPrint('[FormAnalysisHistoryCubit] Failed to delete analysis');
        _revertDelete(removedAnalysis, removedIndex);
      }
    } catch (e) {
      debugPrint('[FormAnalysisHistoryCubit] Delete error: $e');
      _revertDelete(removedAnalysis, removedIndex);
    }
  }

  /// Re-insert a removed analysis back into state and show error toast.
  void _revertDelete(FormAnalysisResponseV2? analysis, int? index) {
    if (analysis == null || index == null || index == -1) return;

    if (state is FormAnalysisHistoryLoaded) {
      final FormAnalysisHistoryLoaded loadedState =
          state as FormAnalysisHistoryLoaded;
      final List<FormAnalysisResponseV2> updatedAnalyses =
          List<FormAnalysisResponseV2>.from(loadedState.analyses);

      final int insertIndex = index.clamp(0, updatedAnalyses.length);
      updatedAnalyses.insert(insertIndex, analysis);

      emit(FormAnalysisHistoryLoaded(
        analyses: updatedAnalyses,
        selectedAnalysis: loadedState.selectedAnalysis,
        hasMore: loadedState.hasMore,
        isLoadingMore: loadedState.isLoadingMore,
      ));
    }

    locator.get<ToastService>().showError(
      'Failed to delete analysis. Please try again.',
    );
  }

  /// Delete all form analyses for the current user (debug only).
  /// Clears both Firestore data and Cloud Storage images.
  Future<void> deleteAllAnalyses() async {
    try {
      emit(const FormAnalysisHistoryLoading());

      // Get current user ID
      final AuthService authService = locator.get<AuthService>();
      final String? uid = authService.currentUid;

      if (uid == null) {
        emit(const FormAnalysisHistoryError(message: 'User not authenticated'));
        return;
      }

      debugPrint('[FormAnalysisHistoryCubit] Deleting all analyses for user: $uid');

      // Delete all data
      final bool success = await FBFormAnalysisDataLoader.deleteAllAnalysesForUser(uid);

      if (success) {
        // Emit empty state
        emit(const FormAnalysisHistoryLoaded(
          analyses: [],
          selectedAnalysis: null,
        ));
        debugPrint('[FormAnalysisHistoryCubit] ✅ All analyses deleted successfully');
      } else {
        emit(const FormAnalysisHistoryError(message: 'Failed to delete analyses'));
      }
    } catch (e) {
      debugPrint('[FormAnalysisHistoryCubit] Delete all error: $e');
      emit(FormAnalysisHistoryError(message: 'Error deleting analyses: $e'));
    }
  }

  @override
  Future<void> clearOnLogout() async {
    emit(const FormAnalysisHistoryInitial());
  }
}
