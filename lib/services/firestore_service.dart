import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

class FirestoreService {
  Future<DGRound> getRound(String roundId) async {
    final round = await firestore.collection('TestRounds').doc(roundId).get();
    return DGRound.fromJson(round.data() ?? {});
  }

  Future<bool> saveTestRound(DGRound round) async {
    await firestore.collection('TestRounds').doc(round.id).set(round.toJson());
    return true;
  }
}
