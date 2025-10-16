import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/roast_tab.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';

class TestRoastScreen extends StatefulWidget {
  const TestRoastScreen({super.key});

  @override
  State<TestRoastScreen> createState() => _TestRoastScreenState();
}

class _TestRoastScreenState extends State<TestRoastScreen> {
  final RoundStorageService _storageService = RoundStorageService();
  final GeminiService _geminiService = locator.get<GeminiService>();

  bool _isLoading = false;
  String? _roast;
  String? _errorMessage;
  DGRound? _cachedRound;

  @override
  void initState() {
    super.initState();
    _loadCachedRound();
  }

  Future<void> _loadCachedRound() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final round = await _storageService.loadRound();

      if (round == null) {
        setState(() {
          _errorMessage = 'No cached round found in shared preferences';
          _isLoading = false;
        });
        debugPrint('❌ No cached round found');
        return;
      }

      setState(() {
        _cachedRound = round;
        _isLoading = false;
      });

      debugPrint('✅ Loaded cached round: ${round.courseName}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading cached round: $e';
        _isLoading = false;
      });
      debugPrint('❌ Error loading cached round: $e');
    }
  }

  String _buildRoastPrompt(DGRound round) {
    final analysis = RoundAnalysisGenerator.generateAnalysis(round);

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
    if (_cachedRound == null) {
      setState(() {
        _errorMessage = 'No round loaded. Please record a round first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _roast = null;
    });

    try {
      debugPrint('==========================================');
      debugPrint('🔥 GENERATING ROAST');
      debugPrint('==========================================');
      debugPrint('Course: ${_cachedRound!.courseName}');
      debugPrint('Holes: ${_cachedRound!.holes.length}');

      final prompt = _buildRoastPrompt(_cachedRound!);
      debugPrint('🔄 Calling Gemini to generate roast...');

      final roast = await _geminiService.generateContent(
        prompt: prompt,
        useFullModel: true,
      );

      debugPrint('==========================================');
      debugPrint('🔥 ROAST RESULT:');
      debugPrint('==========================================');
      debugPrint(roast ?? 'No roast generated');
      debugPrint('==========================================');

      setState(() {
        _roast = roast ?? 'Failed to generate roast. Even the AI is too nice to roast this round.';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error generating roast: $e');
      setState(() {
        _errorMessage = 'Error generating roast: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Roast Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Test Round Roasting',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Round info card
            if (_cachedRound != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.golf_course, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Cached Round',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Course: ${_cachedRound!.courseName}'),
                      Text('Holes: ${_cachedRound!.holes.length}'),
                      const SizedBox(height: 8),
                      Text(
                        'Using gemini-2.5-flash (full model)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Generate button
            FilledButton.icon(
              onPressed: _isLoading ? null : _generateRoast,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.local_fire_department),
              label: Text(_isLoading ? 'Generating Roast...' : 'Roast This Round'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFFFF6B6B),
              ),
            ),

            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Card(
                color: Colors.red.withValues(alpha: 0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Roast section
            if (_roast != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFFF6B6B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your Roast',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF6B6B),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _roast!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                          'Check the console/logs for the raw AI response',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Quick access to actual roast tab
            if (_cachedRound != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Preview Roast Tab',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 600,
                child: RoastTab(round: _cachedRound!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
