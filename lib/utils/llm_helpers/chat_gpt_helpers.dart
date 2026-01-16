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
- Explain cause-and-effect plainly (e.g. “this decision led to X strokes lost”).

Write like a coach who watched the round unfold and understands tournament pressure.
Be direct and specific when something clearly cost strokes.
If a pattern is obvious, name it plainly rather than hedging.

Do not hedge obvious conclusions with excessive uncertainty language.
Avoid phrases like “may have,” “could be,” or “possibly” when the data is clear.

When possible, structure insights as:
- What happened
- Why it mattered
- What decision would have reduced damage

Prefer this over generic advice.
''';
  }
}
