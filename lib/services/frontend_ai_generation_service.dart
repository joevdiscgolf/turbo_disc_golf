import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/protocols/llm_service.dart';
import 'package:turbo_disc_golf/services/ai_generation_service.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/judgment_prompt_service.dart';
import 'package:turbo_disc_golf/services/story_generator_service.dart';

/// Frontend implementation of [AIGenerationService].
///
/// Uses local LLM services (ChatGPT/Gemini) for AI generation. Handles all
/// retry logic and YAML parsing on the client side.
///
/// This is the fallback implementation when backend cloud functions are disabled.
class FrontendAIGenerationService implements AIGenerationService {
  final StoryGeneratorService _storyGeneratorService;
  final AiParsingService _aiParsingService;
  final LLMService _llmService;

  FrontendAIGenerationService({
    required StoryGeneratorService storyGeneratorService,
    required AiParsingService aiParsingService,
    required LLMService llmService,
  })  : _storyGeneratorService = storyGeneratorService,
        _aiParsingService = aiParsingService,
        _llmService = llmService;

  @override
  Future<AIContent?> generateRoundStory({
    required DGRound round,
    required RoundAnalysis analysis,
  }) async {
    // Select story version based on feature flags
    final FeatureFlagService flags = locator.get<FeatureFlagService>();

    if (flags.storyV3Enabled) {
      return generateRoundStoryV3(round: round, analysis: analysis);
    } else if (flags.storyV2Enabled) {
      debugPrint(
        '[FrontendAIGenerationService] Generating V2 story via local LLM...',
      );
      return _storyGeneratorService.generateRoundStoryV2(round);
    } else {
      debugPrint(
        '[FrontendAIGenerationService] Generating V1 story via local LLM...',
      );
      return _storyGeneratorService.generateRoundStory(round);
    }
  }

  @override
  Future<AIContent?> generateRoundStoryV3({
    required DGRound round,
    required RoundAnalysis analysis,
  }) async {
    debugPrint(
      '[FrontendAIGenerationService] Generating V3 story via local LLM...',
    );

    // Delegate to the existing StoryGeneratorService which handles retries
    // and parsing internally
    return _storyGeneratorService.generateRoundStoryV3(round);
  }

  @override
  Future<PotentialDGRound?> parseRoundDescription({
    required String voiceTranscript,
    required List<DGDisc> userBag,
    Course? course,
    String? layoutId,
    int numHoles = 18,
    List<HoleMetadata>? preParsedHoles,
  }) async {
    debugPrint(
      '[FrontendAIGenerationService] Parsing round via local LLM...',
    );

    // Delegate to the existing AiParsingService
    return _aiParsingService.parseRoundDescriptionLocal(
      voiceTranscript: voiceTranscript,
      userBag: userBag,
      course: course,
      layoutId: layoutId,
      numHoles: numHoles,
      preParsedHoles: preParsedHoles,
    );
  }

  @override
  Future<String?> generateRoundJudgment({
    required DGRound round,
    required RoundAnalysis analysis,
    required bool shouldGlaze,
  }) async {
    debugPrint(
      '[FrontendAIGenerationService] Generating judgment via local LLM...',
    );

    try {
      // Build the prompt
      final JudgmentPromptService promptService = JudgmentPromptService();
      final String prompt = promptService.buildJudgmentPrompt(
        round,
        shouldGlaze,
      );

      // Generate content using the LLM
      final String? judgment = await _llmService.generateContent(
        prompt: prompt,
        useFullModel: true,
      );

      if (judgment == null) {
        debugPrint('[FrontendAIGenerationService] LLM returned null judgment');
        return null;
      }

      // Clean up the response - remove markdown code blocks if present
      return _cleanYamlResponse(judgment);
    } catch (e, stackTrace) {
      debugPrint(
        '[FrontendAIGenerationService] Error generating judgment: $e',
      );
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  /// Removes markdown code block wrappers from YAML responses.
  String _cleanYamlResponse(String response) {
    String cleaned = response.trim();

    if (cleaned.startsWith('```yaml') || cleaned.startsWith('```YAML')) {
      cleaned = cleaned.substring(cleaned.indexOf('\n') + 1);
    }
    if (cleaned.startsWith('yaml\n') || cleaned.startsWith('YAML\n')) {
      cleaned = cleaned.substring(5);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3).trim();
    }

    return cleaned;
  }
}
