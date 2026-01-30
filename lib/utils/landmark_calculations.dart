import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

/// Utility class for performing calculations on pose landmarks
class LandmarkCalculations {
  /// Calculate the center point between left and right hip landmarks
  /// Returns a tuple (x, y) in normalized coordinates (0-1)
  /// Returns null if either hip landmark is not found
  static (double, double)? calculateHipCenter(List<PoseLandmark> landmarks) {
    try {
      final PoseLandmark leftHip = landmarks.firstWhere(
        (landmark) => landmark.name == 'left_hip',
      );
      final PoseLandmark rightHip = landmarks.firstWhere(
        (landmark) => landmark.name == 'right_hip',
      );

      final double centerX = (leftHip.x + rightHip.x) / 2;
      final double centerY = (leftHip.y + rightHip.y) / 2;

      return (centerX, centerY);
    } catch (e) {
      // Hip landmarks not found
      return null;
    }
  }
}
