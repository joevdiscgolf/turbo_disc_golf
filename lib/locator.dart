import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/repositories/firebase_auth_database_repository.dart';
import 'package:turbo_disc_golf/repositories/firebase_auth_repository.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/app_phase/app_phase_controller.dart';
import 'package:turbo_disc_golf/services/auth/auth_database_service.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/courses/course_search_service.dart';
import 'package:turbo_disc_golf/services/llm/backend_llm_service.dart';
import 'package:turbo_disc_golf/services/search/course_search_provider.dart';
import 'package:turbo_disc_golf/services/search/meilisearch_provider.dart';
import 'package:turbo_disc_golf/services/search/supabase_search_provider.dart';
import 'package:turbo_disc_golf/services/search/test_course_provider.dart';
import 'package:turbo_disc_golf/services/geocoding/geocoding_service.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_rounds_repository.dart';
import 'package:turbo_disc_golf/services/firestore/fb_user_data_loader.dart';
import 'package:turbo_disc_golf/services/llm/gemini_service.dart';
import 'package:turbo_disc_golf/services/llm/chatgpt_service.dart';
import 'package:turbo_disc_golf/services/ai_generation_service.dart';
import 'package:turbo_disc_golf/services/backend_ai_generation_service.dart';
import 'package:turbo_disc_golf/services/frontend_ai_generation_service.dart';
import 'package:turbo_disc_golf/services/story_generator_service.dart';
import 'package:turbo_disc_golf/protocols/llm_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/logging/mixpanel_logging_provider.dart';
import 'package:turbo_disc_golf/services/error_logging/error_logging_service.dart';
import 'package:turbo_disc_golf/services/error_logging/firebase_crashlytics_provider.dart';
import 'package:turbo_disc_golf/services/round_analysis/disc_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/psych_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/score_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/shot_analysis_service.dart';
import 'package:turbo_disc_golf/services/form_analysis/pose_analysis_api_client.dart';
import 'package:turbo_disc_golf/services/form_analysis/video_form_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/services/rounds_service.dart';
import 'package:turbo_disc_golf/services/share_service.dart';
import 'package:turbo_disc_golf/services/shared_preferences_service.dart';
import 'package:turbo_disc_golf/services/web_scraper_service.dart';
import 'package:turbo_disc_golf/services/voice/base_voice_recording_service.dart';
import 'package:turbo_disc_golf/services/voice/ios_voice_service.dart';
import 'package:turbo_disc_golf/services/voice/speech_to_text_service.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_cubit.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/feature_flags/firebase_feature_flags_provider.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';

final locator = GetIt.instance;
Future<void> setUpLocator() async {
  await dotenv.load();
  final String? geminiApiKey = dotenv.env['GEMINI_API_KEY'];
  final String? openaiApiKey = dotenv.env['OPENAI_API_KEY'];
  final String? mixpanelToken = dotenv.env['MIXPANEL_PROJECT_TOKEN'];
  debugPrint(
    '[Locator] Mixpanel token from .env: ${mixpanelToken == null ? "NULL" : "length=${mixpanelToken.length}, first8=${mixpanelToken.length >= 8 ? mixpanelToken.substring(0, 8) : mixpanelToken}..."}',
  );

  // Initialize Supabase
  final String? supabaseUrl = dotenv.env['SUPABASE_URL'];
  final String? supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl != null && supabaseAnonKey != null) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    debugPrint('[Locator] Supabase initialized');
  } else {
    debugPrint('[Locator] Supabase not initialized - missing URL or anon key');
  }

  // Initialize Mixpanel provider
  final MixpanelLoggingProvider mixpanelProvider = MixpanelLoggingProvider();
  await mixpanelProvider.initialize(
    projectToken: mixpanelToken ?? '',
    trackAutomaticEvents: true,
  );

  // Register LoggingService with providers
  final LoggingService loggingService = LoggingService(
    providers: [mixpanelProvider],
  );
  locator.registerSingleton<LoggingService>(loggingService);

  // Register ToastService (will be initialized with overlay key from main.dart)
  locator.registerSingleton<ToastService>(ToastService());

  // Initialize Firebase Crashlytics provider
  final FirebaseCrashlyticsProvider crashlyticsProvider =
      FirebaseCrashlyticsProvider();
  await crashlyticsProvider.initialize();

  // Create and register ErrorLoggingService
  final ErrorLoggingService errorLoggingService = ErrorLoggingService(
    providers: [crashlyticsProvider],
  );
  locator.registerSingleton<ErrorLoggingService>(errorLoggingService);

  // Initialize the error logging service
  await errorLoggingService.initialize();

  // Initialize Feature Flag Service early (other services may depend on it)
  final FeatureFlagService featureFlagService = FeatureFlagService(
    provider: FirebaseFeatureFlagsProvider(),
  );
  locator.registerSingleton<FeatureFlagService>(featureFlagService);
  await featureFlagService.initialize();

  // Register core services first
  locator.registerSingleton<SharedPreferencesService>(
    SharedPreferencesService(),
  );

  // Auth / Navigation Services
  locator.registerSingleton<AuthDatabaseService>(
    AuthDatabaseService(FirebaseAuthDatabaseRepository()),
  );
  final AuthService authService = AuthService(
    FirebaseAuthRepository(),
    locator.get<AuthDatabaseService>(),
  );
  locator.registerSingleton<AuthService>(authService);

  // BagService must be registered before AppPhaseController because
  // AppPhaseController subscribes to authState immediately in its constructor,
  // and BagService also listens to authState for self-managing its lifecycle.
  locator.registerSingleton<BagService>(BagService(authService: authService));

  locator.registerSingleton(AppPhaseController(authService: authService));

  // Initialize the logging service (must be after AuthService is registered)
  await loggingService.initialize();

  // Register super properties for already logged-in users
  await _registerSuperPropertiesIfLoggedIn(authService, loggingService);

  // Round analysis - conditionally register voice service based on flag
  if (featureFlagService.useIosVoiceService) {
    locator.registerSingleton<BaseVoiceRecordingService>(
      IosVoiceService(),
      // GoogleSpeechRecordingService(),
    );
  } else {
    locator.registerSingleton<BaseVoiceRecordingService>(SpeechToTextService());
  }
  locator.registerSingleton<DiscAnalysisService>(DiscAnalysisService());
  locator.registerSingleton<MistakesAnalysisService>(MistakesAnalysisService());
  locator.registerSingleton<PsychAnalysisService>(PsychAnalysisService());
  locator.registerSingleton<PuttingAnalysisService>(PuttingAnalysisService());
  locator.registerSingleton<ScoreAnalysisService>(ScoreAnalysisService());
  locator.registerSingleton<ShotAnalysisService>(ShotAnalysisService());

  // Form Analysis Services
  locator.registerSingleton<VideoFormAnalysisService>(
    VideoFormAnalysisService(),
  );
  final String poseAnalysisUrl =
      await PoseAnalysisApiClient.getDefaultBaseUrl();
  print('pose analysis url: $poseAnalysisUrl');
  locator.registerSingleton<PoseAnalysisApiClient>(
    PoseAnalysisApiClient(baseUrl: poseAnalysisUrl),
  );
  locator.registerSingleton<FormAnalysisHistoryCubit>(
    FormAnalysisHistoryCubit(),
  );

  locator.registerSingleton<AiParsingService>(AiParsingService());

  // Register both LLM services
  locator.registerSingleton<GeminiService>(
    GeminiService(apiKey: geminiApiKey ?? ''),
  );
  locator.registerSingleton<ChatGPTService>(
    ChatGPTService(apiKey: openaiApiKey ?? ''),
  );

  // Register the LLMService based on configuration
  // This allows swapping providers via FeatureFlagService
  final LLMService storyLLMService =
      featureFlagService.storyGenerationLLMProvider == LLMProvider.chatGPT
      ? locator.get<ChatGPTService>()
      : locator.get<GeminiService>();

  locator.registerSingleton<LLMService>(storyLLMService, instanceName: 'story');

  // Register StoryGeneratorService with the configured LLM service
  locator.registerSingleton<StoryGeneratorService>(
    StoryGeneratorService(locator.get<LLMService>(instanceName: 'story')),
  );

  // Register default LLMService for general AI parsing/analysis
  // Uses defaultLLMProvider from FeatureFlagService (separate from story generation)
  final LLMService defaultLLMService =
      featureFlagService.defaultLLMProvider == LLMProvider.chatGPT
      ? locator.get<ChatGPTService>()
      : locator.get<GeminiService>();

  locator.registerSingleton<LLMService>(
    defaultLLMService,
    // No instanceName - this is the default LLMService
  );

  locator.registerSingleton<BackendLLMService>(BackendLLMService());

  // Register AIGenerationService - the single point of feature flag check.
  // This service abstracts away whether AI generation happens on backend or frontend.
  if (featureFlagService.generateAiContentFromBackend) {
    locator.registerSingleton<AIGenerationService>(
      BackendAIGenerationService(
        backendService: locator.get<BackendLLMService>(),
        storyGeneratorService: locator.get<StoryGeneratorService>(),
      ),
    );
  } else {
    locator.registerSingleton<AIGenerationService>(
      FrontendAIGenerationService(
        storyGeneratorService: locator.get<StoryGeneratorService>(),
        aiParsingService: locator.get<AiParsingService>(),
        llmService: locator.get<LLMService>(),
      ),
    );
  }

  locator.registerSingleton<RoundStorageService>(RoundStorageService());
  locator.registerSingleton<ShareService>(ShareService());
  locator.registerSingleton<WebScraperService>(WebScraperService());
  // Search provider - swap implementation via feature flags
  locator.registerLazySingleton<CourseSearchProvider>(() {
    if (featureFlagService.useTestCourseProvider) {
      return TestCourseProvider();
    } else if (featureFlagService.useSupabaseSearchProvider) {
      return SupabaseSearchProvider();
    } else {
      return MeiliSearchProvider();
    }
  });
  locator.registerLazySingleton<CourseSearchService>(
    () => CourseSearchService(),
  );
  locator.registerLazySingleton<GeocodingService>(() => GeocodingService());

  // Register RoundsService which depends on FirestoreRoundService
  locator.registerSingleton<RoundsService>(
    RoundsService(FirestoreRoundsRepository()),
  );

  // Register RoundParser which depends on other services
  locator.registerSingleton<RoundParser>(RoundParser());
}

/// Registers super properties for already logged-in users during app startup.
/// This ensures analytics context is set even when app restarts with a logged-in user.
Future<void> _registerSuperPropertiesIfLoggedIn(
  AuthService authService,
  LoggingService loggingService,
) async {
  try {
    final String? uid = authService.currentUid;
    if (uid == null || uid.isEmpty) {
      debugPrint(
        '[Locator] No user logged in - skipping super properties registration',
      );
      return;
    }

    debugPrint('[Locator] User is logged in - registering super properties');

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
    debugPrint('[Locator] Failed to register super properties: $e');
  }
}
