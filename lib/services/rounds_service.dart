import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/repositories/rounds_repository.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';

class RoundsService {
  RoundsService(this._roundsRepository);
  final RoundsRepository _roundsRepository;

  Future<List<DGRound>?> loadRoundsForUser() async {
    try {
      final AuthUser? authuser = locator.get<AuthService>().currentUser;
      if (authuser == null) return null;

      final loadedRounds = await _roundsRepository.loadRoundsForUser(
        authuser.uid,
      );

      // Sort rounds by date (most recent first)
      // Assuming rounds have IDs that are sortable (e.g., timestamps or sequential)
      loadedRounds?.sort((a, b) => b.id.compareTo(a.id));

      debugPrint('RoundsService: Loaded ${loadedRounds?.length} rounds');

      return loadedRounds;
    } catch (e) {
      debugPrint('RoundsService: Error loading rounds - $e');
      return null;
    }
  }

  /// Get the last X rounds
  List<DGRound> getLastXRounds(List<DGRound> allRounds, int count) {
    if (count <= 0) return [];

    if (count >= allRounds.length) return allRounds;
    return allRounds.sublist(0, count);
  }

  Future<bool> addRound(DGRound round) {
    return _roundsRepository.addRound(round);
  }

  Future<bool> updateRound(DGRound round) {
    return _roundsRepository.updateRound(round);
  }

  Future<bool> deleteRound(String uid, String roundId) {
    return _roundsRepository.deleteRound(uid, roundId);
  }
}
