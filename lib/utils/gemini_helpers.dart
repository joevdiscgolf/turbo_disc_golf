import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/string_helpers.dart';

abstract class GeminiHelpers {
  static String buildGeminiSingleHoleParsingPrompt(
    String voiceTranscript,
    List<DGDisc> userBag,
    int holeNumber,
    int holePar,
    int? holeFeet,
    String courseName,
  ) {
    // Get enum values dynamically
    final throwPurposeValues = getEnumValuesAsString(ThrowPurpose.values);
    final techniqueValues = getEnumValuesAsString(ThrowTechnique.values);
    final puttStyleValues = getEnumValuesAsString(PuttStyle.values);
    final shotShapeValues = getEnumValuesAsString(ShotShape.values);
    final stanceValues = getEnumValuesAsString(StanceType.values);
    final throwPowerValues = getEnumValuesAsString(ThrowPower.values);
    final landingSpotValues = getEnumValuesAsString(LandingSpot.values);

    // Create disc list string
    final discListString = userBag
        .map(
          (disc) =>
              '- ${disc.name} (${disc.moldName ?? "Unknown mold"} by ${disc.brand ?? "Unknown brand"})',
        )
        .join('\n');

    final String parLine = holePar > 0
        ? 'par: $holePar'
        : '# par: (infer from description or omit)';
    final schemaExample =
        '''
number: $holeNumber
$parLine${holeFeet != null ? '\nfeet: $holeFeet' : ''}
throws:
  - index: 0
    discName: Destroyer
    purpose: tee_drive
    technique: backhand
    distanceFeetAfterThrow: 25
    landingSpot: circle_1
    notes: threw it close
  - index: 1
    distanceFeetBeforeThrow: 25
    distanceFeetAfterThrow: 0
    discName: Aviar
    purpose: putt
    notes: made the putt
    landingSpot: in_basket''';

    return '''
Parse disc golf hole description into YAML. Return ONLY raw YAML (no markdown/code blocks).

CONTEXT: Hole $holeNumber, Par ${holePar > 0 ? holePar : '?'}${holeFeet != null ? ', Distance $holeFeet ft' : ''}, $courseName
TRANSCRIPT: "$voiceTranscript"
DISC BAG: $discListString

OUTPUT FIELDS:
- number: $holeNumber (required)
- par: ${holePar > 0 ? holePar : '?'} (required)${holeFeet != null ? '\n- feet: $holeFeet (required - use this value from context)' : '\n- feet: extract from transcript if mentioned (e.g., "620 foot" → feet: 620), otherwise omit entirely'}
- throws: array of throw objects (required)

THROW STRUCTURE:
- index: 0, 1, 2... (throw number, required)
- purpose: $throwPurposeValues (required, index 0 = tee_drive)
- technique: $techniqueValues
- discName: match from bag if mentioned
- distanceFeetBeforeThrow: starting distance from basket
- distanceFeetAfterThrow: ending distance from basket
- landingSpot: $landingSpotValues (in_basket=0ft, parked=≤10ft, circle_1=11-33ft, circle_2=34-66ft, fairway=>66ft)
- notes: brief description

COMMON PATTERNS:
"parked" → distanceFeetAfterThrow: 8, landingSpot: parked, THEN add final putt (in_basket)
"made putt" → distanceFeetAfterThrow: 0, landingSpot: in_basket
"tap in" → distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0, purpose: putt, landingSpot: in_basket
"laid up and tapped in" → 2 separate throws
"birdied/parred/bogeyed" → hole is finished, last throw must have landingSpot: in_basket

CRITICAL: Every hole MUST end with landingSpot: in_basket. If they finished the hole (any score mentioned), add a final throw with distanceFeetAfterThrow: 0 and landingSpot: in_basket.

IMPORTANT: Only include fields with actual values. Never include null values or empty fields.

EXAMPLE:
$schemaExample
''';
  }

  static String buildGeminiInsightsPrompt(DGRound round, dynamic analysis) {
    // Format disc performance data
    final discPerf = (analysis.discPerformances as List)
        .take(5)
        .map(
          (disc) =>
              '- ${disc.discName}: ${disc.totalShots} throws, ${disc.goodPercentage.toStringAsFixed(0)}% good',
        )
        .join('\n');

    // Format top mistakes
    final topMistakes = (analysis.mistakeTypes as List)
        .take(3)
        .map(
          (m) =>
              '- ${m.label}: ${m.count} (${m.percentage.toStringAsFixed(0)}%)',
        )
        .join('\n');

    return '''
You are a professional disc golf coach analyzing a completed round. Based on the round data and statistics below, provide a comprehensive, honest analysis with specific numbers to back up every claim.

TONE AND STYLE:
- Write like a COACH talking to a player, not an academic report
- Be conversational, direct, and constructive - sound human
- Use "you" statements: "You gave yourself birdie chances" NOT "This metric indicates consistent birdie opportunity creation"
- Avoid formal/academic language: NO "this demonstrates", "this indicates", "this metric shows", "this suggests"
- Avoid overly enthusiastic language (no "remarkable", "outstanding", "exceptional")
- Avoid judgmental or snarky language (no "never ideal", "unfortunately", "sadly")
- Use specific numbers for EVERY claim (e.g., "you made 3/5 C2 putts" not "good putting")
- Present facts in a natural, conversational way
- Focus on constructive feedback - what to work on and why
- When mentioning disc performance, cite specific stats (percentage of good throws, total throws)
- DO NOT explain what stats mean - users already understand disc golf metrics
- Focus on IMPACT: how the stat affected their score, round, or performance
- Example: Say "You parked 67% of your approaches in C1, setting up most of your birdie attempts" NOT "This C1 in regulation rate of 67% indicates that you consistently created birdie opportunities"

ROUND DATA:
- Course: ${round.courseName}
- Total Holes: ${round.holes.length}
- Score: ${analysis.totalScoreRelativeToPar >= 0 ? '+' : ''}${analysis.totalScoreRelativeToPar}

SCORING BREAKDOWN:
- Birdies: ${analysis.scoringStats.birdies}
- Pars: ${analysis.scoringStats.pars}
- Bogeys: ${analysis.scoringStats.bogeys}
- Double Bogey+: ${analysis.scoringStats.doubleBogeyPlus}

PUTTING STATS (Focus on C1x - it's the key metric!):
- C1x Make % (12-33ft outer ring): ${analysis.puttingStats.c1xPercentage.toStringAsFixed(1)}% - THE KEY STAT!
- C1x attempts: ${analysis.puttingStats.c1xAttempts}
- C1x makes: ${analysis.puttingStats.c1xMakes}
- C1x misses: ${analysis.puttingStats.c1xMisses}
- C1 Make % (includes bulls-eye 1-11ft): ${analysis.puttingStats.c1Percentage.toStringAsFixed(1)}%
- C1 attempts: ${analysis.puttingStats.c1Attempts}
- C1 makes: ${analysis.puttingStats.c1Makes}
- C1 misses: ${analysis.puttingStats.c1Misses}
- C2 Make %: ${analysis.puttingStats.c2Percentage.toStringAsFixed(1)}%
- C2 attempts: ${analysis.puttingStats.c2Attempts}
- C2 makes: ${analysis.puttingStats.c2Makes}
- C2 misses: ${analysis.puttingStats.c2Misses}
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

INTERACTIVE STAT CARDS:
You can embed small, lightweight stat card widgets within your response to visualize single metrics alongside text. These cards help tell the story visually - use them to highlight key stats you're discussing.

Available Stat Cards (organized by category):

PUTTING CARDS (prioritize C1X - it's the most impactful putting stat!):
- [STAT_CARD:C1X_PUTTING] - C1x (12-33ft outer ring) makes/attempts - KEY STAT! Most important putts.
- [STAT_CARD:C1_PUTTING] - Overall C1 makes/attempts (includes easy 1-11ft bullseye putts)
- [STAT_CARD:C2_PUTTING] - C2 makes/attempts with percentage (e.g., "3/5 (60%)")
- [STAT_CARD:PUTTING_COMPARISON] - C1 vs C2 percentages side-by-side

IMPORTANT: When discussing putting performance, focus on C1X stats (12-33ft) rather than overall C1, because:
- Bulls-eye putts (1-11ft) are almost always made (~100%)
- C1x putts (12-33ft) are the ones that actually matter and separate good from great putting
- Overall C1 percentage can be misleading if most attempts are short bullseye putts

DRIVING/APPROACH CARDS (prioritize C1_IN_REG - it means birdie opportunities!):
- [STAT_CARD:C1_IN_REG] - C1 in regulation % (parked inside 33ft for birdie chances - KEY STAT!)
- [STAT_CARD:FAIRWAY_HIT] - Fairway hit percentage
- [STAT_CARD:OB_RATE] - Out of bounds percentage

SCORING CARDS:
- [STAT_CARD:BIRDIES] - Total birdies count
- [STAT_CARD:BOGEYS] - Total bogeys count
- [STAT_CARD:SCORING_MIX] - Scoring breakdown (birdies/pars/bogeys/double+)

MISTAKE CARDS:
- [STAT_CARD:TOTAL_MISTAKES] - Total mistakes count
- [STAT_CARD:DRIVING_MISTAKES] - Driving mistakes count
- [STAT_CARD:PUTTING_MISTAKES] - Putting mistakes count
- [STAT_CARD:APPROACH_MISTAKES] - Approach mistakes count

MENTAL GAME CARDS:
- [STAT_CARD:BOUNCE_BACK] - Bounce back rate (recovery from bogeys)
- [STAT_CARD:HOT_STREAK] - Birdie rate after birdies
- [STAT_CARD:COLD_STREAK] - Bogey+ rate after bogeys

DISC PERFORMANCE CARDS:
- [STAT_CARD:TOP_DISC] - Top performing disc with stats
- [STAT_CARD:DISC_COUNT] - Number of discs used

HOW TO USE STAT CARDS:
1. Place markers BETWEEN paragraphs on their own line
2. Use them to visualize the specific stat you're discussing in that section
3. These are small, focused cards - perfect for highlighting single metrics
4. Don't overuse - 1-2 cards per section maximum
5. Choose cards that directly relate to the point you're making
6. Use UPPERCASE format: [STAT_CARD:CARD_NAME] (though lowercase also works)

EXAMPLES:
## Strengths
You nailed 8 out of 10 C1 putts for 80%.

[STAT_CARD:C1_PUTTING]

That consistency from circle edge saved you several strokes throughout the round.

## Areas to Improve
You only parked it inside C1 on 2 of 18 holes (11%), which cost you birdie opportunities.

[STAT_CARD:C1_IN_REG]

Work on approach accuracy - get those approaches inside 33 feet more consistently to create better scoring chances.

FORMAT YOUR RESPONSE IN MARKDOWN EXACTLY LIKE THIS:

## Round Overview
[Write 1 paragraph with high-level summary: final score, total birdies/pars/bogeys, and one key takeaway]

## Strengths
[Write 1-2 paragraphs highlighting what went well with SPECIFIC NUMBERS. State the stat and explain its IMPACT on the round/score. Sound like a coach: "You made 8/10 C1x putts (80%), saving several strokes and keeping momentum going" NOT formal language like "This putting performance indicates strong execution from the outer circle". Focus on the top 2-3 strongest areas]

## Areas to Improve
[Write 2-3 paragraphs covering weaknesses with SPECIFIC NUMBERS and IMMEDIATE actionable advice. State the stat and explain how it AFFECTED the score, then give immediate action.
Example: "You only parked it in C1 on 2 of 18 holes (11%), costing you multiple birdie opportunities. Focus on approach accuracy drills - practice throwing to a target from 150-200 feet, aiming to land within the 33-foot circle." NOT "meaning you didn't get close enough for easy putts"]

## Practice Recommendations
[Write 1-2 paragraphs with specific drills, techniques, or practice routines based on the biggest weaknesses. Be concrete and actionable.
Example: "Set up a putting practice routine from 15-25 feet. Start with 10 putts from 15ft, then 20ft, then 25ft. Track your make percentage and aim for 70%+ from 20ft."]

## Course Management Tips
[Write 1 paragraph about strategic adjustments for future rounds: disc selection insights, course strategy, mental game improvements based on the data]

CRITICAL FORMATTING RULES:
- Return raw markdown (use ## for section headings)
- Do NOT use JSON format
- Do NOT wrap in markdown code blocks (no ``` or ```markdown)
- Be specific with numbers for EVERY claim
- Avoid overly enthusiastic language - be direct and honest
- Start directly with "## Round Overview" as the first line
- DO NOT include "# " top-level headings - only use ## subheadings
- Flow naturally from analysis to action - don't repeat yourself
- DO NOT explain what stats mean (user already knows) - focus on IMPACT and how it affected the round/score
- Example: Say "67% C1 in regulation set up most of your birdie chances" NOT "meaning you got within 33 feet on most holes, creating birdie opportunities"
''';
  }

  static String buildScorecardExtractionPrompt() {
    return '''
You are a disc golf scorecard data extractor. Analyze the attached scorecard image and extract hole information.

TASK:
Extract hole number, par, distance (in feet), and score for EVERY hole visible in the image.

OUTPUT FORMAT:
Return ONLY a JSON array of holes. Do NOT include any explanatory text.

REQUIRED FIELDS:
- holeNumber: integer (1-18)
- par: integer (3-5)
- distanceFeet: integer or null (if not visible)
- score: integer (player's score for that hole)

CRITICAL RULES:
1. Extract ALL holes visible in the image (typically 9 or 18 holes)
2. If distance is not visible or unclear, use null
3. Par and score are REQUIRED - if you can't read them, skip that hole
4. Return ONLY the JSON array, no markdown formatting
5. Do NOT wrap in ```json or any code blocks
6. Start directly with the opening bracket [

IMPORTANT - COLOR-CODED SCORES:
Disc golf scorecards often use color-coding to indicate score performance:
- GREEN background/circle = Birdie (1 under par) - EXTRACT THESE
- WHITE/CLEAR background = Par (even with par) - EXTRACT THESE
- LIGHT GRAY background = Bogey (1 over par) - EXTRACT THESE TOO!
- DARK GRAY background = Double bogey or worse (2+ over par) - EXTRACT THESE TOO!

⚠️ CRITICAL: You MUST extract ALL holes regardless of background color!
Gray backgrounds (bogeys/worse) are JUST AS IMPORTANT as green (birdies) or white (pars).
Do NOT skip holes with gray backgrounds - they may have slightly lower contrast but the numbers are still readable.

VALIDATION:
- After extraction, count how many holes you found
- If you found less than 9 or 18 holes, you likely MISSED some gray-background holes
- Go back and look specifically for gray-colored score circles/backgrounds
- Extract ALL holes you can see, don't skip any!

EXAMPLE OUTPUT:
[
  {"holeNumber": 1, "par": 3, "distanceFeet": 350, "score": 3},
  {"holeNumber": 2, "par": 4, "distanceFeet": 480, "score": 4},
  {"holeNumber": 3, "par": 3, "distanceFeet": 375, "score": 4},
  {"holeNumber": 4, "par": 3, "distanceFeet": 390, "score": 3}
]

COMMON SCORECARD FORMATS:
- UDisc: Usually shows hole#, distance, par, score in columns or rows with color-coded circles
- PDGA: Similar table format with hole info
- Handwritten: May have varying formats - extract what's clearly visible

If the image is unclear or not a scorecard, return an empty array: []
''';
  }

  static String buildImageVoicePrompt(
    String voiceTranscript,
    List<DGDisc> userBag,
    String? courseName,
    List<HoleMetadata> preParsedHoles,
  ) {
    // Build hole metadata table
    String holeMetadataSection = '';
    final holeTable = preParsedHoles
        .map(
          (h) =>
              'Hole ${h.holeNumber}: Par ${h.par}, ${h.distanceFeet != null ? "${h.distanceFeet}ft" : "distance unknown"}, Score ${h.score}',
        )
        .join('\n');

    holeMetadataSection =
        '''

═══════════════════════════════════════════════════════════════════════════
📋 PRE-PARSED SCORECARD DATA (FROM IMAGE - THIS IS GROUND TRUTH) 📋
═══════════════════════════════════════════════════════════════════════════

$holeTable

CRITICAL PARSING RULES FOR IMAGE-FIRST MODE:
1. Use the scorecard data above for: hole number, par, distance, and FINAL SCORE
2. The SCORE from the image is ABSOLUTE TRUTH and CANNOT BE CHANGED OR RECALCULATED
3. EVERY HOLE IN YOUR YAML OUTPUT MUST INCLUDE A "score" FIELD WITH THE SCORECARD SCORE
4. Parse the voice transcript to extract throw-by-throw details ONLY - just what the user said
5. Match voice descriptions to the correct hole numbers from the table above
6. The throws you parse are the user's description of what happened - parse them as stated
7. DO NOT try to make the throw count match the score - the scorecard score overrides everything
8. DO NOT add, remove, or modify throws to match the score - parse exactly what was said
9. If the user said "for birdie" but the scorecard shows triple bogey, the scorecard is correct
10. If voice doesn't mention a hole that's in the scorecard, skip it (only parse holes with voice details)

⚠️ CRITICAL - DO NOT RELABEL THROWS BASED ON SCORE:
- Index 0 (first throw) MUST ALWAYS have purpose: tee_drive - NEVER change this to putt or approach
- DO NOT change a throw's purpose field based on score discrepancies
- DO NOT infer "they must have missed a putt" and relabel a tee drive as a putt
- Parse throws EXACTLY as described - if they say "threw destroyer off the tee", that's purpose: tee_drive
- If throw count doesn't match score, that's EXPECTED and OK - don't "fix" it by relabeling

CRITICAL: When you see a DISCREPANCY between what the user says and the scorecard:
- User says: "tapped in for birdie"
- Scorecard shows: Score 7 (triple bogey)
- YOU MUST: Ignore the "for birdie" part and trust the scorecard score of 7
- The user may have misspoken or recorded incorrectly during the round
- Your job is to parse the THROWS they described, not verify their math

EXAMPLE 1:
Scorecard shows: Hole 7, Par 4, 500ft, Score 7 (triple bogey)
Voice says: "Hole 7, made it through the double mando, second shot parked, tapped in for birdie"
You parse:
  - Throw 1: Tee drive → made it through double mando
  - Throw 2: Approach shot → parked
  - Throw 3: Tap-in → in_basket
  - Final score: 7 (from scorecard - NOT 3!)
The user said "for birdie" but the scorecard shows 7, so use 7 as the final score.

EXAMPLE 2:
Scorecard shows: Hole 1, Par 3, 350ft, Score 3 (Par)
Voice says: "Hole 1, threw destroyer, circle 1, made putt"
You parse:
  - Throw 1: Tee drive → circle_1
  - Throw 2: Putt → in_basket
  - Final score: 3 (from scorecard - even though only 2 throws described)

YOUR TASK:
Parse ONLY the throws the user described in the voice transcript.
Use the SCORE from the scorecard table above as the final score for each hole.
IGNORE any score-related phrases in the voice description (birdie, par, bogey, etc.) - use the scorecard score instead.

═══════════════════════════════════════════════════════════════════════════

''';

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
    score: 3
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
    score: 4
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
        landingSpot: in_basket''';

    return '''
You are a disc golf scorecard parser. Parse the following voice transcript of a disc golf round into structured YAML data.

VOICE TRANSCRIPT:
"$voiceTranscript"

USER'S DISC BAG:
$discListString

${courseName != null ? 'COURSE NAME: $courseName' : 'Extract the course name from the transcript if mentioned.'}
$holeMetadataSection
INSTRUCTIONS:
1. Parse each hole mentioned in the transcript
2. For each throw, assign index starting from 0 (0=tee shot, 1=second throw, etc.)
3. CRITICAL: Index 0 MUST have purpose: tee_drive (NEVER putt, NEVER approach, ALWAYS tee_drive)
4. ⚠️ CRITICAL: Each hole MUST include "score: X" field with the SCORECARD SCORE from the table above
5. CRITICAL - DISC NAMES: When a disc is mentioned in the transcript, include it in the throw:
   - Extract the disc name as mentioned (e.g., "halo Destroyer" → discName: halo Destroyer)
   - Match variations: "PD" could be from the bag list, "tactic" = Tactic, "destroyer" = Destroyer
   - If user says brand+mold (e.g., "Innova Destroyer"), just use the name from your bag (e.g., "Destroyer")
   - ONLY include discName if a disc is explicitly mentioned for that throw
   - Omit discName if no disc is mentioned for that throw
6. Assign purpose field based on the throw's role: tee_drive for first throw, approach for positioning shots, putt for basket attempts
7. Include distanceFeetBeforeThrow and/or distanceFeetAfterThrow when positions are mentioned (see CRITICAL DISTANCE RULES below)
8. Include brief natural language description in the "notes" field
9. Map landing positions to landingSpot enum based on WHERE THE DISC ENDED UP (distance from basket):
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
9. If par or hole distance isn't mentioned, use the values from the scorecard table above
10. Number holes sequentially starting from 1

CRITICAL DISTANCE RULES:
We track TWO distance measurements for each throw:
- distanceFeetBeforeThrow: How far from the basket BEFORE the throw (starting position)
- distanceFeetAfterThrow: How far from the basket AFTER the throw (ending position)

WHEN TO USE EACH FIELD:
- distanceFeetBeforeThrow examples:
  - "from 70 feet" = distanceFeetBeforeThrow: 70
  - "had a 25 ft putt" = distanceFeetBeforeThrow: 25
  - "40 feet out" (when describing starting position) = distanceFeetBeforeThrow: 40

- distanceFeetAfterThrow examples:
  - "to 25 feet" = distanceFeetAfterThrow: 25
  - "ended up 40 feet away" = distanceFeetAfterThrow: 40
  - "parked at 10 ft" = distanceFeetAfterThrow: 10
  - "landed 80 feet from the basket" = distanceFeetAfterThrow: 80

SPECIAL CASES:
- "Tap in" or "tapped in" = distanceFeetBeforeThrow: 8, distanceFeetAfterThrow: 0 (in basket)
- "Gimme" or "drop in" = distanceFeetBeforeThrow: 3, distanceFeetAfterThrow: 0 (in basket)
- "Threw 280 feet and ended up 50 feet away" = distanceFeetAfterThrow: 50 (we can infer beforeThrow was ~330 ft)
- "Pitch out to 25 feet" = distanceFeetAfterThrow: 25 (describes ending position)
- For tee shots, distanceFeetBeforeThrow is usually omitted (starting from tee pad)

IMPORTANT:
- ONLY include these fields when position is explicitly stated or clearly implied
- Include both when possible (e.g., "from 70 feet to 15 feet")
- Can include just one if only one position is mentioned
- Made putts always have distanceFeetAfterThrow: 0
- Omit if position is not mentioned

CRITICAL THROW PARSING RULES FOR IMAGE+VOICE MODE:
IN THIS MODE, THE SCORECARD SCORE IS THE FINAL SCORE - DO NOT VALIDATE THROW COUNTS!
- The scorecard score from the image is ABSOLUTE TRUTH (already provided above)
- Your job is to parse ONLY the throws the user described in their voice transcript
- DO NOT try to validate throw count against the scorecard score
- DO NOT add missing throws to make the count match the score
- The throw count may not match the scorecard score - this is EXPECTED and OK
- Focus on capturing what the user SAID, not validating their math
- IGNORE score-related phrases like "for birdie", "took bogey" - the scorecard score is already known

⚠️ CRITICAL - PRESERVE THROW PURPOSE LABELS:
- Index 0 = ALWAYS purpose: tee_drive (even if it landed at C1, even if you think it should have been a different score)
- DO NOT relabel throws based on "this doesn't match the score" thinking
- DO NOT change purpose: tee_drive to purpose: putt just because the scorecard shows a different score than expected
- A tee shot that parks it is STILL a tee shot (purpose: tee_drive), not a putt
- Parse the throw purpose based on WHAT THE USER DESCRIBED, not based on score math

For EVERY hole, parse throws by analyzing the narrative:
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
5. Parse throws as described - if they say the hole is finished, end with landingSpot: in_basket
6. CRITICAL - "PARKED" ALWAYS NEEDS A TAP-IN:
   - "parked it and birdied" = 2 throws (parked + tap-in with landingSpot: in_basket)
   - "parked at 10 ft so I birdied" = the approach that parked + tap-in for birdie
   - "parked it 2 feet away" followed by score mention = add tap-in (distanceFeetBeforeThrow: 8, landingSpot: in_basket)
   - NEVER end a hole with landingSpot: parked - must add final putt with landingSpot: in_basket
7. Pay special attention to phrases that indicate multiple throws:
   - "Two putts" or "two-putted" = ALWAYS 2 separate putt throws (NEVER combine!)
   - "Three putts" or "3-putted" = ALWAYS 3 separate putt throws
   - "Missed the putt" or "I missed the putt" = ALWAYS a separate throw (don't put this in notes of previous throw!)
   - "Missed the putt, tapped in" = 2 separate throws (missed putt + tap-in)
   - "Missed the par putt" = 2 putts (missed par putt + made bogey/par putt)
   - "Missed the birdie putt" = 2 putts (missed birdie putt + made par putt)
   - "Made the comeback putt" = 2 putts (first missed + comeback made)
   - "3-putted" or "three-putted" = ALWAYS exactly 3 putt throws (2 missed + 1 made)
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
6. Handle penalties correctly:
   - "OB" or "out of bounds" = Add penaltyStrokes: 1 to that throw
   - "Water hazard" or "lost disc" = Add penaltyStrokes: 1 to that throw
   - Re-tee after OB = The re-tee is a separate throw (don't add penalty there)
7. DO NOT VALIDATE THROW COUNTS:
   - In image+voice mode, throw count may NOT match the scorecard score
   - This is EXPECTED - the user may have described only some throws
   - Parse exactly what was said, nothing more, nothing less
   - The scorecard score is the final score regardless of your throw count


EXAMPLES - PARSING THROWS WITHOUT VALIDATING COUNTS:

Example 1: Detecting multiple putts (MUST include score field)
Voice: "250 ft par 3. I threw my fd3 to Circle one about 25 ft away missed the putt off the cage and then miss the par putt because it's bad back at me so I took a bogey there"
Scorecard: Hole 2, Par 3, Score 4
YAML OUTPUT MUST INCLUDE:
  - number: 2
    par: 3
    feet: 250
    score: 4
    throws:
      - index: 0
        notes: threw fd3 to circle one
        distanceFeetAfterThrow: 25
        landingSpot: circle_1
        purpose: tee_drive
      - index: 1
        distanceFeetBeforeThrow: 25
        notes: missed the putt off the cage
        landingSpot: circle_1
        purpose: putt
      - index: 2
        distanceFeetBeforeThrow: 8
        notes: miss the par putt because it bounced back
        purpose: putt
      - index: 3
        distanceFeetBeforeThrow: 8
        distanceFeetAfterThrow: 0
        notes: made the putt
        landingSpot: in_basket
        purpose: putt

Example 2: Completing the hole (MUST include score field)
Voice: "380 ft par 3. Threw forehand 70 ft short. Tried putt from 70 ft, rolled to 15 ft, missed that 15 ft putt, took bogey"
Scorecard: Hole 3, Par 3, Score 4
YAML OUTPUT MUST INCLUDE:
  - number: 3
    par: 3
    feet: 380
    score: 4
    throws:
      - index: 0
        distanceFeetAfterThrow: 70
        landingSpot: circle_2
        purpose: tee_drive
      - index: 1
        distanceFeetBeforeThrow: 70
        distanceFeetAfterThrow: 15
        purpose: putt
      - index: 2
        distanceFeetBeforeThrow: 15
        purpose: putt
      - index: 3
        distanceFeetBeforeThrow: 8
        distanceFeetAfterThrow: 0
        landingSpot: in_basket
        purpose: putt

Example 3: Including score field is MANDATORY
Voice: "475 feet par 4. Threw Firebird 280 feet. Threw Buzzz 195 feet into rough. Pitch out to 25 feet, made putt for par."
Scorecard: Hole 7, Par 4, Score 4
YAML OUTPUT MUST INCLUDE:
  - number: 7
    par: 4
    feet: 475
    score: 4
    throws:
      - index: 0
        purpose: tee_drive
      - index: 1
        purpose: approach
      - index: 2
        distanceFeetAfterThrow: 25
        purpose: approach
      - index: 3
        distanceFeetBeforeThrow: 25
        distanceFeetAfterThrow: 0
        landingSpot: in_basket
        purpose: putt

Example 4: Index 0 is ALWAYS tee_drive, even if score doesn't match
Voice: "Hole 4, threw my MD4, parked it about 10 feet"
Scorecard: Hole 4, Par 3, Score 3 (par)
NOTE: Voice only describes 1 throw, but scorecard shows score of 3
YAML OUTPUT MUST INCLUDE:
  - number: 4
    par: 3
    score: 3
    throws:
      - index: 0
        notes: threw MD4, parked it
        distanceFeetAfterThrow: 10
        landingSpot: parked
        purpose: tee_drive
WRONG - DO NOT DO THIS:
- index 0: purpose: putt (NEVER change index 0 to putt!)
- Adding extra throws to match score (DON'T add throws not described)
- Changing the score to 1 (NEVER recalculate score!)

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
7. ⚠️⚠️⚠️ EVERY HOLE MUST INCLUDE "score: X" FIELD WITH THE SCORECARD SCORE ⚠️⚠️⚠️

Example of CLEAN YAML output (notice EVERY hole includes the "score" field from the scorecard):
$schemaExample
''';
  }
}
