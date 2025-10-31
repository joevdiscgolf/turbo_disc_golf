import 'package:flutter/material.dart';

/// Brightens a color by increasing its lightness in HSL color space.
///
/// [color] The base color to brighten.
/// [amount] How much to increase lightness (0.0 to 1.0). Defaults to 0.2 (20% brighter).
///
/// Returns a new Color that is brighter than the original.
///
/// Example:
/// ```dart
/// Color baseColor = Colors.blue;
/// Color brighterColor = brighten(baseColor, 0.2); // 20% brighter
/// ```
Color brighten(Color color, [double amount = 0.2]) {
  // Convert to HSL
  final HSLColor hsl = HSLColor.fromColor(color);
  // Increase lightness by `amount` (max 1.0)
  final HSLColor lighterHsl =
      hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  // Convert back to Color
  return lighterHsl.toColor();
}
