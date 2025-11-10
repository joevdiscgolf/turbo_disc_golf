import 'package:get_it/get_it.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';
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
import 'package:turbo_disc_golf/services/voice_recording_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final locator = GetIt.instance;
Future<void> setUpLocator() async {
  await dotenv.load();
  final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
  // Register core services first

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
  locator.registerSingleton<FirestoreRoundService>(FirestoreRoundService());

  // Register RoundsService which depends on FirestoreRoundService
  locator.registerSingleton<RoundsService>(
    RoundsService(locator.get<FirestoreRoundService>()),
  );

  // Register RoundParser which depends on other services
  locator.registerSingleton<RoundParser>(RoundParser());
}
