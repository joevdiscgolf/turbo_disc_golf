import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

part 'pro_overlay_alignment.g.dart';

/// Pro overlay alignment data for rendering pro reference over user pose
@JsonSerializable(explicitToJson: true)
class ProOverlayAlignment {
  const ProOverlayAlignment({
    required this.userBodyAnchor,
    required this.userTorsoHeightNormalized,
    required this.referenceHorizontalOffsetPercent,
    required this.referenceScale,
  });

  /// User body anchor point (hip center) for alignment
  @JsonKey(name: 'user_body_anchor')
  final UserBodyAnchor userBodyAnchor;

  /// User torso height as a fraction of frame height (for scaling)
  @JsonKey(name: 'user_torso_height_normalized')
  final double userTorsoHeightNormalized;

  /// Horizontal offset percentage for aligning pro reference with user
  /// Positive values shift right, negative shift left
  @JsonKey(name: 'reference_horizontal_offset_percent')
  final double referenceHorizontalOffsetPercent;

  /// Scale factor for pro reference to match user form size
  @JsonKey(name: 'reference_scale')
  final double referenceScale;

  factory ProOverlayAlignment.fromJson(Map<String, dynamic> json) =>
      _$ProOverlayAlignmentFromJson(json);
  Map<String, dynamic> toJson() => _$ProOverlayAlignmentToJson(this);
}
