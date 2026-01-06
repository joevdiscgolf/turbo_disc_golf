import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/utils/gemini_helpers.dart';
import 'package:turbo_disc_golf/utils/string_helpers.dart';

class GeminiService {
  late final GenerativeModel _textModel; // For text parsing
  late final GenerativeModel _visionModel; // For image + text (multimodal)

  static const String twoPointFiveFlashLiteModel = 'gemini-2.5-flash-lite';
  static const String twoPointFiveFlashModel = 'gemini-2.5-flash';
  static const String twoPointZeroFlashExpModel = 'gemini-2.0-flash-exp';
  static const String onePointFiveFlashModel = 'gemini-1.5-flash';
  static const String onePointFiveFlashLatestModel = 'gemini-1.5-flash-latest';
  static const String onePointZeroProVisionModel = 'models/gemini-1.0-pro-vision';

  late final String _apiKey;

  String? _lastRawResponse; // Store the last raw response
  String? get lastRawResponse => _lastRawResponse;

  GeminiService({required String apiKey}) {
    _apiKey = apiKey;
    // Text model for voice transcript parsing
    _textModel = GenerativeModel(
      model: twoPointFiveFlashLiteModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3, // Lower temperature for more consistent parsing
        topK: 20,
        topP: 0.8,
        maxOutputTokens: 4096,
        // Removed responseMimeType to allow YAML responses
      ),
    );

    // Vision model for scorecard image processing
    // Using gemini-2.5-flash for image generation
    _visionModel = GenerativeModel(
      model: twoPointFiveFlashModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1, // Very low temperature for accurate data extraction
        topK: 10,
        topP: 0.8,
        maxOutputTokens: 2048,
      ),
    );
  }

  Future<String?> generateContent({
    required String prompt,
    bool useFullModel = false,
  }) async {
    try {
      // Use full flash model if requested, otherwise use lite model
      if (useFullModel) {
        final String modelToUse = useGeminiFallbackModel
            ? onePointFiveFlashLatestModel
            : twoPointFiveFlashModel;
        final fullModel = GenerativeModel(
          model: modelToUse,
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            temperature: 1.0, // Higher temperature for creative content
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 4096,
          ),
        );
        return fullModel
            .generateContent([Content.text(prompt)])
            .then((response) => response.text);
      } else {
        return _textModel
            .generateContent([Content.text(prompt)])
            .then((response) => response.text);
      }
    } catch (e, trace) {
      debugPrint('Error generating content with Gemini');
      debugPrint(e.toString());
      debugPrint(trace.toString());
      return null;
    }
  }

  /// Generate content with image (multimodal) - uses vision model
  Future<String?> generateContentWithImage({
    required String prompt,
    required String imagePath,
  }) async {
    try {
      // Load image bytes
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('Image file does not exist: $imagePath');
        return null;
      }

      final imageBytes = await imageFile.readAsBytes();

      // Determine MIME type based on file extension
      final extension = imagePath.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Default fallback
      }

      // Create multimodal content
      final content = Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
      ]);

      final response = await _visionModel.generateContent([content]);
      return response.text;
    } catch (e, trace) {
      debugPrint('Error generating content with image: $e');
      debugPrint(trace.toString());
      return null;
    }
  }

  // Test method to validate the service
  Future<bool> testConnection() async {
    try {
      final response = await _textModel.generateContent([
        Content.text('Reply with just "OK" to confirm the connection works.'),
      ]);
      return response.text?.contains('OK') ?? false;
    } catch (e) {
      debugPrint('Gemini connection test failed: $e');
      return false;
    }
  }

  String buildGeminiParsingPrompt(
    String voiceTranscript,
    List<DGDisc> userBag,
    String? courseName, {
    List<HoleMetadata>? preParsedHoles,
  }) {
    // Use different prompts based on whether we have pre-parsed holes
    if (preParsedHoles != null && preParsedHoles.isNotEmpty) {
      return GeminiHelpers.buildImageVoicePrompt(
        voiceTranscript,
        userBag,
        courseName,
        preParsedHoles,
      );
    } else {
      return _buildVoiceOnlyPrompt(voiceTranscript, userBag, courseName);
    }
  }

  String _buildVoiceOnlyPrompt(
    String voiceTranscript,
    List<DGDisc> userBag,
    String? courseName,
  ) {
    // Get enum values dynamically
    final throwPurposeValues = getEnumValuesAsString(ThrowPurpose.values);
    final techniqueValues = getEnumValuesAsString(ThrowTechnique.values);
    final puttStyleValues = getEnumValuesAsString(PuttStyle.values);
    final shotShapeValues = getEnumValuesAsString(ShotShape.values);
    final stanceValues = getEnumValuesAsString(StanceType.values);
    final throwPowerValues = getEnumValuesAsString(ThrowPower.values);
    final windDirectionValues = getEnumValuesAsString(WindDirection.values);
    final windStrengthValues = getEnumValuesAsString(WindStrength.values);
    final resultRatingValues = getEnumValuesAsString(ThrowResultRating.values);
    final landingSpotValues = getEnumValuesAsString(LandingSpot.values);
    final fairwayWidthValues = getEnumValuesAsString(FairwayWidth.values);
    final gripTypeValues = getEnumValuesAsString(GripType.values);
    final throwHandValues = getEnumValuesAsString(ThrowHand.values);

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
        distanceFeetAfterThrow: 50
        discName: Destroyer
        purpose: tee_drive
        technique: backhand
        shotShape: hyzer
        power: full
        notes: threw straight down the fairway
        landingSpot: fairway
      - index: 1
        distanceFeetBeforeThrow: 50
        distanceFeetAfterThrow: 0
        discName: Aviar
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
        discName: Wraith
        purpose: tee_drive
        notes: went OB right
        landingSpot: out_of_bounds
        penaltyStrokes: 1
      - index: 1
        distanceFeetAfterThrow: 35
        discName: Teebird
        purpose: tee_drive
        technique: backhand
        notes: re-teed and threw safe
        landingSpot: circle_2
      - index: 2
        distanceFeetBeforeThrow: 8
        distanceFeetAfterThrow: 0
        discName: Aviar
        purpose: putt
        notes: tapped in for bogey
        landingSpot: in_basket
  - number: 3
    throws:
      - index: 0
        purpose: tee_drive
        notes: test throw with minimal details
# IMPORTANT: Note how hole 3 omits par and feet - only include fields that are mentioned in the transcript!''';

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
3. CRITICAL - DISC NAMES: When a disc is mentioned in the transcript, include it in the throw:
   - Extract the disc name as mentioned (e.g., "halo Destroyer" → discName: halo Destroyer)
   - Match variations: "PD" could be from the bag list, "tactic" = Tactic, "destroyer" = Destroyer
   - If user says brand+mold (e.g., "Innova Destroyer"), just use the name from your bag (e.g., "Destroyer")
   - ONLY include discName if a disc is explicitly mentioned for that throw
   - Omit discName if no disc is mentioned for that throw
4. Include distanceFeetBeforeThrow and/or distanceFeetAfterThrow when positions are mentioned (see CRITICAL DISTANCE RULES below)
5. Include brief natural language description in the "notes" field

⚠️⚠️⚠️ CRITICAL PURPOSE FIELD RULES ⚠️⚠️⚠️
The "purpose" field is MANDATORY for putting stats tracking. Follow these rules STRICTLY:

- Index 0 (tee shot) → ALWAYS `purpose: tee_drive`
- "tap in" / "tapped in" / "tap that in" → ALWAYS `purpose: putt`
- Description contains "putt" / "putted" / "putting" → ALWAYS `purpose: putt`
- Description says "made the putt" / "missed the putt" → ALWAYS `purpose: putt`
- Throw with `landingSpot: in_basket` → ALWAYS `purpose: putt` (except index 0)
- Throw from C1 or C2 attempting basket → ALWAYS `purpose: putt`
- Layup / pitch out / scramble → `purpose: approach`
- Mid-range positioning shots → `purpose: approach`

NEVER omit the purpose field on putts - it's required for stats tracking!

6. Map landing positions to landingSpot enum based on WHERE THE DISC ENDED UP (distance from basket):
   - "made" or "in the basket" = in_basket
   - Within 10 feet or "parked" = parked
   - 10-33 feet or "C1" = circle_1
   - 33-66 feet or "C2" = circle_2
   - On the intended playing surface beyond C2 = fairway
   - ONLY use off_fairway when user EXPLICITLY says "off the fairway" or "off fairway"
   - "Hit a tree", "caught a tree", "clipped a tree", "stopped by tree" do NOT mean off_fairway
   - Mentions of "trees", "rough", "woods", "bushes" alone do NOT mean off_fairway (fairway can include these!)
   - Prioritize FINAL POSITION over obstacles hit: if disc ends up 80 ft from basket, use circle_2 (not off_fairway)
   - OB, water, or out of bounds = out_of_bounds
   - Missed putts: Usually omit landingSpot or use parked/circle_1 based on distance
   - NEVER use off_fairway for missed putts - putts stay near the basket

⚠️⚠️⚠️ CRITICAL VALIDATION: landingSpot MUST MATCH distanceFeetAfterThrow ⚠️⚠️⚠️
If you set distanceFeetAfterThrow, the landingSpot MUST be consistent with that distance:
   - distanceFeetAfterThrow = 0 → landingSpot: in_basket
   - distanceFeetAfterThrow ≤ 10 → landingSpot: parked
   - distanceFeetAfterThrow 11-33 → landingSpot: circle_1
   - distanceFeetAfterThrow 34-66 → landingSpot: circle_2
   - distanceFeetAfterThrow > 66 → landingSpot: fairway (or off_fairway if explicitly stated)

EXAMPLES OF CORRECT DISTANCE-LANDINGSPOT MATCHING:
- distanceFeetAfterThrow: 23, landingSpot: circle_1 ✅ CORRECT (23 ft is in C1 range)
- distanceFeetAfterThrow: 23, landingSpot: fairway ❌ WRONG! (23 ft must be circle_1)
- distanceFeetAfterThrow: 8, landingSpot: parked ✅ CORRECT
- distanceFeetAfterThrow: 45, landingSpot: circle_2 ✅ CORRECT
- distanceFeetAfterThrow: 45, landingSpot: fairway ❌ WRONG! (45 ft must be circle_2)

DO NOT let descriptive phrases like "into the green" or "in the fairway" override the numeric distance!
If distanceFeetAfterThrow = 23, it MUST be circle_1, even if the user said "into the green".

⚠️⚠️⚠️ CRITICAL: DO NOT MAKE UP DEFAULTS ⚠️⚠️⚠️
6. If par is NOT mentioned in the transcript, OMIT the par field entirely (do NOT add "par: 3" as default)
7. If hole distance is NOT mentioned, OMIT the feet field entirely (do NOT add "feet: 350" as default)
8. If the transcript provides insufficient information about a hole, you can create a minimal hole entry with just:
   - number: (hole number)
   - throws: [] (empty list if no throw details provided)
   BUT do NOT add par or feet fields unless explicitly mentioned!
9. Number holes sequentially starting from 1

CRITICAL DISTANCE RULES:
We track TWO distance measurements for each throw:
- distanceFeetBeforeThrow: How far from the basket BEFORE the throw (starting position)
- distanceFeetAfterThrow: How far from the basket AFTER the throw (ending position)

⚠️⚠️⚠️ MANDATORY: distanceFeetAfterThrow is REQUIRED for stats calculations! ⚠️⚠️⚠️
Without distanceFeetAfterThrow, we cannot calculate C1 in Regulation % and other critical stats!

WHEN TO USE EACH FIELD:
- distanceFeetBeforeThrow examples:
  - "from 70 feet" = distanceFeetBeforeThrow: 70
  - "had a 25 ft putt" = distanceFeetBeforeThrow: 25
  - "40 feet out" (when describing starting position) = distanceFeetBeforeThrow: 40

- distanceFeetAfterThrow examples (EXTRACT THESE WHENEVER POSSIBLE):
  - "to 25 feet" = distanceFeetAfterThrow: 25
  - "ended up 40 feet away" = distanceFeetAfterThrow: 40
  - "parked at 10 ft" = distanceFeetAfterThrow: 10
  - "landed 80 feet from the basket" = distanceFeetAfterThrow: 80
  - "threw it to 15 ft" = distanceFeetAfterThrow: 15
  - "approach from 140 ft into the green" + next throw from 23 ft = distanceFeetAfterThrow: 23 (infer from next throw!)

MANDATORY RULES FOR distanceFeetAfterThrow:
1. If the next throw has distanceFeetBeforeThrow, the current throw MUST have distanceFeetAfterThrow equal to that value
2. ALL approach shots MUST have distanceFeetAfterThrow (use next throw's beforeThrow if not explicitly stated)
3. "parked" = distanceFeetAfterThrow: 8 (unless specific distance given like "parked at 10 ft")
4. "made the putt" = distanceFeetAfterThrow: 0 (in basket)
5. "landed in C1" = distanceFeetAfterThrow: 30 (unless specific distance given)
6. "landed in C2" = distanceFeetAfterThrow: 50 (unless specific distance given)
7. "laid up to 10 ft" = distanceFeetAfterThrow: 10

INFERRING distanceFeetAfterThrow FROM NEXT THROW:
If throw description doesn't explicitly state ending position, but the NEXT throw has distanceFeetBeforeThrow,
then current throw's distanceFeetAfterThrow = next throw's distanceFeetBeforeThrow!

Example:
- Throw 1: "approach from 140 ft into the green" (no ending position stated)
- Throw 2: distanceFeetBeforeThrow: 23 (started from 23 ft)
- Therefore: Throw 1 MUST have distanceFeetAfterThrow: 23

SPECIAL CASES:
- "Tap in" or "tapped in" = distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0 (in basket)
- "Gimme" or "drop in" = distanceFeetBeforeThrow: 3, distanceFeetAfterThrow: 0 (in basket)
- "Threw 280 feet and ended up 50 feet away" = distanceFeetAfterThrow: 50
- "Pitch out to 25 feet" = distanceFeetAfterThrow: 25 (describes ending position)
- For tee shots, distanceFeetBeforeThrow is usually omitted (starting from tee pad)

VALIDATION BEFORE RETURNING YAML:
- Check EVERY throw (except the last) - if next throw has distanceFeetBeforeThrow, current throw MUST have distanceFeetAfterThrow
- If distanceFeetAfterThrow is missing and can be inferred, ADD IT!
- Approach shots without distanceFeetAfterThrow are INVALID - fix them!

CRITICAL THROW COUNTING - REASON THROUGH EACH HOLE:

⚠️⚠️⚠️ SCORE-FIRST VALIDATION - THIS IS ABSOLUTE TRUTH ⚠️⚠️⚠️
When the player states their score (birdie, par, bogey, eagle, etc.), that is the GROUND TRUTH.
This is NON-NEGOTIABLE and MUST be followed!

MANDATORY VALIDATION STEPS:
1. FIRST: Identify the stated score from phrases like:
   - "for birdie", "for par", "for bogey"
   - "I took a bogey", "I made par", "so I got to par"
   - "tapped in for bogey", "made putt for par"
   - "so I birdied", "so I parred"

2. SECOND: Calculate expected throw count:
   - Par 3 + "for par" = EXACTLY 3 throws (NOT 2!)
   - Par 3 + "for birdie" = EXACTLY 2 throws (NOT 1!)
   - Par 4 + "for par" = EXACTLY 4 throws (NOT 3!)
   - Par 4 + "for birdie" = EXACTLY 3 throws (NOT 2!)
   - Par 3 + "for bogey" = EXACTLY 4 throws
   - Par 4 + "for bogey" = EXACTLY 5 throws

3. THIRD: Parse the throws from the description

4. FOURTH: COUNT YOUR PARSED THROWS
   - If count doesn't match expected: YOU MADE A MISTAKE!
   - Too few throws? You MISSED a throw - go back and find it!
   - Too many throws? You created a throw from a position description (like "had a 20 ft putt")

5. FIFTH: BEFORE RETURNING - VERIFY ONE MORE TIME
   - Does throw count match the stated score? If NO, DO NOT RETURN - FIX IT!

COMMON MISTAKES YOU MAKE:
- User says "for par" but you only count 2 throws on a par 3 (should be 3!)
- User says "laid that up to tap in" and you combine them (should be 2 throws!)
- User says "for birdie" but you count 1 throw on a par 3 (should be 2!)

THE STATED SCORE IS ABSOLUTE TRUTH - YOUR THROW COUNT MUST MATCH IT!

For EVERY hole, count throws carefully by analyzing the narrative:
1. Start with the tee shot (index 0)
2. Track each subsequent throw mentioned - NEVER combine multiple throws into one
3. NEVER put information about a second throw in the notes of the first throw
   - WRONG: "ended up 25 ft long and I missed the putt" in one throw's notes
   - CORRECT: First throw notes "ended up 25 ft long", SEPARATE throw for "missed the putt"
4. CRITICAL - DON'T OVER-SPLIT SINGLE THROW DESCRIPTIONS:
   - "threw X and then ended up [position]" = ONE throw (the "ended up" describes where it landed)
   - "threw X out to the right and ended up OB" = ONE throw
   - "threw X and it went [direction/distance]" = ONE throw
   - ONLY create a new throw when a SECOND ACTION is described (re-tee, putt, approach, etc.)
   - After OB, the next throw is typically either a re-tee OR a putt/approach from drop zone
   - "missed putt and had a [distance] putt for [score]" = ONE throw (the "had a X ft putt" describes where it ended up)
   - "had a [distance] putt for [score]" is DESCRIBING POSITION after a previous action, NOT a new throw
   - Only "made/missed the putt" or "threw" indicates an actual new throwing action
5. EVERY HOLE MUST END WITH landingSpot: in_basket - holes must be completed!
6. "Took a bogey/par/birdie" or "for par/birdie/bogey" = they FINISHED the hole, add final made putt if missing
7. CRITICAL - "PARKED" ALWAYS NEEDS A TAP-IN:
   - "parked it and birdied" = 2 throws (parked + tap-in with landingSpot: in_basket)
   - "parked at 10 ft so I birdied" = the approach that parked + tap-in for birdie
   - "parked it 2 feet away" followed by score mention = add tap-in (distanceFeetBeforeThrow: 8, landingSpot: in_basket)
   - NEVER end a hole with landingSpot: parked - must add final putt with landingSpot: in_basket
8. Pay special attention to phrases that indicate multiple throws:
   - "Two putts" or "two-putted" = ALWAYS 2 separate putt throws (NEVER combine!)
   - "Three putts" or "3-putted" = ALWAYS 3 separate putt throws
   - "Missed the putt" or "I missed the putt" = ALWAYS a separate throw (don't put this in notes of previous throw!)
   - "Missed the putt, tapped in" = 2 separate throws (missed putt + tap-in)
   - "Missed the par putt" = they MISSED the putt for par, need another putt for bogey (2 throws: missed par putt + made bogey putt)
   - "Missed the birdie putt" = they MISSED the putt for birdie, need another putt for par (2 throws: missed birdie putt + made par putt)
   - "Missed the par putt, took bogey" = 2 throws (missed par putt + made bogey putt)
   - "Made the comeback putt" = 2 putts (first missed + comeback made)
   - "3-putted" or "three-putted" = ALWAYS exactly 3 putt throws (2 missed + 1 made)
   - "so I got to par/birdie/bogey" = they finished the hole, verify throw count matches stated score
   - "Two putts for par/birdie/bogey" = ALWAYS create 2 separate putt entries
   - "so I laid up" or "had to lay up" = a separate layup/approach throw AFTER the previous throw
   - "laid up and tapped in" = 2 SEPARATE throws (layup + tap-in, NEVER combine these!)
   - "laid that up to tap in" = 2 SEPARATE throws (layup + tap-in, NEVER combine these!)
   - "laid it up to tap in" = 2 SEPARATE throws (layup + tap-in, NEVER combine these!)
   - "laid that up and tap(ped) in" = 2 SEPARATE throws (layup + tap-in, NEVER combine these!)
   - ANY phrase with "laid" + "up" + "tap" + "in" = 2 SEPARATE throws, ALWAYS!
   - "which left me a [distance] putt" = the previous action was a SEPARATE throw
   - "and tap that in" or "and tapped that in" = ALWAYS a separate throw from the previous
   - "Tap in" or "tapped in" or "tap that in" = ALWAYS a separate throw (ALWAYS use 8 feet for tap-in distance)
   - "Pitch out" = a separate approach/scramble throw
   - "Scrambled" = a recovery throw
   - "approach from X AND made Y ft putt" = 2 SEPARATE throws (approach + putt)
   - "approach into the green AND made putt" = 2 SEPARATE throws (approach + putt)
   - NEVER combine approach and putt into one throw - they are ALWAYS separate actions
   CRITICAL: When you see "laid up" followed by "tap in", you MUST create two separate throw entries!
   CRITICAL: When you see "which left me" or "left me a putt", the previous action was a separate throw!
   CRITICAL: When you see "two putts", you MUST create two separate throw entries!
   CRITICAL: "and tap that in for [score]" almost NEVER means hole-in-one - it's a separate tap-in after previous throw(s)!
   CRITICAL: "approach AND made putt" = 2 throws (approach + putt), NEVER combine these!
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
   - Double Bogey on par 3 = exactly 5 throws (or 4 throws + 1 penalty)
   - LAST THROW MUST HAVE landingSpot: in_basket
   - If your throw count doesn't match the score, you MISSED A THROW - go back and find it!
   - VALIDATION PROCESS: For each hole, ask yourself:
     1. What score did they say? (birdie/par/bogey/etc.)
     2. What's the par?
     3. Calculate: par + score difference = expected throw count
     4. Count your parsed throws
     5. If counts don't match, you MISSED a throw - re-read the description!
   - BEFORE returning results, count your throws and verify they match the stated score!


EXAMPLES FROM YOUR ACTUAL MISTAKES:

Hole 2: "250 ft par 3. I threw my fd3 to Circle one about 25 ft away missed the putt off the cage and then miss the par putt because it's bad back at me so I took a bogey there"
SCORE VALIDATION: "I took a bogey" on par 3 = 4 throws total (par 3 + 1 = 4)
YOUR MISTAKES: 1) Only counted 3 throws instead of 4, 2) Didn't detect 3-putt, 3) Ignored explicit "took a bogey"
CRITICAL: "missed the par putt" means they MISSED the putt that would have been for par, so they need ANOTHER putt for bogey!
CORRECT (4 throws for bogey on par 3):
- index 0: Tee shot, notes: "threw fd3 to circle one", distanceFeetAfterThrow: 25, landingSpot: circle_1, purpose: tee_drive
- index 1: First putt (missed off cage), distanceFeetBeforeThrow: 25, notes: "missed the putt off the cage", landingSpot: circle_1, purpose: putt
- index 2: Second putt (missed the par putt), distanceFeetBeforeThrow: 8, notes: "miss the par putt because it bounced back", purpose: putt
- index 3: Third putt (made for bogey), distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, notes: "made for bogey", landingSpot: in_basket, purpose: putt (MUST end in basket!)

Hole 3: "380 ft par 3. Threw forehand 70 ft short. Tried putt from 70 ft, rolled to 15 ft, missed that 15 ft putt, took bogey"
YOUR MISTAKE: Didn't complete the hole - stopped after missed putt
CORRECT (4 throws for bogey):
- index 0: Tee drive, distanceFeetAfterThrow: 70, landingSpot: circle_2, purpose: tee_drive (70 ft away)
- index 1: Long putt attempt, distanceFeetBeforeThrow: 70, distanceFeetAfterThrow: 15, purpose: putt (rolled to 15 ft)
- index 2: Missed 15 ft putt, distanceFeetBeforeThrow: 15, purpose: putt
- index 3: Made bogey putt, distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt (completed hole!)

Hole 6: "island hole 200 feet par 3. Played it safe with Judge, landed on the island 40 feet short. Missed the putt, tapped in for par."
YOUR MISTAKE: Only counted 2 throws, used wrong landingSpot
CORRECT (3 throws for par on par 3):
- index 0: Tee shot, distanceFeetAfterThrow: 40, landingSpot: circle_2, purpose: tee_drive (40 feet = C2 range, "on island" = NOT out_of_bounds)
- index 1: Missed putt, distanceFeetBeforeThrow: 40, purpose: putt
- index 2: Tap-in, distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt (ALWAYS 8 for tap-in)

Hole 7: "475 feet par 4. Threw Firebird 280 feet. Threw Buzzz 195 feet into rough. Pitch out to 25 feet, made putt for par."
YOUR MISTAKE: Used "to 25 feet" as throw distance for the pitch out
CORRECT (4 throws for par on par 4):
- index 0: Drive, purpose: tee_drive (no afterThrow distance mentioned)
- index 1: Approach, purpose: approach (no afterThrow distance mentioned)
- index 2: Pitch out, distanceFeetAfterThrow: 25, purpose: approach ("to 25 feet" is final position)
- index 3: Putt, distanceFeetBeforeThrow: 25, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt

Hole 8: "Threw River hyzer flip but went OB. Re-teed, threw Buzzz 280 feet. Made 35 foot putt for bogey."
CORRECT (bogey = 4 strokes on par 3):
- index 0: First tee (OB), landingSpot: out_of_bounds, penaltyStrokes: 1, purpose: tee_drive
- index 1: Re-tee, purpose: tee_drive (no afterThrow distance mentioned)
- index 2: Putt, distanceFeetBeforeThrow: 35, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt

Hole 9: "Approached from 70 feet to circle 1. Two putts for par."
YOUR MISTAKE: Combined "two putts" into one throw
CORRECT ("two putts" = 2 separate throws):
- Approach, distanceFeetBeforeThrow: 70, distanceFeetAfterThrow: 30, purpose: approach (to circle_1)
- First putt (missed), purpose: putt
- Second putt (made), distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt

Hole 10: "Threw Star Destroyer 380 feet. Long jump putt from 45 feet hit cage but didn't go in. Tapped in for par."
YOUR MISTAKE: Combined drive and jump putt into one throw's notes
CORRECT (3 separate throws):
- index 0: Drive, distanceFeetAfterThrow: 45, landingSpot: circle_2, purpose: tee_drive
- index 1: Jump putt (missed), distanceFeetBeforeThrow: 45, purpose: putt
- index 2: Tap-in, distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt

Hole 12: "780 ft par 5. Threw cloudbreaker left side of fairway. Second shot caught tree and landed short so I laid up and tapped in my birdie"
YOUR MISTAKE: Missed the layup shot - counted only 3 throws instead of 4 for birdie
CORRECT (4 throws for birdie on par 5):
- index 0: Tee drive, landingSpot: fairway, purpose: tee_drive
- index 1: Second shot (caught tree, landed short), purpose: approach
- index 2: Layup shot (the "so I laid up" is a SEPARATE throw), purpose: approach
- index 3: Tap-in for birdie, distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt

Hole 13: "400 ft par 4. Threw instinct backhand but headwind flipped it into tree so I laid up and tap that in for birdie"
YOUR MISTAKE: Combined layup and tap-in into one throw (only 2 throws = eagle, not birdie!)
CORRECT (3 throws for birdie on par 4):
- index 0: Tee drive, notes: "flipped it into the tree", landingSpot: off_fairway, purpose: tee_drive
- index 1: Layup (the "so I laid up" is throw #2), purpose: approach
- index 2: Tap-in for birdie (the "tap that in" is throw #3), distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt

Hole 14: "230 ft Par 3. Pulled my forehand to the left off the tee and hit a tree so I had to lay up which left me a 32 ft putt for par which I made"
YOUR MISTAKE: Missing layup - only counted 2 throws (tee + putt) instead of 3
CORRECT (3 throws for par on par 3):
- index 0: Tee shot, technique: forehand, notes: "pulled left, hit tree", landingSpot: off_fairway, purpose: tee_drive
- index 1: Layup (the "had to lay up" is a separate throw #2), distanceFeetAfterThrow: 32, purpose: approach
- index 2: Made putt, distanceFeetBeforeThrow: 32, distanceFeetAfterThrow: 0, notes: "putt for par", landingSpot: in_basket, purpose: putt

Hole 15: "250 ft tunnel shot. Threw a perfect backhand shot with my tactic and tap that in for birdie"
YOUR MISTAKE: Put "tap that in for birdie" in the notes of tee shot, making it look like ace (1 throw)
CORRECT (2 throws for birdie on par 3):
- index 0: Tee shot, technique: backhand, notes: "perfect shot down the tunnel", landingSpot: parked, purpose: tee_drive
- index 1: Tap-in for birdie (the "tap that in" is throw #2), distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt

Hole 16: "340 ft downhill Par 3. Threw a forehand with a destroyer and ended up 25 ft long and I missed the putt because it went straight through the basket so I got to par on that hole"
YOUR MISTAKE: Put "missed the putt" info in tee shot notes, only counted 2 throws instead of 3
CORRECT (3 throws for par on par 3):
- index 0: Tee shot, technique: forehand, notes: "ended up 25 ft long", distanceFeetAfterThrow: 25, landingSpot: circle_1, purpose: tee_drive
- index 1: Missed putt (the "I missed the putt" is throw #2), distanceFeetBeforeThrow: 25, notes: "went straight through the basket", purpose: putt
- index 2: Made par putt (the "got to par" is throw #3), distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt

Hole 4: "380 ft par 3. I threw a backhand hyzer with a pd2 out to the right and then I ended up 25 ft long and out of bounds and I made my par putt from 25 ft"
YOUR MISTAKE: Split one tee shot description into TWO throws (tee + phantom approach)
CRITICAL: "threw X and then I ended up [position]" describes ONE throw, not two!
CORRECT (2 throws for par on par 3):
- index 0: Tee shot, technique: backhand, shotShape: hyzer, notes: "threw pd2 out to the right, ended up 25 ft long and out of bounds", distanceFeetAfterThrow: 25, landingSpot: out_of_bounds, penaltyStrokes: 1, purpose: tee_drive
- index 1: Made putt from drop zone, distanceFeetBeforeThrow: 25, distanceFeetAfterThrow: 0, notes: "made par putt", landingSpot: in_basket, purpose: putt

Hole 1: "600 ft par 4. I threw my halo Destroyer off the tee and it ended up just into the trees and 140 ft away and I threw a forehand upshot with my razor claw and that parked at 10 ft away so I birdied"
YOUR MISTAKE: Only counted 2 throws, missing tap-in after "parked...so I birdied"
CRITICAL: "parked...so I birdied" means they FINISHED the hole - add tap-in!
CORRECT (3 throws for birdie on par 4):
- index 0: Tee shot, technique: backhand, notes: "ended up just into the trees", distanceFeetAfterThrow: 140, landingSpot: fairway, purpose: tee_drive
- index 1: Upshot, technique: forehand, distanceFeetBeforeThrow: 140, distanceFeetAfterThrow: 10, notes: "parked at 10 ft", landingSpot: parked, purpose: approach
- index 2: Tap-in for birdie, distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt

Hole 2: "170 ft par 3. I threw a forehand tactic out to the left side on hyzer and parked it two feet away"
YOUR MISTAKE: Only counted 1 throw, missing tap-in after "parked"
CRITICAL: When hole ends with "parked" and no more description, add tap-in to complete hole
CORRECT (2 throws for birdie on par 3):
- index 0: Tee shot, technique: forehand, shotShape: hyzer, notes: "parked two feet away", distanceFeetAfterThrow: 2, landingSpot: parked, purpose: tee_drive
- index 1: Tap-in, distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt

Hole 5: "440 ft par 4. I threw a forehand off the tee and had another forehand approach from 140 ft into the green and made a 23 ft putt for birdie"
YOUR MISTAKE: Combined approach and putt into ONE throw
CRITICAL: "approach from X AND made Y ft putt" = TWO separate throws!
CORRECT (3 throws for birdie on par 4):
- index 0: Tee drive, technique: forehand, landingSpot: fairway, purpose: tee_drive
- index 1: Approach, technique: forehand, distanceFeetBeforeThrow: 140, notes: "approach from 140 ft into the green", purpose: approach
- index 2: Made putt, distanceFeetBeforeThrow: 23, distanceFeetAfterThrow: 0, notes: "made putt for birdie", landingSpot: in_basket, purpose: putt

Hole 17: "700 ft par 4. I threw a hyzer flip and ended up in the fairway. I threw a skip shot which rolled and ended up 35 ft away. I missed that putt for birdie and had a 20 ft putt back for par. I missed that putt for par and made a 20-ft putt for bogey."
YOUR MISTAKE: Created a throw for "had a 20 ft putt back for par" - that's describing position, not a new throw! Counted 6 throws (double bogey) instead of 5 (bogey)
CRITICAL: "had a [distance] putt for [score]" describes where the previous putt ended up, NOT a new throw!
CRITICAL: "made X ft putt for bogey" = the final score is bogey, validate throw count matches!
CORRECT (5 throws for bogey on par 4):
- index 0: Tee drive, shotShape: hyzer_flip, landingSpot: fairway, purpose: tee_drive
- index 1: Approach/skip shot, notes: "rolled and ended up 35 ft away", distanceFeetAfterThrow: 35, landingSpot: circle_2, purpose: approach
- index 2: Missed birdie putt, distanceFeetBeforeThrow: 35, distanceFeetAfterThrow: 20, notes: "missed putt for birdie, had 20 ft putt back", landingSpot: circle_1, purpose: putt
- index 3: Missed par putt, distanceFeetBeforeThrow: 20, notes: "missed putt for par", landingSpot: circle_1, purpose: putt
- index 4: Made bogey putt, distanceFeetBeforeThrow: 20, distanceFeetAfterThrow: 0, notes: "made putt for bogey", landingSpot: in_basket, purpose: putt

Hole 14: "340 ft Par 3. Threw it a little bit short and left to 50 ft and laid that up to tap in for par."
YOUR MISTAKE: Combined "laid that up to tap in" into ONE throw, counted only 2 throws = birdie, but user said "for par"!
SCORE VALIDATION: User said "for par" on Par 3 = EXACTLY 3 throws required!
CRITICAL: "laid that up to tap in" = TWO separate throws (layup + tap-in)!
CRITICAL: User said "for par" which is ABSOLUTE TRUTH - throw count MUST be 3!
CORRECT (3 throws for par on par 3):
- index 0: Tee shot, distanceFeetAfterThrow: 50, notes: "a little bit short and left", landingSpot: circle_2, purpose: tee_drive
- index 1: Layup (the "laid that up" is throw #2), notes: "laid up", purpose: approach
- index 2: Tap-in for par (the "tap in" is throw #3), distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, notes: "tapped in for par", landingSpot: in_basket, purpose: putt

Hole 15: "300 ft Par 3. Threw a forehand into a tree on the left and that ended up 50 ft away and I laid that up to tap in for the par."
YOUR MISTAKE: Combined "laid that up to tap in" into ONE throw, counted only 2 throws = birdie, but user said "for the par"!
SCORE VALIDATION: User said "for the par" on Par 3 = EXACTLY 3 throws required!
CRITICAL: "laid that up to tap in" = TWO separate throws (layup + tap-in)!
CORRECT (3 throws for par on par 3):
- index 0: Tee shot, technique: forehand, distanceFeetAfterThrow: 50, notes: "into a tree on the left", landingSpot: circle_2, purpose: tee_drive
- index 1: Layup (the "laid that up" is throw #2), distanceFeetBeforeThrow: 50, notes: "laid up", purpose: approach
- index 2: Tap-in for par (the "tap in" is throw #3), distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, notes: "tapped in for par", landingSpot: in_basket, purpose: putt

EXAMPLES - CRITICAL MISSING distanceFeetAfterThrow ERRORS:

Hole 5: "440 ft par 4. I threw a forehand off the tee and had another forehand approach from 140 ft into the green and made a 23 ft putt for birdie"
YOUR MISTAKE: Approach throw missing distanceFeetAfterThrow!
YAML YOU CREATED (WRONG):
- index 0: purpose: tee_drive, technique: forehand
- index 1: purpose: approach, technique: forehand, distanceFeetBeforeThrow: 140, notes: "approach from 140 ft into the green"
  ❌ MISSING distanceFeetAfterThrow!
- index 2: purpose: putt, distanceFeetBeforeThrow: 23, distanceFeetAfterThrow: 0, landingSpot: in_basket

WHY THIS IS WRONG: Without distanceFeetAfterThrow on throw 1, we cannot calculate C1 in Regulation!
The next throw (index 2) starts from 23 ft (distanceFeetBeforeThrow: 23), so throw 1 MUST have ended at 23 ft!

CORRECT:
- index 0: purpose: tee_drive, technique: forehand, landingSpot: fairway
- index 1: purpose: approach, technique: forehand, distanceFeetBeforeThrow: 140, distanceFeetAfterThrow: 23, notes: "approach from 140 ft into the green"
  ✅ distanceFeetAfterThrow: 23 (inferred from next throw!)
- index 2: purpose: putt, distanceFeetBeforeThrow: 23, distanceFeetAfterThrow: 0, notes: "made a 23 ft putt for birdie", landingSpot: in_basket

Hole 10: "550 ft par 4. Threw Wraith backhand turnover, hit a tree stopping at 80 ft short. Laid up that putt to about 10 ft. Tapped in for birdie."
YOUR MISTAKE: Layup missing distanceFeetAfterThrow!
YAML YOU CREATED (WRONG):
- index 0: distanceFeetAfterThrow: 80, landingSpot: circle_2, purpose: tee_drive
- index 1: distanceFeetBeforeThrow: 10, notes: "laid up that putt to about 10 ft", purpose: putt
  ❌ MISSING distanceFeetAfterThrow!
  ❌ WRONG distanceFeetBeforeThrow (should be 80, not 10!)
- index 2: distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, landingSpot: in_basket, purpose: putt

WHY THIS IS WRONG: Throw 1 says "to about 10 ft" - that's the ENDING position (distanceFeetAfterThrow), not starting!

CORRECT:
- index 0: distanceFeetAfterThrow: 80, landingSpot: circle_2, purpose: tee_drive
- index 1: distanceFeetBeforeThrow: 80, distanceFeetAfterThrow: 10, notes: "laid up to about 10 ft", purpose: putt
  ✅ Started from 80 ft (where drive ended), ended at 10 ft
- index 2: distanceFeetBeforeThrow: 10, distanceFeetAfterThrow: 0, notes: "tapped in for birdie", landingSpot: in_basket, purpose: putt

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
- technique: HOW the disc is thrown (backhand, forehand, etc.) - NOT shot shapes, NOT stances
- shotShape: The FLIGHT PATH/CURVE (hyzer, anhyzer, flex_shot, etc.) - NOT techniques
- stance: FOOTWORK TYPE (standstill, x_step, patent_pending) - NOT techniques
- NEVER use a shotShape value for technique or vice versa
- NEVER use a stance value for technique or vice versa
- Example: "flex_shot" is a shotShape, NOT a technique
- Example: "backhand" is a technique, NOT a shotShape
- Example: "standstill" is a stance, NOT a technique

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

CRITICAL: For the 'technique' field, you MUST use ONLY these values: $techniqueValues
DO NOT use "standstill" for technique - that is a stance value!
DO NOT use "hyzer", "anhyzer", "flex_shot", etc. for technique - those are shotShape values!

OTHER FIELDS (integers, not enums):
- penaltyStrokes: Number of penalty strokes for this throw (1 for OB/water/lost disc, omit if no penalty)
- distanceFeetBeforeThrow: Distance from basket before the throw (starting position in feet)
- distanceFeetAfterThrow: Distance from basket after the throw (ending position in feet)

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

⚠️⚠️⚠️ FINAL VALIDATION BEFORE RETURNING YAML ⚠️⚠️⚠️
Before you return the YAML, YOU MUST validate:
1. Throw count matches stated score (birdie/par/bogey)
2. Every putt has `purpose: putt`
3. Every throw (except last in hole) has `distanceFeetAfterThrow` OR can infer from next throw's `distanceFeetBeforeThrow`
4. If throw N+1 has `distanceFeetBeforeThrow: X`, throw N MUST have `distanceFeetAfterThrow: X`
5. All approach shots have `distanceFeetAfterThrow`
6. Every hole ends with `landingSpot: in_basket`
7. ⚠️ CRITICAL: landingSpot MUST MATCH distanceFeetAfterThrow distance ranges:
   - 0 ft = in_basket
   - 1-10 ft = parked
   - 11-33 ft = circle_1
   - 34-66 ft = circle_2
   - 67+ ft = fairway (or off_fairway if explicitly stated)

If ANY of these are missing or INCORRECT, GO BACK AND FIX THEM before returning!

Example of CLEAN YAML output (notice only mentioned fields are included):
$schemaExample
''';
  }
}
