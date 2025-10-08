import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:yaml/yaml.dart';
import 'package:uuid/uuid.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

class GeminiService {
  late final GenerativeModel _model;
  static const String _defaultApiKey =
      'AIzaSyDGTZoOaO_U76ysJ5dG8Ohdc7B-soUn3rE'; // Replace with actual key
  static const _uuid = Uuid();

  String? _lastRawResponse; // Store the last raw response
  String? get lastRawResponse => _lastRawResponse;

  // Helper method to get enum values as strings with proper snake_case formatting
  static String _getEnumValuesAsString<T>(List<T> values) {
    return values
        .map((e) {
          final str = e.toString().split('.').last;
          // Convert camelCase to snake_case for JSON values
          // Special handling for names with numbers like circle1 -> circle_1
          String snakeCase = str
              .replaceAllMapped(
                RegExp(
                  r'([a-z])([0-9])',
                ), // lowercase letter followed by number
                (Match m) => '${m[1]}_${m[2]}',
              )
              .replaceAllMapped(
                RegExp(r'[A-Z]'),
                (Match m) => '_${m[0]!.toLowerCase()}',
              )
              .replaceAll(RegExp(r'^_'), '');
          return snakeCase;
        })
        .join(', ');
  }

  GeminiService({String? apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
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
      debugPrint('Sending request to Gemini...');
      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        throw Exception('No response from Gemini');
      }

      // Store the raw response
      _lastRawResponse = response.text;

      debugPrint('Gemini response received, parsing YAML...');
      debugPrint(
        '==================== RAW GEMINI RESPONSE ====================',
      );
      // debugPrint in chunks to avoid truncation
      String responseText = response.text!;
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

  String _buildPrompt(
    String voiceTranscript,
    List<DGDisc> userBag,
    String? courseName,
  ) {
    // Get enum values dynamically
    final throwPurposeValues = _getEnumValuesAsString(ThrowPurpose.values);
    final techniqueValues = _getEnumValuesAsString(ThrowTechnique.values);
    final puttStyleValues = _getEnumValuesAsString(PuttStyle.values);
    final shotShapeValues = _getEnumValuesAsString(ShotShape.values);
    final stanceValues = _getEnumValuesAsString(StanceType.values);
    final throwPowerValues = _getEnumValuesAsString(ThrowPower.values);
    final windDirectionValues = _getEnumValuesAsString(WindDirection.values);
    final windStrengthValues = _getEnumValuesAsString(WindStrength.values);
    final resultRatingValues = _getEnumValuesAsString(ThrowResultRating.values);
    final landingSpotValues = _getEnumValuesAsString(LandingSpot.values);
    final fairwayWidthValues = _getEnumValuesAsString(FairwayWidth.values);
    final gripTypeValues = _getEnumValuesAsString(GripType.values);
    final throwHandValues = _getEnumValuesAsString(ThrowHand.values);

    // Create disc list string
    final discListString = userBag
        .map(
          (disc) =>
              '- ${disc.name} (${disc.moldName ?? "Unknown mold"} by ${disc.brand ?? "Unknown brand"})',
        )
        .join('\n');

    // Create the expected YAML schema as a string - showing clean output with only mentioned fields
    final schemaExample = '''
course: Course Name
holes:
  - number: 1
    par: 3
    feet: 350
    throws:
      - index: 0
        distanceFeet: 300
        purpose: tee_drive
        technique: backhand
        shotShape: hyzer
        power: full
        notes: threw straight down the fairway
        landingSpot: fairway
      - index: 1
        distanceFeet: 50
        purpose: putt
        technique: backhand
        puttStyle: staggered
        notes: made the putt
        landingSpot: in_basket
  - number: 2
    par: 3
    feet: 280
    throws:
      - index: 0
        purpose: tee_drive
        notes: went OB right
        landingSpot: out_of_bounds
        penaltyStrokes: 1
      - index: 1
        distanceFeet: 250
        purpose: tee_drive
        technique: backhand
        notes: re-teed and threw safe
        landingSpot: circle_2
      - index: 2
        distanceFeet: 8
        purpose: putt
        notes: tapped in for bogey
        landingSpot: in_basket''';

    return '''
You are a disc golf scorecard parser. Parse the following voice transcript of a disc golf round into structured YAML data.

VOICE TRANSCRIPT:
"$voiceTranscript"

USER'S DISC BAG:
$discListString

${courseName != null ? 'COURSE NAME: $courseName' : 'Extract the course name from the transcript if mentioned.'}

INSTRUCTIONS:
1. Parse each hole mentioned in the transcript
2. For each throw, assign index starting from 0 (0=tee shot, 1=second throw, etc.)
3. ONLY include distanceFeet when the actual throw distance is explicitly stated
4. Include brief natural language description in the "notes" field
5. Map landing positions to landingSpot enum based on distance from basket:
   - "made" or "in the basket" = in_basket
   - Within 10 feet or "parked" = parked
   - 10-33 feet or "C1" = circle_1
   - 33-66 feet or "C2" = circle_2
   - On the intended playing surface beyond C2 = fairway
   - Off the intended line or in rough/trees = off_fairway (NOT for missed putts!)
   - OB, water, or out of bounds = out_of_bounds
   - Missed putts: Usually omit landingSpot or use parked/circle_1 based on distance
   - NEVER use off_fairway for missed putts - putts stay near the basket
6. If par or hole distance isn't mentioned, use standard values (par 3 for <400ft, par 4 for 400-600ft, par 5 for >600ft)
7. Number holes sequentially starting from 1

CRITICAL DISTANCE RULES:
- ONLY include distanceFeet when the THROW DISTANCE is explicitly stated
- "to 25 feet" means the disc ended up 25 feet FROM THE BASKET, NOT that the throw was 25 feet
- "Pitch out to 25 feet" = DO NOT include distanceFeet (we don't know throw distance)
- "Threw 280 feet" = distanceFeet: 280 (actual throw distance stated)
- "40 feet short" describes landing position, NOT throw distance (unless context makes it clear)
- Exception: "Tap in" or "tapped in" ALWAYS = distanceFeet: 8
- Exception: "Gimme" or "drop in" ALWAYS = distanceFeet: 3

CRITICAL THROW COUNTING - REASON THROUGH EACH HOLE:
SCORE-FIRST VALIDATION: When the player states their score (birdie, par, bogey, eagle, etc.), that is the GROUND TRUTH.
- Calculate the expected throw count from the stated score FIRST
- Then ensure you parse EXACTLY that many throws
- If you can't find enough throws, you MISSED one - re-analyze the description
- Examples: "for par" on par 3 = 3 throws, "for birdie" on par 3 = 2 throws, "for birdie" on par 4 = 3 throws

For EVERY hole, count throws carefully by analyzing the narrative:
1. Start with the tee shot (index 0)
2. Track each subsequent throw mentioned - NEVER combine multiple throws into one
3. NEVER put information about a second throw in the notes of the first throw
   - WRONG: "ended up 25 ft long and I missed the putt" in one throw's notes
   - CORRECT: First throw notes "ended up 25 ft long", SEPARATE throw for "missed the putt"
4. EVERY HOLE MUST END WITH landingSpot: in_basket - holes must be completed!
5. "Took a bogey/par/birdie" or "for par/birdie/bogey" = they FINISHED the hole, add final made putt if missing
6. Pay special attention to phrases that indicate multiple throws:
   - "Two putts" or "two-putted" = ALWAYS 2 separate putt throws (NEVER combine!)
   - "Three putts" = ALWAYS 3 separate putt throws
   - "Missed the putt" or "I missed the putt" = ALWAYS a separate throw (don't put this in notes of previous throw!)
   - "Missed the putt, tapped in" = 2 separate throws (missed putt + tap-in)
   - "Missed the par putt, took bogey" = 2 throws (missed + made final putt)
   - "Made the comeback putt" = 2 putts (first missed + comeback made)
   - "so I got to par/birdie/bogey" = they finished the hole, verify throw count matches stated score
   - "Two putts for par/birdie/bogey" = ALWAYS create 2 separate putt entries
   - "so I laid up" or "had to lay up" = a separate layup/approach throw AFTER the previous throw
   - "laid up and tapped in" = 2 SEPARATE throws (layup + tap-in, NEVER combine these!)
   - "which left me a [distance] putt" = the previous action was a SEPARATE throw
   - "and tap that in" or "and tapped that in" = ALWAYS a separate throw from the previous
   - "Tap in" or "tapped in" or "tap that in" = ALWAYS a separate throw (ALWAYS use 8 feet for tap-in distance)
   - "Pitch out" = a separate approach/scramble throw
   - "Scrambled" = a recovery throw
   CRITICAL: When you see "laid up" followed by "tap in", you MUST create two separate throw entries!
   CRITICAL: When you see "which left me" or "left me a putt", the previous action was a separate throw!
   CRITICAL: When you see "two putts", you MUST create two separate throw entries!
   CRITICAL: "and tap that in for [score]" almost NEVER means hole-in-one - it's a separate tap-in after previous throw(s)!
7. Handle penalties correctly:
   - "OB" or "out of bounds" = Add penaltyStrokes: 1 to that throw
   - "Water hazard" or "lost disc" = Add penaltyStrokes: 1 to that throw
   - Re-tee after OB = The re-tee is a separate throw (don't add penalty there)
8. ALWAYS VERIFY throw count matches the score (counting penalties):
   - Eagle on par 5 = exactly 3 throws
   - Birdie on par 5 = exactly 4 throws
   - Birdie on par 4 = exactly 3 throws (NOT 2!)
   - Birdie on par 3 = exactly 2 throws (NOT 1!)
   - Par on par 4 = exactly 4 throws (NOT 3!)
   - Par on par 3 = exactly 3 throws (NOT 2!) (or 2 throws + 1 penalty)
   - Bogey on par 3 = exactly 4 throws (or 3 throws + 1 penalty)
   - LAST THROW MUST HAVE landingSpot: in_basket
   - If your throw count doesn't match the score, you MISSED A THROW - go back and find it!
   - BEFORE returning results, count your throws and verify they match the stated score!


EXAMPLES FROM YOUR ACTUAL MISTAKES:

Hole 2: "250 ft par 3. Threw fd3 to circle one about 25 ft away, missed the putt off cage, missed the par putt, took a bogey"
YOUR MISTAKES: 1) Didn't complete hole, 2) Used off_fairway for missed putt
CORRECT (4 throws for bogey on par 3):
- index 0: Tee shot, landingSpot: circle_1
- index 1: First putt (missed off cage), distanceFeet: 25 (NO landingSpot or use parked)
- index 2: Par putt (missed), distanceFeet: 8 (NO landingSpot, NOT off_fairway!)
- index 3: Made bogey putt, distanceFeet: 8, landingSpot: in_basket (MUST end in basket!)

Hole 3: "380 ft par 3. Threw forehand 70 ft short. Tried putt from 70 ft, rolled to 15 ft, missed that 15 ft putt, took bogey"
YOUR MISTAKE: Didn't complete the hole - stopped after missed putt
CORRECT (4 throws for bogey):
- index 0: Tee drive, landingSpot: circle_2 (70 ft away)
- index 1: Long putt attempt, distanceFeet: 70 (rolled to 15 ft)
- index 2: Missed 15 ft putt, distanceFeet: 15
- index 3: Made bogey putt, distanceFeet: 8, landingSpot: in_basket (completed hole!)

Hole 6: "island hole 200 feet par 3. Played it safe with Judge, landed on the island 40 feet short. Missed the putt, tapped in for par."
YOUR MISTAKE: Only counted 2 throws, used wrong landingSpot
CORRECT (3 throws for par on par 3):
- index 0: Tee shot, landingSpot: circle_2 (40 feet = C2 range, "on island" = NOT out_of_bounds)
- index 1: Missed putt, distanceFeet: 40
- index 2: Tap-in, distanceFeet: 8 (ALWAYS 8, never copy previous distance), landingSpot: in_basket

Hole 7: "475 feet par 4. Threw Firebird 280 feet. Threw Buzzz 195 feet into rough. Pitch out to 25 feet, made putt for par."
YOUR MISTAKE: Used "to 25 feet" as distanceFeet for the pitch out
CORRECT (4 throws for par on par 4):
- index 0: Drive, distanceFeet: 280
- index 1: Approach, distanceFeet: 195
- index 2: Pitch out (NO distanceFeet - "to 25 feet" is final position, not throw distance)
- index 3: Putt, distanceFeet: 25

Hole 8: "Threw River hyzer flip but went OB. Re-teed, threw Buzzz 280 feet. Made 35 foot putt for bogey."
CORRECT (bogey = 4 strokes on par 3):
- index 0: First tee (OB), landingSpot: out_of_bounds, penaltyStrokes: 1
- index 1: Re-tee, distanceFeet: 280
- index 2: Putt, distanceFeet: 35, landingSpot: in_basket

Hole 9: "Approached from 70 feet to circle 1. Two putts for par."
YOUR MISTAKE: Combined "two putts" into one throw
CORRECT ("two putts" = 2 separate throws):
- Approach to circle_1
- First putt (missed)
- Second putt (made), distanceFeet: 8, landingSpot: in_basket

Hole 10: "Threw Star Destroyer 380 feet. Long jump putt from 45 feet hit cage but didn't go in. Tapped in for par."
YOUR MISTAKE: Combined drive and jump putt into one throw's notes
CORRECT (3 separate throws):
- index 0: Drive, distanceFeet: 380, landingSpot: circle_2
- index 1: Jump putt (missed), distanceFeet: 45
- index 2: Tap-in, distanceFeet: 8, landingSpot: in_basket

Hole 12: "780 ft par 5. Threw cloudbreaker left side of fairway. Second shot caught tree and landed short so I laid up and tapped in my birdie"
YOUR MISTAKE: Missed the layup shot - counted only 3 throws instead of 4 for birdie
CORRECT (4 throws for birdie on par 5):
- index 0: Tee drive, landingSpot: fairway
- index 1: Second shot (caught tree, landed short)
- index 2: Layup shot (the "so I laid up" is a SEPARATE throw)
- index 3: Tap-in for birdie, distanceFeet: 8, landingSpot: in_basket

Hole 13: "400 ft par 4. Threw instinct backhand but headwind flipped it into tree so I laid up and tap that in for birdie"
YOUR MISTAKE: Combined layup and tap-in into one throw (only 2 throws = eagle, not birdie!)
CORRECT (3 throws for birdie on par 4):
- index 0: Tee drive, notes: "flipped it into the tree", landingSpot: off_fairway
- index 1: Layup (the "so I laid up" is throw #2)
- index 2: Tap-in for birdie (the "tap that in" is throw #3), distanceFeet: 8, landingSpot: in_basket

Hole 14: "230 ft Par 3. Pulled my forehand to the left off the tee and hit a tree so I had to lay up which left me a 32 ft putt for par which I made"
YOUR MISTAKE: Missing layup - only counted 2 throws (tee + putt) instead of 3
CORRECT (3 throws for par on par 3):
- index 0: Tee shot, technique: forehand, notes: "pulled left, hit tree", landingSpot: off_fairway
- index 1: Layup (the "had to lay up" is a separate throw #2)
- index 2: Made putt, distanceFeet: 32, notes: "putt for par", landingSpot: in_basket

Hole 15: "250 ft tunnel shot. Threw a perfect backhand shot with my tactic and tap that in for birdie"
YOUR MISTAKE: Put "tap that in for birdie" in the notes of tee shot, making it look like ace (1 throw)
CORRECT (2 throws for birdie on par 3):
- index 0: Tee shot, technique: backhand, notes: "perfect shot down the tunnel", landingSpot: parked
- index 1: Tap-in for birdie (the "tap that in" is throw #2), distanceFeet: 8, landingSpot: in_basket

Hole 16: "340 ft downhill Par 3. Threw a forehand with a destroyer and ended up 25 ft long and I missed the putt because it went straight through the basket so I got to par on that hole"
YOUR MISTAKE: Put "missed the putt" info in tee shot notes, only counted 2 throws instead of 3
CORRECT (3 throws for par on par 3):
- index 0: Tee shot, technique: forehand, notes: "ended up 25 ft long", landingSpot: circle_1
- index 1: Missed putt (the "I missed the putt" is throw #2), distanceFeet: 25, notes: "went straight through the basket"
- index 2: Made par putt (the "got to par" is throw #3), distanceFeet: 8, landingSpot: in_basket

ENUM CATEGORY EXAMPLES - CORRECT USAGE:
Example: "Threw a backhand flex shot"
CORRECT:
- technique: backhand (HOW it was thrown)
- shotShape: flex_shot (the flight path)
WRONG: technique: flex_shot (flex_shot is NOT a technique!)

Example: "Forehand roller"
CORRECT:
- technique: forehand_roller (this is a specific throwing technique)
WRONG: technique: forehand, shotShape: roller

Example: "Backhand hyzer"
CORRECT:
- technique: backhand
- shotShape: hyzer
WRONG: technique: hyzer (hyzer is a shot shape, not a technique!)

CRITICAL ENUM FORMATTING AND USAGE:
ALL enum values MUST be in lower snake_case format with underscores between words.
For example: "circle_1" NOT "circle1", "tee_drive" NOT "teeDrive"

STRICT ENUM CATEGORY RULES - NEVER MIX CATEGORIES:
- technique: HOW the disc is thrown (backhand, forehand, etc.) - NOT shot shapes
- shotShape: The FLIGHT PATH/CURVE (hyzer, anhyzer, flex_shot, etc.) - NOT techniques
- NEVER use a shotShape value for technique or vice versa
- Example: "flex_shot" is a shotShape, NOT a technique
- Example: "backhand" is a technique, NOT a shotShape

ALLOWED ENUM VALUES (use ONLY these exact values - NEVER mix categories):
- purpose (what the throw is for): $throwPurposeValues
- technique (HOW it's thrown): $techniqueValues
- puttStyle (putt-specific technique): $puttStyleValues
- shotShape (flight path/curve): $shotShapeValues
- stance (footwork): $stanceValues
- power (effort level): $throwPowerValues
- windDirection: $windDirectionValues
- windStrength: $windStrengthValues
- resultRating: $resultRatingValues
- landingSpot (where it ended up): $landingSpotValues
- fairwayWidth: $fairwayWidthValues
- gripType: $gripTypeValues
- throwHand: $throwHandValues

OTHER FIELDS (integers, not enums):
- penaltyStrokes: Number of penalty strokes for this throw (1 for OB/water/lost disc, omit if no penalty)
- distanceFeet: Actual throw distance in feet (only when explicitly stated)

VALIDATION RULES:
- If unsure which category a value belongs to, OMIT the field entirely
- NEVER guess or place values in wrong categories
- Each field can ONLY use values from its specific enum list above

IMPORTANT YAML OUTPUT RULES:
- OMIT any field that is not explicitly mentioned in the voice input
- NEVER include fields with null values (e.g., don't write "windDirection: null")
- Only include fields that have actual values from the voice transcript
- Only use "other" when something is explicitly mentioned but doesn't match the allowed values
- Keep the YAML clean and minimal - only include what was actually said

Common disc golf terms to understand:
- "Parked" = very close to the basket
- "C1" = Circle 1, within 33 feet
- "C2" = Circle 2, 33-66 feet
- "OB" = Out of bounds
- "Ace" = Hole in one
- "Birdie" = One under par
- "Eagle" = Two under par
- "Bogey" = One over par
- "Island hole" = Hole with island green surrounded by OB (water/hazard)
- "Landed on the island" = In play, use appropriate landingSpot (fairway, circle_1, etc.)
- "Landed in the water" or "went in the water" = out_of_bounds with penaltyStrokes: 1
- For island holes: if it lands "on the island", it's NOT out_of_bounds

CRITICAL YAML FORMAT REQUIREMENTS:
1. Return ONLY raw YAML content - no markdown, no code blocks
2. Do NOT include the word 'yaml' at the beginning
3. Do NOT wrap in ``` or ```yaml
4. Do NOT add any explanatory text before or after
5. Start directly with "course:" as the first line
6. Only include fields that have values - create minimal, clean YAML

Example of CLEAN YAML output (notice only mentioned fields are included):
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
      debugPrint('Gemini connection test failed: $e');
      return false;
    }
  }

  /// Generates AI summary and coaching based on round data and analysis
  Future<Map<String, String>> generateRoundInsights({
    required DGRound round,
    required dynamic analysis, // RoundAnalysis
  }) async {
    try {
      final prompt = _buildInsightsPrompt(round, analysis);

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      // Parse response which should be JSON with 'summary' and 'coaching' keys
      final responseText = response.text ?? '{}';
      debugPrint('Gemini insights response: $responseText');

      try {
        final jsonResponse = jsonDecode(responseText);
        return {
          'summary': jsonResponse['summary']?.toString() ?? '',
          'coaching': jsonResponse['coaching']?.toString() ?? '',
        };
      } catch (jsonError) {
        debugPrint('Failed to parse JSON response: $jsonError');
        // Fallback: try to extract summary and coaching from markdown-style response
        return _extractFromMarkdownResponse(responseText);
      }
    } catch (e) {
      debugPrint('Error generating insights: $e');
      return {'summary': '', 'coaching': ''};
    }
  }

  Map<String, String> _extractFromMarkdownResponse(String text) {
    // Try to extract from markdown headers
    final summaryMatch = RegExp(
      r'(?:^|\n)(?:##?\s*)?Summary[\s:]*\n([\s\S]*?)(?=\n(?:##?\s*)?(?:Coaching|Coach|$))',
      caseSensitive: false,
    ).firstMatch(text);

    final coachingMatch = RegExp(
      r'(?:^|\n)(?:##?\s*)?(?:Coaching|Coach)[\s:]*\n([\s\S]*?)$',
      caseSensitive: false,
    ).firstMatch(text);

    return {
      'summary': summaryMatch?.group(1)?.trim() ?? text,
      'coaching': coachingMatch?.group(1)?.trim() ?? '',
    };
  }

  String _buildInsightsPrompt(DGRound round, dynamic analysis) {
    // Format disc performance data
    final discPerf = (analysis.discPerformances as List)
        .take(5)
        .map((disc) =>
            '- ${disc.discName}: ${disc.totalShots} throws, ${disc.goodPercentage.toStringAsFixed(0)}% good')
        .join('\n');

    // Format top mistakes
    final topMistakes = (analysis.mistakeTypes as List)
        .take(3)
        .map((m) => '- ${m.label}: ${m.count} (${m.percentage.toStringAsFixed(0)}%)')
        .join('\n');

    return '''
You are a professional disc golf coach analyzing a completed round. Based on the round data and statistics below, provide a comprehensive analysis in JSON format.

Return ONLY valid JSON with this exact structure:
{
  "summary": "2-3 paragraph summary here",
  "coaching": "2-3 paragraph coaching recommendations here"
}

**Summary** should cover:
- Overall performance (score relative to par: ${analysis.totalScoreRelativeToPar >= 0 ? '+' : ''}${analysis.totalScoreRelativeToPar})
- What went well (successful shots, discs, techniques)
- What didn't go well (mistakes, problem areas)
- Strokes gained/lost by category
- Disc performance highlights

**Coaching** should cover:
- Specific strategic changes for next round
- Practice priorities based on weaknesses
- Technique adjustments needed
- Disc selection recommendations

ROUND DATA:
- Course: ${round.courseName}
- Total Holes: ${round.holes.length}
- Score: ${analysis.totalScoreRelativeToPar >= 0 ? '+' : ''}${analysis.totalScoreRelativeToPar}

SCORING BREAKDOWN:
- Birdies: ${analysis.scoringStats.birdies}
- Pars: ${analysis.scoringStats.pars}
- Bogeys: ${analysis.scoringStats.bogeys}
- Double Bogey+: ${analysis.scoringStats.doubleBogeyPlus}

PUTTING STATS:
- C1 Make %: ${analysis.puttingStats.c1Percentage.toStringAsFixed(1)}%
- C2 Make %: ${analysis.puttingStats.c2Percentage.toStringAsFixed(1)}%
- Average Birdie Putt: ${analysis.avgBirdiePuttDistance.toStringAsFixed(0)} ft

DRIVING STATS:
- Fairway Hit %: ${analysis.coreStats.fairwayHitPct.toStringAsFixed(1)}%
- C1 in Regulation %: ${analysis.coreStats.c1InRegPct.toStringAsFixed(1)}%
- OB %: ${analysis.coreStats.obPct.toStringAsFixed(1)}%

DISC PERFORMANCE (Top 5):
$discPerf

MISTAKES:
- Total: ${analysis.totalMistakes}
- Driving: ${analysis.mistakesByCategory['driving']}
- Approach: ${analysis.mistakesByCategory['approach']}
- Putting: ${analysis.mistakesByCategory['putting']}

TOP MISTAKE TYPES:
$topMistakes

IMPORTANT: Return ONLY the JSON object, no other text.
''';
  }
}
