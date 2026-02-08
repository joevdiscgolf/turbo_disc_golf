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
        _buildSectionHeader(context, 'Requirements'),
        const SizedBox(height: 12),
        _buildRequirementsCard(context),
        const SizedBox(height: 20),
        _buildSectionHeader(context, 'Helpful tips'),
        const SizedBox(height: 12),
        _buildHelpfulTipsCard(context),
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

  Widget _buildRequirementsCard(BuildContext context) {
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
            'Full body in frame at all times',
            color: const Color(0xFF137e66),
          ),
          _buildBulletPoint(
            context,
            'Start before x-step',
            color: const Color(0xFF137e66),
          ),
          _buildBulletPoint(
            context,
            'End after disc release',
            color: const Color(0xFF137e66),
          ),
          _buildBulletPoint(
            context,
            '${locator.get<FeatureFlagService>().maxFormAnalysisVideoSeconds} seconds max',
            color: const Color(0xFF137e66),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpfulTipsCard(BuildContext context) {
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
            'High contrast thrower vs background',
            color: const Color(0xFF137e66),
          ),
          _buildBulletPoint(
            context,
            'Landscape preferred (portrait works too)',
            color: const Color(0xFF137e66),
          ),
          _buildBulletPoint(
            context,
            'Throwing hand is auto-detected, but you can manually select it',
            color: const Color(0xFF137e66),
          ),
          _buildBulletPoint(
            context,
            '60 fps or higher',
            color: const Color(0xFF137e66),
            isLast: true,
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

  Widget _buildBulletPoint(
    BuildContext context,
    String text, {
    required Color color,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(fontSize: 18, height: 1.35, color: color)),
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
