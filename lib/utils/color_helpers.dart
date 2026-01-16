import 'package:flutter/material.dart';

/// Shared text style for story card section headers
/// Used by headline card and section headers for consistency
const TextStyle kStorySectionHeaderStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
);

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

  static const Color darkGray = Color(0xff111111);

  static const Color blue = Colors.blue;
  static const Color darkBlue = Color(0xff0E7DD6);
  static const Color white = Colors.white;
  static const Color senseiBlue = Color(0xff1F4DB8);
}

/// Returns a semantic color based on percentage value.
///
/// For "higher is better" stats (putting %, fairway hits, etc.):
/// - 70-100% → Green (excellent)
/// - 40-70% → Blue (good/moderate)
/// - 20-40% → Orange (below average)
/// - 0-20% → Red (poor)
///
/// For "lower is better" stats (bogey rate, etc.), pass `100 - percentage`
/// to invert the scale.
///
/// Uses smooth linear interpolation between color stops.
/// All colors are chosen for good contrast and visual appeal against white backgrounds.
Color getSemanticColor(double percentage) {
  final double p = percentage.clamp(0.0, 100.0) / 100.0;

  // Beautiful color gradient: Red → Orange → Blue → Green
  const Color red = Color(0xFFEF4444); // Bright red (Tailwind red-500)
  const Color orange = Color(0xFFF59E0B); // Vibrant orange (Tailwind amber-500)
  const Color blue = Color(0xFF3B82F6); // Bright blue (Tailwind blue-500)
  const Color green = Color(0xFF10B981); // Vibrant green (Tailwind emerald-500)

  if (p >= 0.7) {
    // Blue to Green (70-100%)
    return Color.lerp(blue, green, (p - 0.7) / 0.3)!;
  } else if (p >= 0.4) {
    // Orange to Blue (40-70%)
    return Color.lerp(orange, blue, (p - 0.4) / 0.3)!;
  } else if (p >= 0.2) {
    // Red to Orange (20-40%)
    return Color.lerp(red, orange, (p - 0.2) / 0.2)!;
  } else {
    // Pure red (0-20%)
    return red;
  }
}

Color flattenedOverWhite(Color color, double opacity) {
  assert(opacity >= 0.0 && opacity <= 1.0);

  int blendChannel(double channel) =>
      (channel * 255 * opacity + 255 * (1 - opacity)).round();

  return Color.fromARGB(
    255,
    blendChannel(color.r),
    blendChannel(color.g),
    blendChannel(color.b),
  );
}
