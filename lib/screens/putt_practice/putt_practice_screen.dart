import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/miss_direction.dart';
import 'package:turbo_disc_golf/screens/putt_practice/components/basket_calibration_view.dart';
import 'package:turbo_disc_golf/screens/putt_practice/components/camera_preview_overlay.dart';
import 'package:turbo_disc_golf/screens/putt_practice/components/putt_heat_map.dart';
import 'package:turbo_disc_golf/screens/putt_practice/components/session_stats_overlay.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/state/putt_practice_cubit.dart';
import 'package:turbo_disc_golf/state/putt_practice_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class PuttPracticeScreen extends StatefulWidget {
  static const String routeName = '/putt-practice';
  static const String screenName = 'Putt Practice';

  const PuttPracticeScreen({super.key});

  @override
  State<PuttPracticeScreen> createState() => _PuttPracticeScreenState();
}

class _PuttPracticeScreenState extends State<PuttPracticeScreen> {
  late final LoggingServiceBase _logger;
  late final PuttPracticeCubit _cubit;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': PuttPracticeScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('PuttPracticeScreen');

    // Initialize cubit and camera
    _cubit = PuttPracticeCubit();
    _cubit.initializeCamera();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
      child: BlocProvider<PuttPracticeCubit>.value(
        value: _cubit,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: BlocBuilder<PuttPracticeCubit, PuttPracticeState>(
            builder: (context, state) {
              return Stack(
                children: [
                  // Camera preview or content
                  _buildContent(state),

                  // Top bar overlay
                  _buildTopBar(state),

                  // Bottom controls overlay
                  _buildBottomControls(state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PuttPracticeState state) {
    return switch (state) {
      PuttPracticeInitial() => _buildInitialState(),
      PuttPracticeCameraInitializing() => _buildLoadingState(state.message),
      PuttPracticeCameraReady() => _buildCameraPreview(state.cameraController),
      PuttPracticeCalibrating() => BasketCalibrationView(
          cameraController: state.cameraController,
          detectedBasket: state.detectedBasket,
          message: state.message,
          stableFrameCount: state.stableFrameCount,
          onManualCalibration: (left, top, right, bottom) {
            _logger.track('Manual Basket Calibration Confirmed');
            _cubit.confirmManualCalibration(left, top, right, bottom);
          },
        ),
      PuttPracticeActive() => CameraPreviewOverlay(
          cameraController: state.cameraController,
          session: state.session,
          lastAttempt: state.lastDetectedAttempt,
          motionBoxes: state.motionBoxes,
        ),
      PuttPracticePaused() => _buildPausedState(state),
      PuttPracticeCompleted() => _buildCompletedState(state),
      PuttPracticeError() => _buildErrorState(state),
    };
  }

  Widget _buildTopBar(PuttPracticeState state) {
    final bool showCloseButton = state is! PuttPracticeCompleted;
    final String title = _getTitleForState(state);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showCloseButton)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      _logger.track('Close Button Tapped');
                      Navigator.of(context).pop();
                    },
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(PuttPracticeState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildControlsForState(state),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsForState(PuttPracticeState state) {
    return switch (state) {
      PuttPracticeActive() => _buildActiveControls(state),
      PuttPracticePaused() => _buildPausedControls(state),
      PuttPracticeCompleted() => _buildCompletedControls(state),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildActiveControls(PuttPracticeActive state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Session stats overlay
        SessionStatsOverlay(session: state.session),
        const SizedBox(height: 16),
        // Manual putt recording buttons
        Row(
          children: [
            Expanded(
              child: _buildManualButton(
                label: 'Miss',
                color: Colors.red,
                onPressed: () {
                  _logger.track('Manual Miss Button Tapped');
                  HapticFeedback.mediumImpact();
                  _cubit.recordManualPutt(made: false);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildManualButton(
                label: 'Make',
                color: Colors.green,
                onPressed: () {
                  _logger.track('Manual Make Button Tapped');
                  HapticFeedback.mediumImpact();
                  _cubit.recordManualPutt(made: true);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _logger.track('Pause Session Button Tapped');
                  _cubit.pauseSession();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Pause'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _logger.track('End Session Button Tapped');
                  _cubit.endSession();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('End session'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPausedControls(PuttPracticePaused state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SessionStatsOverlay(session: state.session),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _logger.track('End Session Button Tapped');
                  _cubit.endSession();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('End session'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                label: 'Resume',
                width: double.infinity,
                onPressed: () {
                  _logger.track('Resume Session Button Tapped');
                  _cubit.resumeSession();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedControls(PuttPracticeCompleted state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _logger.track('New Session Button Tapped');
                  _cubit.startNewSession();
                  _cubit.initializeCamera();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('New session'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                label: state.isSaving ? 'Saving...' : 'Save session',
                width: double.infinity,
                loading: state.isSaving,
                onPressed: () {
                  if (!state.isSaving) {
                    _logger.track('Save Session Button Tapped');
                    _cubit.saveSession();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            _logger.track('Done Button Tapped');
            Navigator.of(context).pop();
          },
          child: const Text(
            'Done',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialState() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(CameraController controller) {
    if (!controller.value.isInitialized) {
      return _buildLoadingState('Initializing camera...');
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildPausedState(PuttPracticePaused state) {
    return Stack(
      children: [
        // Dimmed camera preview
        Opacity(
          opacity: 0.5,
          child: _buildCameraPreview(state.cameraController),
        ),
        // Paused indicator
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pause_circle_outline,
                color: Colors.white,
                size: 80,
              ),
              SizedBox(height: 16),
              Text(
                'Session paused',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedState(PuttPracticeCompleted state) {
    return Container(
      color: SenseiColors.gray[900],
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60), // Space for top bar
              // Summary header
              Text(
                'Session complete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDuration(state.session.duration),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              // Stats summary
              _buildStatsSummary(state),
              const SizedBox(height: 24),
              // Heat map
              if (state.session.attempts.isNotEmpty) ...[
                Text(
                  'Miss pattern',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                PuttHeatMap(attempts: state.session.attempts),
              ],
              const SizedBox(height: 100), // Space for bottom controls
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(PuttPracticeCompleted state) {
    final session = state.session;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStatRow('Total putts', '${session.totalAttempts}'),
          const SizedBox(height: 12),
          _buildStatRow('Makes', '${session.makes}', color: Colors.green),
          const SizedBox(height: 12),
          _buildStatRow('Misses', '${session.misses}', color: Colors.red),
          const SizedBox(height: 12),
          _buildStatRow(
            'Make percentage',
            '${session.makePercentage.toStringAsFixed(1)}%',
            color: _getPercentageColor(session.makePercentage),
          ),
          if (session.mostCommonMissDirection != null) ...[
            const SizedBox(height: 12),
            _buildStatRow(
              'Most common miss',
              session.mostCommonMissDirection!.label,
              color: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(PuttPracticeError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[300],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Try again',
              width: 200,
              onPressed: () {
                _logger.track('Try Again Button Tapped');
                _cubit.startNewSession();
                _cubit.initializeCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getTitleForState(PuttPracticeState state) {
    return switch (state) {
      PuttPracticeCalibrating() => 'Calibrate basket',
      PuttPracticeActive() => 'Recording',
      PuttPracticePaused() => 'Paused',
      PuttPracticeCompleted() => 'Summary',
      _ => 'Putt practice',
    };
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
}
