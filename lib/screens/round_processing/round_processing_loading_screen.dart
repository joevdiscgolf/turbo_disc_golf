import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/record_round/record_round_screen.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/explosion_effect.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/morphing_background.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/persistent_square.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/round_confirmation_widget.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/juge_round_tab/judge_round_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/round_stats_body.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';
import 'package:turbo_disc_golf/state/round_confirmation_cubit.dart';
import 'package:turbo_disc_golf/state/round_confirmation_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Full-screen loading experience shown while processing a round.
///
/// This widget reads all necessary data from the RecordRoundCubit state
/// (transcript, course, layout, number of holes) rather than receiving
/// them as constructor parameters.
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
  static const String screenName = 'Round Processing';
  static const String routeName = '/round-processing';

  final bool useSharedPreferences;
  final bool fromFinalizeBanner;

  const RoundProcessingLoadingScreen({
    super.key,
    this.useSharedPreferences = false,
    this.fromFinalizeBanner = false,
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
  confirming,
}

class _RoundProcessingLoadingScreenState
    extends State<RoundProcessingLoadingScreen>
    with SingleTickerProviderStateMixin {
  late RoundParser _roundParser;
  _ProcessingState _processingState = _ProcessingState.loading;
  late TabController _tabController;
  late final LoggingServiceBase _logger;

  // Store the finalized round locally so we can clear cubit state
  DGRound? _finalizedRound;

  // GlobalKey to ensure ExplosionEffect persists across state changes
  final GlobalKey _explosionEffectKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': RoundProcessingLoadingScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('RoundProcessingLoadingScreen');

    _tabController = TabController(length: 3, vsync: this);

    _roundParser = locator.get<RoundParser>();

    // Start processing immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processRound();
    });
  }

  Future<void> _processRound() async {
    // Check if we already have a confirmation in progress from the finalize banner
    final RoundConfirmationCubit confirmationCubit =
        BlocProvider.of<RoundConfirmationCubit>(context);

    if (widget.fromFinalizeBanner &&
        confirmationCubit.state is ConfirmingRoundActive) {
      if (mounted) {
        setState(() {
          _processingState = _ProcessingState.confirming;
        });
      }
      return;
    }

    // Read values from RecordRoundCubit state BEFORE it's cleared
    final RecordRoundCubit cubit = context.read<RecordRoundCubit>();
    final RecordRoundState state = cubit.state;

    // Sanity check: ensure we have an active recording state
    if (state is! RecordRoundActive) {
      if (mounted) {
        _navigateBackToRecordRound();
      }
      return;
    }

    // Extract values from the active state
    final String transcript = state.fullTranscript;
    final Course? selectedCourse = state.selectedCourse;
    final String? selectedLayoutId = state.selectedLayout?.id;
    final int numHoles = state.numHoles;

    // If transcript is empty, show error and go back
    if (transcript.isEmpty && !widget.useSharedPreferences) {
      if (mounted) {
        locator.get<ToastService>().showError('Please add hole descriptions.');
        _navigateBackToRecordRound();
      }
      return;
    }

    try {
      // The RoundParser handles all the logic:
      // - If useSharedPreferences=true and cached round exists: 5-second delay, no parsing
      // - Otherwise: normal Gemini API processing
      await _roundParser.parseVoiceTranscript(
        transcript,
        selectedCourse: selectedCourse,
        selectedLayoutId: selectedLayoutId,
        numHoles: numHoles,
      );

      // After parsing completes, check if we have a valid round
      if (!mounted) return;

      if (_roundParser.lastError.isNotEmpty) {
        locator.get<ToastService>().showError(_roundParser.lastError);
        _navigateBackToRecordRound();
        return;
      }

      // Check for potential round (after initial parsing)
      if (_roundParser.potentialRound != null) {
        // Initialize the cubit with the potential round BEFORE transitioning
        final RoundConfirmationCubit confirmationCubit =
            BlocProvider.of<RoundConfirmationCubit>(context);
        confirmationCubit.startRoundConfirmation(
          context,
          _roundParser.potentialRound!,
        );

        // Now transition to confirmation screen
        setState(() {
          _processingState = _ProcessingState.confirming;
        });
      } else {
        // No round parsed
        _navigateBackToRecordRound();
      }
    } catch (e) {
      if (mounted) {
        locator.get<ToastService>().showError('Error processing round: $e');
        _navigateBackToRecordRound();
      }
    }
  }

  void _revealContent() async {
    final RoundConfirmationCubit cubit =
        BlocProvider.of<RoundConfirmationCubit>(context);

    // Finalize the round using the cubit (stores result in cubit state)
    debugPrint('Finalizing potential round via cubit...');
    final finalizedRound = await cubit.startRevealAnimation();

    if (finalizedRound == null) {
      debugPrint(
        'RoundProcessingLoadingScreen: ERROR - Failed to finalize round',
      );
      if (mounted) {
        locator.get<ToastService>().showError(
          'Round is missing required fields. Please complete all holes.',
        );
        // Go back to confirmation screen
        cubit.setAnimationPhase(AnimationPhase.idle);
        setState(() {
          _processingState = _ProcessingState.confirming;
        });
      }
      return;
    }

    // Store the finalized round locally so we can display it after clearing cubit state
    _finalizedRound = finalizedRound;

    // First, transition: fade out text and move icon to center
    // (cubit.startRevealAnimation already set phase to transitioning)
    setState(() {
      _processingState = _ProcessingState.transitioning;
    });

    // Wait 800ms for text fade and icon movement to complete
    await Future.delayed(const Duration(milliseconds: 800));

    // Then trigger explosion effect
    cubit.setAnimationPhase(AnimationPhase.exploding);
    setState(() {
      _processingState = _ProcessingState.exploding;
    });

    // Wait 2.8 seconds for explosion to complete
    // Reduced by 1700ms total (1200ms + 500ms) for tighter timing before hyperspace
    await Future.delayed(const Duration(milliseconds: 2800));

    // Trigger zoom transition into the center disc (hyperspace starts immediately)
    if (mounted) {
      cubit.setAnimationPhase(AnimationPhase.zooming);
      setState(() {
        _processingState = _ProcessingState.zooming;
      });
    }

    // Wait 2.5 seconds for hyperspace zoom animation to complete
    await Future.delayed(const Duration(milliseconds: 2500));

    // Then transition to revealing state
    if (mounted) {
      cubit.setAnimationPhase(AnimationPhase.revealing);
      setState(() {
        _processingState = _ProcessingState.revealing;
      });

      // Clear the cubit state now that we have the round stored locally
      // This prevents the "Finalize round" banner from showing in history
      cubit.clearRoundConfirmation();
      _roundParser.clearPotentialRound();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Restore system UI when leaving the screen
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  /// Navigate back to the record round screen on failure
  /// Uses pushReplacement since this screen replaced the record round screen
  void _navigateBackToRecordRound() {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RecordRoundScreen(
              topViewPadding: mediaQuery.viewPadding.top,
              bottomViewPadding: mediaQuery.viewPadding.bottom,
              skipIntroAnimations: true,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide in from left (reverse of normal push) to feel like going back
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
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
              const SizedBox(
                height: 100,
              ), // Increased to 100 (52px total down from original)
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
              const SizedBox(
                height: 52,
              ), // Match the increased spacing (24px + 16px + 12px)
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
    // Use the locally stored finalized round (cubit state was cleared)
    if (_finalizedRound == null) {
      debugPrint('_buildReviewContent: ERROR - no finalized round stored');
      return const Center(child: Text('Error: No round data'));
    }

    return Container(
      key: const ValueKey('review'),
      color: SenseiColors.gray[50],
      child: Column(
        children: [
          GenericAppBar(
            topViewPadding: MediaQuery.of(context).viewPadding.top,
            title: locator.get<FeatureFlagService>().showRoundMetadataInfoBar
                ? 'Round overview'
                : _finalizedRound!.courseName,
            backgroundColor: SenseiColors.gray[50],
            bottomWidget: _buildTabBar(),
            bottomWidgetHeight: 40,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RoundStatsBody(
                  round: _finalizedRound!,
                  isReviewV2Screen: true,
                  tabController: _tabController,
                ),
                RoundStoryTab(
                  round: _finalizedRound!,
                  tabController: _tabController,
                ),
                JudgeRoundTab(round: _finalizedRound!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      labelColor: Colors.black,
      unselectedLabelColor: Colors.black54,
      indicatorColor: Colors.black,
      indicatorWeight: 2,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      labelPadding: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      indicatorPadding: EdgeInsets.zero,
      onTap: (_) => HapticFeedback.lightImpact(),
      tabs: const [
        Tab(text: 'Stats'),
        Tab(text: 'Story'),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department, size: 16),
              SizedBox(width: 4),
              Text('Judge'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationContent() {
    // Get potential round from cubit state (single source of truth)
    final RoundConfirmationCubit cubit =
        BlocProvider.of<RoundConfirmationCubit>(context);
    final state = cubit.state;

    if (state is! ConfirmingRoundActive) {
      debugPrint('_buildConfirmationContent: No active confirmation state');
      return const SizedBox.shrink();
    }

    return RoundConfirmationWidget(
      potentialRound: state.potentialRound,
      onBack: () {
        // Clear the confirmation state and potential round when going back
        cubit.clearRoundConfirmation();
        _roundParser.clearPotentialRound();
        Navigator.of(context).pop();
      },
      onConfirm: _revealContent,
      topViewPadding: MediaQuery.of(context).viewPadding.top,
    );
  }

  Widget _buildRestartButton() {
    return GestureDetector(
      onTap: () {
        // Clear the confirmation state and go back to start over
        context.read<RoundConfirmationCubit>().clearRoundConfirmation();
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 16, color: Colors.black87),
            // const SizedBox(width: 6),
            // Text(
            //   'Restart',
            //   style: Theme.of(context).textTheme.labelSmall?.copyWith(
            //     color: Colors.black87,
            //     fontWeight: FontWeight.w600,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: Icon(Icons.close, size: 20, color: Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor:
              Colors.transparent, // Transparent to show body background
          extendBodyBehindAppBar: true, // Body extends behind app bar
          // App bar only shown during confirmation state
          // During revealing state, app bar is built into _buildReviewContent
          appBar: _processingState == _ProcessingState.confirming
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: GenericAppBar(
                    topViewPadding: MediaQuery.of(context).viewPadding.top,
                    title: 'Confirm round',
                    backgroundColor: SenseiColors.gray[50],
                    foregroundColor: Colors.black87,
                    hasBackButton: false,
                    leftWidget: _buildRestartButton(),
                    rightWidget: _buildCloseButton(),
                  ),
                )
              : null,

          body: Stack(
            children: [
              // Layer 0: Base background color - consistent light color throughout
              Container(
                color: const Color(
                  0xFFF5F0FA,
                ), // Lighter purple-gray background
              ),

              // Layer 1: Background animations with smooth 300ms crossfades
              // During revealing, hyperspace fades out as content fades in
              if (_processingState == _ProcessingState.revealing)
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 2500),
                  tween: Tween<double>(begin: 1.0, end: 0.0),
                  curve: Curves.easeInOut,
                  builder: (context, hyperspaceOpacity, child) {
                    return Opacity(opacity: hyperspaceOpacity, child: child);
                  },
                  child: _buildZoomingContent(),
                )
              else if (_processingState != _ProcessingState.confirming)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    // Smooth fade transition between states
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _processingState == _ProcessingState.loading
                      ? _buildLoadingContent()
                      : _processingState == _ProcessingState.transitioning
                      ? _buildTransitioningContent()
                      : _processingState == _ProcessingState.exploding
                      ? _buildExplodingContent()
                      : _processingState == _ProcessingState.zooming
                      ? _buildZoomingContent()
                      : const SizedBox.shrink(),
                ),

              // Layer 2: Round review content that fades in with blur
              // Much faster unblur for snappy reveal (1000ms)
              if (_processingState == _ProcessingState.revealing)
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
                      child: Opacity(opacity: contentOpacity, child: child),
                    );
                  },
                  child: _buildReviewContent(),
                ),

              // Layer 3: Confirmation widget - shows after parsing completes
              if (_processingState == _ProcessingState.confirming)
                _buildConfirmationContent(),

              // Layer 4: Persistent triangle overlay - visible through entire animation
              // Only hide during revealing and confirming
              if (_processingState != _ProcessingState.revealing &&
                  _processingState != _ProcessingState.confirming)
                IgnorePointer(child: _buildPersistentTriangle()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersistentTriangle() {
    // Determine triangle mode and size based on current state
    SquareMode mode;
    double size;

    switch (_processingState) {
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
