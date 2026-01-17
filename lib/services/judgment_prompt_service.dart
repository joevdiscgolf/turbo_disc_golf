import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';

/// Service for generating AI judgment prompts (roasts and glazes)
class JudgmentPromptService {
  /// Builds a detailed prompt for AI to roast or glaze a disc golf round
  ///
  /// [round] The round to judge
  /// [shouldGlaze] If true, generates glaze (compliments), else roast (criticism)
  String buildJudgmentPrompt(DGRound round, bool shouldGlaze) {
    final analysis = RoundAnalysisGenerator.generateAnalysis(round);

    final StringBuffer buffer = StringBuffer();

    if (shouldGlaze) {
      buffer.writeln(
        'You are GLAZING someone about their disc golf round (giving excessive, over-the-top compliments in a funny way). Talk TO them, not about them.',
      );
      buffer.writeln(
        'Write a hilarious glaze-up speaking directly to the player - make them sound like a disc golf god!',
      );
    } else {
      buffer.writeln(
        'You are roasting someone directly about their disc golf round. Talk TO them, not about them.',
      );
      buffer.writeln(
        'Write a hilarious roast speaking directly to the player - at their expense!',
      );
    }
    buffer.writeln('');
    buffer.writeln('CRITICAL - BE UNIQUE AND RANDOM:');
    buffer.writeln(
      '- Every ${shouldGlaze ? 'glaze' : 'roast'} must be COMPLETELY DIFFERENT from any other. Never use the same jokes, metaphors, or structures twice.',
    );
    buffer.writeln(
      '- Pick a RANDOM creative angle: sports commentary, nature documentary, crime report, therapy session, dating profile, job interview, news headline, movie review, etc.',
    );
    buffer.writeln(
      '- Invent fresh metaphors and comparisons each time - avoid common clichés like "restraining order" or "therapy".',
    );
    buffer.writeln('');
    buffer.writeln('IMPORTANT RULES:');
    buffer.writeln(
      '- Talk DIRECTLY to the player using "you" and "your" - make it personal and conversational',
    );
    buffer.writeln(
      '- NO stage directions like (pause for applause) or (audience laughs) - this is NOT a script',
    );
    buffer.writeln(
      '- NO meta-commentary about performing or the audience - just ${shouldGlaze ? 'glaze' : 'roast'} them directly',
    );
    buffer.writeln(
      '- Keep it culturally relevant and contemporary - use slang SPARINGLY and only when it\'s genuinely funny',
    );
    buffer.writeln(
      '- Mix humor with disc golf references - make it feel authentic and funny',
    );
    buffer.writeln(
      '- Use DIVERSE comedy styles: observational humor, absurdist comedy, deadpan delivery, wordplay, ${shouldGlaze ? 'hyperbole' : 'sarcasm'}',
    );
    buffer.writeln(
      '- Vary your joke structures: one-liners, setups/punchlines, callbacks, rule of three, misdirection',
    );
    buffer.writeln(
      '- Avoid overused patterns like "That\'s like..." similes - find fresh ways to make comparisons',
    );
    if (shouldGlaze) {
      buffer.writeln(
        '- Reference the specific numbers in ridiculously over-the-top ways (e.g., "bro you hit fairway so much the trees are filing restraining orders against you")',
      );
      buffer.writeln(
        '- Use disc golf insider references to praise them (chains feared you, hyzer flips bowed down, trees parted like the Red Sea, etc.)',
      );
      buffer.writeln(
        '- Mix short punchy compliments with longer over-the-top praise',
      );
      buffer.writeln(
        '- End with an absurdly exaggerated compliment directed at them',
      );
      buffer.writeln(
        '- Make even mediocre stats sound legendary - be hilariously excessive!',
      );
      buffer.writeln(
        '- IMPORTANT: Use **bold** (double asterisks) for emphasis, NOT *italics* (single asterisks) - italics are hard to read!',
      );
    } else {
      buffer.writeln(
        '- Reference the specific numbers in clever ways (e.g., "bro you went OB more times than I check my phone")',
      );
      buffer.writeln(
        '- Use disc golf insider references (chains, hyzer flips, rollaways, tree love, etc.)',
      );
      buffer.writeln('- Mix short punchy burns with longer observations');
      buffer.writeln('- End with a brutal but funny closer directed at them');
    }
    buffer.writeln('');
    buffer.writeln('STRUCTURE: Write 2-3 SHORT sections (NOT long paragraphs). Total ~100-150 words.');
    buffer.writeln('Each section MUST start with an emoji + bold title on its own line.');
    buffer.writeln('CRITICAL: Put a BLANK LINE after each title before the body text.');
    buffer.writeln('Each section body is 2-3 sentences MAX.');
    buffer.writeln('');
    buffer.writeln('SECTION FORMAT EXAMPLE (note the blank lines after titles):');
    if (shouldGlaze) {
      buffer.writeln('**🎯 The Putting Masterclass**');
      buffer.writeln('');
      buffer.writeln('Your C1X was automatic. The chains didn\'t stand a chance.');
      buffer.writeln('');
      buffer.writeln('**🌲 Course Domination**');
      buffer.writeln('');
      buffer.writeln('89% fairway? Trees literally parted for you.');
    } else {
      buffer.writeln('**🎯 The Putting Situation**');
      buffer.writeln('');
      buffer.writeln('Your C1X was 50%. That\'s a coin flip you lost half the time.');
      buffer.writeln('');
      buffer.writeln('**🌲 Tree Magnetism**');
      buffer.writeln('');
      buffer.writeln('67% fairway means the other 33% had a tree\'s phone number.');
    }
    buffer.writeln('');
    buffer.writeln(
      'Write like you\'re their ${shouldGlaze ? 'biggest hype man' : 'brutally honest'} friend ${shouldGlaze ? 'hyping them up' : 'giving them grief'} about their round.',
    );
    buffer.writeln(
      'Keep it creative, unpredictable, culturally relevant, and DIRECTLY addressed to them!',
    );
    buffer.writeln('');
    buffer.writeln('ROUND STATS TO ROAST:');
    buffer.writeln('Course: ${round.courseName}');
    buffer.writeln(
      'Score: ${analysis.totalScoreRelativeToPar >= 0 ? '+' : ''}${analysis.totalScoreRelativeToPar}',
    );
    buffer.writeln('');

    // Scoring stats
    buffer.writeln('SCORING:');
    buffer.writeln('Birdies: ${analysis.scoringStats.birdies}');
    buffer.writeln('Pars: ${analysis.scoringStats.pars}');
    buffer.writeln('Bogeys: ${analysis.scoringStats.bogeys}');
    buffer.writeln('Double Bogeys+: ${analysis.scoringStats.doubleBogeyPlus}');
    if (analysis.bounceBackPercentage > 0) {
      buffer.writeln(
        'Bounce Back %: ${analysis.bounceBackPercentage.toStringAsFixed(0)}%',
      );
    }
    buffer.writeln('');

    // Driving stats
    buffer.writeln('DRIVING:');
    buffer.writeln(
      'Fairway Hit: ${analysis.coreStats.fairwayHitPct.toStringAsFixed(0)}%',
    );
    buffer.writeln(
      'C1 in Regulation: ${analysis.coreStats.c1InRegPct.toStringAsFixed(0)}%',
    );
    buffer.writeln(
      'C2 in Regulation: ${analysis.coreStats.c2InRegPct.toStringAsFixed(0)}%',
    );
    buffer.writeln(
      'Parked: ${analysis.coreStats.parkedPct.toStringAsFixed(0)}%',
    );
    buffer.writeln(
      'Out of Bounds: ${analysis.coreStats.obPct.toStringAsFixed(0)}%',
    );
    buffer.writeln('');

    // Putting stats
    buffer.writeln('PUTTING:');
    buffer.writeln(
      'C1X Make Rate: ${analysis.puttingStats.c1xPercentage.toStringAsFixed(0)}%',
    );
    buffer.writeln(
      'C2 Make Rate: ${analysis.puttingStats.c2Percentage.toStringAsFixed(0)}%',
    );
    if (analysis.puttingStats.totalAttempts > 0) {
      buffer.writeln(
        'Total Putts Made: ${analysis.puttingStats.totalMakes}/${analysis.puttingStats.totalAttempts}',
      );
      buffer.writeln(
        'Overall Make %: ${analysis.puttingStats.overallPercentage.toStringAsFixed(0)}%',
      );
    }
    buffer.writeln('');

    // Mistakes
    if (analysis.totalMistakes > 0) {
      buffer.writeln('MISTAKES:');
      buffer.writeln('Total Mistakes: ${analysis.totalMistakes}');
      if (analysis.mistakesByCategory.isNotEmpty) {
        analysis.mistakesByCategory.forEach((category, count) {
          buffer.writeln('$category: $count');
        });
      }
      buffer.writeln('');
    }

    // Scramble stats
    if (analysis.scrambleStats.scrambleOpportunities > 0) {
      buffer.writeln('SCRAMBLING:');
      buffer.writeln(
        'Scramble Success: ${analysis.scrambleStats.scrambleRate.toStringAsFixed(0)}% (${analysis.scrambleStats.scrambleSaves}/${analysis.scrambleStats.scrambleOpportunities})',
      );
      buffer.writeln('');
    }

    if (shouldGlaze) {
      buffer.writeln('Now deliver a hilarious glaze session about this round!');
      buffer.writeln(
        'Remember: be absurdly over-the-top with the compliments. Make them sound like a disc golf legend!',
      );
    } else {
      buffer.writeln(
        'Now deliver a hilarious standup comedy routine roasting this round!',
      );
      buffer.writeln(
        'Remember: you\'re a comedian on stage, not writing an essay. Make it punchy, funny, and memorable!',
      );
    }
    buffer.writeln('');
    buffer.writeln('IMPORTANT: Return your response as valid YAML with this exact structure:');
    buffer.writeln('');
    buffer.writeln('headline: Foxwood Legend Status');
    buffer.writeln('tagline: You hit 89% fairways and shot -6. The trees filed a missing persons report on your disc.');
    buffer.writeln('content: |');
    buffer.writeln('  **🎯 The Approach Game**');
    buffer.writeln('');
    buffer.writeln('  Your content paragraphs go here.');
    buffer.writeln('highlightStats:');
    buffer.writeln('  - fairwayPct');
    buffer.writeln('  - c1xPuttPct');
    buffer.writeln('');
    buffer.writeln('CRITICAL FORMAT RULES:');
    buffer.writeln('- Do NOT include the field name in the value (wrong: "headline: Headline: My Title", correct: "headline: My Title")');
    buffer.writeln('- headline: A catchy title, max 6 words, NO quotes needed');
    buffer.writeln('- tagline: 2-3 punchy sentences (up to 280 chars) with specific stats');
    buffer.writeln('- content: The full ${shouldGlaze ? 'glaze' : 'roast'} using markdown');
    buffer.writeln('- highlightStats: Exactly 2 stat keys from the list below');
    buffer.writeln('');
    buffer.writeln('HEADLINE EXAMPLES (just the value, no "Headline:" prefix):');
    if (shouldGlaze) {
      buffer.writeln('- "Disc Golf Perfection Achieved"');
      buffer.writeln('- "The GOAT Graces The Course"');
      buffer.writeln('- "Pro Tour Scouts Incoming"');
    } else {
      buffer.writeln('- "A Masterclass in Missing Putts"');
      buffer.writeln('- "Trees: 18, You: 0"');
      buffer.writeln('- "New Definition of Struggling"');
    }
    buffer.writeln('');
    buffer.writeln(
      'TAGLINE: 2-3 punchy sentences that summarize the round performance in a funny way.',
    );
    buffer.writeln(
      'Include SPECIFIC STATS (putting %, fairway %, OB count, score) so someone can understand the round at a glance.',
    );
    buffer.writeln(
      'Keep it funny and shareable - this is the viral quote people will screenshot.',
    );
    buffer.writeln(
      'IMPORTANT: Tagline MUST be DIFFERENT from headline. Headline is the title, tagline tells the story.',
    );
    buffer.writeln('Examples of GREAT taglines:');
    if (shouldGlaze) {
      buffer.writeln(
        '- "Your C1X putting was automatic at 85%, fairways parted like the Red Sea, and the only thing you missed was a chance to apologize to the course for the beating."',
      );
      buffer.writeln(
        '- "67% fairways, 90% putting, zero mercy. The trees are still talking about the one that got away."',
      );
      buffer.writeln(
        '- "You parked 4 holes, cashed every putt inside the circle, and shot -3. The course owes you an apology for even trying."',
      );
    } else {
      buffer.writeln(
        '- "You hit 45% fairways like the trees owed you money, went OB 4 times, and your putter? Still processing the trauma."',
      );
      buffer.writeln(
        '- "50% C1X putting means you missed half your gimmes. The chains didn\'t even flinch. They knew."',
      );
      buffer.writeln(
        '- "Three double bogeys, 5 OBs, and a scramble rate that made the marshals look away. A round to remember (and then forget)."',
      );
    }
    buffer.writeln('');
    buffer.writeln(
      'HIGHLIGHT STATS: Choose exactly 2 stats from this list that are MOST RELEVANT to your ${shouldGlaze ? 'glaze' : 'roast'}:',
    );
    buffer.writeln('- fairwayPct (Fairway Hit %)');
    buffer.writeln('- c1xPuttPct (C1X Putting %)');
    buffer.writeln('- obPct (Out of Bounds %)');
    buffer.writeln('- parkedPct (Parked %)');
    buffer.writeln('- scramblePct (Scramble Success %)');
    buffer.writeln('- bounceBackPct (Bounce Back %)');
    buffer.writeln('');
    buffer.writeln(
      'CRITICAL: Match your highlightStats to the TOPIC of your ${shouldGlaze ? 'glaze' : 'roast'}:',
    );
    buffer.writeln('- If you mention PUTTING → MUST include c1xPuttPct');
    buffer.writeln('- If you mention DRIVING/FAIRWAYS/TREES → MUST include fairwayPct');
    buffer.writeln('- If you mention OB/OUT OF BOUNDS → MUST include obPct');
    buffer.writeln('- If you mention PARKING/CLOSE SHOTS → include parkedPct');
    buffer.writeln('The stats on the share card should match what you roasted/glazed about!');
    buffer.writeln('');
    buffer.writeln(
      'CRITICAL: Return ONLY the raw YAML text. DO NOT wrap it in ```yaml or ``` code blocks. DO NOT add any markdown formatting. Start directly with "headline:" and nothing else.',
    );

    return buffer.toString();
  }
}
