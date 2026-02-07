import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/putt_practice_session.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';
import 'package:turbo_disc_golf/utils/constants/timing_constants.dart';
import 'package:turbo_disc_golf/utils/firebase/firebase_utils.dart';

/// Data loader for putt practice sessions in Firestore.
/// Handles saving, loading, and pagination of putt practice sessions.
abstract class FBPuttPracticeDataLoader {
  /// Save a putt practice session to Firestore.
  /// Returns true on success, false on failure.
  static Future<bool> saveSession(PuttPracticeSession session) async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBPuttPracticeDataLoader] 💾 SAVE START');
      debugPrint('[FBPuttPracticeDataLoader] Session ID: ${session.id}');
      debugPrint('[FBPuttPracticeDataLoader] User ID: ${session.uid}');
      debugPrint('[FBPuttPracticeDataLoader] Attempts: ${session.totalAttempts}');
      debugPrint('[FBPuttPracticeDataLoader] Makes: ${session.makes}');
      debugPrint('═══════════════════════════════════════════════════════');

      // Path: putt_practice_sessions/{uid}/putt_practice_sessions/{sessionId}
      final String firestorePath =
          '$kPuttPracticeSessionsCollection/${session.uid}/$kPuttPracticeSessionsCollection/${session.id}';

      final bool success = await firestoreWrite(
        firestorePath,
        session.toJson(),
        merge: false,
        timeoutDuration: shortTimeout,
      );

      if (success) {
        debugPrint(
          '[FBPuttPracticeDataLoader] ✅ Successfully saved session: ${session.id}',
        );
      } else {
        debugPrint(
          '[FBPuttPracticeDataLoader] ❌ Failed to save session: ${session.id}',
        );
      }

      return success;
    } catch (e, trace) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBPuttPracticeDataLoader] ❌ SAVE FAILED!');
      debugPrint('[FBPuttPracticeDataLoader] Error: $e');
      debugPrint('[FBPuttPracticeDataLoader] Stack trace: $trace');
      debugPrint('═══════════════════════════════════════════════════════');
      return false;
    }
  }

  /// Load recent putt practice sessions for a user with pagination support.
  /// Returns a tuple of (sessions, hasMore) where hasMore indicates if there are more documents.
  static Future<(List<PuttPracticeSession>, bool)> loadRecentSessions(
    String uid, {
    int limit = 10,
    String? startAfterTimestamp,
  }) async {
    try {
      // Path: putt_practice_sessions/{uid}/putt_practice_sessions
      final String path =
          '$kPuttPracticeSessionsCollection/$uid/$kPuttPracticeSessionsCollection';

      // Build the query
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection(path)
          .orderBy('createdAt', descending: true)
          .limit(limit + 1); // Request one extra to check if there are more

      // If we have a cursor, start after it
      if (startAfterTimestamp != null && startAfterTimestamp.isNotEmpty) {
        query = query.startAfter([startAfterTimestamp]);
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query
          .get()
          .timeout(
            standardTimeout,
            onTimeout: () =>
                throw TimeoutException('Query timed out for path: $path'),
          );

      if (snapshot.docs.isEmpty) {
        debugPrint(
          '[FBPuttPracticeDataLoader][loadRecentSessions] No documents found',
        );
        return (<PuttPracticeSession>[], false);
      }

      // Parse documents
      final List<PuttPracticeSession> allSessions = snapshot.docs
          .map((doc) => PuttPracticeSession.fromJson(doc.data()))
          .toList();

      // Check if there are more documents
      final bool hasMore = allSessions.length > limit;

      // Return only the requested limit
      final List<PuttPracticeSession> sessions =
          hasMore ? allSessions.take(limit).toList() : allSessions;

      debugPrint(
        '[FBPuttPracticeDataLoader][loadRecentSessions] Loaded ${sessions.length} sessions, hasMore: $hasMore',
      );

      return (sessions, hasMore);
    } on TimeoutException catch (e) {
      // Handle timeout gracefully
      debugPrint(
        '[FBPuttPracticeDataLoader][loadRecentSessions] Timeout: ${e.message}',
      );
      debugPrint(
        '[FBPuttPracticeDataLoader][loadRecentSessions] This is normal if no data exists',
      );
      return (<PuttPracticeSession>[], false);
    } catch (e, trace) {
      debugPrint(
        '[FBPuttPracticeDataLoader][loadRecentSessions] Exception: $e',
      );
      debugPrint(
        '[FBPuttPracticeDataLoader][loadRecentSessions] Stack: $trace',
      );
      return (<PuttPracticeSession>[], false);
    }
  }

  /// Load a specific putt practice session by ID.
  static Future<PuttPracticeSession?> loadSessionById(
    String uid,
    String sessionId,
  ) async {
    try {
      // Path: putt_practice_sessions/{uid}/putt_practice_sessions/{sessionId}
      final String path =
          '$kPuttPracticeSessionsCollection/$uid/$kPuttPracticeSessionsCollection/$sessionId';
      final DocumentSnapshot<Map<String, dynamic>>? snapshot =
          await firestoreFetch(path, timeoutDuration: shortTimeout);

      if (snapshot == null || !snapshot.exists || snapshot.data() == null) {
        debugPrint(
          '[FBPuttPracticeDataLoader][loadSessionById] Session not found: $sessionId',
        );
        return null;
      }

      return PuttPracticeSession.fromJson(snapshot.data()!);
    } catch (e, trace) {
      debugPrint('[FBPuttPracticeDataLoader][loadSessionById] Exception: $e');
      debugPrint('[FBPuttPracticeDataLoader][loadSessionById] Stack: $trace');
      return null;
    }
  }
}
