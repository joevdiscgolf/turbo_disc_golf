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
  static const Color birdie = Color(0xFF137e66);
  static Color par = TurbColors.gray[400]!;
  static const Color bogey = Color(0xFFFF7A7A);
  static const Color doubleBogeyPlus = Color(0xFFD32F2F);

  /// Returns gradient colors for the hole background based on relative score.
  static List<Color> getGradientColors(int relativeScore) {
    if (relativeScore < 0) {
      // Birdie - green gradient
      return [
        birdie.withValues(alpha: 0.25),
        birdie.withValues(alpha: 0.15),
      ];
    } else if (relativeScore == 0) {
      // Par - grey gradient
      return [
        par.withValues(alpha: 0.3),
        par.withValues(alpha: 0.2),
      ];
    } else if (relativeScore == 1) {
      // Bogey - light red gradient
      return [
        bogey.withValues(alpha: 0.25),
        bogey.withValues(alpha: 0.15),
      ];
    } else {
      // Double bogey+ - dark red gradient
      return [
        doubleBogeyPlus.withValues(alpha: 0.25),
        doubleBogeyPlus.withValues(alpha: 0.15),
      ];
    }
  }

  /// Returns the solid color for the score circle based on relative score.
  static Color getScoreColor(int relativeScore) {
    if (relativeScore < 0) {
      return birdie;
    } else if (relativeScore == 0) {
      return par;
    } else if (relativeScore == 1) {
      return bogey;
    } else {
      return doubleBogeyPlus;
    }
  }
}
