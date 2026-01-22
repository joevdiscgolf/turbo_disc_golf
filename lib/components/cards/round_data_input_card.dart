import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Info card with clean shadow-based depth styling.
class RoundDataInputCard extends StatelessWidget {
  final IconData icon;
  final String subtitle;
  final VoidCallback? onTap;
  final Color accent;
  final bool showRequiredIndicator;

  const RoundDataInputCard({
    super.key,
    required this.icon,
    required this.subtitle,
    this.onTap,
    required this.accent,
    this.showRequiredIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClickable = onTap != null;

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Circular icon container
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: SenseiColors.gray[300]!),
              ),
              child: Icon(icon, size: 16, color: SenseiColors.gray[600]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: SenseiColors.darkGray,
                      ),
                    ),
                    if (showRequiredIndicator)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                  ],
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
