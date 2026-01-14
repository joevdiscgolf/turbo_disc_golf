import 'package:json_annotation/json_annotation.dart';

/// Represents the camera angle for form analysis videos.
///
/// Used to specify whether the video was recorded from the side of the thrower
/// or from behind the thrower.
enum CameraAngle {
  /// Camera positioned to the side of the throwing motion.
  /// This is the default and most common angle for form analysis.
  @JsonValue('side')
  side,

  /// Camera positioned behind the thrower.
  /// Useful for analyzing follow-through and hip rotation.
  @JsonValue('rear')
  rear;

  /// Returns a human-readable display name for the camera angle.
  String get displayName {
    switch (this) {
      case CameraAngle.side:
        return 'Side View';
      case CameraAngle.rear:
        return 'Rear View';
    }
  }

  /// Returns a description of what the camera angle represents.
  String get description {
    switch (this) {
      case CameraAngle.side:
        return 'Camera positioned to the side of the throwing motion';
      case CameraAngle.rear:
        return 'Camera positioned behind the thrower';
    }
  }

  /// Returns the API/JSON string value.
  /// This is the value sent to the backend and stored in Firestore.
  String toApiString() {
    switch (this) {
      case CameraAngle.side:
        return 'side';
      case CameraAngle.rear:
        return 'rear';
    }
  }
}
