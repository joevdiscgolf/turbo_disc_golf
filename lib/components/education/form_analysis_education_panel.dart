import 'package:flutter/material.dart';

/// Educational content widget for the video form analysis feature.
/// Displays instructions on how to capture or import a good video for analysis.
class FormAnalysisEducationPanel extends StatelessWidget {
  const FormAnalysisEducationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildInstructionsCard(context),
      ],
    );
  }

  Widget _buildInstructionsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF137e66).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF137e66).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBulletPoint(
            context,
            'Film from the side for best results',
            Icons.videocam_outlined,
          ),
          const SizedBox(height: 16),
          _buildBulletPoint(
            context,
            'Ensure good lighting so your form is visible',
            Icons.wb_sunny_outlined,
          ),
          const SizedBox(height: 16),
          _buildBulletPoint(
            context,
            'Capture your full throwing motion',
            Icons.sports_outlined,
          ),
          const SizedBox(height: 16),
          _buildBulletPoint(
            context,
            'Keep the camera steady',
            Icons.stay_current_portrait_outlined,
          ),
          const SizedBox(height: 16),
          _buildBulletPoint(
            context,
            'Videos should be 5-30 seconds long',
            Icons.timer_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(
    BuildContext context,
    String text,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF137e66).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF137e66),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
