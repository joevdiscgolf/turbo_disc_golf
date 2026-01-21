import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/disc_usage_stats_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';

/// Service for accessing disc usage statistics computed by the backend.
///
/// Stats are computed by a Firestore trigger on the backend whenever rounds
/// are created, updated, or deleted. This service listens to the computed
/// stats in Firestore and provides recommendations based on them.
class DiscUsageStatsService extends ChangeNotifier
    implements ClearOnLogoutProtocol {
  StreamSubscription<DocumentSnapshot>? _subscription;
  AllDiscUsageStats _stats = AllDiscUsageStats.empty();
  bool _isLoaded = false;

  /// Whether stats have been loaded from Firestore
  bool get isLoaded => _isLoaded;

  /// Current usage stats (computed by backend)
  AllDiscUsageStats get stats => _stats;

  /// Start listening to Firestore for disc usage stats
  ///
  /// Should be called after user authentication is confirmed.
  Future<void> startListening(String uid) async {
    await _subscription?.cancel();

    _subscription = FirebaseFirestore.instance
        .collection('DiscUsageStats')
        .doc(uid)
        .snapshots()
        .listen(
      (DocumentSnapshot snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          try {
            _stats = AllDiscUsageStats.fromJson(
              snapshot.data() as Map<String, dynamic>,
            );
            debugPrint(
              '[DiscUsageStatsService] Loaded stats: '
              '${_stats.statsByDiscId.length} discs from '
              '${_stats.totalRoundsProcessed} rounds',
            );
          } catch (e) {
            debugPrint('[DiscUsageStatsService] Error parsing stats: $e');
            _stats = AllDiscUsageStats.empty();
          }
        } else {
          debugPrint('[DiscUsageStatsService] No stats document found');
          _stats = AllDiscUsageStats.empty();
        }
        _isLoaded = true;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('[DiscUsageStatsService] Error listening to stats: $e');
        _isLoaded = true;
        notifyListeners();
      },
    );
  }

  /// Stop listening to Firestore (call on logout)
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Get recommended disc IDs for a specific purpose, ordered by usage frequency
  ///
  /// Returns up to [limit] disc IDs that have been used for this purpose,
  /// sorted by most frequently used first.
  List<String> getRecommendedDiscIds({
    required ThrowPurpose purpose,
    int limit = 3,
  }) {
    if (_stats.isEmpty) return [];

    // Build list of (discId, usageCount) pairs for this purpose
    final List<MapEntry<String, int>> usageEntries = [];

    for (final MapEntry<String, DiscUsageStats> entry
        in _stats.statsByDiscId.entries) {
      final int usageCount = entry.value.getUsageForPurpose(purpose);
      if (usageCount > 0) {
        usageEntries.add(MapEntry(entry.key, usageCount));
      }
    }

    // Sort by usage count descending
    usageEntries.sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
        b.value.compareTo(a.value));

    // Return top disc IDs up to limit
    return usageEntries.take(limit).map((MapEntry<String, int> e) => e.key).toList();
  }

  @override
  Future<void> clearOnLogout() async {
    await stopListening();
    _stats = AllDiscUsageStats.empty();
    _isLoaded = false;
    notifyListeners();
  }
}
