import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/endpoints/ai_endpoints.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/llm/backend_llm_service.dart';
import 'package:turbo_disc_golf/services/llm/gemini_service.dart';
import 'package:turbo_disc_golf/utils/ai_response_parser.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/llm_helpers/gemini_helpers.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

enum AiParsingModel { gemini }

class AiParsingService {
  static const _selectedModel = AiParsingModel.gemini;
  static const _uuid = Uuid();

  String? _lastRawResponse; // Store the last raw response
  String? get lastRawResponse => _lastRawResponse;

  /// Sanitizes YAML to fix common AI-generated formatting issues
  String _sanitizeYaml(String yaml) {
    // Fix: notes field with comma-separated strings instead of single string
    // Example: notes: "string1", "string2" -> notes: "string1, string2"
    final RegExp notesPattern = RegExp(
      r'notes:\s*"([^"]+)"(?:\s*,\s*"([^"]+)")+',
      multiLine: true,
    );

    yaml = yaml.replaceAllMapped(notesPattern, (match) {
      // Get all the quoted strings and combine them
      final fullMatch = match.group(0)!;
      final allQuotes = RegExp(r'"([^"]+)"').allMatches(fullMatch);
      final values = allQuotes.map((m) => m.group(1)!).toList();

      // Combine into a single string
      final combinedValue = values.join(', ');
      return 'notes: "$combinedValue"';
    });

    return yaml;
  }

  /// Detects and removes repetitive text patterns (model stuck in a loop)
  String _removeRepetitiveText(String text) {
    // Check for patterns where a phrase repeats many times
    final words = text.split(' ');

    // If text is suspiciously long (>6000 chars) with few unique words, likely repetition
    if (text.length > 6000) {
      final uniqueWords = words.toSet().length;
      final totalWords = words.length;

      // If less than 20% unique words, likely stuck in loop
      if (uniqueWords < totalWords * 0.2) {
        debugPrint('⚠️ Detected repetitive output! Attempting to truncate...');

        // Find where the repetition starts by looking for repeated sequences
        // Look for a phrase that repeats 5+ times
        for (int phraseLength = 2; phraseLength <= 10; phraseLength++) {
          for (int i = 0; i < words.length - (phraseLength * 5); i++) {
            final phrase = words.sublist(i, i + phraseLength).join(' ');
            int count = 0;

            // Count consecutive repetitions
            for (
              int j = i;
              j < words.length - phraseLength;
              j += phraseLength
            ) {
              final testPhrase = words.sublist(j, j + phraseLength).join(' ');
              if (testPhrase == phrase) {
                count++;
              } else {
                break;
              }
            }

            // If we found 5+ repetitions, truncate there
            if (count >= 5) {
              final truncatedText = words.sublist(0, i).join(' ');
              debugPrint(
                '✂️ Truncated at position $i (found "$phrase" repeated $count times)',
              );
              return truncatedText;
            }
          }
        }
      }
    }

    return text;
  }

  Future<PotentialDGRound?> parseRoundDescription({
    required String voiceTranscript,
    required List<DGDisc> userBag,
    Course? course,
    String? layoutId,
    int numHoles = 18,
    List<HoleMetadata>?
    preParsedHoles, // NEW: Pre-parsed hole metadata from image
  }) async {
    final String? uid = locator.get<AuthService>().currentUid;
    if (uid == null) return null;

    try {
      String? responseText;

      final FeatureFlagService flags = locator.get<FeatureFlagService>();
      if (flags.generateAiContentFromBackend) {
        // Use backend cloud function for round parsing
        debugPrint('Sending request to backend cloud function...');
        final BackendLLMService backendService = locator.get<BackendLLMService>();
        final ParseRoundDataRequest request = ParseRoundDataRequest(
          voiceTranscript: voiceTranscript,
          userBag: userBag,
          courseName: course?.name,
        );
        final ParseRoundDataResponse? response = await backendService
            .parseRoundData(request: request);

        if (response == null || !response.success) {
          throw Exception(
            response?.data.error ?? 'No response from backend',
          );
        }

        responseText = response.data.rawResponse;
      } else {
        final prompt = _buildParsingPrompt(
          voiceTranscript,
          userBag,
          course?.name,
          preParsedHoles: preParsedHoles, // Pass through to prompt builder
        );
        debugPrint('Sending request to Gemini...');
        responseText = await _getContentFromModel(prompt: prompt);

        if (responseText == null) {
          throw Exception('No response from Gemini');
        }
      }

      // Store the raw response
      _lastRawResponse = responseText;

      // Detect and handle repetitive output
      responseText = _removeRepetitiveText(responseText);

      debugPrint('Response received, parsing YAML...');
      debugPrint(
        '==================== RAW RESPONSE ====================',
      );
      // debugPrint in chunks to avoid truncation
      const chunkSize =
          800; // Flutter's console typically truncates around 1024 chars
      for (int i = 0; i < responseText.length; i += chunkSize) {
        final end = (i + chunkSize < responseText.length)
            ? i + chunkSize
            : responseText.length;
        debugPrint(responseText.substring(i, end));
      }
      debugPrint(
        '==============================================================',
      );
      debugPrint('Response length: ${responseText.length} characters');

      // Clean up the response - remove markdown code blocks if present
      responseText = responseText.trim();

      // Remove ```yaml or ```YAML at the beginning
      if (responseText.startsWith('```yaml') ||
          responseText.startsWith('```YAML')) {
        responseText = responseText.substring(responseText.indexOf('\n') + 1);
      }

      // Remove just 'yaml' or 'YAML' at the beginning
      if (responseText.startsWith('yaml\n') ||
          responseText.startsWith('YAML\n')) {
        responseText = responseText.substring(5);
      }

      // Remove closing ``` at the end
      if (responseText.endsWith('```')) {
        responseText = responseText
            .substring(0, responseText.length - 3)
            .trim();
      }

      debugPrint('Cleaned response for parsing...');

      // Sanitize YAML to fix common AI formatting issues
      responseText = _sanitizeYaml(responseText);
      debugPrint('YAML sanitized...');

      // Parse the YAML response
      debugPrint('Parsing YAML response...');
      final yamlDoc = loadYaml(responseText);

      // Convert YamlMap to regular Map<String, dynamic>
      final Map<String, dynamic> jsonMap = json.decode(json.encode(yamlDoc));

      jsonMap['id'] = _uuid.v4();
      jsonMap['courseName'] = course?.name;
      jsonMap['courseId'] = course?.id;
      jsonMap['course'] = course?.toJson();
      jsonMap['layoutId'] = layoutId ?? course?.defaultLayout.id;
      jsonMap['uid'] = uid;

      debugPrint('YAML parsed successfully, converting to PotentialDGRound...');
      final PotentialDGRound potentialRound = PotentialDGRound.fromJson(
        jsonMap,
      );

      return _fillMissingHoles(uid, potentialRound, numHoles);
    } catch (e, trace) {
      debugPrint('Error parsing round: $e');
      debugPrint(trace.toString());
      if (e.toString().contains('API key')) {
        throw Exception('API Key Error: $e');
      }
      rethrow;
    }
  }

  /// Fills in missing holes in the sequence from 1 to numHoles.
  /// Creates empty PotentialDGHole objects with null par values.
  PotentialDGRound _fillMissingHoles(
    String uid,
    PotentialDGRound round,
    int numHoles,
  ) {
    // If no holes exist, create empty holes for all
    if (round.holes == null || round.holes!.isEmpty) {
      debugPrint('No holes found, creating $numHoles empty holes');
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
        uid: uid,
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

    // Use the larger of: max hole number in parsed data or requested numHoles
    final int maxParsedHoleNumber = round.holes!
        .where((h) => h.number != null)
        .map((h) => h.number!)
        .fold(0, (max, n) => n > max ? n : max);

    final int maxHoleNumber = maxParsedHoleNumber > numHoles
        ? maxParsedHoleNumber
        : numHoles;

    // Create a set of existing hole numbers
    final Set<int> existingHoles = round.holes!
        .where((h) => h.number != null)
        .map((h) => h.number!)
        .toSet();

    // Find missing holes in the sequence
    final Set<int> missingHoles = {};
    for (int i = 1; i <= maxHoleNumber; i++) {
      if (!existingHoles.contains(i)) {
        missingHoles.add(i);
      }
    }

    if (missingHoles.isEmpty) {
      return round; // No gaps
    }

    debugPrint('Filling ${missingHoles.length} missing holes: $missingHoles');

    // Create complete holes list with empty holes inserted
    final List<PotentialDGHole> completeHoles = List.from(round.holes!);

    for (final int holeNumber in missingHoles) {
      final PotentialDGHole emptyHole = PotentialDGHole(
        number: holeNumber,
        par: null, // Keep null - user must fill in
        feet: null,
        throws: [], // Empty throws
        holeType: null,
      );

      // Find insertion position (maintain order)
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
      uid: uid,
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

  /// Parse a single hole description and return the updated hole
  /// Used for re-recording individual holes
  Future<PotentialDGHole?> parseSingleHole({
    required String voiceTranscript,
    required List<DGDisc> userBag,
    required int holeNumber,
    required int? existingHolePar,
    required int? existingHoleFeet,
    required String courseName,
  }) async {
    try {
      final prompt = _buildSingleHoleParsingPrompt(
        voiceTranscript,
        userBag,
        holeNumber,
        courseName,
      );
      debugPrint(
        'Sending single-hole request to Gemini for hole $holeNumber...',
      );
      String? responseText = await _getContentFromModel(prompt: prompt);

      if (responseText == null) {
        throw Exception('No response from Gemini');
      }

      // Detect and handle repetitive output
      responseText = _removeRepetitiveText(responseText);

      debugPrint(
        'Gemini response received for hole $holeNumber, parsing YAML...',
      );

      // Print raw YAML response for debugging
      debugPrint(
        '==================== RAW SINGLE HOLE YAML (Hole $holeNumber) ====================',
      );
      // debugPrint in chunks to avoid truncation
      const chunkSize = 800;
      for (int i = 0; i < responseText.length; i += chunkSize) {
        final end = (i + chunkSize < responseText.length)
            ? i + chunkSize
            : responseText.length;
        debugPrint(responseText.substring(i, end));
      }
      debugPrint(
        '================================================================================',
      );
      debugPrint('Response length: ${responseText.length} characters');

      // Clean up the response - remove markdown code blocks if present
      responseText = responseText.trim();
      if (responseText.startsWith('```yaml') ||
          responseText.startsWith('```YAML')) {
        responseText = responseText.substring(responseText.indexOf('\n') + 1);
      }
      if (responseText.startsWith('yaml\n') ||
          responseText.startsWith('YAML\n')) {
        responseText = responseText.substring(5);
      }
      if (responseText.endsWith('```')) {
        responseText = responseText
            .substring(0, responseText.length - 3)
            .trim();
      }

      // Sanitize YAML to fix common AI formatting issues
      responseText = _sanitizeYaml(responseText);

      // Parse the YAML response
      final yamlDoc = loadYaml(responseText);
      final Map<String, dynamic> jsonMap = json.decode(json.encode(yamlDoc));

      // Ensure hole number matches
      jsonMap['number'] = holeNumber;

      // Use existing par/feet as fallback if not detected in the AI response
      if (jsonMap['par'] == null && existingHolePar != null) {
        debugPrint(
          'No par detected in AI response, using existing par: $existingHolePar',
        );
        jsonMap['par'] = existingHolePar;
      }

      if (jsonMap['feet'] == null && existingHoleFeet != null) {
        debugPrint(
          'No distance detected in AI response, using existing distance: $existingHoleFeet',
        );
        jsonMap['feet'] = existingHoleFeet;
      }

      debugPrint(
        'Single hole YAML parsed successfully, converting to PotentialDGHole...',
      );
      return PotentialDGHole.fromJson(jsonMap);
    } catch (e, trace) {
      debugPrint('Error parsing single hole with Gemini: $e');
      debugPrint(trace.toString());
      return null;
    }
  }

  /// Parse a scorecard image to extract hole metadata
  /// Returns list of HoleMetadata (hole number, par, distance, score)
  Future<List<HoleMetadata>> parseScorecard({required String imagePath}) async {
    try {
      debugPrint('Parsing scorecard image: $imagePath');

      final prompt = _buildScorecardExtractionPrompt();

      // Use vision model to process image
      String? responseText;
      switch (_selectedModel) {
        case AiParsingModel.gemini:
          // ALWAYS use Gemini for scorecard parsing (vision), regardless of story generation provider
          responseText = await locator
              .get<GeminiService>()
              .generateContentWithImage(prompt: prompt, imagePath: imagePath);
      }

      if (responseText == null || responseText.trim().isEmpty) {
        debugPrint('No response from AI for scorecard extraction');
        return [];
      }

      debugPrint('Scorecard extraction response: $responseText');

      // Clean up response - remove markdown if present
      responseText = responseText.trim();
      if (responseText.startsWith('```json') ||
          responseText.startsWith('```JSON')) {
        responseText = responseText.substring(responseText.indexOf('\n') + 1);
      }
      if (responseText.startsWith('```')) {
        responseText = responseText.substring(3);
      }
      if (responseText.endsWith('```')) {
        responseText = responseText
            .substring(0, responseText.length - 3)
            .trim();
      }

      // Parse JSON response
      final jsonData = json.decode(responseText);

      if (jsonData is! List) {
        debugPrint('Response is not a JSON array');
        return [];
      }

      // Convert to List<HoleMetadata>
      final holes = <HoleMetadata>[];
      for (final holeJson in jsonData) {
        try {
          holes.add(HoleMetadata.fromJson(holeJson as Map<String, dynamic>));
        } catch (e) {
          debugPrint('Error parsing hole metadata: $e');
          // Continue with other holes
        }
      }

      debugPrint('Successfully extracted ${holes.length} holes from scorecard');
      return holes;
    } catch (e, trace) {
      debugPrint('Error parsing scorecard: $e');
      debugPrint(trace.toString());
      return [];
    }
  }

  // Test method to validate the service
  Future<bool> testModelConnection() async {
    try {
      switch (_selectedModel) {
        case AiParsingModel.gemini:
          // ALWAYS use Gemini for testing connection
          return locator.get<GeminiService>().testConnection();
      }
    } catch (e) {
      debugPrint('Gemini connection test failed: $e');
      return false;
    }
  }

  /// Generates unified AI insights based on round data and analysis
  /// Returns both 'summary' and 'coaching' keys for backward compatibility,
  /// but both contain the same unified content
  Future<Map<String, AIContent?>> generateRoundInsights({
    required DGRound round,
    required dynamic analysis, // RoundAnalysis
  }) async {
    try {
      final prompt = _buildInsightsPrompt(round, analysis);

      final response = await _getContentFromModel(prompt: prompt);

      // Parse response in markdown format
      var responseText = response ?? '';
      debugPrint('Gemini insights raw response: $responseText');

      debugPrint('Parsed insights length: ${responseText.length} chars');

      // Parse segments from the response
      final segments = AIResponseParser.parse(responseText);

      debugPrint('Insights segments: ${segments.length}');

      // Create AIContent object with the round's version ID and parsed segments
      final insights = responseText.isNotEmpty
          ? AIContent(
              content: responseText,
              roundVersionId: round.versionId,
              segments: segments,
            )
          : null;

      // Return unified content in 'summary' key, null for 'coaching' (deprecated)
      // This maintains backward compatibility while transitioning to unified response
      return {'summary': insights, 'coaching': null};
    } catch (e) {
      debugPrint('Error generating insights: $e');
      return {'summary': null, 'coaching': null};
    }
  }

  Future<String?> _getContentFromModel({required String prompt}) async {
    switch (_selectedModel) {
      case AiParsingModel.gemini:
        // ALWAYS use Gemini for round parsing, regardless of story generation provider
        return locator.get<GeminiService>().generateContent(prompt: prompt);
    }
  }

  String _buildParsingPrompt(
    String voiceTranscript,
    List<DGDisc> userBag,
    String? courseName, {
    List<HoleMetadata>? preParsedHoles,
  }) {
    switch (_selectedModel) {
      case AiParsingModel.gemini:
        return GeminiHelpers.buildGeminiParsingPrompt(
          voiceTranscript,
          userBag,
          courseName,
          preParsedHoles: preParsedHoles,
        );
    }
  }

  String _buildSingleHoleParsingPrompt(
    String voiceTranscript,
    List<DGDisc> userBag,
    int holeNumber,
    String courseName,
  ) {
    switch (_selectedModel) {
      case AiParsingModel.gemini:
        return GeminiHelpers.buildGeminiSingleHoleParsingPrompt(
          voiceTranscript,
          userBag,
          holeNumber,
          courseName,
        );
    }
  }

  String _buildInsightsPrompt(DGRound round, dynamic analysis) {
    switch (_selectedModel) {
      case AiParsingModel.gemini:
        return GeminiHelpers.buildGeminiInsightsPrompt(round, analysis);
    }
  }

  String _buildScorecardExtractionPrompt() {
    switch (_selectedModel) {
      case AiParsingModel.gemini:
        return GeminiHelpers.buildScorecardExtractionPrompt();
    }
  }
}
