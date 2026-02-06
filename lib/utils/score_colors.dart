import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Utility class for determining hole score colors based on relative score (score - par).
///
/// Provides consistent color schemes across the app for displaying hole scores:
/// - Birdie (< 0): Green
/// - Par (0): Grey
/// - Bogey (1): Light Red
/// - Double Bogey+ (> 1): Dark Red
class ScoreColors {
  ScoreColors._();

  // Static color constants - SINGLE SOURCE OF TRUTH
  static const Color condorColor = Color(0xFF9C27B0); // Purple
  static const Color albatrossColor = Color(0xFFB8860B); // Darker gold
  static const Color eagleColor = Color.fromARGB(255, 31, 158, 255); // Blue
  static const Color birdieColor = Color(0xFF137e66); // Green
  static Color parColor = SenseiColors.gray[300]!;
  static const Color bogeyColor = Color(0xFFFF7A7A); // Light red
  static const Color doubleBogeyPlusColor = Color(0xFFD32F2F); // Dark red

  /// Returns gradient colors for the hole background based on relative score.
  static List<Color> getGradientColors(int relativeScore) {
    if (relativeScore < -3) {
      // Condor - purple gradient
      return [
        flattenedOverWhite(condorColor, 0.25),
        flattenedOverWhite(condorColor, 0.05),
      ];
    } else if (relativeScore == -3) {
      // Albatross - darker gold gradient
      return [
        flattenedOverWhite(albatrossColor, 0.25),
        flattenedOverWhite(albatrossColor, 0.05),
      ];
    } else if (relativeScore < -1) {
      // Eagle - blue gradient
      return [
        flattenedOverWhite(eagleColor, 0.25),
        flattenedOverWhite(eagleColor, 0.05),
      ];
    } else if (relativeScore < 0) {
      // Birdie - green gradient
      return [
        flattenedOverWhite(birdieColor, 0.25),
        flattenedOverWhite(birdieColor, 0.05),
      ];
    } else if (relativeScore == 0) {
      // Par - grey gradient
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
    } else {
      return [
        flattenedOverWhite(doubleBogeyPlusColor, 0.4),
        flattenedOverWhite(doubleBogeyPlusColor, 0.15),
      ];
    }
  }

  /// Returns the solid color for the score circle based on relative score.
  static Color getScoreColor(int relativeScore) {
    if (relativeScore < -3) {
      return condorColor;
    } else if (relativeScore == -3) {
      return albatrossColor;
    } else if (relativeScore < -1) {
      return eagleColor;
    } else if (relativeScore < 0) {
      return birdieColor;
    } else if (relativeScore == 0) {
      return parColor;
    } else if (relativeScore == 1) {
      return bogeyColor;
    } else {
      return doubleBogeyPlusColor;
    }
  }

  /// Helper function to get score color based on relative score
  /// - Green for birdie/eagle (< 0)
  /// - Gray for par (== 0)
  /// - Orange for bogey (== 1)
  /// - Red for double+ (> 1)
  static Color getRoundScoreColor(int relativeScore) {
    if (relativeScore < 0) {
      return birdieColor;
    } else if (relativeScore == 0) {
      return parColor;
    } else {
      return bogeyColor;
    }
  }
}
