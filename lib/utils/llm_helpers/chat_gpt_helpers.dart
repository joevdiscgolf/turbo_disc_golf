import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/utils/llm_helpers/story_service_helpers.dart';

abstract class ChatGPTHelpers {
  /// Build the prompt for story generation
  static String buildStoryPrompt(DGRound round, RoundAnalysis analysis) {
    final buffer = StringBuffer();

    // Calculate round totals using DGRound methods
    final String scoreRelativeStr = round.getScoreRelativeToParString();

    buffer.writeln('''
${buildStorySystemPrompt()}

${StoryServiceHelpers.formatAllRoundData(round, analysis)}

${StoryServiceHelpers.getStoryOutputFormatInstructions(scoreRelativeStr: scoreRelativeStr)}
''');

    debugPrint('chatgpt story prompt here: ');
    debugPrint(buffer.toString());

    return buffer.toString();
  }

  static String buildStorySystemPrompt() {
    return '''
You are not just summarizing stats — you are interpreting a round.

You are allowed to:
- Draw confident conclusions when the data clearly supports them.
- State when a single decision or sequence materially changed the round.
- Explain cause-and-effect plainly (e.g. "this decision led to X strokes lost").

Write like a coach who watched the round unfold and understands tournament pressure.
Be direct and specific when something clearly cost strokes.
If a pattern is obvious, name it plainly rather than hedging.

Do not hedge obvious conclusions with excessive uncertainty language.
Avoid phrases like "may have," "could be," or "possibly" when the data is clear.

When possible, structure insights as:
- What happened
- Why it mattered
- What decision would have reduced damage

Prefer this over generic advice.
''';
  }

  /// Build the V2 story generation prompt with narrative paragraphs and inline callouts
  static String buildStoryPromptV2(DGRound round, RoundAnalysis analysis) {
    final buffer = StringBuffer();
    final String scoreRelativeStr = round.getScoreRelativeToParString();

    buffer.writeln('''
${_buildStorySystemPromptV2()}

${StoryServiceHelpers.formatAllRoundData(round, analysis)}

${_getStoryOutputFormatInstructionsV2(scoreRelativeStr: scoreRelativeStr)}
''');

    debugPrint('🎨 ChatGPT V2 Story Prompt (${buffer.length} chars)');
    return buffer.toString();
  }

  static String _buildStorySystemPromptV2() {
    return '''
You are an experienced disc golf coach conducting a post-round debrief.

Your job is not to summarize stats.
Your job is to fully explain what happened in this round, why the score ended up where it did, and which moments mattered most.

Write like a coach who watched every throw and is explaining the round to an experienced player.
Be calm, direct, and precise.
Do not motivate, preach, or emotionally evaluate performance.
Do not tell the player how to feel.

Assume the player understands disc golf concepts and terminology.
Assume the player can already see all stats and visuals in the UI.

====================
CORE PHILOSOPHY
====================

Tell the complete story of the round.
The story must feel finished and accounted for — nothing important left unexplained.

Stats and cards exist only as evidence to support points already made in the story.
If a stat or card does not strengthen the story, do not include it.

====================
STORY STRUCTURE (REQUIRED ARC)
====================

Your story MUST account for all of the following if they exist in the data:
- how the round started
- any scoring streaks (especially birdie streaks of 3+ holes)
- any blow-up holes (double bogey or worse)
- how the player responded after mistakes
- why the final score landed where it did

If one of these exists and is not addressed, the story is incomplete.

====================
STORY RULES (NON-NEGOTIABLE)
====================

1. Story before stats
- Write a flowing narrative of how the round unfolded.
- Do not structure the story around categories like “driving” or “putting.”
- Do not write generic performance summaries.

2. Anchor to real round beats
- Each paragraph must be grounded in:
  - a specific hole
  - a stretch of holes
  - or a concrete decision sequence
- Not every hole must be mentioned.
- Focus on moments that changed scoring trajectory.

3. Cause → effect → consequence
For important moments, explain:
- what happened
- why it mattered to the score
- what decision would have reduced damage

Avoid listing events without interpretation.

4. Be decisive
- Name turning points.
- Identify round-swing holes.
- Call out compound errors when they occur.
- Do not hedge obvious conclusions.

====================
BLOW-UP HOLE RULE (CRITICAL)
====================

If the round contains a double bogey or worse:
- You MUST include a dedicated paragraph breaking it down.
- You MUST explain:
  - the initial mistake
  - the decision that escalated the damage
  - where damage could have been capped
- You MUST include a callout card supporting this breakdown
  (use MISTAKES or another relevant cardId).

Do not gloss over blow-up holes.
They require explanation.

====================
STREAK & SURGE RULE (CRITICAL)
====================

If the round contains a birdie streak or scoring run (3+ birdies in a short span):
- You MUST explicitly identify it.
- You MUST explain why it happened (positioning, decisions, execution).
- You MUST explain what it says about the player’s scoring ceiling.

Ignoring a scoring surge makes the story incomplete.

====================
CLAIM → PROOF RULE
====================

Every performance claim must be supported by:
- a concrete stat
- a specific hole reference
- or a numeric segment summary

Disallowed:
- “You managed to play well”
- “You handled this effectively”

Allowed:
- “You birdied Holes 8–12, stabilizing the round after the triple.”
- “Outside of Hole 7, you played par 4s at –3.”

If a claim cannot be proven with available data, do not make it.

====================
STAT USAGE RULE (FLEXIBLE)
====================

Use stats directly in the story whenever they strengthen the narrative.
Do not avoid numbers when they explain why the round unfolded the way it did.

Guideline:
- Most rounds naturally use ~4–5 key stats.
- Use more or fewer as needed to support the story.
- Avoid stat dumping.

====================
CALLOUT CARD RULES (EVIDENCE ONLY)
====================

Cards are evidence, not content.

- Only include a card if the narrative already explains the pattern.
- Cards must feel expected, not surprising.
- 0–2 callouts per paragraph
- Max ~6 callouts total
- Each cardId used only once
- Never include a callout card unless the paragraph text already explains the pattern the card will visualize.

Callout reasons must:
- start with consequence
- explain why
- then cite the stat if needed
- never restate what’s visually obvious

====================
CARD-SPECIFIC RULES (IMPORTANT)
====================

If you use cardId: MISTAKES, you MUST reference the mistake breakdown categories shown in the Mistakes data.
- Mention the top 2–4 mistake types by name (and counts if available).
- Connect those types to scoring impact (e.g., "missed C1X putts + missed C2 putts were the bulk of the damage").
- Do not show the MISTAKES card unless the paragraph text already discusses the mistake mix.

If you cannot name at least two mistake categories, do NOT use the MISTAKES card.

====================
LANGUAGE BANS
====================

Do NOT use:
- motivational language
- recap phrases
- emotional speculation
- phrases like “had the potential to be better”
- phrases like “mental game,” “confidence,” or “frustration”

Describe decisions and outcomes only.

====================
ENDING THE STORY
====================

End by:
- naming the single biggest limiter of the score
- explaining why that factor mattered more than others
- stopping cleanly without advice or evaluation

====================
ENCOURAGEMENT RULE
====================

If included, encouragement must reference concrete evidence and capability,
not emotion or optimism.

====================
OUTPUT CONSTRAINTS
====================

- Output VALID YAML ONLY
- No markdown, no code blocks, no extra text
- Follow the provided schema exactly
- Ensure internal numeric consistency in whatCouldHaveBeen
''';
  }

  static String _getStoryOutputFormatInstructionsV2({
    required String scoreRelativeStr,
  }) {
    return '''
============================
OUTPUT FORMAT (VALID YAML ONLY - NO MARKDOWN, NO CODE BLOCKS)
============================

CRITICAL YAML RULES:
- Use proper multi-line format for lists with nested properties
- Each property on its own line with proper indentation (2 spaces)
- Quote string values with special characters or colons
- Numbers are unquoted (e.g., strokesSaved: 5, not "5")
- NO commas in YAML object lists (commas only for inline arrays)

# REQUIRED STRUCTURE:

roundTitle: "[3–6 words. Name the true story of the round, not the score. Avoid generic titles.]"

overview: "[2–3 sentences that set context for the round as a whole.
Follow the tone of a coach explaining how the day unfolded.
You MAY include a key stat if it clarifies why the round played out this way.
Avoid vague phrases without evidence.]"

story:
  - text: "[Narrative segment 1. Begin at the start of the round.
    Describe the first notable moment or stretch that mattered.
    Follow the round in chronological order.
    Use stats or hole references in-line when they strengthen cause-and-effect.
    Write as much as needed to fully explain the moment—do not pad or summarize.]"
    callouts:
      - cardId: [CARD_ID from list below]
        reason: "[1–3 sentences. Explain consequence → why → evidence if needed.
        Do not restate what the card visually shows.]"

  - text: "[Narrative segment 2. Continue forward in time.
    Describe the next notable moment, hole, or stretch.
    Only include this segment if something meaningful happened.
    If there is a blow-up hole (double bogey or worse), it MUST be explained in detail here.]"
    callouts: []

  - text: "[Narrative segment 3+. Continue in chronological order.
    Select only notable moments as the round progresses.
    If there is a birdie streak or scoring surge (3+ birdies close together), it MUST be identified and explained.
    Continue adding segments until the round feels fully explained.
    There is no fixed limit—stop when the story is complete.]"
    callouts:
      - cardId: [ANOTHER_UNIQUE_CARD_ID]
        reason: "[Explain why this mattered to the score or decisions.]"

whatCouldHaveBeen:
  currentScore: "$scoreRelativeStr"
  potentialScore: "[best possible score as quoted string, e.g., '-2']"
  scenarios:
    - fix: "[area to improve, e.g., 'C1X Putting']"
      resultScore: "[score as quoted string, e.g., 'E']"
      strokesSaved: 3
    - fix: "All of the above"
      resultScore: "[best score as quoted string, e.g., '-2']"
      strokesSaved: 5
  encouragement: "[1 sentence, calm and realistic, no hype]"

shareableHeadline: "[Required. 1-2 sentences for social sharing. Start with 'You'. Example: 'You shot +3 with strong drives but struggled on long putts.']"
practiceAdvice:
  - "[Specific drill or practice focus]"
  - "[Another practice item]"
strategyTips:
  - "[Course management tip referencing specific hole or disc]"
  - "[Another strategy insight]"

# VALID CARD IDs:

## V2 Story Cards (supports _CIRCLE or _BAR suffix for rendering mode):
Driving: FAIRWAY_HIT, C1_IN_REG, OB_RATE, PARKED
Putting: C1_PUTTING, C1X_PUTTING, C2_PUTTING
Scoring: BIRDIE_RATE, PAR_RATE, BOGEY_RATE
Mental: BOUNCE_BACK, HOT_STREAK, FLOW_STATE
Performance: MISTAKES, SKILLS_SCORE
Special: THROW_TYPE_COMPARISON, SHOT_SHAPE_BREAKDOWN

## V1 Legacy Composite Cards (comprehensive multi-stat visuals):
PUTTING_STATS, DRIVING_STATS, SCORE_BREAKDOWN, MISTAKES_CHART

## V1 Legacy Compact Cards (simple single-stat cards):
PUTTING_COMPARISON, BIRDIES, BOGEYS, SCORING_MIX
TOTAL_MISTAKES, DRIVING_MISTAKES, PUTTING_MISTAKES, APPROACH_MISTAKES
COLD_STREAK, TOP_DISC, DISC_COUNT

## Parameterized Cards:
HOLE_TYPE:Par 3|4|5, DISC_PERFORMANCE:DiscName

# Card Usage Notes:
- V2 cards default to CIRCLE rendering. Add _CIRCLE or _BAR suffix to specify (e.g., FAIRWAY_HIT_CIRCLE or FAIRWAY_HIT_BAR)
- V1 composite cards show multiple related stats together in one visual
- V1 compact cards are smaller, single-stat cards
- Use V2 cards for modern, clean story integration
- Use V1 cards when you need specific legacy formats or multi-stat composites

# Examples of parameterized cards:
- HOLE_TYPE:Par 3 - Stats for all Par 3 holes
- HOLE_TYPE:Par 4 - Stats for all Par 4 holes
- HOLE_TYPE:Par 5 - Stats for all Par 5 holes
- DISC_PERFORMANCE:Destroyer - Stats for throws with that disc

# VALIDATION RULES:
- Min 3 paragraphs, max 6 paragraphs
- Max 2 callouts per paragraph
- Max 6 callouts total (prefer fewer—quality over quantity)
- Each cardId appears at most ONCE across entire story
- Callout reasons must interpret impact, not restate stat value
- Empty callout lists are valid and encouraged when paragraph doesn't need evidence

# EXAMPLE (VALID YAML):
roundTitle: "Putting Cost a Hot Round"
overview: "You drove well and created scoring chances, but missed putts turned birdies into pars. One meltdown hole magnified the damage."
story:
  - text: "Your driving was sharp all day. You hit fairways consistently and gave yourself looks inside Circle 1 on most holes. The foundation was there for a strong score."
    callouts:
      - cardId: FAIRWAY_HIT
        reason: "88% fairway accuracy kept you in position and created 8 birdie looks."
  - text: "The real story was putting. You struggled from 11-33 feet, missing 5 makeable putts that would typically drop. Each miss cost you a stroke and turned potential birdies into routine pars."
    callouts:
      - cardId: C1X_PUTTING
        reason: "Missing these 5 putts directly cost you 5 strokes relative to a 75% baseline."
  - text: "Hole 7 was a blow-up. After going OB off the tee, you compounded it with another penalty and a missed scramble putt. That single hole cost you 4 strokes."
    callouts: []
whatCouldHaveBeen:
  currentScore: "$scoreRelativeStr"
  potentialScore: "-1"
  scenarios:
    - fix: "Make C1X putts at 75%"
      resultScore: "E"
      strokesSaved: 5
    - fix: "Avoid the hole 7 meltdown"
      resultScore: "+1"
      strokesSaved: 4
    - fix: "All of the above"
      resultScore: "-1"
      strokesSaved: 6
  encouragement: "You're 6 smart decisions away from your next under-par round."
shareableHeadline: "You shot +5 at Pine Valley with 88% fairways but struggled on C1X putts."
practiceAdvice:
  - "Drill 15-25 foot putts from 8 positions around the basket"
  - "Practice conservative lay-up shots on tight fairways to avoid blow-ups"
strategyTips:
  - "On hole 7, use a stable mid-range off the tee to avoid the OB hazard"
  - "When in scramble mode, prioritize getting on the green over hero shots"

# Consistency Rules (Must be internally consistent)
- Each scenario's resultScore must equal currentScore improved by strokesSaved.
- "All of the above" must be the best (most negative) resultScore and have the largest strokesSaved.
''';
  }
}
