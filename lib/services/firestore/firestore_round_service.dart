import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';

class FirestoreRoundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> addRound(DGRound round) async {
    try {
      debugPrint('Saving round with id: ${round.id}');
      await _firestore
          .collection(kRoundsCollection)
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

  Future<DGRound?> getRound(String roundId) async {
    try {
      final snapshot = await _firestore
          .collection(kRoundsCollection)
          .doc(roundId)
          .get();
      if (snapshot.exists && snapshot.data() != null) {
        return DGRound.fromJson(snapshot.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting round: $e');
      return null;
    }
  }

  Future<List<DGRound>> getRounds() async {
    try {
      final snapshot = await _firestore.collection(kRoundsCollection).get();
      return snapshot.docs.map((doc) => DGRound.fromJson(doc.data())).toList();
    } catch (e, trace) {
      debugPrint('Error getting rounds: $e');
      debugPrint(trace.toString());
      return [];
    }
  }
}
