import 'package:flutter/material.dart';

/// Types of key moments in a round
enum MomentType {
  hotStreak,
  bounceBack,
  mistake,
  achievement,
  turningPoint,
}

/// Callout card highlighting important moments in the round story
class KeyMomentHighlight extends StatelessWidget {
  final String title;
  final String description;
  final MomentType type;
  final Widget? statWidget; // Optional stat visualization

  const KeyMomentHighlight({
    super.key,
    required this.title,
    required this.description,
    required this.type,
    this.statWidget,
  });

  Color _getPrimaryColor() {
    switch (type) {
      case MomentType.hotStreak:
        return const Color(0xFFFFA726); // Orange - fire/hot
      case MomentType.bounceBack:
        return const Color(0xFF4CAF50); // Green - success
      case MomentType.mistake:
        return const Color(0xFFFF7A7A); // Red - error
      case MomentType.achievement:
        return const Color(0xFF9C27B0); // Purple - special
      case MomentType.turningPoint:
        return const Color(0xFF2196F3); // Blue - important
    }
  }

  Color _getSecondaryColor() {
    switch (type) {
      case MomentType.hotStreak:
        return const Color(0xFFFFE0B2);
      case MomentType.bounceBack:
        return const Color(0xFFC8E6C9);
      case MomentType.mistake:
        return const Color(0xFFFFCDD2);
      case MomentType.achievement:
        return const Color(0xFFE1BEE7);
      case MomentType.turningPoint:
        return const Color(0xFFBBDEFB);
    }
  }

  IconData _getIcon() {
    switch (type) {
      case MomentType.hotStreak:
        return Icons.local_fire_department;
      case MomentType.bounceBack:
        return Icons.trending_up;
      case MomentType.mistake:
        return Icons.warning_amber_rounded;
      case MomentType.achievement:
        return Icons.emoji_events;
      case MomentType.turningPoint:
        return Icons.loop;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _getPrimaryColor();
    final Color secondaryColor = _getSecondaryColor();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.15),
            secondaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            // Optional stat widget
            if (statWidget != null) ...[
              const SizedBox(height: 12),
              statWidget!,
            ],
          ],
        ),
      ),
    );
  }
}
