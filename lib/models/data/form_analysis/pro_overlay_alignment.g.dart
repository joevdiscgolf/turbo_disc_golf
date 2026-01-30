// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_overlay_alignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProOverlayAlignment _$ProOverlayAlignmentFromJson(Map<String, dynamic> json) =>
    ProOverlayAlignment(
      userBodyAnchor: UserBodyAnchor.fromJson(
        json['user_body_anchor'] as Map<String, dynamic>,
      ),
      userTorsoHeightNormalized: (json['user_torso_height_normalized'] as num)
          .toDouble(),
      referenceHorizontalOffsetPercent:
          (json['reference_horizontal_offset_percent'] as num).toDouble(),
      referenceScale: (json['reference_scale'] as num).toDouble(),
    );

Map<String, dynamic> _$ProOverlayAlignmentToJson(
  ProOverlayAlignment instance,
) => <String, dynamic>{
  'user_body_anchor': instance.userBodyAnchor.toJson(),
  'user_torso_height_normalized': instance.userTorsoHeightNormalized,
  'reference_horizontal_offset_percent':
      instance.referenceHorizontalOffsetPercent,
  'reference_scale': instance.referenceScale,
};
