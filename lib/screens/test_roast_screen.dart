import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/custom_markdown_content.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
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
  bool _shouldGlaze = false; // Toggle between roast and glaze

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
    if (_shouldGlaze) {
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
    buffer.writeln('IMPORTANT RULES:');
    buffer.writeln(
      '- Talk DIRECTLY to the player using "you" and "your" - make it personal and conversational',
    );
    buffer.writeln(
      '- NO stage directions like (pause for applause) or (audience laughs) - this is NOT a script',
    );
    buffer.writeln(
      '- NO meta-commentary about performing or the audience - just ${_shouldGlaze ? 'glaze' : 'roast'} them directly',
    );
    buffer.writeln(
      '- Keep it culturally relevant and contemporary - use slang SPARINGLY and only when it\'s genuinely funny (e.g., "that shot was cheeks" works, but don\'t force slang into every sentence)',
    );
    buffer.writeln(
      '- Mix humor with disc golf references - make it feel authentic and funny',
    );
    buffer.writeln(
      '- Use DIVERSE comedy styles: observational humor, absurdist comedy, deadpan delivery, wordplay, ${_shouldGlaze ? 'hyperbole' : 'sarcasm'}',
    );
    buffer.writeln(
      '- Vary your joke structures: one-liners, setups/punchlines, callbacks, rule of three, misdirection',
    );
    buffer.writeln(
      '- You can use "That\'s like..." or "It\'s like..." patterns ONCE or TWICE max - don\'t overdo it!',
    );
    buffer.writeln(
      '- Mix in many other joke structures besides similes - keep it varied and unpredictable',
    );
    if (_shouldGlaze) {
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
    buffer.writeln(
      'Make it 4-6 short paragraphs. Make it REALLY funny but good-natured.',
    );
    buffer.writeln(
      'Write like you\'re their ${_shouldGlaze ? 'biggest hype man' : 'brutally honest'} friend ${_shouldGlaze ? 'hyping them up' : 'giving them grief'} about their round.',
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

    if (_shouldGlaze) {
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
      debugPrint('🔥 GENERATING ${_shouldGlaze ? 'GLAZE' : 'ROAST'}');
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
      debugPrint('🔥 ${_shouldGlaze ? 'GLAZE' : 'ROAST'} RESULT:');
      debugPrint('==========================================');
      debugPrint(roast ?? 'No roast generated');
      debugPrint('==========================================');

      setState(() {
        _roast =
            roast ??
            'Failed to generate roast. Even the AI is too nice to roast this round.';
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
      appBar: GenericAppBar(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        title: 'Test roast generator',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Test Round Roasting',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
                            style: Theme.of(context).textTheme.titleMedium
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

            // Toggle between roast and glaze
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _shouldGlaze
                                ? 'Glaze (excessive compliments)'
                                : 'Roast (brutal honesty)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _shouldGlaze,
                      onChanged: (value) {
                        setState(() {
                          _shouldGlaze = value;
                        });
                      },
                      activeThumbColor: Colors.amber,
                      inactiveThumbColor: const Color(0xFFFF6B6B),
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
                  : Icon(
                      _shouldGlaze
                          ? Icons.auto_awesome
                          : Icons.local_fire_department,
                    ),
              label: Text(
                _isLoading
                    ? 'Generating ${_shouldGlaze ? 'Glaze' : 'Roast'}...'
                    : '${_shouldGlaze ? 'Glaze' : 'Roast'} This Round',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: _shouldGlaze
                    ? Colors.amber
                    : const Color(0xFFFF6B6B),
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
                  Icon(
                    _shouldGlaze
                        ? Icons.auto_awesome
                        : Icons.local_fire_department,
                    color: _shouldGlaze
                        ? Colors.amber
                        : const Color(0xFFFF6B6B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _shouldGlaze ? 'Your Glaze' : 'Your Roast',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _shouldGlaze
                          ? Colors.amber
                          : const Color(0xFFFF6B6B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                color: (_shouldGlaze ? Colors.amber : const Color(0xFFFF6B6B))
                    .withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [CustomMarkdownContent(data: _roast!)],
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // // Quick access to actual roast tab
            // if (_cachedRound != null) ...[
            //   const SizedBox(height: 24),
            //   const Divider(),
            //   const SizedBox(height: 16),
            //   Text(
            //     'Preview Roast Tab',
            //     style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //           fontWeight: FontWeight.bold,
            //         ),
            //   ),
            //   const SizedBox(height: 8),
            //   SizedBox(
            //     height: 600,
            //     child: RoastTab(round: _cachedRound!),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}
