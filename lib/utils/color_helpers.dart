import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/throw_technique_constants.dart';

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

abstract class SenseiColors {
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

  static const Color blueSecondary = Color.fromARGB(255, 12, 190, 255);
  static const Color blue = Colors.blue;
  static const Color darkBlue = Color(0xff0E7DD6);
  static const Color white = Colors.white;
  static const Color senseiBlue = Color(0xff1F4DB8);
  static const Color forestGreen = Color(0xff137e66);
}

/// Returns a semantic color based on percentage value.
///
/// For "higher is better" stats (putting %, fairway hits, etc.):
/// - 75-100% → Green (excellent)
/// - 50-75% → Teal/Cyan (good)
/// - 25-50% → Gold (below average)
/// - 0-25% → Red (poor)
///
/// For "lower is better" stats (bogey rate, etc.), pass `100 - percentage`
/// to invert the scale.
///
/// Uses smooth linear interpolation between color stops.
/// All colors are chosen for good contrast and visual appeal, avoiding muddy browns.
Color getSemanticColor(double percentage) {
  final double p = percentage.clamp(0.0, 100.0) / 100.0;

  // Clean color gradient: Red → Gold → Teal → Green
  const Color red = Color(0xFFEF4444); // Bright red (Tailwind red-500)
  const Color gold = Color(0xFFFBBF24); // Vibrant gold (Tailwind yellow-400)
  const Color teal = Color(0xFF14B8A6); // Bright teal (Tailwind teal-500)
  const Color green = Color(0xFF10B981); // Vibrant green (Tailwind emerald-500)

  if (p >= 0.75) {
    // Teal to Green (75-100%)
    return Color.lerp(teal, green, (p - 0.75) / 0.25)!;
  } else if (p >= 0.5) {
    // Gold to Teal (50-75%)
    return Color.lerp(gold, teal, (p - 0.5) / 0.25)!;
  } else if (p >= 0.25) {
    // Red to Gold (25-50%)
    return Color.lerp(red, gold, (p - 0.25) / 0.25)!;
  } else {
    // Pure red (0-25%)
    return red;
  }
}

/// Returns a smoothly interpolated color based on metric performance.
///
/// Uses the metric's thresholds as anchor points:
/// - Below good: interpolates red → amber
/// - Between good and excellent: interpolates amber → green
/// - At or above excellent: solid green
///
/// For inverse metrics (lower is better), the logic is reversed:
/// - At or below excellent: solid green
/// - Between excellent and good: interpolates green → amber
/// - Above good: interpolates amber → red
Color getMetricColor(double percentage, MetricThresholds thresholds) {
  const Color red = Color(0xFFEF4444);
  const Color amber = Color(0xFFF59E0B);
  const Color green = Color(0xFF10B981);

  // Clamp to reasonable range
  final double p = percentage.clamp(thresholds.floor, thresholds.ceiling);

  if (thresholds.inverse) {
    // Lower is better: green at low values, red at high
    if (p <= thresholds.excellent) {
      return green;
    } else if (p <= thresholds.good) {
      final double t =
          (p - thresholds.excellent) / (thresholds.good - thresholds.excellent);
      return Color.lerp(green, amber, t)!;
    } else {
      final double t =
          (p - thresholds.good) / (thresholds.ceiling - thresholds.good);
      return Color.lerp(amber, red, t.clamp(0.0, 1.0))!;
    }
  } else {
    // Higher is better: green at high values, red at low
    if (p >= thresholds.excellent) {
      return green;
    } else if (p >= thresholds.good) {
      final double t =
          (p - thresholds.good) / (thresholds.excellent - thresholds.good);
      return Color.lerp(amber, green, t)!;
    } else {
      final double t =
          (p - thresholds.floor) / (thresholds.good - thresholds.floor);
      return Color.lerp(red, amber, t.clamp(0.0, 1.0))!;
    }
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
