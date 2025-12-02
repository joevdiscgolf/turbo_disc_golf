import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/app_phase_data.dart';
import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';

class AppPhaseController extends ChangeNotifier {
  final AuthService authService;
  AppPhase _phase = AppPhase.loading;

  AppPhase get phase => _phase;

  AppPhaseController({required this.authService}) {
    // React to login/logout - Firebase emits immediately on subscription
    authService.authState.distinct((previous, next) {
      // Only emit when the user ID changes (handles login, logout, user switch)
      return previous?.uid == next?.uid;
    }).listen(_handleAuthStateChange);
  }

  void _handleAuthStateChange(AuthUser? user) async {
    if (user == null) {
      setPhase(AppPhase.loggedOut);
    } else {
      final requiresOnboarding = await _needsOnboarding(user);

      if (requiresOnboarding) {
        setPhase(AppPhase.onboarding);
      } else {
        setPhase(AppPhase.home);
      }
    }
  }

  Future<bool> _needsOnboarding(AuthUser authuser) async {
    // Placeholder — you will replace with Firestore or preferences
    return false;
  }

  void setPhase(AppPhase newPhase) {
    if (newPhase == _phase) return;
    _phase = newPhase;
    notifyListeners(); // GoRouter reacts to this
  }
}
