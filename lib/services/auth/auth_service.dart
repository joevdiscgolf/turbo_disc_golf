import 'dart:async';
import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/app_phase_data.dart';
import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/repositories/auth_repository.dart';
import 'package:turbo_disc_golf/services/app_phase/app_phase_controller.dart';
import 'package:turbo_disc_golf/services/auth/auth_database_service.dart';
import 'package:turbo_disc_golf/services/shared_preferences_service.dart';

class AuthService {
  final AuthRepository _authRepository;
  final AuthDatabaseService _authDatabaseService;

  AuthService(this._authRepository, this._authDatabaseService);

  Stream<AuthUser?> get authState => _authRepository.authStateChanges();

  Future<bool> isLoggedIn() async =>
      (await _authRepository.getCurrentUser()) != null;

  Future<void> login(String email, String password) =>
      _authRepository.signInWithEmailPassword(email, password);

  Future<void> logout() => _authRepository.signOut();

  Future<AuthUser?> getCurrentUser() => _authRepository.getCurrentUser();

  String errorMessage = '';

  Future<bool> deleteCurrentUser() {
    return _authRepository.deleteCurrentUser();
  }

  Future<bool> attemptSignUpWithEmail(String email, String password) async {
    final bool signUpSuccess = await _authRepository.signUpWithEmailPassword(
      email,
      password,
    );

    print('[attemptSignUpWithEmail] signUpSuccess: $signUpSuccess');

    final AuthUser? authUser = await getCurrentUser();

    if (!signUpSuccess || authUser == null) {
      errorMessage = _authRepository.exceptionMessage;
      return false;
    } else {
      locator.get<AppPhaseController>().setPhase(AppPhase.onboarding);
      return true;
    }
  }

  Future<bool> attemptSignInWithEmail(String email, String password) async {
    final bool signinSuccess = await _authRepository.signInWithEmailPassword(
      email,
      password,
    );

    if (!signinSuccess) {
      errorMessage = 'Something went wrong, please try again.';
      return false;
    }

    final AuthUser? authUser = await getCurrentUser();
    if (authUser == null) {
      return false;
    }

    final bool isSetUp = await _authDatabaseService.userIsSetUp(authUser.uid);

    if (!isSetUp) {
      locator.get<AppPhaseController>().setPhase(AppPhase.onboarding);
      return true;
    }

    locator.get<SharedPreferencesService>().markUserIsSetUp(true);

    try {
      // fetchLocalRepositoryData();
      // fetchRepositoryData();
      locator.get<AppPhaseController>().setPhase(AppPhase.home);
    } catch (e, trace) {
      log(
        '[myputt_auth_service][attemptSigninWithEmail] Failed to fetch repository data. Error: $e',
      );
      log(trace.toString());
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason:
            '[MyPuttAuthService][attemptSignInWithEmail] fetchRepositoryData timeout',
      );
    }

    return true;
  }

  Future<bool> setupNewUser(
    String username,
    String displayName, {
    int? pdgaNumber,
  }) async {
    final AuthUser? authUser = await getCurrentUser();
    if (authUser == null) {
      return false;
    }

    final TurboUser? newUser = await _authDatabaseService
        .setUpNewUserInDatabase(
          authUser,
          username,
          displayName,
          pdgaNumber: pdgaNumber,
        );
    if (newUser == null) {
      return false;
    }

    final bool isSetUp = await _authDatabaseService.userIsSetUp(authUser.uid);

    if (!isSetUp) {
      return false;
    }

    locator.get<AppPhaseController>().setPhase(AppPhase.home);
    return true;
  }

  void signOut() {
    // clearRepositoryData();
    // locator.get<SharedPreferencesService>().markUserIsSetUp(false);
    _authRepository.signOut();
  }
}
