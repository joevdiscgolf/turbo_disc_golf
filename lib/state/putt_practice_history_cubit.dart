import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/putt_practice_session.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_putt_practice_data_loader.dart';
import 'package:turbo_disc_golf/state/putt_practice_history_state.dart';

/// Cubit for managing putt practice history state.
/// Handles loading recent sessions and managing session list.
class PuttPracticeHistoryCubit extends Cubit<PuttPracticeHistoryState>
    implements ClearOnLogoutProtocol {
  PuttPracticeHistoryCubit() : super(const PuttPracticeHistoryInitial());

  static const int _pageSize = 10;

  /// Load putt practice sessions from Firestore.
  Future<void> loadHistory() async {
    try {
      emit(const PuttPracticeHistoryLoading());

      final String? uid = locator.get<AuthService>().currentUid;
      if (uid == null) {
        debugPrint('[PuttPracticeHistoryCubit] No authenticated user');
        emit(const PuttPracticeHistoryLoaded(
          sessions: [],
          hasMore: false,
        ));
        return;
      }

      final (List<PuttPracticeSession> sessions, bool hasMore) =
          await FBPuttPracticeDataLoader.loadRecentSessions(
        uid,
        limit: _pageSize,
      );

      emit(PuttPracticeHistoryLoaded(
        sessions: sessions,
        hasMore: hasMore,
      ));
      debugPrint(
        '[PuttPracticeHistoryCubit] Loaded ${sessions.length} sessions, hasMore: $hasMore',
      );
    } catch (e) {
      debugPrint('[PuttPracticeHistoryCubit] Error loading history: $e');
      emit(PuttPracticeHistoryError(message: e.toString()));
    }
  }

  /// Refresh the session history.
  /// Merges new sessions with existing paginated results to preserve scroll position.
  Future<void> refreshHistory() async {
    try {
      final String? uid = locator.get<AuthService>().currentUid;
      if (uid == null) {
        debugPrint('[PuttPracticeHistoryCubit] No authenticated user');
        return;
      }

      final (List<PuttPracticeSession> newSessions, bool hasMore) =
          await FBPuttPracticeDataLoader.loadRecentSessions(
        uid,
        limit: _pageSize,
      );

      final PuttPracticeHistoryState currentState = state;
      if (currentState is PuttPracticeHistoryLoaded) {
        // Merge new sessions with existing ones (keep sessions beyond first page)
        final Set<String> newSessionIds =
            newSessions.map((s) => s.id).toSet();
        final List<PuttPracticeSession> existingBeyondFirstPage = currentState
            .sessions
            .skip(_pageSize)
            .where((s) => !newSessionIds.contains(s.id))
            .toList();

        emit(PuttPracticeHistoryLoaded(
          sessions: [...newSessions, ...existingBeyondFirstPage],
          hasMore: hasMore || existingBeyondFirstPage.isNotEmpty,
        ));
      } else {
        emit(PuttPracticeHistoryLoaded(
          sessions: newSessions,
          hasMore: hasMore,
        ));
      }
      debugPrint('[PuttPracticeHistoryCubit] Refreshed history');
    } catch (e) {
      debugPrint('[PuttPracticeHistoryCubit] Error refreshing history: $e');
    }
  }

  /// Load more sessions (pagination).
  Future<void> loadMore() async {
    final PuttPracticeHistoryState currentState = state;
    if (currentState is! PuttPracticeHistoryLoaded) return;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    try {
      // Set loading more flag
      emit(PuttPracticeHistoryLoaded(
        sessions: currentState.sessions,
        hasMore: currentState.hasMore,
        isLoadingMore: true,
      ));

      final String? uid = locator.get<AuthService>().currentUid;
      if (uid == null) {
        debugPrint('[PuttPracticeHistoryCubit] No authenticated user');
        emit(PuttPracticeHistoryLoaded(
          sessions: currentState.sessions,
          hasMore: false,
          isLoadingMore: false,
        ));
        return;
      }

      // Get cursor from last session's createdAt
      final PuttPracticeSession lastSession = currentState.sessions.last;
      final String cursor = lastSession.createdAt.toIso8601String();

      final (List<PuttPracticeSession> moreSessions, bool hasMore) =
          await FBPuttPracticeDataLoader.loadRecentSessions(
        uid,
        limit: _pageSize,
        startAfterTimestamp: cursor,
      );

      // Append to existing sessions
      emit(PuttPracticeHistoryLoaded(
        sessions: [...currentState.sessions, ...moreSessions],
        hasMore: hasMore,
        isLoadingMore: false,
      ));
      debugPrint(
        '[PuttPracticeHistoryCubit] Loaded ${moreSessions.length} more sessions, hasMore: $hasMore',
      );
    } catch (e) {
      debugPrint('[PuttPracticeHistoryCubit] Error loading more: $e');
      // Reset loading state on error
      emit(PuttPracticeHistoryLoaded(
        sessions: currentState.sessions,
        hasMore: currentState.hasMore,
        isLoadingMore: false,
      ));
    }
  }

  /// Add a new session to the history.
  void addSession(PuttPracticeSession session) {
    if (state is PuttPracticeHistoryLoaded) {
      final PuttPracticeHistoryLoaded loadedState =
          state as PuttPracticeHistoryLoaded;
      final List<PuttPracticeSession> updatedSessions = [
        session,
        ...loadedState.sessions,
      ];

      emit(PuttPracticeHistoryLoaded(
        sessions: updatedSessions,
        hasMore: loadedState.hasMore,
        isLoadingMore: loadedState.isLoadingMore,
      ));
      debugPrint('[PuttPracticeHistoryCubit] Added session ${session.id}');
    } else {
      // If not loaded yet, just load everything
      loadHistory();
    }
  }

  @override
  Future<void> clearOnLogout() async {
    emit(const PuttPracticeHistoryInitial());
  }
}
