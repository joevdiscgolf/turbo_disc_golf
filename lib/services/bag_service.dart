import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/disc_usage_stats_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';

class BagService extends ChangeNotifier implements ClearOnLogoutProtocol {
  final AuthService _authService;
  StreamSubscription<AuthUser?>? _authSubscription;

  static const String _bagKey = 'user_disc_bag';
  List<DGDisc> _userBag = [];

  // Disc usage stats (computed by backend)
  StreamSubscription<DocumentSnapshot>? _statsSubscription;
  AllDiscUsageStats _usageStats = AllDiscUsageStats.empty();
  bool _usageStatsLoaded = false;

  BagService({required AuthService authService}) : _authService = authService {
    _authSubscription = _authService.authState
        .distinct((previous, next) => previous?.uid == next?.uid)
        .listen(_handleAuthStateChange);
  }

  void _handleAuthStateChange(AuthUser? user) {
    if (user != null) {
      // Start listening to new user's doc (cancels old subscription internally)
      startListeningToUsageStats(user.uid);
    } else {
      // User logged out - stop listening and clear stats
      stopListeningToUsageStats();
      _usageStats = AllDiscUsageStats.empty();
      _usageStatsLoaded = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _statsSubscription?.cancel();
    super.dispose();
  }

  List<DGDisc> get userBag => List.unmodifiable(_userBag);

  /// Whether disc usage stats have been loaded from Firestore
  bool get usageStatsLoaded => _usageStatsLoaded;

  /// Current usage stats (computed by backend)
  AllDiscUsageStats get usageStats => _usageStats;

  Future<void> loadBag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bagJson = prefs.getString(_bagKey);

      if (bagJson != null) {
        final List<dynamic> decoded = jsonDecode(bagJson);
        _userBag = decoded.map((json) => DGDisc.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading bag: $e');
    }
  }

  Future<bool> saveBag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bagJson = jsonEncode(
        _userBag.map((disc) => disc.toJson()).toList(),
      );
      await prefs.setString(_bagKey, bagJson);
      return true;
    } catch (e) {
      debugPrint('Error saving bag: $e');
      return false;
    }
  }

  Future<bool> addDisc(DGDisc disc) async {
    _userBag.add(disc);
    notifyListeners();
    return await saveBag();
  }

  Future<bool> removeDisc(String discId) async {
    _userBag.removeWhere((disc) => disc.id == discId);
    notifyListeners();
    return await saveBag();
  }

  Future<bool> updateDisc(DGDisc updatedDisc) async {
    final index = _userBag.indexWhere((disc) => disc.id == updatedDisc.id);
    if (index != -1) {
      _userBag[index] = updatedDisc;
      notifyListeners();
      return await saveBag();
    }
    return false;
  }

  void clearBag() {
    _userBag.clear();
    notifyListeners();
    saveBag();
  }

  DGDisc? findDiscByName(String name) {
    final searchName = name.toLowerCase();
    try {
      return _userBag.firstWhere(
        (disc) =>
            disc.name.toLowerCase().contains(searchName) ||
            (disc.moldName?.toLowerCase().contains(searchName) ?? false),
      );
    } catch (e) {
      // No match found, return null instead of defaulting to first disc
      // debugPrint('No disc found matching "$name" in bag');
      return null;
    }
  }

  // Helper method to create disc ID
  static String generateDiscId(DGDisc disc) {
    return '${disc.brand}_${disc.moldName}_${disc.plasticType}_${DateTime.now().millisecondsSinceEpoch}'
        .replaceAll(' ', '_')
        .toLowerCase();
  }

  // Sample discs for testing - can be removed in production
  void loadSampleBag() {
    _userBag = [
      const DGDisc(
        id: 'innova_destroyer_star_1',
        name: 'Star Destroyer',
        brand: 'Innova',
        moldName: 'Destroyer',
        plasticType: 'Star',
        speed: 12,
        glide: 5,
        turn: -1,
        fade: 3,
      ),
      const DGDisc(
        id: 'discraft_buzzz_esp_1',
        name: 'ESP Buzzz',
        brand: 'Discraft',
        moldName: 'Buzzz',
        plasticType: 'ESP',
        speed: 5,
        glide: 4,
        turn: -1,
        fade: 1,
      ),
      const DGDisc(
        id: 'dynamic_judge_classic_1',
        name: 'Classic Judge',
        brand: 'Dynamic Discs',
        moldName: 'Judge',
        plasticType: 'Classic',
        speed: 2,
        glide: 4,
        turn: 0,
        fade: 1,
      ),
      const DGDisc(
        id: 'latitude_river_opto_1',
        name: 'Opto River',
        brand: 'Latitude 64',
        moldName: 'River',
        plasticType: 'Opto',
        speed: 7,
        glide: 7,
        turn: -1,
        fade: 1,
      ),
      const DGDisc(
        id: 'innova_firebird_champion_1',
        name: 'Champion Firebird',
        brand: 'Innova',
        moldName: 'Firebird',
        plasticType: 'Champion',
        speed: 9,
        glide: 3,
        turn: 0,
        fade: 4,
      ),
    ];
    notifyListeners();
    saveBag();
  }

  // =========================================================================
  // Disc Usage Stats (from Firestore, computed by backend)
  // =========================================================================

  /// Start listening to Firestore for disc usage stats
  ///
  /// Should be called after user authentication is confirmed.
  Future<void> startListeningToUsageStats(String uid) async {
    await _statsSubscription?.cancel();

    _statsSubscription = FirebaseFirestore.instance
        .collection('DiscUsageStats')
        .doc(uid)
        .snapshots()
        .listen(
          (DocumentSnapshot snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              try {
                final Map<String, dynamic> rawData =
                    snapshot.data() as Map<String, dynamic>;
                debugPrint('[BagService] Loaded raw usage stats data');
                _usageStats = AllDiscUsageStats.fromJson(rawData);
                debugPrint(
                  '[BagService] Loaded usage stats: '
                  '${_usageStats.statsByDiscName.length} discs from '
                  '${_usageStats.totalRoundsProcessed} rounds',
                );
              } catch (e, stackTrace) {
                debugPrint('[BagService] Error parsing usage stats: $e');
                debugPrint('[BagService] Stack trace: $stackTrace');
                _usageStats = AllDiscUsageStats.empty();
              }
            } else {
              debugPrint('[BagService] No usage stats document found');
              _usageStats = AllDiscUsageStats.empty();
            }
            _usageStatsLoaded = true;
            notifyListeners();
          },
          onError: (Object e) {
            debugPrint('[BagService] Error listening to usage stats: $e');
            _usageStatsLoaded = true;
            notifyListeners();
          },
        );
  }

  /// Stop listening to Firestore (call on logout)
  Future<void> stopListeningToUsageStats() async {
    await _statsSubscription?.cancel();
    _statsSubscription = null;
  }

  /// Get most used disc names overall, ordered by total usage frequency
  ///
  /// Returns up to [limit] disc names sorted by most frequently used first.
  List<String> getMostUsedDiscNames({int limit = 3}) {
    if (_usageStats.isEmpty) return [];

    // Build list of (discName, totalUses) pairs
    final List<MapEntry<String, int>> usageEntries = _usageStats
        .statsByDiscName
        .entries
        .map((e) => MapEntry(e.key, e.value.totalUses))
        .toList();

    // Sort by total uses descending
    usageEntries.sort((a, b) => b.value.compareTo(a.value));

    // Return top disc names up to limit
    return usageEntries.take(limit).map((e) => e.key).toList();
  }

  /// Get recommended disc names for a specific purpose, ordered by usage frequency
  ///
  /// Returns up to [limit] disc names that have been used for this purpose,
  /// sorted by most frequently used first.
  List<String> getRecommendedDiscNamesForPurpose({
    required ThrowPurpose purpose,
    int limit = 3,
  }) {
    if (_usageStats.isEmpty) return [];

    // Build list of (discName, usageCount) pairs for this purpose
    final List<MapEntry<String, int>> usageEntries = [];

    for (final MapEntry<String, DiscUsageStats> entry
        in _usageStats.statsByDiscName.entries) {
      final int usageCount = entry.value.getUsageForPurpose(purpose);
      if (usageCount > 0) {
        usageEntries.add(MapEntry(entry.key, usageCount));
      }
    }

    // Sort by usage count descending
    usageEntries.sort(
      (MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value),
    );

    // Return top disc names up to limit
    return usageEntries
        .take(limit)
        .map((MapEntry<String, int> e) => e.key)
        .toList();
  }

  @override
  Future<void> clearOnLogout() async {
    // Clear bag
    _userBag.clear();
    await saveBag();

    // Clear usage stats
    await stopListeningToUsageStats();
    _usageStats = AllDiscUsageStats.empty();
    _usageStatsLoaded = false;

    notifyListeners();
  }
}
