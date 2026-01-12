import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_form_analysis_data_loader.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_state.dart';

/// Cubit for managing form analysis history state.
/// Handles loading recent analyses and selecting historical analyses for viewing.
class FormAnalysisHistoryCubit extends Cubit<FormAnalysisHistoryState>
    implements ClearOnLogoutProtocol {
  FormAnalysisHistoryCubit() : super(const FormAnalysisHistoryInitial());

  /// Load recent form analyses from Firestore.
  /// Loads the 5 most recent analyses for the current user.
  Future<void> loadHistory() async {
    try {
      emit(const FormAnalysisHistoryLoading());

      final String? uid = locator.get<AuthService>().currentUid;
      if (uid == null) {
        debugPrint('[FormAnalysisHistoryCubit] No user logged in');
        emit(const FormAnalysisHistoryError(message: 'Not logged in'));
        return;
      }

      final List<FormAnalysisRecord> analyses =
          await FBFormAnalysisDataLoader.loadRecentAnalyses(uid, limit: 5);

      emit(FormAnalysisHistoryLoaded(analyses: analyses));
      debugPrint(
          '[FormAnalysisHistoryCubit] Loaded ${analyses.length} analyses');
    } catch (e) {
      debugPrint('[FormAnalysisHistoryCubit] Error loading history: $e');
      emit(FormAnalysisHistoryError(message: e.toString()));
    }
  }

  /// Select a historical analysis for viewing.
  /// Updates the state to include the selected analysis.
  void selectAnalysis(FormAnalysisRecord analysis) {
    if (state is FormAnalysisHistoryLoaded) {
      final FormAnalysisHistoryLoaded loadedState =
          state as FormAnalysisHistoryLoaded;
      emit(FormAnalysisHistoryLoaded(
        analyses: loadedState.analyses,
        selectedAnalysis: analysis,
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
      ));
      debugPrint('[FormAnalysisHistoryCubit] Cleared selection');
    }
  }

  /// Add a new analysis to the history (called after saving a new analysis).
  /// Adds to the front of the list since it's the most recent.
  void addAnalysis(FormAnalysisRecord analysis) {
    if (state is FormAnalysisHistoryLoaded) {
      final FormAnalysisHistoryLoaded loadedState =
          state as FormAnalysisHistoryLoaded;
      final List<FormAnalysisRecord> updatedAnalyses = [
        analysis,
        ...loadedState.analyses,
      ];
      // Keep only the most recent 5
      final List<FormAnalysisRecord> trimmedAnalyses =
          updatedAnalyses.take(5).toList();

      emit(FormAnalysisHistoryLoaded(
        analyses: trimmedAnalyses,
        selectedAnalysis: loadedState.selectedAnalysis,
      ));
      debugPrint('[FormAnalysisHistoryCubit] Added analysis ${analysis.id}');
    } else {
      // If not loaded yet, just load everything
      loadHistory();
    }
  }

  @override
  Future<void> clearOnLogout() async {
    emit(const FormAnalysisHistoryInitial());
  }
}
