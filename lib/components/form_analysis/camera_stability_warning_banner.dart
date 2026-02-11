import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// A warning banner shown when camera stability is low.
///
/// Displays above the video toggle in [TimelineAnalysisView] to inform users
/// that camera movement may have affected pose detection accuracy.
/// Tapping opens an educational panel with tips for better recordings.
class CameraStabilityWarningBanner extends StatelessWidget {
  const CameraStabilityWarningBanner({super.key});

  /// The stability threshold below which the warning should be shown.
  /// Value from 0-1 where 1 is most stable.
  static const double stabilityThreshold = 0.95;

  // Yellow color for warning icon
  static const Color _warningIconColor = Color(0xFFF59E0B); // amber-500

  // Accent color for the education panel
  static const Color _accentColor = Color(0xFFF59E0B); // amber-500

  void _showEducationPanel(BuildContext context) {
    HapticFeedback.lightImpact();
    EducationPanel.show(
      context,
      title: 'Recording tips',
      modalName: 'Camera Stability Tips',
      accentColor: _accentColor,
      buttonLabel: 'Got it',
      contentBuilder: (_) => const _CameraStabilityEducationContent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEducationPanel(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SenseiColors.gray[100]!, width: 1),
          boxShadow: defaultCardBoxShadow(),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_rounded,
              size: 20,
              color: _warningIconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Camera movement detected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SenseiColors.darkGray,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: SenseiColors.gray[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: SenseiColors.gray[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: SenseiColors.darkGray.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              'Results may be inaccurate, avoid panning and zooming. ',
                        ),
                        TextSpan(
                          text: 'Learn more',
                          style: TextStyle(
                            color: SenseiColors.darkGray.withValues(
                              alpha: 0.75,
                            ),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Educational content explaining camera stability best practices.
class _CameraStabilityEducationContent extends StatelessWidget {
  const _CameraStabilityEducationContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildTipItem(
          icon: Icons.back_hand_outlined,
          title: 'Keep a steady hand',
          description:
              'If you don\'t have a tripod, no problem. Keep the camera as stefiady as possible.',
        ),
        const SizedBox(height: 16),
        _buildTipItem(
          icon: Icons.videocam_rounded,
          title: 'Use a tripod',
          description:
              'A tripod or phone mount provides the most stable recording and best results.',
        ),
        const SizedBox(height: 16),
        _buildTipItem(
          icon: Icons.zoom_out_map,
          title: 'Avoid panning and zooming',
          description:
              'Keep the camera in a fixed position. Moving or zooming while recording makes it harder to track your form accurately.',
        ),
        const SizedBox(height: 16),
        _buildTipItem(
          icon: Icons.fullscreen,
          title: 'Frame yourself fully',
          description:
              'Position the camera so your entire body is visible throughout the throw.',
        ),
      ],
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: SenseiColors.gray[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: SenseiColors.darkGray),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: SenseiColors.darkGray,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: SenseiColors.darkGray.withValues(alpha: 0.75),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
