import 'package:flutter/material.dart';

/// Section header widget for story tab with visual divider
class StorySectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? accentColor;

  const StorySectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = accentColor ?? const Color(0xFF137e66);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient divider line
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  color,
                  color.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Section title with optional icon
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
