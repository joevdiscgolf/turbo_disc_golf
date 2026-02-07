import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/detected_putt_attempt.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/putt_practice_session.dart';
import 'package:turbo_disc_golf/screens/putt_practice/components/putt_result_animation.dart';

/// Camera preview with detection overlays during active session
class CameraPreviewOverlay extends StatelessWidget {
  final CameraController cameraController;
  final PuttPracticeSession session;
  final DetectedPuttAttempt? lastAttempt;

  const CameraPreviewOverlay({
    super.key,
    required this.cameraController,
    required this.session,
    this.lastAttempt,
  });

  @override
  Widget build(BuildContext context) {
    if (!cameraController.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview - fills entire screen
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: cameraController.value.previewSize?.height ?? 1,
              height: cameraController.value.previewSize?.width ?? 1,
              child: CameraPreview(cameraController),
            ),
          ),
        ),

        // Basket detection overlay
        if (session.calibration != null)
          _buildBasketOverlay(session.calibration!),

        // Putt result animation
        if (lastAttempt != null)
          PuttResultAnimation(
            key: ValueKey(lastAttempt!.id),
            attempt: lastAttempt!,
          ),

        // Recording indicator
        _buildRecordingIndicator(),
      ],
    );
  }

  Widget _buildBasketOverlay(calibration) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          // Calculate basket position based on calibration
          final double left = calibration.left * width;
          final double top = calibration.top * height;
          final double right = calibration.right * width;
          final double bottom = calibration.bottom * height;

          return Stack(
            children: [
              // Basket bounding box
              Positioned(
                left: left,
                top: top,
                width: right - left,
                height: bottom - top,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.8),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'RECORDING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
