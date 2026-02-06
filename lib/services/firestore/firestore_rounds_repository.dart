import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/repositories/rounds_repository.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class FirestoreRoundsRepository implements RoundsRepository {
  @override
  Future<bool> addRound(DGRound round) async {
    try {
      debugPrint('Saving round with id: ${round.id}');
      await _firestore
          .collection('$kRoundsCollection/${round.uid}/$kRoundsCollection')
          .doc(round.id)
          .set(round.toJson())
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Timeout saving round to Firestore');
              throw Exception('Timeout saving round');
            },
          );
      return true;
    } catch (e) {
      debugPrint('Error adding round: $e');
      return false;
    }
  }

  @override
  Future<bool> updateRound(DGRound round) async {
    try {
      debugPrint('Updating round with id: ${round.id}');
      await _firestore
          .collection('$kRoundsCollection/${round.uid}/$kRoundsCollection')
          .doc(round.id)
          .update(round.toJson())
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Timeout updating round to Firestore');
              throw Exception('Timeout updating round');
            },
          );
      return true;
    } catch (e) {
      debugPrint('Error updating round: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteRound(String uid, String roundId) async {
    try {
      debugPrint('Deleting round with id: $roundId');
      await _firestore
          .collection('$kRoundsCollection/$uid/$kRoundsCollection')
          .doc(roundId)
          .delete()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Timeout deleting round from Firestore');
              throw Exception('Timeout deleting round');
            },
          );
      return true;
    } catch (e) {
      debugPrint('Error deleting round: $e');
      return false;
    }
  }

  @override
  Future<List<DGRound>?> loadRoundsForUser(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('$kRoundsCollection/$uid/$kRoundsCollection')
          .get();
      return snapshot.docs.map((doc) => DGRound.fromJson(doc.data())).toList();
    } catch (e, trace) {
      debugPrint('Error getting rounds: $e');
      debugPrint(trace.toString());
      return [];
    }
  }

  @override
  Future<(List<DGRound>, bool)> loadRoundsPaginated(
    String uid, {
    required int limit,
    String? startAfterTimestamp,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('$kRoundsCollection/$uid/$kRoundsCollection')
          .orderBy('playedRoundAt', descending: true)
          .limit(limit + 1);

      if (startAfterTimestamp != null) {
        query = query.startAfter([startAfterTimestamp]);
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      final List<DGRound> rounds =
          snapshot.docs.map((doc) => DGRound.fromJson(doc.data())).toList();

      // Check if there are more results
      final bool hasMore = rounds.length > limit;
      if (hasMore) {
        rounds.removeLast();
      }

      debugPrint(
        'FirestoreRoundsRepository: Loaded ${rounds.length} rounds, hasMore: $hasMore',
      );
      return (rounds, hasMore);
    } catch (e, trace) {
      debugPrint('Error getting paginated rounds: $e');
      debugPrint(trace.toString());
      return (<DGRound>[], false);
    }
  }
}
