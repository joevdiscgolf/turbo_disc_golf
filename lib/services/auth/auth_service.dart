import 'dart:async';
import 'dart:developer';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/repositories/auth_repository.dart';
import 'package:turbo_disc_golf/services/auth/auth_database_service.dart';
import 'package:turbo_disc_golf/utils/constants/timing_constants.dart';

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

  Future<bool> attemptSignInWithEmail(String email, String password) async {
    final bool signinSuccess = await _authRepository.signInWithEmailPassword(
      email,
      password,
    );

    if (!signinSuccess) {
      errorMessage = 'Something went wrong, please try again.';
      return false;
    }

    bool? isSetup;

    await FBUserDataLoader.instance
        .getCurrentUser()
        .then((TurboUser? user) {
          isSetup = userIsValid(user);
        })
        .catchError((e, trace) async {
          FirebaseCrashlytics.instance.recordError(
            e,
            trace,
            reason: '[AuthService][userIsSetup] get User timeout',
          );
        });

    if (isSetup == null) {
      errorMessage = 'Something went wrong, please try again.';
      return false;
    } else if (isSetup == false) {
      locator.get<AppPhaseCubit>().emitState(const SetUpPhase());
      return true;
    }

    // mark is set up to true
    locator.get<SharedPreferencesService>().markUserIsSetUp(true);

    _mixpanel.track(
      'Sign in',
      properties: {'Uid': _firebaseAuthService.getCurrentUserId()},
    );

    try {
      fetchLocalRepositoryData();
      fetchRepositoryData();
      locator.get<AppPhaseCubit>().emitState(const LoggedInPhase());
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
    final TurboUser? newUser = await _firebaseAuthService.setupNewUser(
      username,
      displayName,
      pdgaNumber: pdgaNumber,
    );
    if (newUser == null) {
      return false;
    }
    bool? isSetUp;

    await FBUserDataLoader.instance
        .getCurrentUser()
        .then((TurboUser? user) {
          isSetUp = userIsValid(user);
        })
        .catchError((e, trace) async {
          FirebaseCrashlytics.instance.recordError(
            e,
            trace,
            reason: '[AuthService][userIsSetup] get User timeout',
          );
        });

    if (isSetUp != true) {
      return false;
    }

    _mixpanel.track(
      'New User Set Up',
      properties: {'Uid': newUser.uid, 'Username': username},
    );

    _userRepository.currentUser = newUser;
    locator.get<AppPhaseCubit>().emitState(const LoggedInPhase());
    return true;
  }

  void signOut() {
    // clearRepositoryData();
    // locator.get<SharedPreferencesService>().markUserIsSetUp(false);
    _authRepository.signOut();
  }
}
