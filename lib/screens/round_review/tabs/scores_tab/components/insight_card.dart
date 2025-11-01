import 'package:flutter/material.dart';

/// A card that displays an actionable insight with icon and description
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.type = InsightType.neutral,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final InsightType type;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? _getBackgroundColor();
    final effectiveIconColor = iconColor ?? _getIconColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: effectiveIconColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: effectiveIconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case InsightType.strength:
        return const Color(0xFF137e66).withValues(alpha: 0.05);
      case InsightType.weakness:
        return const Color(0xFFFF7A7A).withValues(alpha: 0.05);
      case InsightType.opportunity:
        return const Color(0xFF2196F3).withValues(alpha: 0.05);
      case InsightType.neutral:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getIconColor() {
    switch (type) {
      case InsightType.strength:
        return const Color(0xFF137e66);
      case InsightType.weakness:
        return const Color(0xFFFF7A7A);
      case InsightType.opportunity:
        return const Color(0xFF2196F3);
      case InsightType.neutral:
        return const Color(0xFF757575);
    }
  }
}

enum InsightType {
  strength,
  weakness,
  opportunity,
  neutral,
}
