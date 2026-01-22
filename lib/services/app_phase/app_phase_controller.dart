import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:turbo_disc_golf/models/data/app_phase_data.dart';
import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_app_info_data_loader.dart';
import 'package:turbo_disc_golf/services/firestore/fb_user_data_loader.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/constants/timing_constants.dart';
import 'package:turbo_disc_golf/utils/string_helpers.dart';

class AppPhaseController extends ChangeNotifier {
  final AuthService _authService;
  AppPhase _phase = AppPhase.initial;
  AppVersionInfo? _appVersionInfo;

  AppPhase get phase => _phase;
  AppVersionInfo? get appVersionInfo => _appVersionInfo;

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
    debugPrint('[AppPhaseCubit][init] 🚀 Starting initialization...');

    try {
      // Testing override: always show force upgrade screen if enabled
      final FeatureFlagService flags = locator.get<FeatureFlagService>();
      if (flags.alwaysShowForceUpgradeScreen) {
        debugPrint(
          '[AppPhaseCubit][init] Testing mode - forcing upgrade screen',
        );
        setPhase(AppPhase.forceUpgrade);
        return;
      }

      // Testing override: always show feature walkthrough if enabled
      if (flags.alwaysShowFeatureWalkthrough) {
        debugPrint(
          '[AppPhaseCubit][init] Testing mode - forcing feature walkthrough',
        );
        setPhase(AppPhase.featureWalkthrough);
        return;
      }

      // Testing override: always show onboarding if enabled
      if (flags.alwaysShowOnboarding) {
        debugPrint('[AppPhaseCubit][init] Testing mode - forcing onboarding');
        setPhase(AppPhase.onboarding);
        return;
      }

      debugPrint('[AppPhaseCubit][init] Getting package info...');
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String version = packageInfo.version;
      debugPrint('[AppPhaseCubit][init] Current app version: $version');

      final AuthUser? currentAuthUser = _authService.currentUser;
      if (currentAuthUser == null) {
        debugPrint(
          '[AppPhaseCubit][init] No auth user, setting loggedOut phase',
        );
        setPhase(AppPhase.loggedOut);
        return;
      }

      debugPrint(
        '[AppPhaseCubit][init] Auth user found: ${currentAuthUser.uid}',
      );

      TurboUser? currentTurboUser;
      AppVersionInfo? appVersionInfo;

      debugPrint(
        '[AppPhaseCubit][init] Loading app version info and current user...',
      );
      try {
        await Future.wait([
              FBAppInfoDataLoader.getAppVersionInfo(),
              FBUserDataLoader.getCurrentUser(currentAuthUser.uid),
            ])
            .then((results) {
              appVersionInfo = results[0] as AppVersionInfo?;
              currentTurboUser = results[1] as TurboUser?;
              debugPrint(
                '[AppPhaseCubit][init] Successfully loaded app version info and user',
              );
            })
            .timeout(
              tinyTimeout,
              onTimeout: () {
                debugPrint(
                  '[AppPhaseCubit][init] ⏱️ Load version info and user timed out',
                );
              },
            )
            .catchError((e, trace) {
              debugPrint('[AppPhaseCubit][init] ❌ Error loading data: $e');
              FirebaseCrashlytics.instance.recordError(
                e,
                trace,
                reason:
                    '[AppPhaseCubit][init] app version info and current user timeout',
              );
            });
      } catch (e, trace) {
        debugPrint('[AppPhaseCubit][init] ❌ Exception loading data: $e');
        FirebaseCrashlytics.instance.recordError(
          e,
          trace,
          reason:
              '[AppPhaseCubit][init] app version info and current user error',
        );
      }

      _appVersionInfo = appVersionInfo;

      debugPrint(
        '[AppPhaseCubit][init] Minimum version: ${appVersionInfo?.minimumVersion}, Current version: $version, User: ${currentTurboUser?.displayName}',
      );

      // Only trigger force upgrade if BOTH versions are valid (not null, not empty, not "unknown")
      final String? minimumVersion = appVersionInfo?.minimumVersion;
      final bool canCheckVersion =
          minimumVersion != null &&
          isValidVersionString(minimumVersion) &&
          isValidVersionString(version);

      debugPrint('[AppPhaseCubit][init] Can check version: $canCheckVersion');

      if (canCheckVersion) {
        debugPrint(
          '[AppPhaseCubit][init] Checking version: minimum $minimumVersion vs current $version',
        );
        try {
          final int minVersionNum = versionToNumber(minimumVersion);
          final int currentVersionNum = versionToNumber(version);
          debugPrint(
            '[AppPhaseCubit][init] Version numbers: min=$minVersionNum, current=$currentVersionNum',
          );

          if (minVersionNum > currentVersionNum) {
            debugPrint(
              '[AppPhaseCubit][init] ⚠️ Force upgrade required: minimum $minimumVersion > current $version',
            );
            setPhase(AppPhase.forceUpgrade);
            return;
          } else {
            debugPrint(
              '[AppPhaseCubit][init] ✅ Version check passed: current $version is acceptable',
            );
          }
        } catch (e) {
          debugPrint(
            '[AppPhaseCubit][init] ❌ Error parsing version numbers: $e',
          );
          debugPrint(
            '[AppPhaseCubit][init] Skipping version check due to parsing error',
          );
        }
      } else {
        debugPrint(
          '[AppPhaseCubit][init] ⏭️ Skipping version check - invalid version strings (minimum: $minimumVersion, current: $version)',
        );
      }

      // Start listening to disc usage stats for logged-in user
      locator.get<BagService>().startListeningToUsageStats(currentAuthUser.uid);

      final bool hasOnboarded = _authService.userHasOnboarded();
      debugPrint('[AppPhaseCubit][init] Has onboarded: $hasOnboarded');
      debugPrint(
        '[AppPhaseCubit][init] Setting phase to: ${hasOnboarded ? "home" : "onboarding"}',
      );
      setPhase(hasOnboarded ? AppPhase.home : AppPhase.onboarding);
      debugPrint('[AppPhaseCubit][init] ✅ Initialization complete');
    } catch (e, stackTrace) {
      debugPrint(
        '[AppPhaseCubit][init] ❌ FATAL ERROR during initialization: $e',
      );
      debugPrint('[AppPhaseCubit][init] Stack trace: $stackTrace');
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: '[AppPhaseCubit][init] Fatal error during initialization',
      );
      // Fallback to logged out state on fatal error
      setPhase(AppPhase.loggedOut);
    }
  }

  // called from AuthService when user marks onboarded (e.g., skip onboarding)
  void onMarkUserOnboarded() {
    setPhase(AppPhase.featureWalkthrough);
  }

  void _handleAuthStateChange(AuthUser? user) async {
    // Testing override: always show force upgrade screen if enabled
    final FeatureFlagService flags = locator.get<FeatureFlagService>();
    if (flags.alwaysShowForceUpgradeScreen) {
      setPhase(AppPhase.forceUpgrade);
      return;
    }

    // Testing override: always show feature walkthrough if enabled
    if (flags.alwaysShowFeatureWalkthrough) {
      setPhase(AppPhase.featureWalkthrough);
      return;
    }

    // Testing override: always show onboarding if enabled
    if (flags.alwaysShowOnboarding) {
      setPhase(AppPhase.onboarding);
      return;
    }

    if (user == null) {
      setPhase(AppPhase.loggedOut);
    } else {
      // Start listening to disc usage stats when user logs in
      locator.get<BagService>().startListeningToUsageStats(user.uid);

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
