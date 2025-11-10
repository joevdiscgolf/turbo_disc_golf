import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/explosion_effect.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/morphing_background.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/persistent_square.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/round_confirmation_widget.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_overview_body.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

/// Full-screen loading experience shown while processing a round.
///
/// Instead of navigating to a new screen, this widget transitions its content
/// in-place from loading UI to round review UI once processing completes.
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

enum _ProcessingState {
  loading,
  transitioning,
  exploding,
  zooming,
  revealing,
  confirming
}

class _RoundProcessingLoadingScreenState
    extends State<RoundProcessingLoadingScreen> {
  late RoundParser _roundParser;
  _ProcessingState _state = _ProcessingState.loading;

  // GlobalKey to ensure ExplosionEffect persists across state changes
  final GlobalKey _explosionEffectKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _roundParser = locator.get<RoundParser>();

    // Start processing immediately
    _processRound();
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

      // Check for potential round (after initial parsing)
      if (_roundParser.potentialRound != null) {
        // Transition to confirmation screen
        setState(() {
          _state = _ProcessingState.confirming;
        });
      } else if (_roundParser.parsedRound != null) {
        // For cached rounds, we skip confirmation and go straight to reveal
        _revealContent();
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

  void _revealContent() async {
    // If we have a potential round, finalize it first
    if (_roundParser.potentialRound != null && _roundParser.parsedRound == null) {
      debugPrint('Finalizing potential round...');

      // Show a brief loading state
      setState(() {
        _state = _ProcessingState.loading;
      });

      final bool success = await _roundParser.finalizeRound();

      if (!success) {
        debugPrint(
          'RoundProcessingLoadingScreen: ERROR - Failed to finalize round: ${_roundParser.lastError}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_roundParser.lastError)),
          );
          // Go back to confirmation screen
          setState(() {
            _state = _ProcessingState.confirming;
          });
        }
        return;
      }
    }

    if (_roundParser.parsedRound == null) {
      debugPrint(
        'RoundProcessingLoadingScreen: ERROR - parsedRound is null, cannot reveal',
      );
      return;
    }

    // Set the round so the parser can calculate stats
    _roundParser.setRound(_roundParser.parsedRound!);

    // First, transition: fade out text and move icon to center
    setState(() {
      _state = _ProcessingState.transitioning;
    });

    // Wait 800ms for text fade and icon movement to complete
    await Future.delayed(const Duration(milliseconds: 800));

    // Then trigger explosion effect
    setState(() {
      _state = _ProcessingState.exploding;
    });

    // Wait 2.8 seconds for explosion to complete
    // Reduced by 1700ms total (1200ms + 500ms) for tighter timing before hyperspace
    await Future.delayed(const Duration(milliseconds: 2800));

    // Trigger zoom transition into the center disc (hyperspace starts immediately)
    if (mounted) {
      setState(() {
        _state = _ProcessingState.zooming;
      });
    }

    // Wait 2.5 seconds for hyperspace zoom animation to complete
    await Future.delayed(const Duration(milliseconds: 2500));

    // Then transition to revealing state
    if (mounted) {
      setState(() {
        _state = _ProcessingState.revealing;
      });
    }
  }

  @override
  void dispose() {
    // Restore system UI when leaving the screen
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  Widget _buildLoadingContent() {
    // Show loading view WITHOUT the triangle (triangle is in persistent overlay)
    return Stack(
      key: const ValueKey('loading'),
      children: [
        const MorphingBackground(),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Empty space where triangle would be (it's in the overlay)
              const SizedBox(height: 120),
              const SizedBox(height: 100), // Increased to 100 (52px total down from original)
              // Text with loading indicator to match transitioning layout
              Text(
                'Processing your round...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 24),
              // Loading indicator (same as transitioning state)
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransitioningContent() {
    // Show loading view with text fading out (triangle is in persistent overlay)
    return Stack(
      key: const ValueKey('transitioning'),
      children: [
        // Keep the morphing background
        const MorphingBackground(),

        // Fade out text (triangle stays in overlay)
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Empty space where triangle is (it's in the overlay)
              const SizedBox(height: 120),
              const SizedBox(height: 52), // Match the increased spacing (24px + 16px + 12px)

              // Text elements fade out
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 1.0, end: 0.0),
                curve: Curves.easeOut,
                builder: (context, opacity, child) {
                  return Opacity(
                    opacity: opacity,
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        Text(
                          'Processing your round...',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2C2C2C),
                              ),
                        ),
                        const SizedBox(height: 24),
                        // Loading indicator
                        Container(
                          width: 200,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExplodingContent() {
    // Explosion state: Shows blue energy waves radiating outward
    return const ExplosionEffect(
      key: ValueKey('exploding'),
      isZooming: false, // Energy waves only, no hyperspace particles
      hideSquare: true, // Persistent triangle handles all triangle rendering
    );
  }

  Widget _buildZoomingContent() {
    // Zoom state: Shows hyperspace particles
    // Uses GlobalKey to persist this widget through zooming -> revealing transition
    return ExplosionEffect(
      key: _explosionEffectKey, // Ensures widget persists to revealing state
      isZooming: true, // Hyperspace particles only
      hideSquare: true, // Persistent triangle handles all triangle rendering
    );
  }

  Widget _buildReviewContent() {
    // Background will be handled by the revealing transition
    // to keep hyperspace particles visible
    return Container(
      key: const ValueKey('review'),
      color: Colors.transparent, // Transparent initially
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight,
        ),
        child: RoundOverviewBody(
          round: _roundParser.parsedRound!,
          isReviewV2Screen: true,
        ),
      ),
    );
  }

  Widget _buildConfirmationContent() {
    return RoundConfirmationWidget(
      potentialRound: _roundParser.potentialRound!,
      onBack: () => Navigator.of(context).pop(),
      onConfirm: _revealContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show body background
      extendBodyBehindAppBar: true, // Body extends behind app bar
      // App bar always present to reserve space, fades in with content
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _state == _ProcessingState.revealing
            ? TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000), // Same as content fade
                tween: Tween<double>(begin: 0.0, end: 1.0),
                curve: Curves.easeOut, // Same curve as content
                builder: (context, progress, child) {
                  return Opacity(
                    opacity: progress, // Fade from 0 to 1
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      foregroundColor: Colors.black87, // Dark text for light background
                      title: Text(
                        _roundParser.parsedRound?.courseName ?? 'Round Review',
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: Colors.transparent, // Just reserve space, no AppBar widget
              ),
      ),

      body: Stack(
        children: [
          // Layer 0: Base background color - consistent light color throughout
          Container(
            color: const Color(0xFFEEE8F5), // Light purple-gray background
          ),

          // Layer 1: Background animations with smooth 300ms crossfades
          // During revealing, hyperspace fades out as content fades in
          if (_state == _ProcessingState.revealing)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 2500),
              tween: Tween<double>(begin: 1.0, end: 0.0),
              curve: Curves.easeInOut,
              builder: (context, hyperspaceOpacity, child) {
                return Opacity(
                  opacity: hyperspaceOpacity,
                  child: child,
                );
              },
              child: _buildZoomingContent(),
            )
          else if (_state != _ProcessingState.confirming)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                // Smooth fade transition between states
                return FadeTransition(opacity: animation, child: child);
              },
              child: _state == _ProcessingState.loading
                  ? _buildLoadingContent()
                  : _state == _ProcessingState.transitioning
                      ? _buildTransitioningContent()
                      : _state == _ProcessingState.exploding
                          ? _buildExplodingContent()
                          : _state == _ProcessingState.zooming
                              ? _buildZoomingContent()
                              : const SizedBox.shrink(),
            ),

          // Layer 2: Round review content that fades in with blur
          // Much faster unblur for snappy reveal (1000ms)
          if (_state == _ProcessingState.revealing)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              curve: Curves.easeOut, // Faster easing at the end
              builder: (context, progress, child) {
                // Strong blur at start (20), clear at end (0)
                final double blur = 20.0 * (1.0 - progress);

                // Start at 0% opacity, fade to 100%
                final double contentOpacity = progress;

                return ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blur,
                    sigmaY: blur,
                    tileMode: TileMode.decal,
                  ),
                  child: Opacity(
                    opacity: contentOpacity,
                    child: child,
                  ),
                );
              },
              child: _buildReviewContent(),
            ),

          // Layer 3: Confirmation widget - shows after parsing completes
          if (_state == _ProcessingState.confirming) _buildConfirmationContent(),

          // Layer 4: Persistent triangle overlay - visible through entire animation
          // Only hide during revealing and confirming
          if (_state != _ProcessingState.revealing &&
              _state != _ProcessingState.confirming)
            IgnorePointer(child: _buildPersistentTriangle()),
        ],
      ),
    );
  }

  Widget _buildPersistentTriangle() {
    // Determine triangle mode and size based on current state
    SquareMode mode;
    double size;

    switch (_state) {
      case _ProcessingState.loading:
      case _ProcessingState.transitioning:
        mode = SquareMode.pulsing;
        size = 140; // Keep consistent size to prevent jolt
        break;
      case _ProcessingState.exploding:
        mode = SquareMode.exploding;
        size = 140;
        break;
      case _ProcessingState.zooming:
        mode = SquareMode.zooming;
        size = 140;
        break;
      case _ProcessingState.revealing:
      case _ProcessingState.confirming:
        // Hide triangle during reveal and confirmation
        return const SizedBox.shrink();
    }

    return Center(
      child: PersistentSquare(
        key: const ValueKey(
          'persistent_triangle',
        ), // Same key ensures widget persistence
        mode: mode,
        size: size,
      ),
    );
  }
}
