import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';

class RoundStorageService implements ClearOnLogoutProtocol {
  static const String _cachedRoundKey = 'cached_test_round';

  /// Save a DGRound to shared preferences
  Future<bool> saveRound(DGRound round) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(round.toJson());
      return await prefs.setString(_cachedRoundKey, jsonString);
    } catch (e) {
      debugPrint('Error saving round to shared preferences: $e');
      return false;
    }
  }

  /// Load a DGRound from shared preferences
  /// Returns null if no round is cached or if there's an error
  Future<DGRound?> loadRound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cachedRoundKey);

      if (jsonString == null) {
        return null;
      }

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return DGRound.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Error loading round from shared preferences: $e');
      return null;
    }
  }

  /// Check if a cached round exists
  Future<bool> hasCachedRound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_cachedRoundKey);
    } catch (e) {
      debugPrint('Error checking for cached round: $e');
      return false;
    }
  }

  /// Clear the cached round
  Future<bool> clearCachedRound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_cachedRoundKey);
    } catch (e) {
      debugPrint('Error clearing cached round: $e');
      return false;
    }
  }

  @override
  Future<void> clearOnLogout() async {
    await clearCachedRound();
  }
}
