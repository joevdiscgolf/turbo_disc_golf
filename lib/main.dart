import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:turbo_disc_golf/firebase_options.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/app_phase_data.dart';
import 'package:turbo_disc_golf/observers/status_bar_observer.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/screens/auth/landing_screen.dart';
import 'package:turbo_disc_golf/screens/connection_required/connection_required_screen.dart';
import 'package:turbo_disc_golf/screens/force_upgrade/force_upgrade_screen.dart';
import 'package:turbo_disc_golf/screens/main_wrapper.dart';
import 'package:turbo_disc_golf/screens/onboarding/feature_walkthrough/feature_walkthrough_screen.dart';
import 'package:turbo_disc_golf/screens/onboarding/onboarding_screen.dart';
import 'package:turbo_disc_golf/services/animation_state_service.dart';
import 'package:turbo_disc_golf/services/app_phase/app_phase_controller.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/courses/course_search_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_pro_players_loader.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/logout_manager.dart';
import 'package:turbo_disc_golf/services/voice/base_voice_recording_service.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/services/form_analysis/video_form_analysis_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/state/create_course_cubit.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/state/round_confirmation_cubit.dart';
import 'package:turbo_disc_golf/state/round_history_cubit.dart';
import 'package:turbo_disc_golf/state/round_review_cubit.dart';
import 'package:turbo_disc_golf/state/user_data_cubit.dart';
import 'package:turbo_disc_golf/utils/theme/theme_data.dart';
import 'package:wiredash/wiredash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style - dark icons for light background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Dark icons for Android
      statusBarBrightness: Brightness.light, // Dark text for iOS
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Use Firebase Functions emulator on simulators/emulators only
  if (kDebugMode && !await _isPhysicalDevice()) {
    FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
  }

  await setUpLocator();

  await locator.get<AppPhaseController>().initialize();
  await locator.get<BaseVoiceRecordingService>().initialize();

  // Pre-fetch pro players config for faster form analysis loading
  // Disable retry at startup to avoid blocking; retry happens when screen opens
  FBProPlayersLoader.getProPlayersConfig(withRetry: false);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();
  late final GoRouter _router;
  late final RoundHistoryCubit _roundHistoryCubit;
  late final RoundConfirmationCubit _roundConfirmationCubit;
  late final RoundReviewCubit _roundReviewCubit;
  late final RecordRoundCubit _recordRoundCubit;
  late final CreateCourseCubit _createCourseCubit;
  late final UserDataCubit _userDataCubit;

  @override
  void initState() {
    super.initState();

    // Initialize ToastService with overlay key
    locator.get<ToastService>().initialize(_overlayKey);

    // Create router once
    final AppPhaseController appPhaseController = locator
        .get<AppPhaseController>();
    _router = createRouter(appPhaseController);

    // Create cubits once
    _roundHistoryCubit = RoundHistoryCubit();
    _recordRoundCubit = RecordRoundCubit();
    _roundConfirmationCubit = RoundConfirmationCubit(
      roundHistoryCubit: _roundHistoryCubit,
      recordRoundCubit: _recordRoundCubit,
    );
    _roundReviewCubit = RoundReviewCubit(roundHistoryCubit: _roundHistoryCubit);
    _createCourseCubit = CreateCourseCubit();
    _userDataCubit = UserDataCubit();
    // Load user data on app startup (fire and forget)
    _userDataCubit.loadUserData();

    // Centralized list of ALL components (cubits + services) that need logout cleanup
    final List<ClearOnLogoutProtocol> clearOnLogoutComponents = [
      // Cubits
      _roundHistoryCubit,
      _roundConfirmationCubit,
      _roundReviewCubit,
      _recordRoundCubit,
      _userDataCubit,

      // Services from locator
      locator.get<RoundParser>(),
      locator.get<BagService>(),
      locator.get<BaseVoiceRecordingService>(),
      locator.get<CourseSearchService>(),
      locator.get<VideoFormAnalysisService>(),
      locator.get<LoggingService>(),
      AnimationStateService.instance,
    ];

    // Register LogoutManager with service locator
    locator.registerSingleton<LogoutManager>(
      LogoutManager(components: clearOnLogoutComponents),
    );
  }

  @override
  void dispose() {
    _roundHistoryCubit.close();
    _roundConfirmationCubit.close();
    _roundReviewCubit.close();
    _recordRoundCubit.close();
    _userDataCubit.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Global Overlay for toast notifications above the entire app
    // Directionality is required since Overlay is outside MaterialApp
    // WidgetsApp provides WidgetsLocalizations needed by TextField's context menu
    return Directionality(
      textDirection: TextDirection.ltr,
      child: WidgetsApp(
        color: Colors.white,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => Overlay(
          key: _overlayKey,
          initialEntries: [
            OverlayEntry(
              builder: (BuildContext context) => MultiBlocProvider(
                providers: [
                  BlocProvider<RoundHistoryCubit>.value(
                    value: _roundHistoryCubit,
                  ),
                  BlocProvider<RoundConfirmationCubit>.value(
                    value: _roundConfirmationCubit,
                  ),
                  BlocProvider<RoundReviewCubit>.value(
                    value: _roundReviewCubit,
                  ),
                  BlocProvider<RecordRoundCubit>.value(
                    value: _recordRoundCubit,
                  ),
                  BlocProvider<CreateCourseCubit>.value(
                    value: _createCourseCubit,
                  ),
                  BlocProvider<UserDataCubit>.value(value: _userDataCubit),
                ],
                child: ChangeNotifierProvider<RoundParser>.value(
                  value: locator.get<RoundParser>(),
                  child: Wiredash(
                    projectId: dotenv.env['WIREDASH_PROJECT_ID'] ?? '',
                    secret: dotenv.env['WIREDASH_SECRET'] ?? '',
                    child: MaterialApp.router(
                      routerConfig: _router,
                      debugShowCheckedModeBanner: false,
                      title: 'Turbo Disc Golf',
                      theme: kThemeData,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

GoRouter createRouter(AppPhaseController controller) {
  return GoRouter(
    refreshListenable: controller,
    observers: [StatusBarObserver()],
    redirect: (context, state) {
      switch (controller.phase) {
        case AppPhase.initial:
          return '/initial';

        case AppPhase.loggedOut:
          return '/login';

        case AppPhase.onboarding:
          return '/onboarding';

        case AppPhase.featureWalkthrough:
          return '/feature_walkthrough';

        case AppPhase.home:
          return '/home';

        case AppPhase.forceUpgrade:
          return '/force_upgrade';

        case AppPhase.connectionRequired:
          return '/connection_required';
      }
    },
    routes: [
      GoRoute(
        path: '/initial',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: Text('Initial')),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0), // Slide from right
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LandingScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0), // Slide from right
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/feature_walkthrough',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FeatureWalkthroughScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0), // Slide from right
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainWrapper(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0), // Slide from right
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/force_upgrade',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForceUpgradeScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/connection_required',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConnectionRequiredScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
    ],
  );
}

Future<bool> _isPhysicalDevice() async {
  if (Platform.isIOS) {
    final IosDeviceInfo info = await DeviceInfoPlugin().iosInfo;
    return info.isPhysicalDevice;
  }
  if (Platform.isAndroid) {
    final AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
    return info.isPhysicalDevice;
  }
  return false;
}
