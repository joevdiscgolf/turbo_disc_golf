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
  final HSLColor lighterHsl = hsl.withLightness(
    (hsl.lightness + amount).clamp(0.0, 1.0),
  );
  // Convert back to Color
  return lighterHsl.toColor();
}

class CustomColor extends ColorSwatch<int> {
  final Map<int, Color> swatch;

  const CustomColor(int primary, this.swatch) : super(primary, swatch);

  /// The lightest shade.
  Color? get shade50 => this[50];

  /// The second lightest shade.
  Color get shade100 => this[100]!;

  /// The third lightest shade.
  Color get shade200 => this[200]!;

  /// The fourth lightest shade.
  Color get shade300 => this[300]!;

  Color get shade350 => this[350]!;

  /// The fifth lightest shade.
  Color get shade400 => this[400]!;

  /// The default shade.
  Color get shade500 => this[500]!;

  /// The fourth darkest shade.
  Color get shade600 => this[600]!;

  /// The third darkest shade.
  Color get shade700 => this[700]!;

  /// The second darkest shade.
  Color get shade800 => this[800]!;

  /// The darkest shade.
  Color get shade900 => this[900]!;
}

abstract class TurbColors {
  static const CustomColor gray = CustomColor(0xff535353, {
    50: Color(0xffF7F7F7),
    100: Color(0xffEBEBEB),
    200: Color(0xffDDDDDD),
    300: Color(0xffB0B0B0),
    350: Color(0xff949494),
    400: Color(0xff717171),
    500: Color(0xff535353),
    600: Color(0xff3F3F3F),
    700: Color(0xff212121),
    800: Color(0xff111111),
    900: Color(0xff000000),
  });
}
