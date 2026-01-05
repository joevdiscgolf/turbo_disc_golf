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
    return Row(
      children: [
        Icon(
          icon,
          color: accentColor,
          size: 22,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: accentColor,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
