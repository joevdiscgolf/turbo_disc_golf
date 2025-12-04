import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:turbo_disc_golf/repositories/firebase_auth_database_repository.dart';
import 'package:turbo_disc_golf/repositories/firebase_auth_repository.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/app_phase/app_phase_controller.dart';
import 'package:turbo_disc_golf/services/auth/auth_database_service.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_rounds_repository.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/disc_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/psych_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/score_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/shot_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/services/rounds_service.dart';
import 'package:turbo_disc_golf/services/shared_preferences_service.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';

final locator = GetIt.instance;
Future<void> setUpLocator() async {
  await dotenv.load();
  final String? geminiApiKey = dotenv.env['GEMINI_API_KEY'];
  // Register core services first
  locator.registerSingleton<SharedPreferencesService>(
    SharedPreferencesService(),
  );

  // Auth / Navigation Services
  final AuthDatabaseService authDatabaseService = AuthDatabaseService(
    FirebaseAuthDatabaseRepository(),
  );
  final AuthService authService = AuthService(
    FirebaseAuthRepository(),
    authDatabaseService,
  );
  locator.registerSingleton<AuthService>(authService);
  locator.registerSingleton(AppPhaseController(authService: authService));

  // Round analysis
  locator.registerSingleton<VoiceRecordingService>(VoiceRecordingService());
  locator.registerSingleton<DiscAnalysisService>(DiscAnalysisService());
  locator.registerSingleton<MistakesAnalysisService>(MistakesAnalysisService());
  locator.registerSingleton<PsychAnalysisService>(PsychAnalysisService());
  locator.registerSingleton<PuttingAnalysisService>(PuttingAnalysisService());
  locator.registerSingleton<ScoreAnalysisService>(ScoreAnalysisService());
  locator.registerSingleton<ShotAnalysisService>(ShotAnalysisService());

  locator.registerSingleton<AiParsingService>(AiParsingService());
  locator.registerSingleton<GeminiService>(
    GeminiService(apiKey: geminiApiKey ?? ''),
  );
  locator.registerSingleton<BagService>(BagService());
  locator.registerSingleton<RoundStorageService>(RoundStorageService());

  // Register RoundsService which depends on FirestoreRoundService
  locator.registerSingleton<RoundsService>(
    RoundsService(FirestoreRoundsRepository()),
  );

  // Register RoundParser which depends on other services
  locator.registerSingleton<RoundParser>(RoundParser());
}
