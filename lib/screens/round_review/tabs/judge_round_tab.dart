import 'dart:math';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/ai_content_renderer.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_building_animation.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_confetti_overlay.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_reveal_effect.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_slot_reel.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_verdict_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/judgment_prompt_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/state/round_review_cubit.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

/// State machine for the judgment animation flow.
enum JudgmentState {
  idle, // "Ready to Be Judged?" card
  building, // Suspense buildup with morphing background
  spinning, // Slot reel cycles ROAST/GLAZE
  revealing, // Particle explosion as verdict locks
  celebrating, // Confetti burst + result card scales in
  complete, // Static result view
  error, // Error state
}

/// AI-powered judgment tab that roasts or glazes your round (50/50 chance)
/// with a viral slot machine reveal experience.
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
  JudgmentState _currentState = JudgmentState.idle;
  String? _errorMessage;
  bool _isGlaze = false;
  String? _generatedJudgment;

  // Confetti controller
  late ConfettiController _confettiController;

  // Notifier to signal slot reel when API is ready
  final ValueNotifier<bool> _apiReadyNotifier = ValueNotifier<bool>(false);

  // For blur transition into content
  bool _showBlurTransition = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentRound = widget.round;
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 4000),
    );

    // Extract judgment type from existing content if present
    if (_currentRound.aiJudgment != null) {
      _isGlaze = _extractJudgmentType(_currentRound.aiJudgment!.content);
      _currentState = JudgmentState.complete;
    }

    // Auto-start if no judgment exists
    if (_shouldGenerateJudgment()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startJudgmentFlow();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _apiReadyNotifier.dispose();
    super.dispose();
  }

  bool _shouldGenerateJudgment() {
    return _currentRound.aiJudgment == null ||
        _currentRound.isAIJudgmentOutdated;
  }

  bool _extractJudgmentType(String content) {
    if (content.startsWith('<!-- JUDGMENT_TYPE: GLAZE -->')) {
      return true;
    }
    return false;
  }

  String _buildJudgmentContent(String judgment, bool isGlaze) {
    return '<!-- JUDGMENT_TYPE: ${isGlaze ? 'GLAZE' : 'ROAST'} -->\n$judgment';
  }

  /// Starts the full judgment animation flow.
  Future<void> _startJudgmentFlow() async {
    // Determine roast vs glaze upfront (so slot reel knows where to land)
    final Random random = Random(DateTime.now().microsecondsSinceEpoch);
    _isGlaze = random.nextBool();
    _generatedJudgment = null;
    _errorMessage = null;
    _apiReadyNotifier.value = false;

    // Phase 1: Building (1500ms)
    setState(() {
      _currentState = JudgmentState.building;
    });

    // Start API call in parallel with animations
    _generateJudgmentContent();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Phase 2: Spinning - continues until API signals ready
    setState(() {
      _currentState = JudgmentState.spinning;
    });

    // Slot reel will spin until _apiReadyNotifier becomes true,
    // then land and call onSpinComplete
  }

  /// Called when slot reel finishes spinning (API is already complete at this point).
  void _onSpinComplete() async {
    if (!mounted) return;

    // Check for error immediately - if failed, go to error state
    if (_errorMessage != null) {
      setState(() {
        _currentState = JudgmentState.error;
      });
      return;
    }

    // Phase 3: Revealing (800ms)
    setState(() {
      _currentState = JudgmentState.revealing;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Phase 4: Celebrating (show announcement, then blur transition to complete)
    setState(() {
      _currentState = JudgmentState.celebrating;
    });
    _confettiController.play();

    // Hold on "YOU GOT ROASTED/GLAZED" for 3.5 seconds to let confetti land
    await Future.delayed(const Duration(milliseconds: 3500));
    if (!mounted) return;

    // Phase 5: Complete - transition with blur effect
    setState(() {
      _showBlurTransition = true;
      _currentState = JudgmentState.complete;
    });

    // Save the judgment (API already completed)
    await _saveJudgment();

    // Trigger rebuild to show content
    if (mounted) {
      setState(() {});
    }
  }

  /// Generates judgment content via API (runs in parallel with animations).
  Future<void> _generateJudgmentContent() async {
    try {
      // Use mock judgment for testing the animation flow
      if (useMockJudgment) {
        await Future.delayed(const Duration(milliseconds: 2000));
        _generatedJudgment = _isGlaze
            ? _getMockGlazeJudgment()
            : _getMockRoastJudgment();
      } else {
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

        _generatedJudgment = judgment;
      }
    } catch (e) {
      _errorMessage = 'Failed to generate judgment: $e';
    }

    // Signal slot reel to stop spinning (whether success or error)
    if (mounted) {
      _apiReadyNotifier.value = true;
    }
  }

  String _getMockRoastJudgment() {
    return '''🔥 The Disc Golf Disaster Report

Listen, I've seen some questionable rounds in my time, but this one takes the cake and then throws it OB.

Your putting was... well, let's just say the basket had a restraining order against your discs. C1 putts? More like "See ya, putt!" as they sailed past the chains.

The fairway hits were giving "blindfolded throws in a wind tunnel" energy. Did you bring a map? Because you found every tree on the course.

But hey, at least you got some exercise walking to all those OB zones. Cardio counts, right?

Keep grinding though - even the worst rounds teach us something. Usually it's humility. Lots and lots of humility.''';
  }

  String _getMockGlazeJudgment() {
    return '''🍩 Sweet Victory Unlocked!

Okay, we need to talk about what just happened out there because it was BEAUTIFUL.

Your putting was absolutely chef's kiss. Those chains didn't stand a chance - you were threading needles from C1 like it was your job. Automatic.

The fairway game? Surgical precision. You found lines I didn't even know existed. Every drive was painting a masterpiece on the fairway canvas.

This wasn't just a round - this was a statement. You showed up, showed out, and made the course your personal highlight reel.

Take a bow, champion. You earned every single stroke of that score. This is the kind of round you tell your grandkids about!''';
  }

  /// Saves the generated judgment to storage.
  Future<void> _saveJudgment() async {
    if (_generatedJudgment == null) return;

    final String contentWithMetadata = _buildJudgmentContent(
      _generatedJudgment!,
      _isGlaze,
    );

    final AIContent aiJudgment = AIContent(
      content: contentWithMetadata,
      roundVersionId: _currentRound.versionId,
    );

    final RoundStorageService storageService =
        locator.get<RoundStorageService>();
    final DGRound updatedRound = _currentRound.copyWith(
      aiJudgment: aiJudgment,
    );
    await storageService.saveRound(updatedRound);

    if (mounted) {
      final RoundReviewCubit reviewCubit = BlocProvider.of<RoundReviewCubit>(
        context,
      );
      reviewCubit.updateRoundData(updatedRound);
      _currentRound = updatedRound;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      decoration: const BoxDecoration(
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
      child: Stack(
        children: [
          // Main content
          _buildMainContent(context),

          // Confetti overlay (always mounted, controlled by controller)
          if (_currentState == JudgmentState.celebrating ||
              _currentState == JudgmentState.complete)
            JudgmentConfettiOverlay(
              isGlaze: _isGlaze,
              controller: _confettiController,
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    switch (_currentState) {
      case JudgmentState.idle:
        return _buildIdleState(context);
      case JudgmentState.building:
        return const JudgmentBuildingAnimation();
      case JudgmentState.spinning:
        return _buildSpinningState(context);
      case JudgmentState.revealing:
        return _buildRevealingState(context);
      case JudgmentState.celebrating:
        return _buildCelebratingState(context);
      case JudgmentState.complete:
        return _buildResultState(context);
      case JudgmentState.error:
        return _buildErrorState(context);
    }
  }

  Widget _buildIdleState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Card(
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Get an AI-powered roast or glaze of your round. '
                "It's a 50/50 shot!",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startJudgmentFlow,
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
      ),
    );
  }

  Widget _buildSpinningState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          JudgmentSlotReel(
            targetIsGlaze: _isGlaze,
            onSpinComplete: _onSpinComplete,
            readyToStop: _apiReadyNotifier,
          ),
          const SizedBox(height: 32),
          Text(
            'Spinning the wheel of fate...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C2C2C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealingState(BuildContext context) {
    return JudgmentRevealEffect(
      isGlaze: _isGlaze,
    );
  }

  Widget _buildCelebratingState(BuildContext context) {
    return Center(
      child: JudgmentVerdictAnnouncement(isGlaze: _isGlaze),
    );
  }

  void _shareJudgment(String content, String headline) {
    final String shareText = '''
${_isGlaze ? '\u{1F369}' : '\u{1F525}'} $headline

$content

\u{1F4CA} ${_currentRound.courseName}
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
    // If judgment isn't ready yet, show loading with the verdict card
    if (_currentRound.aiJudgment == null) {
      return _buildLoadingResultState(context);
    }

    // Wrap in blur transition if coming from celebrating state
    if (_showBlurTransition) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween<double>(begin: 15.0, end: 0.0),
        onEnd: () {
          // Reset the flag after animation completes
          if (mounted) {
            setState(() {
              _showBlurTransition = false;
            });
          }
        },
        builder: (context, blur, child) {
          return ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blur,
              sigmaY: blur,
              tileMode: TileMode.decal,
            ),
            child: Opacity(
              opacity: (1.0 - (blur / 15.0)).clamp(0.3, 1.0),
              child: child,
            ),
          );
        },
        child: _buildResultContent(context),
      );
    }

    return _buildResultContent(context);
  }

  Widget _buildResultContent(BuildContext context) {

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

    final List<String> lines = cleanContent.split('\n');
    if (lines.isNotEmpty && lines[0].trim().isNotEmpty) {
      headline = lines[0].trim();
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Regenerate button
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentRound = _currentRound.copyWith(aiJudgment: null);
                    _currentState = JudgmentState.idle;
                  });
                  _startJudgmentFlow();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Regenerate'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),

          // Verdict card
          JudgmentVerdictCard(
            isGlaze: _isGlaze,
            headline: headline,
            animate: false,
          ),

          const SizedBox(height: 16),

          // Share button
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

          // Content card
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

          // Info card
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
                      'Judgment is permanent for this round. '
                      'Each round gets one 50/50 roll!',
                      style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildLoadingResultState(BuildContext context) {
    final String headline = _isGlaze ? 'YOU GOT GLAZED!' : 'YOU GOT ROASTED!';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict card
          JudgmentVerdictCard(
            isGlaze: _isGlaze,
            headline: headline,
            animate: false,
          ),
          const SizedBox(height: 24),
          // Loading indicator for content
          Center(
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Generating your judgment...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Card(
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
                onPressed: () {
                  setState(() {
                    _currentState = JudgmentState.idle;
                  });
                  _startJudgmentFlow();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
