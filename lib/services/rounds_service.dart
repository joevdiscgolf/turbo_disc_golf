import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';

/// Service that manages rounds data and makes it accessible app-wide
/// Uses ValueNotifier for reactive updates throughout the app
class RoundsService {
  RoundsService(this._firestoreRoundService) {
    // Load rounds on initialization
    loadRounds();
  }

  final FirestoreRoundService _firestoreRoundService;

  /// Notifier that holds all rounds loaded from Firestore
  final ValueNotifier<List<DGRound>> roundsNotifier = ValueNotifier<List<DGRound>>([]);

  /// Loading state
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// Error state
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  /// Get all rounds
  List<DGRound> get rounds => roundsNotifier.value;

  /// Load rounds from Firestore
  Future<void> loadRounds() async {
    try {
      isLoading.value = true;
      error.value = null;

      final loadedRounds = await _firestoreRoundService.getRounds();

      // Sort rounds by date (most recent first)
      // Assuming rounds have IDs that are sortable (e.g., timestamps or sequential)
      loadedRounds.sort((a, b) => b.id.compareTo(a.id));

      roundsNotifier.value = loadedRounds;
      debugPrint('RoundsService: Loaded ${loadedRounds.length} rounds');
    } catch (e) {
      error.value = 'Failed to load rounds: $e';
      debugPrint('RoundsService: Error loading rounds - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh rounds from Firestore
  Future<void> refreshRounds() async {
    await loadRounds();
  }

  /// Get the last X rounds
  List<DGRound> getLastXRounds(int count) {
    if (count <= 0) return [];
    final allRounds = roundsNotifier.value;
    if (count >= allRounds.length) return allRounds;
    return allRounds.sublist(0, count);
  }

  /// Get all rounds (alias for convenience)
  List<DGRound> getAllRounds() {
    return roundsNotifier.value;
  }

  /// Dispose notifiers when service is destroyed
  void dispose() {
    roundsNotifier.dispose();
    isLoading.dispose();
    error.dispose();
  }
}
