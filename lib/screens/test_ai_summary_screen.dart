import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/components/custom_markdown_content.dart';

class TestAiSummaryScreen extends StatefulWidget {
  const TestAiSummaryScreen({super.key});

  @override
  State<TestAiSummaryScreen> createState() => _TestAiSummaryScreenState();
}

class _TestAiSummaryScreenState extends State<TestAiSummaryScreen> {
  final RoundStorageService _storageService = RoundStorageService();
  final GeminiService _geminiService = locator.get<GeminiService>();

  bool _isLoading = false;
  String? _aiSummary;
  String? _aiCoaching;
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

  Future<void> _generateAiSummary() async {
    if (_cachedRound == null) {
      setState(() {
        _errorMessage = 'No round loaded. Please record a round first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _aiSummary = null;
      _aiCoaching = null;
    });

    try {
      debugPrint('==========================================');
      debugPrint('🤖 GENERATING AI SUMMARY AND COACHING');
      debugPrint('==========================================');
      debugPrint('Course: ${_cachedRound!.courseName}');
      debugPrint('Holes: ${_cachedRound!.holes.length}');

      // Generate analysis from round data
      final analysis = RoundAnalysisGenerator.generateAnalysis(_cachedRound!);
      debugPrint('✅ Analysis generated');

      // Generate AI insights (summary and coaching)
      debugPrint('🔄 Calling Gemini to generate insights...');
      final insights = await _geminiService.generateRoundInsights(
        round: _cachedRound!,
        analysis: analysis,
      );

      final summary = insights['summary'] ?? '';
      final coaching = insights['coaching'] ?? '';

      debugPrint('==========================================');
      debugPrint('📊 AI SUMMARY:');
      debugPrint('==========================================');
      debugPrint(summary);
      debugPrint('');
      debugPrint('==========================================');
      debugPrint('🎯 AI COACHING:');
      debugPrint('==========================================');
      debugPrint(coaching);
      debugPrint('==========================================');

      setState(() {
        _aiSummary = summary;
        _aiCoaching = coaching;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error generating AI summary: $e');
      setState(() {
        _errorMessage = 'Error generating AI summary: $e';
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Test AI Summary Generator',
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
                      Text(
                        'Cached Round',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text('Course: ${_cachedRound!.courseName}'),
                      Text('Holes: ${_cachedRound!.holes.length}'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Generate button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateAiSummary,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.psychology),
              label: Text(_isLoading ? 'Generating...' : 'Generate AI Summary'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
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

            // AI Summary section
            if (_aiSummary != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomMarkdownContent(data: _aiSummary!),
                ),
              ),
            ],

            // AI Coaching section
            if (_aiCoaching != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomMarkdownContent(data: _aiCoaching!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
