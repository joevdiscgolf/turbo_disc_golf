import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:turbo_disc_golf/firebase_options.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/app_phase_data.dart';
import 'package:turbo_disc_golf/screens/auth/login_screen.dart';
import 'package:turbo_disc_golf/screens/main_wrapper.dart';
import 'package:turbo_disc_golf/screens/onboarding/onboarding_screen.dart';
import 'package:turbo_disc_golf/services/app_phase/app_phase_controller.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setUpLocator();

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

  @override
  void initState() {
    super.initState();

    // Create router once
    final AppPhaseController appPhaseController = locator
        .get<AppPhaseController>();
    _router = createRouter(appPhaseController);

    // Create cubit once
    _roundHistoryCubit = RoundHistoryCubit();
  }

  @override
  void dispose() {
    _roundHistoryCubit.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provide RoundParser at app level so components can listen to round changes
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoundHistoryCubit>.value(value: _roundHistoryCubit),
        BlocProvider<RoundConfirmationCubit>(
          create: (_) =>
              RoundConfirmationCubit(roundHistoryCubit: _roundHistoryCubit),
        ),
        BlocProvider<RoundReviewCubit>(
          create: (_) =>
              RoundReviewCubit(roundHistoryCubit: _roundHistoryCubit),
        ),
        BlocProvider<RecordRoundCubit>(create: (_) => RecordRoundCubit()),
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
        case AppPhase.loading:
          return '/loading';

        case AppPhase.loggedOut:
          return '/login';

        case AppPhase.onboarding:
          return '/onboarding';

        case AppPhase.home:
          return '/home';
      }
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, __) => const Scaffold(body: Text('Loading')),
      ),
      // todo: implement login
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      // todo: implement onboarding
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/home', builder: (_, __) => const MainWrapper()),
    ],
  );
}
