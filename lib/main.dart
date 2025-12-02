import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:turbo_disc_golf/firebase_options.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/app_phase_data.dart';
import 'package:turbo_disc_golf/screens/main_wrapper.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create RoundHistoryCubit first (no dependencies)
    final RoundHistoryCubit roundHistoryCubit = RoundHistoryCubit();

    final AppPhaseController appPhaseController = locator
        .get<AppPhaseController>();

    // Provide RoundParser at app level so components can listen to round changes
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoundHistoryCubit>.value(value: roundHistoryCubit),
        BlocProvider<RoundConfirmationCubit>(
          create: (_) =>
              RoundConfirmationCubit(roundHistoryCubit: roundHistoryCubit),
        ),
        BlocProvider<RoundReviewCubit>(
          create: (_) => RoundReviewCubit(roundHistoryCubit: roundHistoryCubit),
        ),
        BlocProvider<RecordRoundCubit>(create: (_) => RecordRoundCubit()),
      ],
      child: ChangeNotifierProvider<RoundParser>.value(
        value: locator.get<RoundParser>(),
        child: ListenableBuilder(
          listenable: appPhaseController,
          builder: (_, __) {
            return MaterialApp.router(
              routerConfig: createRouter(appPhaseController),
              debugShowCheckedModeBanner: false,
              title: 'Turbo Disc Golf',
              theme: kThemeData,
            );
          },
        ),
      ),
    );
  }
}

GoRouter createRouter(AppPhaseController controller) {
  return GoRouter(
    refreshListenable: controller,
    redirect: (context, state) {
      print('controller phase: ${controller.phase}');
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
      GoRoute(path: '/login', builder: (_, __) => const Scaffold()),
      // todo: implement onboarding
      GoRoute(path: '/onboarding', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/home', builder: (_, __) => const MainWrapper()),
    ],
  );
}
