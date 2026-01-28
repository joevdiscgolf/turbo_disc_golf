import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/loaders/atomic_nuclear_loader.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_result.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/video_analysis_session.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/analysis_completion_transition.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/analysis_results_view.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/cycling_analysis_text.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/form_analysis_background.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/video_input_body.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_type.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_cubit.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Screen for recording/importing videos and analyzing form.
/// Keeps the exact same UI/UX as the original FormAnalysisScreen.
class FormAnalysisRecordingScreen extends StatefulWidget {
  static const String routeName = '/form-analysis-recording';
  static const String screenName = 'Form Analysis Recording';

  const FormAnalysisRecordingScreen({super.key, required this.topViewPadding});

  final double topViewPadding;

  @override
  State<FormAnalysisRecordingScreen> createState() =>
      _FormAnalysisRecordingScreenState();
}

class _FormAnalysisRecordingScreenState
    extends State<FormAnalysisRecordingScreen> {
  bool _showingTransition = false;
  VideoFormAnalysisComplete? _pendingResults;
  late final LoggingServiceBase _logger;

  // Persistent speed notifier for the loader
  final ValueNotifier<double> _loaderSpeedNotifier = ValueNotifier<double>(1.0);

  // Brain opacity notifier for smooth fade out during transition
  final ValueNotifier<double> _brainOpacityNotifier = ValueNotifier<double>(
    1.0,
  );

  // DEBUG MODE: Set to true to automatically test the finalization animation
  // When enabled, the screen will show:
  //   - 4 seconds of loading (brain orbiting, messages cycling)
  //   - Then the 5-second finalization animation
  // Set to FALSE when done testing to require actual video upload
  static const bool _debugAutoFinalization = false;
  bool _debugLoadingStarted = false;

  @override
  void initState() {
    super.initState();

    // Set light status bar (light icons/text for dark background)
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': FormAnalysisRecordingScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('FormAnalysisRecordingScreen');

    // Debug mode: automatically trigger loading and transition
    if (_debugAutoFinalization) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDebugTransition();
      });
    }
  }

  void _startDebugTransition() async {
    if (_debugLoadingStarted) return;

    // Start showing the loader in loading state (not transition yet)
    setState(() {
      _debugLoadingStarted = true;
    });

    // Wait 4 seconds in loading state (brain orbiting, messages cycling)
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    // Create minimal mock data for testing
    final mockSession = VideoAnalysisSession(
      id: 'debug-session-id',
      uid: 'debug-uid',
      createdAt: DateTime.now().toIso8601String(),
      videoPath: '/debug/path/video.mp4',
      videoSource: VideoSource.camera,
      throwType: ThrowTechnique.backhand,
    );

    final mockResult = FormAnalysisResult(
      id: 'debug-result-id',
      sessionId: 'debug-session-id',
      createdAt: DateTime.now().toIso8601String(),
      checkpointResults: const [],
      overallScore: 85,
      overallFeedback: 'Debug test feedback',
      prioritizedImprovements: const [],
    );

    // Trigger the transition with mock data
    setState(() {
      _showingTransition = true;
      _pendingResults = VideoFormAnalysisComplete(
        session: mockSession,
        result: mockResult,
        poseAnalysis: null,
        poseAnalysisWarning: null,
      );
    });
  }

  @override
  void dispose() {
    // Restore dark status bar (dark icons/text for light background)
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _loaderSpeedNotifier.dispose();
    _brainOpacityNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
      child: BlocProvider<VideoFormAnalysisCubit>(
        create: (context) => VideoFormAnalysisCubit(),
        child: BlocBuilder<VideoFormAnalysisCubit, VideoFormAnalysisState>(
          builder: (context, state) {
            // Determine colors based on state and transition
            final bool isCompleted =
                state is VideoFormAnalysisComplete && !_showingTransition;
            final Color foregroundColor = isCompleted
                ? SenseiColors.darkGray
                : Colors.white;

            final bool isLoadingOrAnalyzing =
                state is VideoFormAnalysisRecording ||
                state is VideoFormAnalysisValidating ||
                state is VideoFormAnalysisAnalyzing ||
                (_debugAutoFinalization &&
                    !_showingTransition &&
                    _debugLoadingStarted);

            // App bar background should match the light background when completed
            final Color appBarBackgroundColor = isCompleted
                ? const Color(0xFFEEE8F5)
                : Colors.transparent;

            return Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: GenericAppBar(
                topViewPadding: MediaQuery.of(context).viewPadding.top,
                title: isCompleted ? 'Form analysis' : '',
                hasBackButton: false,
                backgroundColor: appBarBackgroundColor,
                foregroundColor: foregroundColor,
                rightWidget: (isLoadingOrAnalyzing || _showingTransition)
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close, color: foregroundColor),
                        onPressed: () {
                          SystemChrome.setSystemUIOverlayStyle(
                            SystemUiOverlayStyle.dark,
                          );
                          HapticFeedback.lightImpact();
                          _logger.track('Close Recording Screen Button Tapped');
                          Navigator.pop(context);
                        },
                      ),
              ),
              body: Stack(
                fit: StackFit.expand,
                children: [
                  // Background layer
                  if (!isCompleted || _showingTransition)
                    // Before and during transition: dark background
                    const Positioned.fill(child: FormAnalysisBackground())
                  else
                    // After transition: light background
                    Positioned.fill(
                      child: Container(
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
                      ),
                    ),

                  // Main content - positioned to fill
                  Positioned.fill(
                    child:
                        BlocConsumer<
                          VideoFormAnalysisCubit,
                          VideoFormAnalysisState
                        >(
                          listener: (context, state) {
                            // Trigger transition when analysis completes
                            if (state is VideoFormAnalysisComplete &&
                                !_showingTransition) {
                              setState(() {
                                _showingTransition = true;
                                _pendingResults = state;
                              });

                              // Show warning snackbar if pose analysis failed
                              if (state.poseAnalysisWarning != null) {
                                _showPoseAnalysisWarning(
                                  context,
                                  state.poseAnalysisWarning!,
                                );
                              }
                            }
                          },
                          builder: (context, state) {
                            // Show transition if triggered
                            if (_showingTransition && _pendingResults != null) {
                              return AnalysisCompletionTransition(
                                speedMultiplierNotifier: _loaderSpeedNotifier,
                                brainOpacityNotifier: _brainOpacityNotifier,
                                onComplete: () {
                                  // Set dark status bar for light background
                                  SystemChrome.setSystemUIOverlayStyle(
                                    SystemUiOverlayStyle.dark,
                                  );
                                  setState(() {
                                    _showingTransition = false;
                                    // Reset debug flag so loader hides after transition
                                    if (_debugAutoFinalization) {
                                      _debugLoadingStarted = false;
                                    }
                                    // Reset brain opacity for next time
                                    _brainOpacityNotifier.value = 1.0;
                                  });
                                },
                                child: AnalysisResultsView(
                                  result: _pendingResults!.result,
                                  poseAnalysis: _pendingResults!.poseAnalysis,
                                  topViewPadding: widget.topViewPadding,
                                ),
                              );
                            }

                            return _buildContent(context, state);
                          },
                        ),
                  ),

                  // Persistent loader layer - only during loading or transition
                  if (isLoadingOrAnalyzing || _showingTransition)
                    Positioned.fill(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ValueListenableBuilder<double>(
                              valueListenable: _brainOpacityNotifier,
                              builder: (context, opacity, child) {
                                return Opacity(opacity: opacity, child: child);
                              },
                              child: AtomicNucleusLoader(
                                key: const ValueKey(
                                  'persistent-analysis-loader',
                                ),
                                speedMultiplierNotifier: _loaderSpeedNotifier,
                              ),
                            ),
                            const SizedBox(height: 32),
                            CyclingAnalysisText(
                              brainOpacityNotifier: _brainOpacityNotifier,
                              shouldShow: !_showingTransition,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VideoFormAnalysisState state) {
    // During debug loading, hide the upload screen
    if (_debugAutoFinalization && _debugLoadingStarted && !_showingTransition) {
      return const SizedBox.shrink();
    }

    if (state is VideoFormAnalysisInitial) {
      return VideoInputBody(topViewpadding: widget.topViewPadding);
    } else if (state is VideoFormAnalysisRecording ||
        state is VideoFormAnalysisValidating ||
        state is VideoFormAnalysisAnalyzing) {
      // Just show empty space - the loader is rendered separately
      return const SizedBox.shrink();
    } else if (state is VideoFormAnalysisComplete) {
      return AnalysisResultsView(
        result: state.result,
        poseAnalysis: state.poseAnalysis,
        topViewPadding: widget.topViewPadding,
      );
    } else if (state is VideoFormAnalysisError) {
      return _buildErrorView(context, state.message, state.session);
    }
    return const SizedBox.shrink();
  }

  void _showPoseAnalysisWarning(BuildContext context, String message) {
    locator.get<ToastService>().show(
      message: message,
      type: ToastType.warning,
      duration: const Duration(seconds: 5),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    String message,
    dynamic session,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'Analysis Failed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _logger.track('Try Again Button Tapped');
                BlocProvider.of<VideoFormAnalysisCubit>(context).reset();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
