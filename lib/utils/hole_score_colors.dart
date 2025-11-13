import 'package:flutter/material.dart';

/// Utility class for determining hole score colors based on relative score (score - par).
///
/// Provides consistent color schemes across the app for displaying hole scores:
/// - Birdie (< 0): Green
/// - Par (0): Grey
/// - Bogey (1): Light Red
/// - Double Bogey+ (> 1): Dark Red
class HoleScoreColors {
  HoleScoreColors._();

  /// Returns gradient colors for the hole background based on relative score.
  static List<Color> getGradientColors(int relativeScore) {
    if (relativeScore < 0) {
      // Birdie - green gradient
      return [
        const Color(0xFF137e66).withValues(alpha: 0.25),
        const Color(0xFF137e66).withValues(alpha: 0.15),
      ];
    } else if (relativeScore == 0) {
      // Par - darker grey gradient
      return [
        Colors.grey.withValues(alpha: 0.35),
        Colors.grey.withValues(alpha: 0.25),
      ];
    } else if (relativeScore == 1) {
      // Bogey - light red gradient
      return [
        const Color(0xFFFF7A7A).withValues(alpha: 0.25),
        const Color(0xFFFF7A7A).withValues(alpha: 0.15),
      ];
    } else {
      // Double bogey+ - dark red gradient
      return [
        const Color(0xFFD32F2F).withValues(alpha: 0.25),
        const Color(0xFFD32F2F).withValues(alpha: 0.15),
      ];
    }
  }

  /// Returns the solid color for the score circle based on relative score.
  static Color getScoreColor(int relativeScore) {
    if (relativeScore < 0) {
      // Birdie - green
      return const Color(0xFF137e66);
    } else if (relativeScore == 0) {
      // Par - grey
      return Colors.grey;
    } else if (relativeScore == 1) {
      // Bogey - light red
      return const Color(0xFFFF7A7A);
    } else {
      // Double bogey+ - dark red
      return const Color(0xFFD32F2F);
    }
  }
}
