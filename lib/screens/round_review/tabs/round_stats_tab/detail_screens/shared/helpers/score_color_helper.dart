import 'package:flutter/material.dart';

/// Helper function to get score color based on relative score
/// - Green for birdie/eagle (< 0)
/// - Gray for par (== 0)
/// - Orange for bogey (== 1)
/// - Red for double+ (> 1)
Color getScoreColor(int relativeScore) {
  if (relativeScore < 0) {
    return const Color(0xFF10B981); // Birdie/Eagle - Green
  } else if (relativeScore == 0) {
    return const Color(0xFF6B7280); // Par - Gray
  } else if (relativeScore == 1) {
    return const Color(0xFFFB923C); // Bogey - Orange
  } else {
    return const Color(0xFFEF4444); // Double+ - Red
  }
}
