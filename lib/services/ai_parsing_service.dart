import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/utils/ai_response_parser.dart';
import 'package:turbo_disc_golf/utils/gemini_helpers.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

enum AiParsingModel { gemini }

class AiParsingService {
  static const _selectedModel = AiParsingModel.gemini;
  static const _uuid = Uuid();

  String? _lastRawResponse; // Store the last raw response
  String? get lastRawResponse => _lastRawResponse;

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
    String? courseName,
    List<HoleMetadata>?
    preParsedHoles, // NEW: Pre-parsed hole metadata from image
  }) async {
    try {
      final prompt = _buildParsingPrompt(
        voiceTranscript,
        userBag,
        courseName,
        preParsedHoles: preParsedHoles, // Pass through to prompt builder
      );
      debugPrint('Sending request to Gemini...');
      String? responseText = await _getContentFromModel(prompt: prompt);

      if (responseText == null) {
        throw Exception('No response from Gemini');
      }

      // Store the raw response
      _lastRawResponse = responseText;

      // Detect and handle repetitive output
      responseText = _removeRepetitiveText(responseText);

      debugPrint('Gemini response received, parsing YAML...');
      debugPrint(
        '==================== RAW GEMINI RESPONSE ====================',
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

      // Parse the YAML response
      debugPrint('Parsing YAML response...');
      final yamlDoc = loadYaml(responseText);

      // Convert YamlMap to regular Map<String, dynamic>
      final Map<String, dynamic> jsonMap = json.decode(json.encode(yamlDoc));

      jsonMap['id'] = _uuid.v4();
      jsonMap['courseName'] = courseName;

      debugPrint('YAML parsed successfully, converting to PotentialDGRound...');
      final PotentialDGRound potentialRound = PotentialDGRound.fromJson(
        jsonMap,
      );
      return _fillMissingHoles(potentialRound);
    } catch (e, trace) {
      debugPrint('Error parsing round with Gemini: $e');
      debugPrint(trace.toString());
      if (e.toString().contains('API key')) {
        throw Exception('API Key Error: $e');
      }
      rethrow;
    }
  }

  /// Fills in missing holes in the sequence from 1 to max hole number.
  /// Creates empty PotentialDGHole objects with null par values.
  PotentialDGRound _fillMissingHoles(PotentialDGRound round) {
    if (round.holes == null || round.holes!.isEmpty) {
      return round;
    }

    // Find the maximum hole number
    final int maxHoleNumber = round.holes!
        .where((h) => h.number != null)
        .map((h) => h.number!)
        .fold(0, (max, n) => n > max ? n : max);

    if (maxHoleNumber <= 1) {
      return round; // No gaps possible with 0 or 1 hole
    }

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
    required int holePar,
    required int? holeFeet,
    required String courseName,
  }) async {
    try {
      final prompt = _buildSingleHoleParsingPrompt(
        voiceTranscript,
        userBag,
        holeNumber,
        holePar,
        holeFeet,
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

      // // Print raw YAML response for debugging
      // debugPrint(
      //   '==================== RAW SINGLE HOLE YAML (Hole $holeNumber) ====================',
      // );
      // // debugPrint in chunks to avoid truncation
      // const chunkSize = 800;
      // for (int i = 0; i < responseText.length; i += chunkSize) {
      //   final end = (i + chunkSize < responseText.length)
      //       ? i + chunkSize
      //       : responseText.length;
      //   debugPrint(responseText.substring(i, end));
      // }
      // debugPrint(
      //   '================================================================================',
      // );
      // debugPrint('Response length: ${responseText.length} characters');

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

      // Parse the YAML response
      final yamlDoc = loadYaml(responseText);
      final Map<String, dynamic> jsonMap = json.decode(json.encode(yamlDoc));

      // Ensure hole number, par, and feet match the context
      jsonMap['number'] = holeNumber;

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
        return locator.get<GeminiService>().buildGeminiParsingPrompt(
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
    int holePar,
    int? holeFeet,
    String courseName,
  ) {
    switch (_selectedModel) {
      case AiParsingModel.gemini:
        return GeminiHelpers.buildGeminiSingleHoleParsingPrompt(
          voiceTranscript,
          userBag,
          holeNumber,
          holePar,
          holeFeet,
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
