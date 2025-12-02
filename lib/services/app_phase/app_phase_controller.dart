import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/app_phase_data.dart';
import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';

class AppPhaseController extends ChangeNotifier {
  final AuthService authService;
  AppPhase _phase = AppPhase.loading;

  AppPhase get phase => _phase;

  AppPhaseController({required this.authService}) {
    // React to login/logout
    authService.authState.listen(_handleAuthStateChange);

    // On startup, compute initial state
    _initialize();
  }

  Future<void> _initialize() async {
    final user = await authService.getCurrentUser();

    if (user == null) {
      _set(AppPhase.loggedOut);
    } else {
      // You'll expand this logic later based on profile data, onboarding steps, etc.
      final requiresOnboarding = await _needsOnboarding(user);
      if (requiresOnboarding) {
        _set(AppPhase.onboarding);
      } else {
        _set(AppPhase.home);
      }
    }
  }

  void _handleAuthStateChange(AuthUser? user) async {
    if (user == null) {
      _set(AppPhase.loggedOut);
    } else {
      final requiresOnboarding = await _needsOnboarding(user);

      if (requiresOnboarding) {
        _set(AppPhase.onboarding);
      } else {
        _set(AppPhase.home);
      }
    }
  }

  Future<bool> _needsOnboarding(AuthUser authuser) async {
    // Placeholder — you will replace with Firestore or preferences
    return false;
  }

  void _set(AppPhase newPhase) {
    if (newPhase == _phase) return;
    _phase = newPhase;
    notifyListeners(); // GoRouter reacts to this
  }
}
