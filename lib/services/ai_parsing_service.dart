import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

enum AiParsingModel { gemini }

class AiParsingService {
  static const _selectedModel = AiParsingModel.gemini;
  static const _uuid = Uuid();

  String? _lastRawResponse; // Store the last raw response
  String? get lastRawResponse => _lastRawResponse;

  Future<DGRound?> parseRoundDescription({
    required String voiceTranscript,
    required List<DGDisc> userBag,
    String? courseName,
  }) async {
    try {
      final prompt = _buildParsingPrompt(voiceTranscript, userBag, courseName);
      debugPrint('Sending request to Gemini...');
      String? responseText = await _getContentFromModel(prompt: prompt);

      if (responseText == null) {
        throw Exception('No response from Gemini');
      }

      // Store the raw response
      _lastRawResponse = responseText;

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

      debugPrint('YAML parsed successfully, converting to DGRound...');
      return DGRound.fromJson(jsonMap);
    } catch (e, trace) {
      debugPrint('Error parsing round with Gemini: $e');
      debugPrint(trace.toString());
      if (e.toString().contains('API key')) {
        throw Exception('API Key Error: $e');
      }
      rethrow;
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

  /// Generates AI summary and coaching based on round data and analysis
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

      // Split on the separator
      final parts = responseText.split('---SPLIT---');

      final summaryText = parts.isNotEmpty ? parts[0].trim() : '';
      final coachingText = parts.length > 1 ? parts[1].trim() : '';

      debugPrint('Parsed summary length: ${summaryText.length} chars');
      debugPrint('Parsed coaching length: ${coachingText.length} chars');

      // Create AIContent objects with the round's version ID
      final summary = summaryText.isNotEmpty
          ? AIContent(content: summaryText, roundVersionId: round.versionId)
          : null;
      final coaching = coachingText.isNotEmpty
          ? AIContent(content: coachingText, roundVersionId: round.versionId)
          : null;

      return {'summary': summary, 'coaching': coaching};
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
    String? courseName,
  ) {
    switch (_selectedModel) {
      case AiParsingModel.gemini:
        return locator.get<GeminiService>().buildGeminiParsingPrompt(
          voiceTranscript,
          userBag,
          courseName,
        );
    }
  }

  String _buildInsightsPrompt(DGRound round, dynamic analysis) {
    switch (_selectedModel) {
      case AiParsingModel.gemini:
        return locator.get<GeminiService>().buildGeminiInsightsPrompt(
          round,
          analysis,
        );
    }
  }
}
