import 'package:json_annotation/json_annotation.dart';

/// Represents whether the player throws right-handed or left-handed.
///
/// Used for form analysis to properly mirror video frames and
/// provide accurate feedback based on throwing hand.
enum Handedness {
  /// Left-handed thrower.
  @JsonValue('left')
  left,

  /// Right-handed thrower (most common).
  @JsonValue('right')
  right;

  /// Returns a human-readable display name.
  String get displayName {
    switch (this) {
      case Handedness.left:
        return 'Left-handed';
      case Handedness.right:
        return 'Right-handed';
    }
  }

  /// Returns a short display name for UI.
  String get shortName {
    switch (this) {
      case Handedness.left:
        return 'Left';
      case Handedness.right:
        return 'Right';
    }
  }

  /// Returns a casual badge label for UI overlays.
  String get badgeLabel {
    switch (this) {
      case Handedness.left:
        return 'Lefty';
      case Handedness.right:
        return 'Righty';
    }
  }

  /// Returns the API/JSON string value.
  /// Backend expects "right-handed" or "left-handed"
  String toApiString() {
    switch (this) {
      case Handedness.left:
        return 'left-handed';
      case Handedness.right:
        return 'right-handed';
    }
  }

  /// Parses API string values: "right-handed" or "left-handed"
  static Handedness? fromApiString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'left-handed':
        return Handedness.left;
      case 'right-handed':
        return Handedness.right;
      default:
        return null;
    }
  }
}
