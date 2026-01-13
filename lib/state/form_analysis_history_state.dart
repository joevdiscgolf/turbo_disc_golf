import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';

/// State for form analysis history.
@immutable
abstract class FormAnalysisHistoryState {
  const FormAnalysisHistoryState();
}

/// Initial state - no history loaded yet.
class FormAnalysisHistoryInitial extends FormAnalysisHistoryState {
  const FormAnalysisHistoryInitial();
}

/// Loading history from Firestore.
class FormAnalysisHistoryLoading extends FormAnalysisHistoryState {
  const FormAnalysisHistoryLoading();
}

/// History successfully loaded.
class FormAnalysisHistoryLoaded extends FormAnalysisHistoryState {
  const FormAnalysisHistoryLoaded({
    required this.analyses,
    this.selectedAnalysis,
  });

  /// List of recent form analyses (newest first).
  final List<FormAnalysisRecord> analyses;

  /// Currently selected analysis for viewing (if any).
  final FormAnalysisRecord? selectedAnalysis;
}

/// Error loading history.
class FormAnalysisHistoryError extends FormAnalysisHistoryState {
  const FormAnalysisHistoryError({required this.message});

  final String message;
}
