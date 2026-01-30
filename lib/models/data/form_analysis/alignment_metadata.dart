import 'package:json_annotation/json_annotation.dart';

part 'alignment_metadata.g.dart';

/// Represents the body anchor point (hip center) in the pro reference image
/// Coordinates are normalized (0-1) relative to the image dimensions
@JsonSerializable()
class BodyAnchor {
  /// Name of the anchor point (e.g., "hip_center")
  final String? name;

  /// Horizontal position of hip center (0-1, where 0 is left edge, 1 is right edge)
  final double x;

  /// Vertical position of hip center (0-1, where 0 is top edge, 1 is bottom edge)
  final double y;

  const BodyAnchor({
    this.name,
    required this.x,
    required this.y,
  });

  factory BodyAnchor.fromJson(Map<String, dynamic> json) =>
      _$BodyAnchorFromJson(json);

  Map<String, dynamic> toJson() => _$BodyAnchorToJson(this);
}

/// Output image dimensions for a checkpoint
@JsonSerializable()
class OutputDimensions {
  final int width;
  final int height;

  const OutputDimensions({
    required this.width,
    required this.height,
  });

  double get aspectRatio => width / height;

  factory OutputDimensions.fromJson(Map<String, dynamic> json) =>
      _$OutputDimensionsFromJson(json);

  Map<String, dynamic> toJson() => _$OutputDimensionsToJson(this);
}

/// Alignment data for a specific checkpoint in the throwing motion
@JsonSerializable()
class CheckpointAlignmentData {
  /// The body anchor point (hip center) for this checkpoint
  @JsonKey(name: 'body_anchor')
  final BodyAnchor bodyAnchor;

  /// Output image dimensions for this checkpoint
  final OutputDimensions? output;

  /// Torso height in normalized coordinates (for reference/validation)
  @JsonKey(name: 'torso_height_normalized')
  final double? torsoHeightNormalized;

  const CheckpointAlignmentData({
    required this.bodyAnchor,
    this.output,
    this.torsoHeightNormalized,
  });

  factory CheckpointAlignmentData.fromJson(Map<String, dynamic> json) =>
      _$CheckpointAlignmentDataFromJson(json);

  Map<String, dynamic> toJson() => _$CheckpointAlignmentDataToJson(this);
}

/// Metadata for aligning pro reference images with user skeletons
/// Contains body anchor points for all checkpoints in a specific pro reference video
@JsonSerializable()
class AlignmentMetadata {
  /// Player ID (e.g., "paul_mcbeth")
  final String? player;

  /// Throw type (e.g., "backhand", "forehand")
  @JsonKey(name: 'throw_type')
  final String? throwType;

  /// Camera angle (e.g., "side", "rear")
  @JsonKey(name: 'camera_angle')
  final String? cameraAngle;

  /// Map of checkpoint IDs to their alignment data
  final Map<String, CheckpointAlignmentData> checkpoints;

  const AlignmentMetadata({
    this.player,
    this.throwType,
    this.cameraAngle,
    required this.checkpoints,
  });

  factory AlignmentMetadata.fromJson(Map<String, dynamic> json) =>
      _$AlignmentMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$AlignmentMetadataToJson(this);
}
