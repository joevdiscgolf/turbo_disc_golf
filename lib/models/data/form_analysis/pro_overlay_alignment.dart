import 'package:json_annotation/json_annotation.dart';

part 'pro_overlay_alignment.g.dart';

/// Pro overlay alignment data for rendering pro reference over user pose
@JsonSerializable()
class ProOverlayAlignment {
  const ProOverlayAlignment({
    required this.userBodyHeightScreenPortion,
    required this.bodyCenterXScreenPortion,
    required this.bodyCenterYScreenPortion,
  });

  /// User's body height (shoulders to feet, excluding head) as a portion of the video frame height (0-1).
  /// e.g., 0.75 means the user's body takes up 75% of the frame height.
  @JsonKey(name: 'user_body_height_screen_portion')
  final double userBodyHeightScreenPortion;

  /// X position of the user's body center as a portion of screen width (0-1).
  /// 0 = left edge, 1 = right edge, 0.5 = center.
  @JsonKey(name: 'body_center_x_screen_portion')
  final double bodyCenterXScreenPortion;

  /// Y position of the user's body center as a portion of screen height (0-1).
  /// 0 = top edge, 1 = bottom edge.
  @JsonKey(name: 'body_center_y_screen_portion')
  final double bodyCenterYScreenPortion;

  factory ProOverlayAlignment.fromJson(Map<String, dynamic> json) =>
      _$ProOverlayAlignmentFromJson(json);
  Map<String, dynamic> toJson() => _$ProOverlayAlignmentToJson(this);
}
