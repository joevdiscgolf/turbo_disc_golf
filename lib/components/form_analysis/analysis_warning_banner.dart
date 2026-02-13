import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/analysis_warning.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// A list of analysis warning banners stacked vertically.
///
/// Displays warnings above the video content in the video tab.
/// Each warning can be tapped to show more details.
class AnalysisWarningsList extends StatelessWidget {
  const AnalysisWarningsList({
    super.key,
    required this.warnings,
    this.padding = const EdgeInsets.fromLTRB(8, 0, 8, 8),
  });

  final List<AnalysisWarning> warnings;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Column(
        children: addRunSpacing(
          warnings
              .map(
                (warning) => AnalysisWarningBanner(
                  warning: warning,
                  padding: EdgeInsets.zero,
                ),
              )
              .toList(),
          runSpacing: 8,
          axis: Axis.vertical,
        ),
      ),
    );
  }
}

/// A warning banner for displaying analysis warnings.
///
/// Follows the same design as [CameraStabilityWarningBanner] but is generic
/// and works with any [AnalysisWarning] from the backend.
/// Tapping opens an educational panel with more details and recommendations.
class AnalysisWarningBanner extends StatelessWidget {
  const AnalysisWarningBanner({
    super.key,
    required this.warning,
    this.padding = const EdgeInsets.fromLTRB(8, 0, 8, 8),
  });

  final AnalysisWarning warning;
  final EdgeInsets padding;

  Color get _iconColor {
    switch (warning.severity) {
      case WarningSeverity.info:
        return const Color(0xFF3B82F6); // blue-500
      case WarningSeverity.warning:
        return const Color(0xFFF59E0B); // amber-500
      case WarningSeverity.critical:
        return const Color(0xFFEF4444); // red-500
    }
  }

  IconData get _icon {
    switch (warning.severity) {
      case WarningSeverity.info:
        return Icons.info_rounded;
      case WarningSeverity.warning:
        return Icons.warning_rounded;
      case WarningSeverity.critical:
        return Icons.error_rounded;
    }
  }

  void _showEducationPanel(BuildContext context) {
    HapticFeedback.lightImpact();
    EducationPanel.show(
      context,
      title: warning.title,
      modalName: 'Analysis Warning: ${warning.warningId}',
      accentColor: _iconColor,
      buttonLabel: 'Got it',
      contentBuilder: (_) => _WarningEducationContent(warning: warning),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMoreInfo = warning.recommendation != null;

    return Padding(
      padding: padding,
      child: GestureDetector(
        onTap: hasMoreInfo ? () => _showEducationPanel(context) : null,
        child: Container(
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
              Icon(_icon, size: 20, color: _iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            warning.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: SenseiColors.darkGray,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (hasMoreInfo) ...[
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
                          TextSpan(text: warning.message),
                          if (hasMoreInfo) ...[
                            const TextSpan(text: ' '),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Educational content for a warning, showing recommendation and details.
class _WarningEducationContent extends StatelessWidget {
  const _WarningEducationContent({required this.warning});

  final AnalysisWarning warning;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          warning.message,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: SenseiColors.darkGray.withValues(alpha: 0.85),
            height: 1.5,
          ),
        ),
        if (warning.recommendation != null) ...[
          const SizedBox(height: 16),
          _buildRecommendationSection(),
        ],
      ],
    );
  }

  Widget _buildRecommendationSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: SenseiColors.gray[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.lightbulb_outline_rounded,
            size: 22,
            color: SenseiColors.darkGray,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recommendation',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: SenseiColors.darkGray,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                warning.recommendation!,
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
