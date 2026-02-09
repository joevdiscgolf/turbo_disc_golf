import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_form_analysis_data_loader.dart';
import 'package:turbo_disc_golf/services/form_analysis/pose_analysis_api_client.dart';
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
  /// Removes analyses that are missing from Firestore (likely deleted externally).
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

        // Find the oldest timestamp in the new batch - anything newer than this
        // that's not in the new batch was likely deleted from Firestore
        final String? oldestNewTimestamp = newAnalyses.isNotEmpty
            ? newAnalyses
                .map((a) => a.createdAt)
                .whereType<String>()
                .reduce((a, b) => a.compareTo(b) < 0 ? a : b)
            : null;

        // Keep existing analyses that:
        // 1. Are in the new batch (will be deduplicated), OR
        // 2. Are OLDER than the oldest item in the new batch (paginated data)
        //
        // Remove analyses that:
        // - Are NOT in the new batch AND
        // - Are NEWER than or equal to the oldest new item (should have been returned)
        final List<FormAnalysisResponseV2> existingToKeep = currentState
            .analyses
            .where((existing) {
              if (existing.id == null) return false;

              // If it's in the new batch, it will be included from newAnalyses
              if (newAnalysisIds.contains(existing.id)) return false;

              // If no new analyses returned, keep nothing from local state
              // (Firestore is the source of truth)
              if (oldestNewTimestamp == null) return false;

              // Keep only if it's older than the oldest new analysis
              // (meaning it's paginated data we haven't refreshed yet)
              final String? existingTimestamp = existing.createdAt;
              if (existingTimestamp == null) return false;

              return existingTimestamp.compareTo(oldestNewTimestamp) < 0;
            })
            .toList();

        // Track removed analyses for logging
        final int previousCount = currentState.analyses.length;
        final int removedCount = previousCount - newAnalysisIds
            .intersection(currentState.analyses
                .map((a) => a.id)
                .whereType<String>()
                .toSet())
            .length - existingToKeep.length;

        // Combine: new analyses first, then older paginated analyses
        final List<FormAnalysisResponseV2> mergedAnalyses = [
          ...newAnalyses,
          ...existingToKeep,
        ];

        emit(FormAnalysisHistoryLoaded(
          analyses: mergedAnalyses,
          selectedAnalysis: currentState.selectedAnalysis,
          hasMore: hasMore || existingToKeep.isNotEmpty,
        ));

        if (removedCount > 0) {
          debugPrint(
            '[FormAnalysisHistoryCubit] Refreshed: ${newAnalyses.length} from Firestore, '
            '${existingToKeep.length} preserved (older), $removedCount removed (deleted externally), '
            'total: ${mergedAnalyses.length}',
          );
        } else {
          debugPrint(
            '[FormAnalysisHistoryCubit] Refreshed: ${newAnalyses.length} from Firestore, '
            '${existingToKeep.length} preserved, total: ${mergedAnalyses.length}',
          );
        }
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
  /// Removes from local state immediately, then calls backend API to delete
  /// from Firestore and Cloud Storage. Reverts and shows error toast on failure.
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
      debugPrint('[FormAnalysisHistoryCubit] Deleting analysis: $analysisId');

      // Call backend API to delete analysis (handles Firestore + Cloud Storage)
      final PoseAnalysisApiClient apiClient =
          locator.get<PoseAnalysisApiClient>();
      final bool success = await apiClient.deleteAnalysis(
        analysisId: analysisId,
      );

      if (success) {
        debugPrint(
            '[FormAnalysisHistoryCubit] Analysis deleted: $analysisId');
      } else {
        debugPrint('[FormAnalysisHistoryCubit] Failed to delete analysis');
        _revertDelete(removedAnalysis, removedIndex);
      }
    } on PoseAnalysisException catch (e) {
      debugPrint('[FormAnalysisHistoryCubit] Delete error: ${e.message}');
      _revertDelete(removedAnalysis, removedIndex);
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
  /// Calls the delete endpoint for each analysis in sequence.
  Future<void> deleteAllAnalyses() async {
    if (state is! FormAnalysisHistoryLoaded) return;

    final FormAnalysisHistoryLoaded loadedState =
        state as FormAnalysisHistoryLoaded;
    final List<FormAnalysisResponseV2> analyses =
        List<FormAnalysisResponseV2>.from(loadedState.analyses);

    if (analyses.isEmpty) {
      debugPrint('[FormAnalysisHistoryCubit] No analyses to delete');
      return;
    }

    emit(const FormAnalysisHistoryLoading());

    final PoseAnalysisApiClient apiClient = locator.get<PoseAnalysisApiClient>();
    int successCount = 0;
    int failCount = 0;

    debugPrint(
        '[FormAnalysisHistoryCubit] Deleting ${analyses.length} analyses in sequence...');

    for (final FormAnalysisResponseV2 analysis in analyses) {
      if (analysis.id == null) {
        failCount++;
        continue;
      }

      try {
        final bool success = await apiClient.deleteAnalysis(
          analysisId: analysis.id!,
        );

        if (success) {
          successCount++;
          debugPrint(
              '[FormAnalysisHistoryCubit] Deleted ${analysis.id} ($successCount/${analyses.length})');
        } else {
          failCount++;
          debugPrint(
              '[FormAnalysisHistoryCubit] Failed to delete ${analysis.id}');
        }
      } catch (e) {
        failCount++;
        debugPrint(
            '[FormAnalysisHistoryCubit] Error deleting ${analysis.id}: $e');
      }
    }

    // Emit empty state
    emit(const FormAnalysisHistoryLoaded(
      analyses: [],
      selectedAnalysis: null,
    ));

    debugPrint(
        '[FormAnalysisHistoryCubit] ✅ Delete all complete: $successCount succeeded, $failCount failed');
  }

  @override
  Future<void> clearOnLogout() async {
    emit(const FormAnalysisHistoryInitial());
  }
}
