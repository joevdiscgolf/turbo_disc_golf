import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

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
        _buildSectionHeader(context, 'General tips'),
        const SizedBox(height: 12),
        _buildGeneralTipsCard(context),
        const SizedBox(height: 20),
        _buildSectionHeader(context, 'Camera angles'),
        const SizedBox(height: 12),
        _buildCameraPositionCard(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildGeneralTipsCard(BuildContext context) {
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
          // High priority tips with emphasis
          _buildHighPriorityBulletPoint(context, 'Select throwing hand'),
          _buildHighPriorityBulletPoint(
            context,
            'Full body in frame at all times!',
          ),
          _buildHighPriorityBulletPoint(
            context,
            'Start recording before your x-step',
          ),
          _buildHighPriorityBulletPoint(context, 'End ~1s after disc release'),
          const SizedBox(height: 8),
          // Regular tips
          _buildBulletPoint(
            context,
            'Keep videos under ${locator.get<FeatureFlagService>().maxFormAnalysisVideoSeconds} seconds',
          ),
          _buildBulletPoint(context, 'High contrast thrower vs background'),
          _buildBulletPoint(context, 'Closer is better'),
          _buildBulletPoint(
            context,
            'Landscape preferred (portrait works too)',
          ),
        ],
      ),
    );
  }

  Widget _buildHighPriorityBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF137e66),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF137e66),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPositionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCameraAngleSection(
            context,
            'Side View',
            'Position slightly behind, not directly to the side',
          ),
          const SizedBox(height: 12),
          _buildCameraAngleSection(
            context,
            'Rear View',
            'Position directly behind the thrower',
          ),
        ],
      ),
    );
  }

  Widget _buildCameraAngleSection(
    BuildContext context,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 18,
              height: 1.35,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 18,
              height: 1.35,
              color: const Color(0xFF137e66),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
