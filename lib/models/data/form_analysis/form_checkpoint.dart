import 'package:json_annotation/json_annotation.dart';

part 'form_checkpoint.g.dart';

/// Represents a single checkpoint in the throwing form analysis
/// Based on the Slingshot disc golf methodology
@JsonSerializable(explicitToJson: true, anyMap: true)
class FormCheckpoint {
  const FormCheckpoint({
    required this.id,
    required this.name,
    required this.description,
    required this.keyPoints,
    required this.orderIndex,
    this.referenceImagePath,
    this.referenceDescription,
  });

  /// Unique identifier for this checkpoint (e.g., 'reachback', 'power_pocket')
  final String id;

  /// Human-readable name (e.g., 'Reachback Position')
  final String name;

  /// Detailed description of what this checkpoint represents
  final String description;

  /// List of key points to evaluate at this checkpoint
  final List<FormKeyPoint> keyPoints;

  /// Order in the throwing sequence (0 = first checkpoint)
  final int orderIndex;

  /// Optional path to reference image for this position
  final String? referenceImagePath;

  /// Optional detailed description of ideal position
  final String? referenceDescription;

  factory FormCheckpoint.fromJson(Map<String, dynamic> json) =>
      _$FormCheckpointFromJson(json);
  Map<String, dynamic> toJson() => _$FormCheckpointToJson(this);
}

/// A specific point to evaluate within a checkpoint
@JsonSerializable(explicitToJson: true, anyMap: true)
class FormKeyPoint {
  const FormKeyPoint({
    required this.id,
    required this.name,
    required this.description,
    required this.idealState,
    this.commonMistakes,
  });

  /// Unique identifier for this key point
  final String id;

  /// Human-readable name (e.g., 'Arm Extension')
  final String name;

  /// Description of what this key point evaluates
  final String description;

  /// Description of the ideal state for this key point
  final String idealState;

  /// Common mistakes to look for
  final List<String>? commonMistakes;

  factory FormKeyPoint.fromJson(Map<String, dynamic> json) =>
      _$FormKeyPointFromJson(json);
  Map<String, dynamic> toJson() => _$FormKeyPointToJson(this);
}
