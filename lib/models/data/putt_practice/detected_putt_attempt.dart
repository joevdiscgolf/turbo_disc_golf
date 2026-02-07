import 'package:json_annotation/json_annotation.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/miss_direction.dart';

part 'detected_putt_attempt.g.dart';

/// A single detected putt attempt with position and result data
@JsonSerializable(anyMap: true, explicitToJson: true)
class DetectedPuttAttempt {
  /// Unique identifier for this attempt
  final String id;

  /// Timestamp when the putt was detected
  final DateTime timestamp;

  /// Whether the putt was made (true) or missed (false)
  final bool made;

  /// X position relative to basket center (-1 to 1)
  /// Negative = left, Positive = right
  final double relativeX;

  /// Y position relative to basket center (-1 to 1)
  /// Negative = low, Positive = high
  final double relativeY;

  /// Estimated distance from basket in feet (if determinable)
  final double? estimatedDistanceFeet;

  /// Confidence score of the detection (0.0 to 1.0)
  final double confidence;

  /// Frame number in the video when the putt was detected
  final int? frameNumber;

  DetectedPuttAttempt({
    required this.id,
    required this.timestamp,
    required this.made,
    required this.relativeX,
    required this.relativeY,
    this.estimatedDistanceFeet,
    required this.confidence,
    this.frameNumber,
  });

  /// Derive the miss direction from X/Y coordinates
  /// Returns null if the putt was made
  MissDirection? get missDirection {
    if (made) return null;

    // Threshold for determining direction (0.3 = 30% off center)
    const double threshold = 0.3;

    // Check Y-axis first (high/low takes priority)
    if (relativeY > threshold) return MissDirection.high;
    if (relativeY < -threshold) return MissDirection.low;

    // Then check X-axis
    if (relativeX < -threshold) return MissDirection.left;
    if (relativeX > threshold) return MissDirection.right;

    // Close miss near center
    return MissDirection.center;
  }

  /// Distance from basket center in normalized units
  double get distanceFromCenter {
    return (relativeX * relativeX + relativeY * relativeY);
  }

  /// Create a copy with updated fields
  DetectedPuttAttempt copyWith({
    String? id,
    DateTime? timestamp,
    bool? made,
    double? relativeX,
    double? relativeY,
    double? estimatedDistanceFeet,
    double? confidence,
    int? frameNumber,
  }) {
    return DetectedPuttAttempt(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      made: made ?? this.made,
      relativeX: relativeX ?? this.relativeX,
      relativeY: relativeY ?? this.relativeY,
      estimatedDistanceFeet:
          estimatedDistanceFeet ?? this.estimatedDistanceFeet,
      confidence: confidence ?? this.confidence,
      frameNumber: frameNumber ?? this.frameNumber,
    );
  }

  factory DetectedPuttAttempt.fromJson(Map<String, dynamic> json) =>
      _$DetectedPuttAttemptFromJson(json);

  Map<String, dynamic> toJson() => _$DetectedPuttAttemptToJson(this);
}
