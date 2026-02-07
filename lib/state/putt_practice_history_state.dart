import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/putt_practice_session.dart';

/// State for putt practice history.
@immutable
abstract class PuttPracticeHistoryState {
  const PuttPracticeHistoryState();
}

/// Initial state - no history loaded yet.
class PuttPracticeHistoryInitial extends PuttPracticeHistoryState {
  const PuttPracticeHistoryInitial();
}

/// Loading history from Firestore.
class PuttPracticeHistoryLoading extends PuttPracticeHistoryState {
  const PuttPracticeHistoryLoading();
}

/// History successfully loaded.
class PuttPracticeHistoryLoaded extends PuttPracticeHistoryState {
  const PuttPracticeHistoryLoaded({
    required this.sessions,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  /// List of recent putt practice sessions (newest first).
  final List<PuttPracticeSession> sessions;

  /// Whether there are more sessions to load.
  final bool hasMore;

  /// Whether currently loading more sessions (pagination).
  final bool isLoadingMore;
}

/// Error loading history.
class PuttPracticeHistoryError extends PuttPracticeHistoryState {
  const PuttPracticeHistoryError({required this.message});

  final String message;
}
