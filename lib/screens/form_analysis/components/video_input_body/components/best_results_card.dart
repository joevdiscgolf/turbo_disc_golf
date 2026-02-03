import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/education/form_analysis_education_panel.dart';
import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

class FormAnalysisBestResultsCard extends StatelessWidget {
  const FormAnalysisBestResultsCard({
    super.key,
    required this.loggingService,
    required this.selectedCameraAngle,
  });

  final LoggingServiceBase loggingService;
  final CameraAngle selectedCameraAngle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        loggingService.track(
          'Form Analysis Tips Card Tapped',
          properties: {'version': 'v2'},
        );
        await EducationPanel.show(
          context,
          title: 'Tips for best results',
          modalName: 'Form Analysis Education',
          accentColor: const Color(0xFF137e66),
          contentBuilder: (_) => const FormAnalysisEducationPanel(),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'For best results',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF137e66),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Full body in view',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF137e66),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'MUST start before x-step',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF137e66),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${locator.get<FeatureFlagService>().maxFormAnalysisVideoSeconds}s max',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF137e66),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Avoid others in background',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ),
                    ],
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
