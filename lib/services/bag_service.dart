import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';

class BagService extends ChangeNotifier implements ClearOnLogoutProtocol {
  static const String _bagKey = 'user_disc_bag';
  List<DGDisc> _userBag = [];

  List<DGDisc> get userBag => List.unmodifiable(_userBag);

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

  @override
  Future<void> clearOnLogout() async {
    _userBag.clear();
    notifyListeners();
    await saveBag();
  }
}
