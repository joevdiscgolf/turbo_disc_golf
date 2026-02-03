import 'package:flutter/material.dart';

/// A compact PopupMenuItem with reduced vertical padding and optional icon.
///
/// This widget provides a consistent, compact appearance for popup menu items
/// across the app, with reduced vertical padding compared to the default.
class CompactPopupMenuItem<T> extends PopupMenuItem<T> {
  CompactPopupMenuItem({
    super.key,
    required T super.value,
    required String label,
    IconData? icon,
    Color? color,
    Color? iconColor,
    double iconSize = 20,
    bool showCheckmark = false,
    super.onTap,
  }) : super(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCheckmark)
                Icon(Icons.check, size: 18, color: iconColor ?? color)
              else if (icon != null)
                Icon(icon, size: iconSize, color: iconColor ?? color)
              else
                const SizedBox.shrink(),
              if (icon != null || showCheckmark) const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: showCheckmark ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
}
