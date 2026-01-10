import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:turbo_disc_golf/firebase_options.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/app_phase_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/screens/auth/landing_screen.dart';
import 'package:turbo_disc_golf/screens/main_wrapper.dart';
import 'package:turbo_disc_golf/screens/onboarding/onboarding_screen.dart';
import 'package:turbo_disc_golf/services/animation_state_service.dart';
import 'package:turbo_disc_golf/services/app_phase/app_phase_controller.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/courses/course_search_service.dart';
import 'package:turbo_disc_golf/services/logout_manager.dart';
import 'package:turbo_disc_golf/services/voice/base_voice_recording_service.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/state/create_course_cubit.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/state/round_confirmation_cubit.dart';
import 'package:turbo_disc_golf/state/round_history_cubit.dart';
import 'package:turbo_disc_golf/state/round_review_cubit.dart';
import 'package:turbo_disc_golf/utils/theme/theme_data.dart';

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
  await setUpLocator();

  await locator.get<AppPhaseController>().initialize();
  await locator.get<BaseVoiceRecordingService>().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  late final RoundHistoryCubit _roundHistoryCubit;
  late final RoundConfirmationCubit _roundConfirmationCubit;
  late final RoundReviewCubit _roundReviewCubit;
  late final RecordRoundCubit _recordRoundCubit;
  late final CreateCourseCubit _createCourseCubit;

  @override
  void initState() {
    super.initState();

    // Create router once
    final AppPhaseController appPhaseController = locator
        .get<AppPhaseController>();
    _router = createRouter(appPhaseController);

    // Create cubits once
    _roundHistoryCubit = RoundHistoryCubit();
    _roundConfirmationCubit = RoundConfirmationCubit(
      roundHistoryCubit: _roundHistoryCubit,
    );
    _roundReviewCubit = RoundReviewCubit(roundHistoryCubit: _roundHistoryCubit);
    // Warm up voice recognition (fire and forget - don't block app startup)
    _recordRoundCubit = RecordRoundCubit();
    _createCourseCubit = CreateCourseCubit();

    // Centralized list of ALL components (cubits + services) that need logout cleanup
    final List<ClearOnLogoutProtocol> clearOnLogoutComponents = [
      // Cubits
      _roundHistoryCubit,
      _roundConfirmationCubit,
      _roundReviewCubit,
      _recordRoundCubit,

      // Services from locator
      locator.get<RoundParser>(),
      locator.get<BagService>(),
      locator.get<RoundStorageService>(),
      locator.get<BaseVoiceRecordingService>(),
      locator.get<CourseSearchService>(),
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
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provide RoundParser at app level so components can listen to round changes
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoundHistoryCubit>.value(value: _roundHistoryCubit),
        BlocProvider<RoundConfirmationCubit>.value(
          value: _roundConfirmationCubit,
        ),
        BlocProvider<RoundReviewCubit>.value(value: _roundReviewCubit),
        BlocProvider<RecordRoundCubit>.value(value: _recordRoundCubit),
        BlocProvider<CreateCourseCubit>.value(value: _createCourseCubit),
      ],
      child: ChangeNotifierProvider<RoundParser>.value(
        value: locator.get<RoundParser>(),
        child: MaterialApp.router(
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          title: 'Turbo Disc Golf',
          theme: kThemeData,
        ),
      ),
    );
  }
}

GoRouter createRouter(AppPhaseController controller) {
  return GoRouter(
    refreshListenable: controller,
    redirect: (context, state) {
      switch (controller.phase) {
        case AppPhase.initial:
          return '/initial';

        case AppPhase.loggedOut:
          return '/login';

        case AppPhase.onboarding:
          return '/onboarding';

        case AppPhase.home:
          return '/home';

        case AppPhase.forceUpgrade:
          return '/force_upgrade';
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
      // todo: implement onboarding
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
          child: const Scaffold(body: Center(child: Text('Force upgrade'))),
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
    ],
  );
}
