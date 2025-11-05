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
    _startMessageCycle();

    // Start processing immediately
    _processRound();
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
    // If using shared preferences (cached round), we still need a transcript
    // but it won't be used if a cached round is found
    if (widget.transcript.isEmpty && !widget.useSharedPreferences) {
      return;
    }

    try {
      // The RoundParser handles all the logic:
      // - If useSharedPreferences=true and cached round exists: 5-second delay, no parsing
      // - Otherwise: normal Gemini API processing
      await _roundParser.parseVoiceTranscript(
        widget.transcript,
        courseName: widget.courseName,
        useSharedPreferences: widget.useSharedPreferences,
      );

      // After parsing completes, check if we have a valid round
      if (!mounted) return;

      if (_roundParser.lastError.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_roundParser.lastError)));
        Navigator.of(context).pop();
        return;
      }

      if (_roundParser.parsedRound != null) {
        _navigateToReviewScreen();
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('RoundProcessingLoadingScreen: Exception during parsing: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing round: $e')));
        Navigator.of(context).pop();
      }
    }
  }

  void _navigateToReviewScreen() {
    if (_roundParser.parsedRound == null) {
      debugPrint(
        'RoundProcessingLoadingScreen: ERROR - parsedRound is null, cannot navigate',
      );
      return;
    }

    // Set the round so the parser can calculate stats
    _roundParser.setRound(_roundParser.parsedRound!);

    // Navigate to review screen with magical zoom transition
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return RoundReviewScreenV2(
            round: _roundParser.parsedRound!,
            showStoryOnLoad: false,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth curved animation
          final CurvedAnimation curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          // Scale animation - magical zoom from center
          final Animation<double> scaleAnimation = Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation);

          // Fade animation with smooth appearance
          final Animation<double> fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            ),
          );

          // Energy glow that pulses and fades
          final Animation<double> glowAnimation = Tween<double>(
            begin: 1.0,
            end: 0.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
            ),
          );

          return Stack(
            children: [
              // Multi-layered energy glow background
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final double glowIntensity = glowAnimation.value;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.5,
                        colors: [
                          const Color(0xFFB8E986).withValues(
                            alpha: glowIntensity * 0.4,
                          ),
                          const Color(0xFF5B7EFF).withValues(
                            alpha: glowIntensity * 0.3,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  );
                },
              ),

              // Main content with smooth transformations
              ScaleTransition(
                scale: scaleAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
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
