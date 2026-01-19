import 'dart:io';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/app_phase_data.dart';
import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/models/data/user_data/pdga_metadata.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/repositories/auth_repository.dart';
import 'package:turbo_disc_golf/services/app_phase/app_phase_controller.dart';
import 'package:turbo_disc_golf/services/auth/auth_database_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_user_data_loader.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/logout_manager.dart';

class AuthService {
  final AuthRepository _authRepository;
  final AuthDatabaseService _authDatabaseService;

  AuthService(this._authRepository, this._authDatabaseService);

  Stream<AuthUser?> get authState => _authRepository.authStateChanges();

  Future<bool> isLoggedIn() async => _authRepository.getCurrentUser() != null;

  Future<void> login(String email, String password) =>
      _authRepository.signInWithEmailPassword(email, password);

  Future<void> logout() async {
    // Clear all component state before Firebase logout
    await locator.get<LogoutManager>().clearAll();

    // Then perform Firebase logout
    await _authRepository.signOut();
  }

  AuthUser? get currentUser => _authRepository.getCurrentUser();

  String? get currentUid => _authRepository.getCurrentUser()?.uid;

  bool userHasOnboarded() {
    return _authRepository.userHasOnboarded();
  }

  Future<bool> markUserOnboarded() async {
    final bool markUserOnboardedSuccess = await _authRepository
        .markUserOnboarded();

    if (markUserOnboardedSuccess) {
      locator.get<AppPhaseController>().onMarkUserOnboarded();
    }

    return markUserOnboardedSuccess;
  }

  String errorMessage = '';

  Future<bool> deleteCurrentUser() {
    return _authRepository.deleteCurrentUser();
  }

  /// Identifies user in logging service and registers super properties.
  /// Called after successful login to set up analytics context.
  Future<void> _setupLoggingForUser(String uid) async {
    try {
      final LoggingService loggingService = locator.get<LoggingService>();

      // Identify the user
      await loggingService.identify(uid);

      // Fetch user data for super properties
      final TurboUser? user = await FBUserDataLoader.getCurrentUser(uid);
      if (user != null) {
        await loggingService.registerSuperProperties({
          'is_admin': user.isAdmin ?? false,
          'has_pdga_number': user.pdgaMetadata?.pdgaNum != null,
          'platform': Platform.isIOS ? 'iOS' : 'Android',
        });
      } else {
        // Register basic super properties even if user data not available
        await loggingService.registerSuperProperties({
          'is_admin': false,
          'has_pdga_number': false,
          'platform': Platform.isIOS ? 'iOS' : 'Android',
        });
      }
    } catch (e) {
      debugPrint('[AuthService] Failed to setup logging for user: $e');
    }
  }

  Future<bool> attemptSignUpWithEmail(String email, String password) async {
    final bool signUpSuccess = await _authRepository.signUpWithEmailPassword(
      email,
      password,
    );

    debugPrint('[attemptSignUpWithEmail] signUpSuccess: $signUpSuccess');

    if (!signUpSuccess || currentUser == null) {
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

    final AuthUser? authUser = currentUser;
    if (authUser == null) return false;

    // Setup logging after successful login
    await _setupLoggingForUser(authUser.uid);

    // AppPhaseController._handleAuthStateChange() handles routing based on userHasOnboarded()
    return true;
  }

  Future<bool> attemptSignInWithGoogle() async {
    final bool signInSuccess =
        await _authRepository.signInWithGoogle() ?? false;

    if (!signInSuccess) {
      errorMessage = _authRepository.exceptionMessage.isNotEmpty
          ? _authRepository.exceptionMessage
          : 'Google sign-in failed or was cancelled.';
      return false;
    }

    final AuthUser? authUser = currentUser;
    if (authUser == null) return false;

    // Setup logging after successful login
    await _setupLoggingForUser(authUser.uid);

    // AppPhaseController._handleAuthStateChange() handles routing based on userHasOnboarded()
    return true;
  }

  Future<bool> attemptSignInWithApple() async {
    final bool signInSuccess = await _authRepository.signInWithApple() ?? false;

    if (!signInSuccess) {
      errorMessage = _authRepository.exceptionMessage.isNotEmpty
          ? _authRepository.exceptionMessage
          : 'Apple sign-in failed or was cancelled.';
      return false;
    }

    final AuthUser? authUser = currentUser;
    if (authUser == null) return false;

    // Setup logging after successful login
    await _setupLoggingForUser(authUser.uid);

    // AppPhaseController._handleAuthStateChange() handles routing based on userHasOnboarded()
    return true;
  }

  Future<bool> setupNewUser(
    String username, {
    PDGAMetadata? pdgaMetadata,
  }) async {
    final AuthUser? authUser = currentUser;
    if (authUser == null) return false;

    // Use username as displayName
    final String displayName = username;

    final TurboUser? newUser = await _authDatabaseService
        .setUpNewUserInDatabase(
          authUser,
          username,
          displayName,
          pdgaMetadata: pdgaMetadata,
        );

    if (newUser == null) {
      return false;
    }

    // Mark onboarding complete NOW (persists the has_onboarded flag)
    await _authRepository.markUserOnboarded();

    // Go to feature walkthrough (not home) for first-time users
    locator.get<AppPhaseController>().setPhase(AppPhase.featureWalkthrough);

    // Setup logging after successful onboarding
    await _setupLoggingForUser(authUser.uid);

    return true;
  }
}
