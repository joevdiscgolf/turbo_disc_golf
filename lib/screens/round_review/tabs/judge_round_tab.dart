import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/ai_content_renderer.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/judgment_prompt_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/state/round_review_cubit.dart';

/// AI-powered judgment tab that roasts or glazes your round (50/50 chance)
class JudgeRoundTab extends StatefulWidget {
  final DGRound round;
  final bool autoStartJudgment;

  const JudgeRoundTab({
    super.key,
    required this.round,
    this.autoStartJudgment = false,
  });

  @override
  State<JudgeRoundTab> createState() => _JudgeRoundTabState();
}

class _JudgeRoundTabState extends State<JudgeRoundTab>
    with AutomaticKeepAliveClientMixin {
  late DGRound _currentRound;
  bool _isGenerating = false;
  String? _errorMessage;
  bool _isGlaze = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentRound = widget.round;

    // Extract judgment type from existing content if present
    if (_currentRound.aiJudgment != null) {
      _isGlaze = _extractJudgmentType(_currentRound.aiJudgment!.content);
    }

    // Auto-start if no judgment exists (always auto-generate)
    if (_shouldGenerateJudgment()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateJudgment();
      });
    }
  }

  bool _shouldGenerateJudgment() {
    return _currentRound.aiJudgment == null ||
        _currentRound.isAIJudgmentOutdated;
  }

  bool _extractJudgmentType(String content) {
    // Parse metadata comment to determine roast vs glaze
    if (content.startsWith('<!-- JUDGMENT_TYPE: GLAZE -->')) {
      return true;
    }
    return false;
  }

  String _buildJudgmentContent(String judgment, bool isGlaze) {
    // Prepend metadata for future parsing
    return '<!-- JUDGMENT_TYPE: ${isGlaze ? 'GLAZE' : 'ROAST'} -->\n$judgment';
  }

  Future<void> _generateJudgment() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Determine roast vs glaze (true 50/50 random)
      final Random random = Random(DateTime.now().microsecondsSinceEpoch);
      _isGlaze = random.nextBool();

      // Wait 2 seconds for suspense animation
      await Future.delayed(const Duration(milliseconds: 2000));

      // Generate judgment using service
      final JudgmentPromptService promptService = JudgmentPromptService();
      final String prompt = promptService.buildJudgmentPrompt(
        _currentRound,
        _isGlaze,
      );

      final GeminiService geminiService = locator.get<GeminiService>();
      final String? judgment = await geminiService.generateContent(
        prompt: prompt,
        useFullModel: true,
      );

      if (judgment == null) {
        throw Exception('Failed to generate judgment');
      }

      // Build content with metadata
      final String contentWithMetadata = _buildJudgmentContent(
        judgment,
        _isGlaze,
      );

      // Create AIContent
      final AIContent aiJudgment = AIContent(
        content: contentWithMetadata,
        roundVersionId: _currentRound.versionId,
      );

      // Update round with judgment
      final RoundStorageService storageService = locator
          .get<RoundStorageService>();
      final DGRound updatedRound = _currentRound.copyWith(
        aiJudgment: aiJudgment,
      );
      await storageService.saveRound(updatedRound);

      // Update cubit state so banner disappears
      if (mounted) {
        final RoundReviewCubit reviewCubit = BlocProvider.of<RoundReviewCubit>(
          context,
        );
        reviewCubit.updateRoundData(updatedRound);

        setState(() {
          _isGenerating = false;
          _currentRound = updatedRound;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Failed to generate judgment: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEEE8F5),
            Color(0xFFECECEE),
            Color(0xFFE8F4E8),
            Color(0xFFEAE8F0),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isGenerating)
              _buildJudgingState(context)
            else if (_errorMessage != null)
              _buildErrorState(context)
            else if (_currentRound.aiJudgment != null)
              _buildResultState(context)
            else
              _buildIdleState(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 80,
              color: Color(0xFFFF6B6B),
            ),
            const SizedBox(height: 16),
            Text(
              'Ready to Be Judged?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Get an AI-powered roast or glaze of your round. It\'s a 50/50 shot!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateJudgment,
              icon: const Icon(Icons.local_fire_department),
              label: const Text('Begin Judgment'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJudgingState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            _JudgmentLoadingAnimation(),
            const SizedBox(height: 24),
            Text(
              'Analyzing your round...',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Will you get roasted or glazed?',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _shareJudgment(String content, String headline) {
    final String shareText =
        '''
${_isGlaze ? '🍩' : '🔥'} $headline

$content

📊 ${_currentRound.courseName}
Shared from Turbo Disc Golf''';

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard! Ready to share.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildResultState(BuildContext context) {
    // Extract clean content (remove metadata comment)
    String cleanContent = _currentRound.aiJudgment!.content;
    if (cleanContent.startsWith('<!-- JUDGMENT_TYPE:')) {
      final int endIndex = cleanContent.indexOf('-->');
      if (endIndex != -1) {
        cleanContent = cleanContent.substring(endIndex + 3).trim();
      }
    }

    // Extract headline from first line
    String headline = _isGlaze ? 'YOU GOT GLAZED!' : 'YOU GOT ROASTED!';
    String contentWithoutHeadline = cleanContent;

    final lines = cleanContent.split('\n');
    if (lines.isNotEmpty && lines[0].trim().isNotEmpty) {
      headline = lines[0].trim();
      // Remove headline from content
      contentWithoutHeadline = lines.skip(1).join('\n').trim();
    }

    // Create AIContent with clean content for rendering
    final AIContent cleanAIContent = AIContent(
      content: contentWithoutHeadline,
      roundVersionId: _currentRound.versionId,
    );

    // Generate analysis for rendering
    final RoundAnalysis analysis = RoundAnalysisGenerator.generateAnalysis(
      _currentRound,
    );

    final Color primaryColor = _isGlaze
        ? const Color(0xFF2196F3)
        : const Color(0xFFFF6B6B);
    final Color darkColor = _isGlaze
        ? const Color(0xFF1565C0)
        : const Color(0xFFD32F2F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Debug regenerate button (only in debug mode)
        if (kDebugMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: () {
                // Clear the current judgment to force regeneration
                setState(() {
                  _currentRound = _currentRound.copyWith(aiJudgment: null);
                });
                _generateJudgment();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Regenerate (Debug)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.15),
                primaryColor.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _isGlaze
                  ? const Text('🍩', style: TextStyle(fontSize: 48))
                  : Icon(
                      Icons.local_fire_department,
                      size: 48,
                      color: primaryColor,
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isGlaze
                          ? 'Excessive compliments incoming...'
                          : 'Brutal honesty incoming...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: darkColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Full-width share button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _shareJudgment(contentWithoutHeadline, headline),
            icon: const Icon(Icons.ios_share, size: 20),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            child: AIContentRenderer(
              aiContent: cleanAIContent,
              round: _currentRound,
              analysis: analysis,
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
                    'Judgment is permanent for this round. Each round gets one 50/50 roll!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to generate judgment',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateJudgment,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Suspenseful loading animation during judgment generation
class _JudgmentLoadingAnimation extends StatefulWidget {
  @override
  State<_JudgmentLoadingAnimation> createState() =>
      _JudgmentLoadingAnimationState();
}

class _JudgmentLoadingAnimationState extends State<_JudgmentLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: const Icon(
        Icons.local_fire_department,
        size: 80,
        color: Color(0xFFFF6B6B),
      ),
    );
  }
}
