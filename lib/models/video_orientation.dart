import 'package:json_annotation/json_annotation.dart';

/// Represents the orientation of a video used for form analysis.
///
/// Used to determine whether the video was recorded in portrait or landscape
/// mode, which affects how the analysis results are displayed.
enum VideoOrientation {
  /// Video recorded in portrait orientation (taller than it is wide).
  /// Typical aspect ratios: 9:16, 3:4
  @JsonValue('portrait')
  portrait,

  /// Video recorded in landscape orientation (wider than it is tall).
  /// Typical aspect ratios: 16:9, 4:3
  @JsonValue('landscape')
  landscape;

  /// Returns a human-readable display name for the video orientation.
  String get displayName {
    switch (this) {
      case VideoOrientation.portrait:
        return 'Portrait';
      case VideoOrientation.landscape:
        return 'Landscape';
    }
  }

  /// Returns a description of what the video orientation represents.
  String get description {
    switch (this) {
      case VideoOrientation.portrait:
        return 'Video recorded in portrait orientation (taller than wide)';
      case VideoOrientation.landscape:
        return 'Video recorded in landscape orientation (wider than tall)';
    }
  }

  /// Returns the API/JSON string value.
  /// This is the value sent to the backend and stored in Firestore.
  String toApiString() {
    switch (this) {
      case VideoOrientation.portrait:
        return 'portrait';
      case VideoOrientation.landscape:
        return 'landscape';
    }
  }

  /// Determines video orientation from aspect ratio.
  /// Aspect ratio is calculated as width / height.
  /// Returns portrait if aspect ratio < 1.0, landscape otherwise.
  static VideoOrientation fromAspectRatio(double aspectRatio) {
    return aspectRatio < 1.0
        ? VideoOrientation.portrait
        : VideoOrientation.landscape;
  }
}
