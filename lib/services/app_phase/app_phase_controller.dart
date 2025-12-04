import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:turbo_disc_golf/models/data/app_phase_data.dart';
import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_app_info_data_loader.dart';
import 'package:turbo_disc_golf/services/firestore/fb_user_data_loader.dart';
import 'package:turbo_disc_golf/utils/constants/timing_constants.dart';
import 'package:turbo_disc_golf/utils/string_helpers.dart';

class AppPhaseController extends ChangeNotifier {
  final AuthService _authService;
  AppPhase _phase = AppPhase.initial;

  AppPhase get phase => _phase;

  AppPhaseController({required AuthService authService})
    : _authService = authService {
    // React to login/logout - Firebase emits immediately on subscription
    _authService.authState
        .distinct((previous, next) {
          // Only emit when the user ID changes (handles login, logout, user switch)
          return previous?.uid == next?.uid;
        })
        .listen(_handleAuthStateChange);
  }

  Future<void> initialize() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String version = packageInfo.version;

    String? minimumVersion;

    final AuthUser? currentAuthUser = _authService.getCurrentUser();
    if (currentAuthUser == null) {
      setPhase(AppPhase.loggedOut);
      return;
    }

    TurboUser? currentTurboUser;

    debugPrint(
      '[AppPhaseCubit][init] loading minimum version and current user...',
    );
    try {
      await Future.wait([
            FBAppInfoDataLoader.getMinimumAppVersion(),
            FBUserDataLoader.getCurrentUser(currentAuthUser.uid),
          ])
          .then((results) {
            minimumVersion = results[0] as String?;
            currentTurboUser = results[1] as TurboUser?;
          })
          .timeout(
            tinyTimeout,
            onTimeout: () {
              debugPrint(
                '[AppPhaseCubit][init] load version and user on timeout',
              );
            },
          )
          .catchError((e, trace) {
            FirebaseCrashlytics.instance.recordError(
              e,
              trace,
              reason:
                  '[AppPhaseCubit][init] minimum version and current user timeout',
            );
          });
    } catch (e, trace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason:
            '[AppPhaseCubit][init] minimum version and current user timeout',
      );
    }

    debugPrint(
      '[AppPhaseCubit][init] minimum version: $minimumVersion, current user: $currentTurboUser',
    );

    if (minimumVersion != null &&
        versionToNumber(minimumVersion!) > versionToNumber(version)) {
      setPhase(AppPhase.forceUpgrade);

      return;
    }

    final bool hasOnboarded = _authService.userHasOnboarded();
    setPhase(hasOnboarded ? AppPhase.home : AppPhase.onboarding);
  }

  // called from AuthService
  void onMarkUserOnboarded() {
    setPhase(AppPhase.home);
  }

  void _handleAuthStateChange(AuthUser? user) async {
    if (user == null) {
      setPhase(AppPhase.loggedOut);
    } else {
      final hasOnboarded = _authService.userHasOnboarded();

      if (hasOnboarded) {
        setPhase(AppPhase.home);
      } else {
        setPhase(AppPhase.onboarding);
      }
    }
  }

  void setPhase(AppPhase newPhase) {
    if (newPhase == _phase) return;
    _phase = newPhase;
    notifyListeners(); // GoRouter reacts to this
  }
}
