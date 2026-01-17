import 'package:turbo_disc_golf/models/data/round_data.dart';

abstract class RoundsRepository {
  Future<bool> addRound(DGRound round);

  Future<bool> updateRound(DGRound round);

  Future<bool> deleteRound(String uid, String roundId);

  Future<List<DGRound>?> loadRoundsForUser(String uid);
}
