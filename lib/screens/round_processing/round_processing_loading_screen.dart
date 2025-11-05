import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/animated_disc_icon.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/morphing_background.dart';
import 'package:turbo_disc_golf/screens/round_review/round_review_screen_v2.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

/// Full-screen loading experience shown while processing a round.
///
/// Features organic, fluid animations with a breathing disc icon.
///
/// When `useSharedPreferences` is true (e.g., from Test Parse Constant button):
/// - If a cached round exists, uses that with a 5-second mock delay
/// - If no cached round, processes with Gemini API
///
/// Otherwise, processes the transcript normally with Gemini.
class RoundProcessingLoadingScreen extends StatefulWidget {
  final String transcript;
  final String? courseName;
  final bool useSharedPreferences;

  const RoundProcessingLoadingScreen({
    super.key,
    this.transcript = '',
    this.courseName,
    this.useSharedPreferences = false,
  });

  @override
  State<RoundProcessingLoadingScreen> createState() =>
      _RoundProcessingLoadingScreenState();
}

class _RoundProcessingLoadingScreenState
    extends State<RoundProcessingLoadingScreen> {
  int _currentMessageIndex = 0;
  Timer? _messageTimer;
  late RoundParser _roundParser;
  bool _hasNavigated = false;

  final List<String> _loadingMessages = [
    'Processing your round...',
    'Analyzing your throws...',
    'Calculating statistics...',
    'Generating insights...',
  ];

  @override
  void initState() {
    super.initState();
    _roundParser = locator.get<RoundParser>();
    _roundParser.addListener(_onRoundParserUpdate);
    _startMessageCycle();

    // Delay processing until after the screen has fully transitioned in
    // This prevents navigator lock errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _processRound();
      }
    });
  }

  void _startMessageCycle() {
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  Future<void> _processRound() async {
    debugPrint(
      'RoundProcessingLoadingScreen: _processRound called - transcript length: ${widget.transcript.length}, useSharedPreferences: ${widget.useSharedPreferences}',
    );

    // If using shared preferences (cached round), we still need a transcript
    // but it won't be used if a cached round is found
    if (widget.transcript.isEmpty && !widget.useSharedPreferences) {
      debugPrint(
        'RoundProcessingLoadingScreen: No transcript provided and not using cache - returning',
      );
      return;
    }

    debugPrint(
      'RoundProcessingLoadingScreen: Starting processing (useSharedPreferences: ${widget.useSharedPreferences})',
    );

    // The RoundParser handles all the logic:
    // - If useSharedPreferences=true and cached round exists: 5-second delay, no parsing
    // - Otherwise: normal Gemini API processing
    await _roundParser.parseVoiceTranscript(
      widget.transcript,
      courseName: widget.courseName,
      useSharedPreferences: widget.useSharedPreferences,
    );
  }

  void _onRoundParserUpdate() {
    // Prevent multiple navigation attempts
    if (_hasNavigated) return;

    // Check for errors
    if (_roundParser.lastError.isNotEmpty && mounted) {
      debugPrint(
        'RoundProcessingLoadingScreen: Error - ${_roundParser.lastError}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_roundParser.lastError)));
        }
      });
      return;
    }

    // When ready to navigate to review screen
    if (_roundParser.shouldNavigateToReview && mounted) {
      _hasNavigated = true; // Set flag BEFORE scheduling navigation
      debugPrint(
        'RoundProcessingLoadingScreen: Ready to navigate, scheduling...',
      );

      // Wait for next frame AND add a small delay to ensure navigator is unlocked
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          // Small delay to ensure any ongoing navigation completes
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            debugPrint(
              'RoundProcessingLoadingScreen: Navigating to review screen now',
            );
            _navigateToReviewScreen();
          }
        }
      });
    }
  }

  void _navigateToReviewScreen() {
    debugPrint('RoundProcessingLoadingScreen: _navigateToReviewScreen called');

    if (_roundParser.parsedRound == null) {
      debugPrint(
        'RoundProcessingLoadingScreen: ERROR - parsedRound is null, cannot navigate',
      );
      return;
    }

    debugPrint(
      'RoundProcessingLoadingScreen: parsedRound exists, preparing to navigate',
    );

    // Set the round so the parser can calculate stats
    _roundParser.setRound(_roundParser.parsedRound!);

    // Clear the navigation flag
    _roundParser.clearNavigationFlag();

    debugPrint(
      'RoundProcessingLoadingScreen: Calling Navigator.pushReplacement',
    );

    // Navigate to review screen, replacing this loading screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          debugPrint(
            'RoundProcessingLoadingScreen: Building RoundReviewScreenV2',
          );
          return RoundReviewScreenV2(
            round: _roundParser.parsedRound!,
            showStoryOnLoad: false,
          );
        },
      ),
    );

    debugPrint(
      'RoundProcessingLoadingScreen: Navigator.pushReplacement called successfully',
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _roundParser.removeListener(_onRoundParserUpdate);
    // Restore system UI when leaving the loading screen
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECECEE),
      // Debug-only app bar with back button for testing
      appBar: kDebugMode
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: Stack(
        children: [
          // Animated morphing background
          const MorphingBackground(),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated pulsing disc icon
                const AnimatedDiscIcon(size: 120),

                const SizedBox(height: 48),

                // Cycling loading message with fade animation
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _loadingMessages[_currentMessageIndex],
                    key: ValueKey<int>(_currentMessageIndex),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C2C2C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                // Shimmer loading indicator
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child:
                      Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(
                                    0xFFB8E986,
                                  ).withValues(alpha: 0.3),
                                  const Color(0xFFB8E986),
                                  const Color(0xFF5B7EFF),
                                  const Color(
                                    0xFF5B7EFF,
                                  ).withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: const Duration(milliseconds: 2000),
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                ),

                const SizedBox(height: 16),

                // Subtle hint text with breathing animation
                Text(
                      'Creating something special...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: const Duration(milliseconds: 1500))
                    .then()
                    .fadeOut(duration: const Duration(milliseconds: 1500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
