import 'package:flutter/material.dart';

/// Section header for structured story with icon and accent color
///
/// Used to visually separate sections in the story tab:
/// - What You Did Well (green)
/// - What Cost You Strokes (red)
/// - Biggest Opportunity (orange)
/// - Practice & Strategy (blue)
class StorySectionHeader extends StatelessWidget {
  const StorySectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: accentColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor,
                accentColor.withValues(alpha: 0.1),
              ],
              stops: const [0.3, 1.0],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
