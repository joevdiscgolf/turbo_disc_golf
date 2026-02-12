import 'package:json_annotation/json_annotation.dart';

part 'crop_metadata.g.dart';

/// Metadata for cropping/zooming into a specific region of the video
/// Used to focus on a particular body part or movement
@JsonSerializable()
class CropMetadata {
  const CropMetadata({
    required this.centerX,
    required this.centerY,
    required this.scale,
    this.focusRegion,
  });

  /// X coordinate of the crop center (0.0-1.0, where 0 is left, 1 is right)
  @JsonKey(name: 'center_x')
  final double centerX;

  /// Y coordinate of the crop center (0.0-1.0, where 0 is top, 1 is bottom)
  @JsonKey(name: 'center_y')
  final double centerY;

  /// Scale factor for the crop (0.0-1.0, where smaller = more zoomed in)
  final double scale;

  /// Optional description of the focus region (e.g., "back_foot", "release_point")
  @JsonKey(name: 'focus_region')
  final String? focusRegion;

  factory CropMetadata.fromJson(Map<String, dynamic> json) =>
      _$CropMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$CropMetadataToJson(this);
}
