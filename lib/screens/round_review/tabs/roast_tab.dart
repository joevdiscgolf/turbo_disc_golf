import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';

class RoastTab extends StatefulWidget {
  final DGRound round;

  const RoastTab({super.key, required this.round});

  @override
  State<RoastTab> createState() => _RoastTabState();
}

class _RoastTabState extends State<RoastTab> {
  String? _roast;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateRoast();
  }

  String _buildRoastPrompt() {
    final analysis = RoundAnalysisGenerator.generateAnalysis(widget.round);
    final round = widget.round;

    // Build a comprehensive stats summary for the AI to roast
    final buffer = StringBuffer();
    buffer.writeln('You are roasting someone directly about their disc golf round. Talk TO them, not about them.');
    buffer.writeln('Write a hilarious roast speaking directly to the player - at their expense!');
    buffer.writeln('');
    buffer.writeln('IMPORTANT RULES:');
    buffer.writeln('- Talk DIRECTLY to the player using "you" and "your" - make it personal and conversational');
    buffer.writeln('- NO stage directions like (pause for applause) or (audience laughs) - this is NOT a script');
    buffer.writeln('- NO meta-commentary about performing or the audience - just roast them directly');
    buffer.writeln('- Use Gen Z slang naturally: bro, no cap, fr fr, deadass, lowkey/highkey, mid, that\'s cheeks/buns, cooked, down bad, etc.');
    buffer.writeln('- Mix Gen Z humor with disc golf references - make it feel authentic and funny');
    buffer.writeln('- Use DIVERSE comedy styles: observational humor, absurdist comedy, deadpan delivery, wordplay, sarcasm');
    buffer.writeln('- Vary your joke structures: one-liners, setups/punchlines, callbacks, rule of three, misdirection');
    buffer.writeln('- You can use "That\'s like..." or "It\'s like..." patterns ONCE or TWICE max - don\'t overdo it!');
    buffer.writeln('- Mix in many other joke structures besides similes - keep it varied and unpredictable');
    buffer.writeln('- Reference the specific numbers in clever ways (e.g., "bro you went OB more times than I check my phone")');
    buffer.writeln('- Use disc golf insider references (chains, hyzer flips, rollaways, tree love, etc.)');
    buffer.writeln('- Mix short punchy burns with longer observations');
    buffer.writeln('- End with a brutal but funny closer directed at them');
    buffer.writeln('');
    buffer.writeln('Make it 4-6 short paragraphs. Make it REALLY funny but good-natured.');
    buffer.writeln('Write like you\'re their brutally honest Gen Z friend giving them grief about their round.');
    buffer.writeln('Keep it creative, unpredictable, and DIRECTLY addressed to them with natural slang!');
    buffer.writeln('');
    buffer.writeln('ROUND STATS TO ROAST:');
    buffer.writeln('Course: ${round.courseName}');
    buffer.writeln('Score: ${analysis.totalScoreRelativeToPar >= 0 ? '+' : ''}${analysis.totalScoreRelativeToPar}');
    buffer.writeln('');

    // Scoring stats
    buffer.writeln('SCORING:');
    buffer.writeln('Birdies: ${analysis.scoringStats.birdies}');
    buffer.writeln('Pars: ${analysis.scoringStats.pars}');
    buffer.writeln('Bogeys: ${analysis.scoringStats.bogeys}');
    buffer.writeln('Double Bogeys+: ${analysis.scoringStats.doubleBogeyPlus}');
    if (analysis.bounceBackPercentage > 0) {
      buffer.writeln('Bounce Back %: ${analysis.bounceBackPercentage.toStringAsFixed(0)}%');
    }
    buffer.writeln('');

    // Driving stats
    buffer.writeln('DRIVING:');
    buffer.writeln('Fairway Hit: ${analysis.coreStats.fairwayHitPct.toStringAsFixed(0)}%');
    buffer.writeln('C1 in Regulation: ${analysis.coreStats.c1InRegPct.toStringAsFixed(0)}%');
    buffer.writeln('C2 in Regulation: ${analysis.coreStats.c2InRegPct.toStringAsFixed(0)}%');
    buffer.writeln('Parked: ${analysis.coreStats.parkedPct.toStringAsFixed(0)}%');
    buffer.writeln('Out of Bounds: ${analysis.coreStats.obPct.toStringAsFixed(0)}%');
    buffer.writeln('');

    // Putting stats
    buffer.writeln('PUTTING:');
    buffer.writeln('C1X Make Rate: ${analysis.puttingStats.c1xPercentage.toStringAsFixed(0)}%');
    buffer.writeln('C2 Make Rate: ${analysis.puttingStats.c2Percentage.toStringAsFixed(0)}%');
    if (analysis.puttingStats.totalAttempts > 0) {
      buffer.writeln('Total Putts Made: ${analysis.puttingStats.totalMakes}/${analysis.puttingStats.totalAttempts}');
      buffer.writeln('Overall Make %: ${analysis.puttingStats.overallPercentage.toStringAsFixed(0)}%');
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
      buffer.writeln('Scramble Success: ${analysis.scrambleStats.scrambleRate.toStringAsFixed(0)}% (${analysis.scrambleStats.scrambleSaves}/${analysis.scrambleStats.scrambleOpportunities})');
      buffer.writeln('');
    }

    buffer.writeln('Now deliver a hilarious standup comedy routine roasting this round!');
    buffer.writeln('Remember: you\'re a comedian on stage, not writing an essay. Make it punchy, funny, and memorable!');

    return buffer.toString();
  }

  Future<void> _generateRoast() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final geminiService = locator.get<GeminiService>();
      final prompt = _buildRoastPrompt();

      final roast = await geminiService.generateContent(
        prompt: prompt,
        useFullModel: true, // Use full flash model for better roasts
      );

      // Print raw response for debugging
      print('========== RAW ROAST RESPONSE ==========');
      print(roast ?? 'null');
      print('========================================');

      if (mounted) {
        setState(() {
          _roast = roast ?? 'Failed to generate roast. Even the AI is too nice to roast this round.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate roast: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with fire emoji and mascot
          Row(
            children: [
              Image.asset(
                'assets/mascots/turbo_mascot.png',
                width: 60,
                height: 60,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROAST MY ROUND',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6B6B),
                          ),
                    ),
                    Text(
                      'Prepare to be roasted...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main roast card
          Card(
            elevation: 4,
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _isLoading
                  ? Column(
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFFFF6B6B),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Generating your roast...\nThis is gonna be good!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    )
                  : _error != null
                      ? Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _generateRoast,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B6B),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _roast ?? '',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    height: 1.6,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: _generateRoast,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Roast Me Again'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF6B6B),
                                  side: const BorderSide(
                                    color: Color(0xFFFF6B6B),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),

          const SizedBox(height: 16),

          // Disclaimer
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This roast is AI-generated and meant to be funny. Don\'t take it too seriously!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
