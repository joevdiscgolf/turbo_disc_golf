import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/ai_content_renderer.dart';
import 'package:turbo_disc_golf/components/custom_markdown_content.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';

class TestAiSummaryScreen extends StatefulWidget {
  const TestAiSummaryScreen({super.key});

  @override
  State<TestAiSummaryScreen> createState() => _TestAiSummaryScreenState();
}

class _TestAiSummaryScreenState extends State<TestAiSummaryScreen> {
  final RoundStorageService _storageService = RoundStorageService();
  final AiParsingService _aiParsingService = locator.get<AiParsingService>();

  bool _isLoading = false;
  AIContent? _aiInsights;
  RoundAnalysis? _analysis;
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
      _aiInsights = null;
    });

    try {
      debugPrint('==========================================');
      debugPrint('🤖 GENERATING UNIFIED AI INSIGHTS');
      debugPrint('==========================================');
      debugPrint('Course: ${_cachedRound!.courseName}');
      debugPrint('Holes: ${_cachedRound!.holes.length}');

      // Generate analysis from round data
      final analysis = RoundAnalysisGenerator.generateAnalysis(_cachedRound!);
      debugPrint('✅ Analysis generated');

      // Generate AI insights (unified response)
      debugPrint('🔄 Calling Gemini to generate unified insights...');
      final Map<String, AIContent?> insights = await _aiParsingService
          .generateRoundInsights(round: _cachedRound!, analysis: analysis);

      final unifiedContent = insights['summary'];

      debugPrint('==========================================');
      debugPrint('📊 UNIFIED AI INSIGHTS:');
      debugPrint('==========================================');
      debugPrint(unifiedContent?.content ?? 'No insights generated');
      debugPrint('==========================================');

      setState(() {
        _aiInsights = unifiedContent;
        _analysis = analysis;
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
                      Text(
                        'Cached Round',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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

            // Unified AI Insights section
            if (_aiInsights != null) ...[
              const SizedBox(height: 16),
              Text(
                'AI Insights (Analysis + Coaching)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _analysis != null
                      ? AIContentRenderer(
                          aiContent: _aiInsights!,
                          round: _cachedRound!,
                          analysis: _analysis!,
                        )
                      : CustomMarkdownContent(data: _aiInsights!.content),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
