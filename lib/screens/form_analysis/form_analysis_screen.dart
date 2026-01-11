import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/analysis_progress_view.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/analysis_results_view.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/video_input_panel.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_cubit.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_state.dart';

/// Main screen for AI-powered video form analysis.
/// Allows users to record or import throwing videos and receive
/// personalized coaching feedback.
class FormAnalysisScreen extends StatefulWidget {
  const FormAnalysisScreen({super.key});

  static const String routeName = '/form-analysis';
  static const String screenName = 'Form Coach';

  @override
  State<FormAnalysisScreen> createState() => _FormAnalysisScreenState();
}

class _FormAnalysisScreenState extends State<FormAnalysisScreen> {
  ThrowTechnique _selectedThrowType = ThrowTechnique.backhand;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VideoFormAnalysisCubit>(
      create: (context) => VideoFormAnalysisCubit(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
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
          child: SafeArea(
            child: BlocConsumer<VideoFormAnalysisCubit, VideoFormAnalysisState>(
              listener: (context, state) {
                // Show warning snackbar if pose analysis failed
                if (state is VideoFormAnalysisComplete &&
                    state.poseAnalysisWarning != null) {
                  _showPoseAnalysisWarning(context, state.poseAnalysisWarning!);
                }
              },
              builder: (context, state) {
                return _buildContent(context, state);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VideoFormAnalysisState state) {
    if (state is VideoFormAnalysisInitial) {
      return VideoInputPanel(
        selectedThrowType: _selectedThrowType,
        onThrowTypeChanged: (ThrowTechnique type) {
          setState(() => _selectedThrowType = type);
        },
      );
    } else if (state is VideoFormAnalysisRecording) {
      return AnalysisProgressView(message: state.progressMessage);
    } else if (state is VideoFormAnalysisValidating) {
      return AnalysisProgressView(message: state.progressMessage);
    } else if (state is VideoFormAnalysisAnalyzing) {
      return AnalysisProgressView(message: state.progressMessage);
    } else if (state is VideoFormAnalysisComplete) {
      return AnalysisResultsView(
        result: state.result,
        poseAnalysis: state.poseAnalysis,
      );
    } else if (state is VideoFormAnalysisError) {
      return _buildErrorView(context, state.message, state.session);
    }
    return const SizedBox.shrink();
  }

  void _showPoseAnalysisWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analysis Failed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (session != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      BlocProvider.of<VideoFormAnalysisCubit>(context)
                          .retryAnalysis();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137e66),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                if (session != null) const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    BlocProvider.of<VideoFormAnalysisCubit>(context).reset();
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Start Over'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
