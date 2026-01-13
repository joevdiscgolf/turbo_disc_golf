import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/utils/constants/timing_constants.dart';

class FirestoreQueryInstruction {
  FirestoreQueryInstruction({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.orderBy,
  });
  final String field;
  final Object? isEqualTo;
  final Object? isNotEqualTo;
  final Object? isLessThan;
  final Object? isLessThanOrEqualTo;
  final Object? isGreaterThan;
  final Object? isGreaterThanOrEqualTo;
  final Object? arrayContains;
  final List<Object?>? arrayContainsAny;
  final List<Object?>? whereIn;
  final List<Object?>? whereNotIn;
  final String? orderBy;
}

Future<DocumentSnapshot<Map<String, dynamic>>?> firestoreFetch(
  String path, {
  Duration timeoutDuration = shortTimeout,
}) async {
  try {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .doc(path)
            .get()
            .timeout(
              timeoutDuration,
              onTimeout: () => throw TimeoutException(
                'Firestore fetch timed out for path: $path',
              ),
            );
    return snapshot;
  } on TimeoutException catch (_) {
    log(
      '[firestore][utils][firestoreFetch] on timeout, path: $path, timeout: ${timeoutDuration.inSeconds} s',
    );
    return null;
  } catch (e, trace) {
    FirebaseCrashlytics.instance.recordError(
      e,
      trace,
      reason: '[firestore][utils][firestoreFetch] exception, path: $path',
    );
    return null;
  }
}

Future<QuerySnapshot<Map<String, dynamic>>?> firestoreQuery({
  required String path,
  List<FirestoreQueryInstruction>? firestoreQueries,
  String? orderBy,
  Duration timeoutDuration = shortTimeout,
}) async {
  try {
    final CollectionReference<Map<String, dynamic>> collectionReference =
        FirebaseFirestore.instance.collection(path);
    Query<Map<String, dynamic>>? query;
    late final Future<QuerySnapshot<Map<String, dynamic>>> fetch;

    if (firestoreQueries?.isNotEmpty == true || orderBy != null) {
      if (firestoreQueries?.isNotEmpty == true) {
        for (FirestoreQueryInstruction firestoreQuery in firestoreQueries!) {
          if (query != null) {
            query = query.where(
              firestoreQuery.field,
              isEqualTo: firestoreQuery.isEqualTo,
              isNotEqualTo: firestoreQuery.isNotEqualTo,
              isLessThan: firestoreQuery.isLessThan,
              isLessThanOrEqualTo: firestoreQuery.isLessThanOrEqualTo,
              isGreaterThan: firestoreQuery.isGreaterThan,
              isGreaterThanOrEqualTo: firestoreQuery.isGreaterThanOrEqualTo,
              arrayContains: firestoreQuery.arrayContains,
              arrayContainsAny: firestoreQuery.arrayContainsAny,
              whereIn: firestoreQuery.whereIn,
              whereNotIn: firestoreQuery.whereNotIn,
            );
          } else {
            query = collectionReference.where(
              firestoreQuery.field,
              isEqualTo: firestoreQuery.isEqualTo,
              isNotEqualTo: firestoreQuery.isNotEqualTo,
              isLessThan: firestoreQuery.isLessThan,
              isLessThanOrEqualTo: firestoreQuery.isLessThanOrEqualTo,
              isGreaterThan: firestoreQuery.isGreaterThan,
              isGreaterThanOrEqualTo: firestoreQuery.isGreaterThanOrEqualTo,
              arrayContains: firestoreQuery.arrayContains,
              arrayContainsAny: firestoreQuery.arrayContainsAny,
              whereIn: firestoreQuery.whereIn,
              whereNotIn: firestoreQuery.whereNotIn,
            );
          }
        }
      }
      if (orderBy != null) {
        if (query != null) {
          query = query.orderBy(orderBy);
        } else {
          query = collectionReference.orderBy(orderBy);
        }
      }
    }

    if (query != null) {
      fetch = query.get();
    } else {
      fetch = collectionReference.get();
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await fetch.timeout(
      timeoutDuration,
      onTimeout: () =>
          throw TimeoutException('Firestore query timed out for path: $path'),
    );
    return snapshot;
  } on TimeoutException catch (_) {
    log(
      '[firestore][utils][firestoreQuery] on timeout, path: $path, duration: $timeoutDuration s,',
    );
    return null;
  } catch (e, trace) {
    FirebaseCrashlytics.instance.recordError(
      e,
      trace,
      reason: '[firestore][utils][firestoreQuery] exception, path: $path',
    );
    return null;
  }
}

/// A generic Firestore write helper that performs set or update operations.
///
/// [path]: The Firestore document path (e.g., 'collection/docId').
/// [data]: The data to write (as a Map).
/// [merge]: If true (default), performs a merge with existing doc data (`set`), otherwise overwrites.
/// [timeoutDuration]: Duration before timing out (default 5 seconds).
/// Returns true if successful, false if an error or timeout occurred.
Future<bool> firestoreWrite(
  String path,
  Map<String, dynamic> data, {
  bool merge = true,
  Duration timeoutDuration = const Duration(seconds: 5),
}) async {
  try {
    final docRef = FirebaseFirestore.instance.doc(path);
    await docRef
        .set(data, SetOptions(merge: merge))
        .timeout(
          timeoutDuration,
          onTimeout: () {
            throw TimeoutException(
              'Firestore write timed out for path: $path after $timeoutDuration',
            );
          },
        );
    return true;
  } on TimeoutException catch (_) {
    log(
      '[firestore][utils][firestoreWrite] on timeout, path: $path, duration: $timeoutDuration s,',
    );
    return false;
  } catch (e, trace) {
    FirebaseCrashlytics.instance.recordError(
      e,
      trace,
      reason: '[firestore][utils][firestoreWrite] exception, path: $path',
    );
    return false;
  }
}

/// Delete a single Firestore document
Future<bool> firestoreDelete(
  String path, {
  Duration timeoutDuration = defaultTimeout,
}) async {
  try {
    await FirebaseFirestore.instance
        .doc(path)
        .delete()
        .timeout(timeoutDuration);
    return true;
  } catch (e, trace) {
    debugPrint('[FirestoreUtils] Delete error: $e');
    FirebaseCrashlytics.instance.recordError(
      e,
      trace,
      reason: '[firestore][utils][firestoreDelete] exception, path: $path',
    );
    return false;
  }
}

/// Delete all documents in a collection
Future<bool> firestoreDeleteCollection(
  String collectionPath, {
  int batchSize = 500,
  Duration timeoutDuration = longTimeout,
}) async {
  try {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .get()
        .timeout(timeoutDuration);

    // Delete in batches to avoid limits
    final List<List<DocumentSnapshot>> batches = [];
    for (int i = 0; i < snapshot.docs.length; i += batchSize) {
      batches.add(snapshot.docs.skip(i).take(batchSize).toList());
    }

    for (final batch in batches) {
      final WriteBatch writeBatch = FirebaseFirestore.instance.batch();
      for (final doc in batch) {
        writeBatch.delete(doc.reference);
      }
      await writeBatch.commit().timeout(timeoutDuration);
    }

    debugPrint('[FirestoreUtils] Deleted ${snapshot.docs.length} documents from $collectionPath');
    return true;
  } catch (e, trace) {
    debugPrint('[FirestoreUtils] Delete collection error: $e');
    FirebaseCrashlytics.instance.recordError(
      e,
      trace,
      reason: '[firestore][utils][firestoreDeleteCollection] exception, path: $collectionPath',
    );
    return false;
  }
}
