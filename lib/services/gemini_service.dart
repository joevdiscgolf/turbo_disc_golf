import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:yaml/yaml.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

class GeminiService {
  late final GenerativeModel _model;
  static const String _defaultApiKey =
      'AIzaSyDGTZoOaO_U76ysJ5dG8Ohdc7B-soUn3rE'; // Replace with actual key

  String? _lastRawResponse; // Store the last raw response
  String? get lastRawResponse => _lastRawResponse;

  // Helper method to get enum values as strings
  static String _getEnumValuesAsString<T>(List<T> values) {
    return values.map((e) {
      final str = e.toString().split('.').last;
      // Convert camelCase to snake_case for JSON values
      return str.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (Match m) => '_${m[0]!.toLowerCase()}',
      ).replaceAll(RegExp(r'^_'), '');
    }).join(', ');
  }

  GeminiService({String? apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey ?? _defaultApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3, // Lower temperature for more consistent parsing
        topK: 20,
        topP: 0.8,
        maxOutputTokens: 4096,
        // Removed responseMimeType to allow YAML responses
      ),
    );
  }

  Future<DGRound?> parseRoundDescription({
    required String voiceTranscript,
    required List<DGDisc> userBag,
    String? courseName,
  }) async {
    try {
      // Check for API key
      if (_defaultApiKey == 'YOUR_API_KEY_HERE') {
        throw Exception(
          'Please add your Gemini API key in gemini_service.dart line 10',
        );
      }

      final prompt = _buildPrompt(voiceTranscript, userBag, courseName);
      print('Sending request to Gemini...');
      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        throw Exception('No response from Gemini');
      }

      // Store the raw response
      _lastRawResponse = response.text;

      print('Gemini response received, parsing YAML...');
      print('==================== RAW GEMINI RESPONSE ====================');
      // Print in chunks to avoid truncation
      String responseText = response.text!;
      const chunkSize = 800; // Flutter's console typically truncates around 1024 chars
      for (int i = 0; i < responseText.length; i += chunkSize) {
        final end = (i + chunkSize < responseText.length)
            ? i + chunkSize
            : responseText.length;
        print(responseText.substring(i, end));
      }
      print('==============================================================');
      print('Response length: ${responseText.length} characters');

      // Clean up the response - remove markdown code blocks if present
      responseText = responseText.trim();

      // Remove ```yaml or ```YAML at the beginning
      if (responseText.startsWith('```yaml') || responseText.startsWith('```YAML')) {
        responseText = responseText.substring(responseText.indexOf('\n') + 1);
      }

      // Remove just 'yaml' or 'YAML' at the beginning
      if (responseText.startsWith('yaml\n') || responseText.startsWith('YAML\n')) {
        responseText = responseText.substring(5);
      }

      // Remove closing ``` at the end
      if (responseText.endsWith('```')) {
        responseText = responseText.substring(0, responseText.length - 3).trim();
      }

      print('Cleaned response for parsing...');

      // Parse the YAML response
      print('Parsing YAML response...');
      final yamlDoc = loadYaml(responseText);

      // Convert YamlMap to regular Map<String, dynamic>
      final Map<String, dynamic> jsonMap = json.decode(json.encode(yamlDoc));

      print('YAML parsed successfully, converting to DGRound...');
      return DGRound.fromJson(jsonMap);
    } catch (e) {
      print('Error parsing round with Gemini: $e');
      if (e.toString().contains('API key')) {
        throw Exception('API Key Error: $e');
      }
      rethrow;
    }
  }

  String _buildPrompt(
    String voiceTranscript,
    List<DGDisc> userBag,
    String? courseName,
  ) {
    // Get enum values dynamically
    final throwTypeValues = _getEnumValuesAsString(DiscThrowType.values);
    final techniqueValues = _getEnumValuesAsString(ThrowTechnique.values);
    final shotTypeValues = _getEnumValuesAsString(ShotType.values);
    final stanceValues = _getEnumValuesAsString(StanceType.values);
    final conditionValues = _getEnumValuesAsString(ShotCondition.values);
    final windValues = _getEnumValuesAsString(WindCondition.values);
    final landingZoneValues = _getEnumValuesAsString(LandingZone.values);

    // Create disc list string
    final discListString = userBag
        .map(
          (disc) =>
              '- ${disc.name} (${disc.moldName ?? "Unknown mold"} by ${disc.brand ?? "Unknown brand"})',
        )
        .join('\n');

    // Create the expected YAML schema as a string
    final schemaExample = '''
course: Course Name
holes:
  - number: 1
    par: 3
    feet: 350
    throws:
      - distance: 300
        discName: Star Destroyer
        discId: innova_destroyer_star_1
        throwType: drive
        technique: backhand
        shotType: hyzer
        stance: x_step
        conditions: [tunnel_shot, uphill]
        windCondition: headwind
        description: threw my destroyer straight down the fairway
        result: parked
      - distance: 50
        discName: Classic Judge
        discId: dynamic_judge_classic_1
        throwType: putt
        technique: putt
        shotType: flat
        stance: standstill
        description: made the putt
        result: made''';

    return '''
You are a disc golf scorecard parser. Parse the following voice transcript of a disc golf round into structured YAML data.

VOICE TRANSCRIPT:
"$voiceTranscript"

USER'S DISC BAG:
$discListString

${courseName != null ? 'COURSE NAME: $courseName' : 'Extract the course name from the transcript if mentioned.'}

INSTRUCTIONS:
1. Parse each hole mentioned in the transcript
2. For each throw, match the disc mentioned to one from the user's bag (use exact disc names and IDs from the bag)
3. Extract distances when mentioned (estimate if not explicit)
4. Include the natural language description in the "description" field
5. Note results like "parked", "OB", "C1", "C2", "made", "missed" in the "result" field
6. If par or hole distance isn't mentioned, use standard values (par 3 for <400ft, par 4 for 400-600ft, par 5 for >600ft)
7. Number holes sequentially starting from 1

ALLOWED ENUM VALUES (use ONLY these exact values or 'other' if no match):
- throwType: $throwTypeValues
- technique: $techniqueValues
- shotType: $shotTypeValues
- stance: $stanceValues
- conditions (can be multiple): $conditionValues
- windCondition: $windValues
- landingZone: $landingZoneValues
- resultRating: 1, 2, 3, 4, 5 (numbers only)

IMPORTANT: If the description doesn't clearly match any enum value, use 'other' instead of making up a value.

Common disc golf terms to understand:
- "Parked" = very close to the basket
- "C1" = Circle 1, within 33 feet
- "C2" = Circle 2, 33-66 feet
- "OB" = Out of bounds
- "Ace" = Hole in one
- "Birdie" = One under par
- "Eagle" = Two under par
- "Bogey" = One over par

CRITICAL: Return ONLY the raw YAML content. Do NOT include:
- The word 'yaml' at the beginning
- Markdown code blocks (no ``` or ```yaml)
- Any other text before or after the YAML

Start directly with the course name and return ONLY valid YAML matching this exact structure:
$schemaExample
''';
  }

  // Test method to validate the service
  Future<bool> testConnection() async {
    try {
      final response = await _model.generateContent([
        Content.text('Reply with just "OK" to confirm the connection works.'),
      ]);
      return response.text?.contains('OK') ?? false;
    } catch (e) {
      print('Gemini connection test failed: $e');
      return false;
    }
  }
}
