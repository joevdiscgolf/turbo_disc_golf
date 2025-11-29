import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Info card with subtle gradient tint and shared icon bubble.
class RoundDataInputCard extends StatelessWidget {
  final IconData icon;
  final String subtitle;
  final VoidCallback? onTap;
  final Color accent;

  const RoundDataInputCard({
    super.key,
    required this.icon,
    required this.subtitle,
    this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClickable = onTap != null;
    final Color baseColor = Colors.grey.shade50;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: flattenedOverWhite(accent, 0.3)),
          gradient: LinearGradient(
            transform: GradientRotation(math.pi / 4),
            colors: [
              flattenedOverWhite(accent, 0.2),
              Colors.white, // Fade to white at bottom right
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Circular icon container with radial gradient
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.white, accent.withValues(alpha: 0.0)],
                  stops: const [0.6, 1.0],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08), // Colored shadow
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isClickable ? Colors.grey[500] : Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}
