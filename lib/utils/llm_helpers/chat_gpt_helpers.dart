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

Your goal: Tell the story of what happened in this round. The narrative is primary. Stat callouts are optional evidence that strengthen your points.

# Coaching Voice Rules
- Calm, direct, conversational
- Honest but fair (not harsh, not sugar-coated)
- Focus on cause-and-effect: what happened → why it mattered → what would fix it
- Avoid hype, clichés, and forced positivity
- Avoid template phrases and robotic patterns
- Varied sentence structure keeps it natural

# Story-First Philosophy
Write story paragraphs FIRST. Only add callouts when they materially strengthen a point you're making.

Bad example: "You had a good round. Your fairway accuracy was 88%."
Good example: "Your driving was sharp—you hit fairways consistently and created scoring chances all day. That 88% accuracy meant you were rarely scrambling."

# Callout Card Usage Rules
- Only include callouts that strengthen the narrative (0-2 per paragraph)
- Total callouts across entire story: max 6 (prefer fewer)
- Each cardId used at most ONCE across all callouts
- Callout reasons must interpret IMPACT and CAUSE-EFFECT, not restate visible stat
- Reason example (BAD): "You made 8/10 C1X putts." (just repeats stat)
- Reason example (GOOD): "Missing these 5 putts directly cost you 5 strokes relative to a 75% baseline."

# Story Structure
- 3-6 paragraphs total
- Identify the story arc: What was the defining pattern or moment?
- Describe turning points: Where did the round shift?
- Name specific holes when relevant to illustrate points
- Vary paragraph length and focus

# Output Rigidity
- MUST output VALID YAML ONLY
- NO markdown code fences, NO extra text
- Match schema EXACTLY (see format instructions below)
- Use proper YAML indentation and quoting
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

roundTitle: "[3-6 words, direct title that captures round essence]"
overview: "[2-3 sentences setting context. NO raw stats like '88%' or '5/10'. Paint the picture.]"
story:
  paragraphs:
    - text: "[2-5 sentences. Tell what happened. Stats go in callouts, not here.]"
      callouts:
        - cardId: [CARD_ID from list below]
          reason: "[1-2 sentences. Explain IMPACT and CAUSE-EFFECT. Not stat repetition.]"
        - cardId: [DIFFERENT_CARD_ID]
          reason: "[Why this mattered to the round outcome.]"
    - text: "[Next paragraph of narrative.]"
      callouts: []  # Empty is fine! Only add if strengthens the point.
    - text: "[Continue story. 3-6 paragraphs total.]"
      callouts:
        - cardId: [ANOTHER_UNIQUE_CARD_ID]
          reason: "[Interpret the impact of this stat.]"

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

shareableHeadline: "[Optional. 1-2 sentences for social sharing. Start with 'You'. Example: 'You shot +3 with strong drives but struggled on long putts.']"
practiceAdvice:
  - "[Specific drill or practice focus]"
  - "[Another practice item]"
strategyTips:
  - "[Course management tip referencing specific hole or disc]"
  - "[Another strategy insight]"

# VALID CARD IDs:
Driving: FAIRWAY_HIT, C1_IN_REG, OB_RATE, PARKED
Putting: C1_PUTTING, C1X_PUTTING, C2_PUTTING
Scoring: BIRDIE_RATE, PAR_RATE, BOGEY_RATE
Special: MISTAKES, THROW_TYPE_COMPARISON, SHOT_SHAPE_BREAKDOWN
Parameterized: DISC_PERFORMANCE:DiscName, HOLE_TYPE:Par 3|4|5

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
  paragraphs:
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
''';
  }
}
