import 'package:flutter/material.dart';

/// Displays a severity badge for form analysis deviations.
///
/// Maps severity levels to colors and labels:
/// - good: green
/// - minor: yellow
/// - moderate: orange
/// - significant: red
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({
    super.key,
    required this.severity,
    this.showLabel = true,
  });

  final String severity;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, Color textColor, String label) = _getSeverityStyle();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, Color, String) _getSeverityStyle() {
    switch (severity.toLowerCase()) {
      case 'good':
        return (
          const Color(0xFF4CAF50).withValues(alpha: 0.15),
          const Color(0xFF2E7D32),
          'Good',
        );
      case 'minor':
        return (
          const Color(0xFFFFC107).withValues(alpha: 0.2),
          const Color(0xFFF57C00),
          'Minor',
        );
      case 'moderate':
        return (
          const Color(0xFFFF9800).withValues(alpha: 0.2),
          const Color(0xFFE65100),
          'Moderate',
        );
      case 'significant':
        return (
          const Color(0xFFF44336).withValues(alpha: 0.15),
          const Color(0xFFC62828),
          'Significant',
        );
      default:
        return (
          Colors.grey.withValues(alpha: 0.2),
          Colors.grey[700]!,
          severity,
        );
    }
  }
}
