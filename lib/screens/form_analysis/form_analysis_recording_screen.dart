import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/loaders/gpt_atomic_nuclear_loader_v3.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/analysis_completion_transition.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/analysis_results_view.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/form_analysis_background.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/video_input_body.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_cubit.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Screen for recording/importing videos and analyzing form.
/// Keeps the exact same UI/UX as the original FormAnalysisScreen.
class FormAnalysisRecordingScreen extends StatefulWidget {
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

  // Persistent speed notifier for the loader
  final ValueNotifier<double> _loaderSpeedNotifier = ValueNotifier<double>(1.0);

  @override
  void dispose() {
    _loaderSpeedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VideoFormAnalysisCubit>(
      create: (context) => VideoFormAnalysisCubit(),
      child: BlocBuilder<VideoFormAnalysisCubit, VideoFormAnalysisState>(
        builder: (context, state) {
          // Determine colors based on state and transition
          final bool isCompleted =
              state is VideoFormAnalysisComplete && !_showingTransition;
          final Color foregroundColor =
              isCompleted ? TurbColors.darkGray : Colors.white;

          final bool isLoadingOrAnalyzing = state is VideoFormAnalysisRecording ||
              state is VideoFormAnalysisValidating ||
              state is VideoFormAnalysisAnalyzing;

          return Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: GenericAppBar(
              topViewPadding: MediaQuery.of(context).viewPadding.top,
              title: '',
              hasBackButton: false,
              backgroundColor: Colors.transparent,
              foregroundColor: foregroundColor,
              rightWidget: IconButton(
                icon: Icon(Icons.close, color: foregroundColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Background layer
                if (_showingTransition)
                  // During transition, the transition widget handles background
                  const SizedBox.shrink()
                else if (!isCompleted)
                  // Before transition: dark background
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
                  child: BlocConsumer<VideoFormAnalysisCubit, VideoFormAnalysisState>(
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
                          onComplete: () {
                            setState(() {
                              _showingTransition = false;
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
                      child: GPTAtomicNucleusLoaderV3(
                        key: const ValueKey('persistent-analysis-loader'),
                        speedMultiplierNotifier: _loaderSpeedNotifier,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, VideoFormAnalysisState state) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.orange,
      ),
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
