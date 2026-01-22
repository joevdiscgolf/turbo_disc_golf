import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/endpoints/ai_endpoints.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/ai_generation_service.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/llm/backend_llm_service.dart';
import 'package:turbo_disc_golf/services/story_generator_service.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

/// Backend implementation of [AIGenerationService].
///
/// Uses Firebase Cloud Functions for AI generation. When the backend returns
/// pre-parsed content (aiContent or parsedData fields), uses it directly.
/// Falls back to local YAML parsing when backend returns only rawResponse.
class BackendAIGenerationService implements AIGenerationService {
  final BackendLLMService _backendService;
  final StoryGeneratorService _storyGeneratorService;

  static const _uuid = Uuid();

  BackendAIGenerationService({
    required BackendLLMService backendService,
    required StoryGeneratorService storyGeneratorService,
  })  : _backendService = backendService,
        _storyGeneratorService = storyGeneratorService;

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
      // For V2, fall back to local generation via StoryGeneratorService
      debugPrint(
        '[BackendAIGenerationService] V2 story requested, using local generation',
      );
      return _storyGeneratorService.generateRoundStoryV2(round);
    } else {
      // For V1, fall back to local generation via StoryGeneratorService
      debugPrint(
        '[BackendAIGenerationService] V1 story requested, using local generation',
      );
      return _storyGeneratorService.generateRoundStory(round);
    }
  }

  @override
  Future<AIContent?> generateRoundStoryV3({
    required DGRound round,
    required RoundAnalysis analysis,
  }) async {
    try {
      debugPrint(
        '[BackendAIGenerationService] Generating V3 story via backend...',
      );

      final GenerateRoundStoryRequest request = GenerateRoundStoryRequest(
        round: round,
        analysis: analysis,
      );

      final GenerateRoundStoryResponse? response =
          await _backendService.generateRoundStory(request: request);

      if (response == null) {
        debugPrint('[BackendAIGenerationService] Backend returned null');
        return null;
      }

      if (!response.success) {
        debugPrint(
          '[BackendAIGenerationService] Backend error: ${response.data.error}',
        );
        return null;
      }

      // If backend returned pre-parsed aiContent, use it directly
      if (response.data.aiContent != null) {
        debugPrint(
          '[BackendAIGenerationService] Using pre-parsed aiContent from backend',
        );
        return response.data.aiContent;
      }

      // Fall back to local parsing of rawResponse
      debugPrint(
        '[BackendAIGenerationService] Backend returned rawResponse, parsing locally',
      );
      return _storyGeneratorService.parseStoryV3Response(
        response.data.rawResponse,
        round,
      );
    } catch (e, stackTrace) {
      debugPrint('[BackendAIGenerationService] Error generating story: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
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
    try {
      debugPrint(
        '[BackendAIGenerationService] Parsing round description via backend...',
      );

      final ParseRoundDataRequest request = ParseRoundDataRequest(
        voiceTranscript: voiceTranscript,
        userBag: userBag,
        courseName: course?.name,
      );

      final ParseRoundDataResponse? response =
          await _backendService.parseRoundData(request: request);

      if (response == null) {
        debugPrint('[BackendAIGenerationService] Backend returned null');
        return null;
      }

      if (!response.success) {
        debugPrint(
          '[BackendAIGenerationService] Backend error: ${response.data.error}',
        );
        return null;
      }

      Map<String, dynamic> jsonMap;

      // If backend returned pre-parsed data, use it directly
      if (response.data.parsedData != null) {
        debugPrint(
          '[BackendAIGenerationService] Using pre-parsed data from backend',
        );
        jsonMap = response.data.parsedData!;
      } else {
        // Fall back to local parsing of rawResponse
        debugPrint(
          '[BackendAIGenerationService] Backend returned rawResponse, parsing locally',
        );
        jsonMap = _parseRoundYaml(response.data.rawResponse);
      }

      // Add required fields not from AI response
      jsonMap['uid'] = locator.get<AuthService>().currentUid ?? '';
      jsonMap['id'] = _uuid.v4();
      jsonMap['courseName'] = course?.name;
      jsonMap['courseId'] = course?.id;
      jsonMap['course'] = course?.toJson();
      jsonMap['layoutId'] = layoutId ?? course?.defaultLayout.id;

      final PotentialDGRound potentialRound = PotentialDGRound.fromJson(
        jsonMap,
      );

      return _fillMissingHoles(potentialRound, numHoles);
    } catch (e, stackTrace) {
      debugPrint(
        '[BackendAIGenerationService] Error parsing round description: $e',
      );
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  @override
  Future<String?> generateRoundJudgment({
    required DGRound round,
    required RoundAnalysis analysis,
    required bool shouldGlaze,
  }) async {
    try {
      debugPrint(
        '[BackendAIGenerationService] Generating judgment via backend...',
      );

      final GenerateRoundJudgmentRequest request = GenerateRoundJudgmentRequest(
        round: round,
        analysis: analysis,
        shouldGlaze: shouldGlaze,
      );

      final GenerateRoundJudgmentResponse? response =
          await _backendService.generateRoundJudgment(request: request);

      if (response == null) {
        debugPrint('[BackendAIGenerationService] Backend returned null');
        return null;
      }

      if (!response.success) {
        debugPrint(
          '[BackendAIGenerationService] Backend error: ${response.data.error}',
        );
        return null;
      }

      // If backend returned pre-parsed aiContent, extract the content string
      if (response.data.aiContent != null) {
        debugPrint(
          '[BackendAIGenerationService] Using pre-parsed judgment from backend',
        );
        return response.data.aiContent!.content;
      }

      // Use the raw response
      debugPrint(
        '[BackendAIGenerationService] Using rawResponse from backend',
      );
      return _cleanYamlResponse(response.data.rawResponse);
    } catch (e, stackTrace) {
      debugPrint('[BackendAIGenerationService] Error generating judgment: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  /// Parse YAML response from backend into a JSON map.
  Map<String, dynamic> _parseRoundYaml(String responseText) {
    // Clean up the response - remove markdown code blocks if present
    String cleaned = responseText.trim();

    if (cleaned.startsWith('```yaml') || cleaned.startsWith('```YAML')) {
      cleaned = cleaned.substring(cleaned.indexOf('\n') + 1);
    }
    if (cleaned.startsWith('yaml\n') || cleaned.startsWith('YAML\n')) {
      cleaned = cleaned.substring(5);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3).trim();
    }

    // Sanitize YAML to fix common AI formatting issues
    cleaned = _sanitizeYaml(cleaned);

    // Parse the YAML response
    final dynamic yamlDoc = loadYaml(cleaned);

    // Convert YamlMap to regular Map<String, dynamic>
    return json.decode(json.encode(yamlDoc)) as Map<String, dynamic>;
  }

  /// Sanitizes YAML to fix common AI-generated formatting issues.
  String _sanitizeYaml(String yaml) {
    // Fix: notes field with comma-separated strings instead of single string
    final RegExp notesPattern = RegExp(
      r'notes:\s*"([^"]+)"(?:\s*,\s*"([^"]+)")+',
      multiLine: true,
    );

    yaml = yaml.replaceAllMapped(notesPattern, (match) {
      final String fullMatch = match.group(0)!;
      final Iterable<RegExpMatch> allQuotes =
          RegExp(r'"([^"]+)"').allMatches(fullMatch);
      final List<String> values = allQuotes.map((m) => m.group(1)!).toList();
      final String combinedValue = values.join(', ');
      return 'notes: "$combinedValue"';
    });

    return yaml;
  }

  /// Fill in missing holes in the sequence from 1 to numHoles.
  PotentialDGRound _fillMissingHoles(PotentialDGRound round, int numHoles) {
    if (round.holes == null || round.holes!.isEmpty) {
      final List<PotentialDGHole> emptyHoles = List.generate(
        numHoles,
        (index) => PotentialDGHole(
          number: index + 1,
          par: null,
          feet: null,
          throws: [],
          holeType: null,
        ),
      );
      return PotentialDGRound(
        uid: round.uid,
        id: round.id,
        courseId: round.courseId,
        courseName: round.courseName,
        holes: emptyHoles,
        analysis: round.analysis,
        aiSummary: round.aiSummary,
        aiCoachSuggestion: round.aiCoachSuggestion,
        versionId: round.versionId,
        createdAt: round.createdAt,
        playedRoundAt: round.playedRoundAt,
      );
    }

    final int maxParsedHoleNumber = round.holes!
        .where((h) => h.number != null)
        .map((h) => h.number!)
        .fold(0, (max, n) => n > max ? n : max);

    final int maxHoleNumber =
        maxParsedHoleNumber > numHoles ? maxParsedHoleNumber : numHoles;

    final Set<int> existingHoles = round.holes!
        .where((h) => h.number != null)
        .map((h) => h.number!)
        .toSet();

    final Set<int> missingHoles = {};
    for (int i = 1; i <= maxHoleNumber; i++) {
      if (!existingHoles.contains(i)) {
        missingHoles.add(i);
      }
    }

    if (missingHoles.isEmpty) {
      return round;
    }

    final List<PotentialDGHole> completeHoles = List.from(round.holes!);

    for (final int holeNumber in missingHoles) {
      final PotentialDGHole emptyHole = PotentialDGHole(
        number: holeNumber,
        par: null,
        feet: null,
        throws: [],
        holeType: null,
      );

      int insertIndex = completeHoles.length;
      for (int i = 0; i < completeHoles.length; i++) {
        if (completeHoles[i].number != null &&
            completeHoles[i].number! > holeNumber) {
          insertIndex = i;
          break;
        }
      }

      completeHoles.insert(insertIndex, emptyHole);
    }

    return PotentialDGRound(
      uid: round.uid,
      id: round.id,
      courseId: round.courseId,
      courseName: round.courseName,
      holes: completeHoles,
      analysis: round.analysis,
      aiSummary: round.aiSummary,
      aiCoachSuggestion: round.aiCoachSuggestion,
      versionId: round.versionId,
      createdAt: round.createdAt,
      playedRoundAt: round.playedRoundAt,
    );
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
