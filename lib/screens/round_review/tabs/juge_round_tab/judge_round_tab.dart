import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/ai_content_renderer.dart';
import 'package:turbo_disc_golf/components/banners/regenerate_prompt_banner.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_building_animation.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_confetti_overlay.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_preparing_animation.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_reveal_effect.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_share_card.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_slot_reel.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_verdict_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/endpoints/ai_endpoints.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/protocols/llm_service.dart';
import 'package:turbo_disc_golf/screens/round_review/share_judgment_preview_screen.dart';
import 'package:turbo_disc_golf/services/judgment_prompt_service.dart';
import 'package:turbo_disc_golf/services/llm/backend_llm_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/services/share_service.dart';
import 'package:turbo_disc_golf/state/round_review_cubit.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';
import 'package:yaml/yaml.dart';

/// State machine for the judgment animation flow.
enum JudgmentState {
  idle, // "Ready to Be Judged?" card
  building, // Suspense buildup with morphing background
  preparing, // Waiting for API response with engaging animation
  spinning, // Slot reel cycles ROAST/GLAZE (API already ready)
  revealing, // Particle explosion as verdict locks
  celebrating, // Confetti burst + result card scales in
  complete, // Static result view
  error, // Error state
}

/// AI-powered judgment tab that roasts or glazes your round (50/50 chance)
/// with a viral slot machine reveal experience.
class JudgeRoundTab extends StatefulWidget {
  static const String tabName = 'Judge';

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

  // Track regeneration count from previous judgment (for incrementing on regenerate)
  int _previousRegenerateCount = 0;

  // Confetti controller
  late ConfettiController _confettiController;

  // Notifier to signal slot reel when API is ready
  final ValueNotifier<bool> _apiReadyNotifier = ValueNotifier<bool>(false);

  // Key for capturing share card as image
  final GlobalKey _shareCardKey = GlobalKey();

  // For blur transition into content
  bool _showBlurTransition = false;

  late final LoggingServiceBase _logger;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': JudgeRoundTab.tabName,
    });

    _currentRound = widget.round;
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 4000),
    );

    // Extract judgment type from existing content if present
    if (_currentRound.aiJudgment != null) {
      _isGlaze = _extractJudgmentType(_currentRound.aiJudgment!.content);

      // If testing flag is on, show preparing animation first
      if (locator.get<FeatureFlagService>().showJudgmentPreparingAnimation) {
        _currentState = JudgmentState.preparing;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPreparingAnimationForTesting();
        });
      } else {
        _currentState = JudgmentState.complete;
      }
    }

    // Auto-start only if no judgment exists (not when outdated - show banner instead)
    if (_currentRound.aiJudgment == null) {
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

  /// Shows preparing animation for testing when judgment already exists.
  Future<void> _showPreparingAnimationForTesting() async {
    // Show preparing animation for 3 seconds for testing
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    setState(() {
      _currentState = JudgmentState.complete;
    });
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

  String _getDefaultTagline(bool isGlaze) {
    return isGlaze
        ? 'The chains literally bowed down when you walked up. Your disc had GPS-level accuracy. The course is considering renaming a hole after you.'
        : 'The basket is still in therapy after watching your putts. The trees formed a support group. Even the OB stakes felt bad.';
  }

  /// Strips common AI-generated prefixes from YAML values.
  ///
  /// The AI sometimes returns values like "Headline: actual headline" instead
  /// of just "actual headline". This strips those redundant prefixes.
  String _stripAIPrefix(String value) {
    return value
        .replaceFirst(
          RegExp(r'^(Headline|Tagline|Content):\s*', caseSensitive: false),
          '',
        )
        .trim();
  }

  /// Waits for the API to signal it's ready.
  ///
  /// Returns immediately if already ready, otherwise waits for the
  /// [_apiReadyNotifier] to become true.
  Future<void> _waitForAPIReady() async {
    if (_apiReadyNotifier.value) return;

    final Completer<void> completer = Completer<void>();

    void listener() {
      if (_apiReadyNotifier.value && !completer.isCompleted) {
        completer.complete();
      }
    }

    _apiReadyNotifier.addListener(listener);
    await completer.future;
    _apiReadyNotifier.removeListener(listener);
  }

  /// Starts the full judgment animation flow.
  Future<void> _startJudgmentFlow() async {
    // Determine roast vs glaze upfront (so slot reel knows where to land)
    final FeatureFlagService flags = locator.get<FeatureFlagService>();
    if (flags.forceJudgmentType != null) {
      _isGlaze = flags.forceJudgmentType == 'glaze';
    } else {
      final Random random = Random(DateTime.now().microsecondsSinceEpoch);
      _isGlaze = random.nextBool();
    }
    _generatedJudgment = null;
    _errorMessage = null;
    _apiReadyNotifier.value = false;

    // Phase 1: Building (1500ms) - suspense buildup
    setState(() {
      _currentState = JudgmentState.building;
    });

    // Start API call in parallel with animations
    _generateJudgmentContent();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Phase 2: Preparing - wait for API to complete
    if (locator.get<FeatureFlagService>().showJudgmentPreparingAnimation) {
      setState(() {
        _currentState = JudgmentState.preparing;
      });

      // Show preparing animation for at least 2 seconds for testing visibility
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;
    }

    await _waitForAPIReady();
    if (!mounted) return;

    // Phase 3: Spinning - API is ready, reel will land immediately
    setState(() {
      _currentState = JudgmentState.spinning;
    });

    // Slot reel will detect _apiReadyNotifier is already true,
    // start landing animation, and call onSpinComplete when done
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
    // Only play confetti for glaze - fire emojis are triggered directly via fireIsPlaying prop
    if (_isGlaze) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _confettiController.play();
        }
      });
    }

    // Wait for fire to stop entering from top (~3730ms) + 500ms buffer
    await Future.delayed(const Duration(milliseconds: 4200));
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
      String? judgment;

      // Use mock judgment for testing the animation flow
      if (locator.get<FeatureFlagService>().useMockJudgment) {
        await Future.delayed(const Duration(milliseconds: 2000));
        judgment = _isGlaze ? _getMockGlazeJudgment() : _getMockRoastJudgment();
      } else if (locator
          .get<FeatureFlagService>()
          .generateAiContentFromBackend) {
        debugPrint('using backend to generate roast');
        // Use backend cloud function for judgment generation
        final RoundAnalysis? analysis = _currentRound.analysis;
        if (analysis == null) return;

        final BackendLLMService backendService = locator
            .get<BackendLLMService>();

        final GenerateRoundJudgmentResponse? response = await backendService
            .generateRoundJudgment(
              request: GenerateRoundJudgmentRequest(
                round: _currentRound,
                analysis: analysis,
                shouldGlaze: _isGlaze,
              ),
            );

        if (response == null || !response.success) {
          throw Exception(
            response?.data.error ?? 'Failed to generate judgment from backend',
          );
        }
        judgment = response.data.rawResponse;
      } else {
        // Use local LLM service
        final JudgmentPromptService promptService = JudgmentPromptService();
        final String prompt = promptService.buildJudgmentPrompt(
          _currentRound,
          _isGlaze,
        );
        final LLMService llmService = locator.get<LLMService>();
        judgment = await llmService.generateContent(
          prompt: prompt,
          useFullModel: true,
        );
      }

      if (judgment == null) {
        throw Exception('Failed to generate judgment');
      }

      // Clean up the response - remove markdown code blocks if present
      _generatedJudgment = _cleanYamlResponse(judgment);
    } catch (e) {
      _errorMessage = 'Failed to generate judgment: $e';
    }

    // Signal slot reel to stop spinning (whether success or error)
    if (mounted) {
      _apiReadyNotifier.value = true;
    }
  }

  /// Removes markdown code block wrappers from YAML responses.
  String _cleanYamlResponse(String response) {
    String cleaned = response.trim();

    // Remove ```yaml or ```YAML at the beginning
    if (cleaned.startsWith('```yaml') || cleaned.startsWith('```YAML')) {
      cleaned = cleaned.substring(cleaned.indexOf('\n') + 1);
    }

    // Remove just 'yaml' or 'YAML' at the beginning
    if (cleaned.startsWith('yaml\n') || cleaned.startsWith('YAML\n')) {
      cleaned = cleaned.substring(5);
    }

    // Remove closing ``` at the end
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3).trim();
    }

    return cleaned;
  }

  String _getMockRoastJudgment() {
    return '''headline: The Disc Golf Disaster Report
tagline: Your putter filed a restraining order against the basket
content: |
  **🎯 The Putting Situation**
  Your C1X was a coin flip you kept losing. The basket had a restraining order against your discs - every putt sailed past like it had somewhere better to be.

  **🌲 Tree Magnetism**
  Your fairway hits were giving "blindfolded throws in a wind tunnel" energy. Did you bring a map? Because you found every tree on the course.

  **💡 Silver Lining**
  At least you got cardio walking to all those OB zones. Every cloud, right?
highlightStats:
  - c1xPuttPct
  - obPct''';
  }

  String _getMockGlazeJudgment() {
    return '''headline: Sweet Victory Unlocked
tagline: The chains literally bowed down to your putting prowess
content: |
  **🎯 The Putting Masterclass**
  Your putting was chef's kiss. Those chains didn't stand a chance - you were threading needles from C1 like it was your job. Automatic.

  **🌲 Course Domination**
  Surgical precision on the fairways. You found lines that didn't exist before. Every drive was painting a masterpiece.

  **👑 The Verdict**
  This wasn't just a round - this was a statement. Take a bow, champion!
highlightStats:
  - fairwayPct
  - parkedPct''';
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
      regenerateCount: _previousRegenerateCount,
    );

    final RoundStorageService storageService = locator
        .get<RoundStorageService>();
    final DGRound updatedRound = _currentRound.copyWith(aiJudgment: aiJudgment);
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
              fireIsPlaying:
                  !_isGlaze && _currentState == JudgmentState.celebrating,
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
      case JudgmentState.preparing:
        return const JudgmentPreparingAnimation();
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                onPressed: () {
                  _logger.track('Begin Judgment Button Tapped');
                  _startJudgmentFlow();
                },
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
    return JudgmentRevealEffect(isGlaze: _isGlaze);
  }

  Widget _buildCelebratingState(BuildContext context) {
    return Center(child: JudgmentVerdictAnnouncement(isGlaze: _isGlaze));
  }

  Future<void> _shareJudgmentCard(String headline) async {
    _logger.track(
      'Judgment Share Button Tapped',
      properties: {'judgment_type': _isGlaze ? 'glaze' : 'roast'},
    );
    final ShareService shareService = locator.get<ShareService>();

    final String emoji = _isGlaze ? '\u{1F369}' : '\u{1F525}';
    final String caption =
        '$emoji $headline\n\n${_currentRound.courseName}\nShared from Turbo Disc Golf';

    final bool success = await shareService.captureAndShare(
      _shareCardKey,
      caption: caption,
      filename: 'judgment_${_isGlaze ? 'glaze' : 'roast'}',
    );

    if (!success && mounted) {
      // Fall back to clipboard if capture fails
      Clipboard.setData(ClipboardData(text: caption));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard! Ready to share.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildShareButton(String headline) {
    return PrimaryButton(
      width: double.infinity,
      height: 56,
      label: _isGlaze ? 'Share my glaze' : 'Share my roast',
      icon: Icons.ios_share,
      gradientBackground: _isGlaze
          ? const [Color(0xFF137e66), Color(0xFF1a9f7f)]
          : const [Color(0xFFFF6B6B), Color(0xFFFF8A8A)],
      onPressed: () => _shareJudgmentCard(headline),
    );
  }

  Widget _buildShareActionBar(String headline) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Preview button
          Expanded(
            child: PrimaryButton(
              width: double.infinity,
              height: 56,
              label: 'Preview',
              // icon: Icons.visibility_outlined,
              backgroundColor: Colors.white,
              labelColor: Colors.grey[800]!,
              iconColor: Colors.grey[800]!,
              borderColor: SenseiColors.gray[100],
              onPressed: () => _showShareCardPreview(headline),
            ),
          ),
          const SizedBox(width: 8),
          // Share button (primary gradient)
          Expanded(flex: 2, child: _buildShareButton(headline)),
        ],
      ),
    );
  }

  void _showShareCardPreview(String headline) {
    _logger.track(
      'Judgment Preview Button Tapped',
      properties: {'judgment_type': _isGlaze ? 'glaze' : 'roast'},
    );
    final String displayTagline = _getPreviewTagline();
    final RoundAnalysis analysis = RoundAnalysisGenerator.generateAnalysis(
      _currentRound,
    );
    final List<String> highlightStats = _getPreviewHighlightStats();

    pushCupertinoRoute(
      context,
      ShareJudgmentPreviewScreen(
        isGlaze: _isGlaze,
        headline: headline,
        tagline: displayTagline,
        round: _currentRound,
        analysis: analysis,
        highlightStats: highlightStats,
      ),
      pushFromBottom: true,
    );
  }

  String _getPreviewTagline() {
    if (_currentRound.aiJudgment == null) return _getDefaultTagline(_isGlaze);

    String cleanContent = _currentRound.aiJudgment!.content;
    if (cleanContent.startsWith('<!-- JUDGMENT_TYPE:')) {
      final int endIndex = cleanContent.indexOf('-->');
      if (endIndex != -1) {
        cleanContent = cleanContent.substring(endIndex + 3).trim();
      }
    }

    try {
      final dynamic yaml = loadYaml(cleanContent);
      if (yaml is YamlMap) {
        final String headline = _stripAIPrefix(
          (yaml['headline'] as String?) ?? '',
        );
        final String tagline = _stripAIPrefix(
          (yaml['tagline'] as String?) ?? '',
        );
        return (tagline.isNotEmpty && tagline != headline)
            ? tagline
            : _getDefaultTagline(_isGlaze);
      }
    } catch (e) {
      // Fall back to default
    }
    return _getDefaultTagline(_isGlaze);
  }

  List<String> _getPreviewHighlightStats() {
    if (_currentRound.aiJudgment == null) return <String>[];

    String cleanContent = _currentRound.aiJudgment!.content;
    if (cleanContent.startsWith('<!-- JUDGMENT_TYPE:')) {
      final int endIndex = cleanContent.indexOf('-->');
      if (endIndex != -1) {
        cleanContent = cleanContent.substring(endIndex + 3).trim();
      }
    }

    try {
      final dynamic yaml = loadYaml(cleanContent);
      if (yaml is YamlMap) {
        final YamlList? stats = yaml['highlightStats'] as YamlList?;
        if (stats != null) {
          return stats.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      // Fall back to empty
    }
    return <String>[];
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
    // Feature flag: use new bottom action bar layout
    if (locator.get<FeatureFlagService>().useBottomShareActionBar) {
      return _buildResultContentV2(context);
    }

    // Extract clean content (remove metadata comment)
    String cleanContent = _currentRound.aiJudgment!.content;
    if (cleanContent.startsWith('<!-- JUDGMENT_TYPE:')) {
      final int endIndex = cleanContent.indexOf('-->');
      if (endIndex != -1) {
        cleanContent = cleanContent.substring(endIndex + 3).trim();
      }
    }

    // Parse YAML content
    String headline = _isGlaze ? 'YOU GOT GLAZED!' : 'YOU GOT ROASTED!';
    String tagline = '';
    String content = cleanContent;
    List<String> highlightStats = <String>[];

    try {
      final dynamic yaml = loadYaml(cleanContent);
      if (yaml is YamlMap) {
        // Strip AI-generated prefixes like "Headline: " from values
        headline = _stripAIPrefix((yaml['headline'] as String?) ?? headline);
        tagline = _stripAIPrefix((yaml['tagline'] as String?) ?? '');
        content = (yaml['content'] as String?) ?? cleanContent;
        final YamlList? stats = yaml['highlightStats'] as YamlList?;
        if (stats != null) {
          highlightStats = stats.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      // Fall back to legacy format (first line is headline)
      final List<String> lines = cleanContent.split('\n');
      if (lines.isNotEmpty && lines[0].trim().isNotEmpty) {
        headline = lines[0].trim();
        content = lines.skip(1).join('\n').trim();
      }
    }

    // Create AIContent with clean content for rendering
    final AIContent cleanAIContent = AIContent(
      content: content,
      roundVersionId: _currentRound.versionId,
    );

    // Generate analysis for rendering
    final RoundAnalysis analysis = RoundAnalysisGenerator.generateAnalysis(
      _currentRound,
    );

    // Ensure tagline is different from headline (AI sometimes duplicates them)
    final String displayTagline = (tagline.isNotEmpty && tagline != headline)
        ? tagline
        : _getDefaultTagline(_isGlaze);

    // Build the share card widget
    final Widget shareCard = RepaintBoundary(
      key: _shareCardKey,
      child: JudgmentShareCard(
        isGlaze: _isGlaze,
        headline: headline,
        tagline: displayTagline,
        round: _currentRound,
        analysis: analysis,
        highlightStats: highlightStats,
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show regenerate banner when content is outdated
          if (_currentRound.isAIJudgmentOutdated)
            RegeneratePromptBanner(
              onRegenerate: () {
                _logger.track('Judgment Regenerate Button Tapped');
                // Save the current regenerate count + 1 for the new judgment
                _previousRegenerateCount =
                    (_currentRound.aiJudgment?.regenerateCount ?? 0) + 1;
                setState(() {
                  _currentRound = _currentRound.copyWith(aiJudgment: null);
                  _currentState = JudgmentState.idle;
                });
                _startJudgmentFlow();
              },
              isLoading: _currentState == JudgmentState.building ||
                  _currentState == JudgmentState.preparing,
              subtitle: 'Roast may be outdated',
              regenerationsRemaining:
                  _currentRound.aiJudgment?.regenerationsRemaining,
            ),

          // Verdict card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: JudgmentVerdictCard(
              isGlaze: _isGlaze,
              headline: headline,
              animate: false,
            ),
          ),

          const SizedBox(height: 16),

          // Premium share button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildShareButton(headline),
          ),

          const SizedBox(height: 16),

          // Content card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
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
          ),

          const SizedBox(height: 16),

          // Info card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
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
          ),

          // Share card preview
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Share Card Preview:',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 8),
          // Full-width share card
          shareCard,
        ],
      ),
    );
  }

  /// V2 layout with bottom action bar for share functionality.
  Widget _buildResultContentV2(BuildContext context) {
    // Extract clean content (remove metadata comment)
    String cleanContent = _currentRound.aiJudgment!.content;
    if (cleanContent.startsWith('<!-- JUDGMENT_TYPE:')) {
      final int endIndex = cleanContent.indexOf('-->');
      if (endIndex != -1) {
        cleanContent = cleanContent.substring(endIndex + 3).trim();
      }
    }

    // Parse YAML content
    String headline = _isGlaze ? 'YOU GOT GLAZED!' : 'YOU GOT ROASTED!';
    String tagline = '';
    String content = cleanContent;
    List<String> highlightStats = <String>[];

    try {
      final dynamic yaml = loadYaml(cleanContent);
      if (yaml is YamlMap) {
        headline = _stripAIPrefix((yaml['headline'] as String?) ?? headline);
        tagline = _stripAIPrefix((yaml['tagline'] as String?) ?? '');
        content = (yaml['content'] as String?) ?? cleanContent;
        final YamlList? stats = yaml['highlightStats'] as YamlList?;
        if (stats != null) {
          highlightStats = stats.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      final List<String> lines = cleanContent.split('\n');
      if (lines.isNotEmpty && lines[0].trim().isNotEmpty) {
        headline = lines[0].trim();
        content = lines.skip(1).join('\n').trim();
      }
    }

    // Create AIContent with clean content for rendering
    final AIContent cleanAIContent = AIContent(
      content: content,
      roundVersionId: _currentRound.versionId,
    );

    // Generate analysis for rendering
    final RoundAnalysis analysis = RoundAnalysisGenerator.generateAnalysis(
      _currentRound,
    );

    // Ensure tagline is different from headline
    final String displayTagline = (tagline.isNotEmpty && tagline != headline)
        ? tagline
        : _getDefaultTagline(_isGlaze);

    // Hidden share card for capture (using Offstage)
    final Widget shareCard = Offstage(
      offstage: true,
      child: RepaintBoundary(
        key: _shareCardKey,
        child: JudgmentShareCard(
          isGlaze: _isGlaze,
          headline: headline,
          tagline: displayTagline,
          round: _currentRound,
          analysis: analysis,
          highlightStats: highlightStats,
        ),
      ),
    );

    return Stack(
      children: [
        Column(
          children: [
            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 12, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show regenerate banner when content is outdated
                    if (_currentRound.isAIJudgmentOutdated)
                      RegeneratePromptBanner(
                        onRegenerate: () {
                          _logger.track('Judgment Regenerate Button Tapped');
                          // Save the current regenerate count + 1 for the new judgment
                          _previousRegenerateCount =
                              (_currentRound.aiJudgment?.regenerateCount ?? 0) +
                              1;
                          setState(() {
                            _currentRound = _currentRound.copyWith(
                              aiJudgment: null,
                            );
                            _currentState = JudgmentState.idle;
                          });
                          _startJudgmentFlow();
                        },
                        isLoading: _currentState == JudgmentState.building ||
                            _currentState == JudgmentState.preparing,
                        subtitle: 'Roast may be outdated',
                        regenerationsRemaining:
                            _currentRound.aiJudgment?.regenerationsRemaining,
                      ),

                    // Verdict card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: JudgmentVerdictCard(
                        isGlaze: _isGlaze,
                        headline: headline,
                        animate: false,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Content card (no share button in V2 - moved to bottom bar)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
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
                    ),

                    const SizedBox(height: 16),

                    // Info card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                    ),
                    // No share card preview in V2 - available via bottom sheet
                  ],
                ),
              ),
            ),
            // Fixed bottom action bar
            _buildShareActionBar(headline),
          ],
        ),
        // Hidden share card for capture
        shareCard,
      ],
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
                  _logger.track('Judgment Try Again Button Tapped');
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
