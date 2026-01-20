import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Utility class for determining hole score colors based on relative score (score - par).
///
/// Provides consistent color schemes across the app for displaying hole scores:
/// - Birdie (< 0): Green
/// - Par (0): Grey
/// - Bogey (1): Light Red
/// - Double Bogey+ (> 1): Dark Red
class HoleScoreColors {
  HoleScoreColors._();

  // Static color constants - SINGLE SOURCE OF TRUTH
  static const Color birdieColor = Color(0xFF137e66);
  static const Color birdieColorBright = Color.fromARGB(255, 15, 255, 79);
  static Color parColor = SenseiColors.gray[300]!;
  static const Color bogeyColor = Color(0xFFFF7A7A);
  // static const Color bogeyBright = Color(0xFFFF7A7A);
  static const Color doubleBogeyPlusColor = Color(0xFFD32F2F);

  /// Returns gradient colors for the hole background based on relative score.
  static List<Color> getGradientColors(int relativeScore) {
    if (relativeScore < 0) {
      // Birdie - green gradient
      return [
        flattenedOverWhite(birdieColor, 0.25),
        flattenedOverWhite(birdieColor, 0.05),
      ];
    } else if (relativeScore == 0) {
      // Par - grey gradient
      // return [ par.withValues(alpha: 0.15), par.withValues(alpha: 0.05)];
      return [
        flattenedOverWhite(parColor, 0.15),
        flattenedOverWhite(parColor, 0.05),
      ];
    } else if (relativeScore == 1) {
      // Bogey - light red gradient
      return [
        flattenedOverWhite(bogeyColor, 0.25),
        flattenedOverWhite(bogeyColor, 0.05),
      ];
      // return [bogey.withValues(alpha: 0.25), bogey.withValues(alpha: 0.15)];
    } else {
      // Double bogey+ - dark red gradient
      return [
        doubleBogeyPlusColor.withValues(alpha: 0.25),
        doubleBogeyPlusColor.withValues(alpha: 0.15),
      ];
    }
  }

  /// Returns the solid color for the score circle based on relative score.
  static Color getScoreColor(int relativeScore) {
    if (relativeScore < 0) {
      return birdieColor;
    } else if (relativeScore == 0) {
      return parColor;
    } else if (relativeScore == 1) {
      return bogeyColor;
    } else {
      return doubleBogeyPlusColor;
    }
  }
}
