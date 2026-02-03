// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_overlay_alignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProOverlayAlignment _$ProOverlayAlignmentFromJson(Map<String, dynamic> json) =>
    ProOverlayAlignment(
      userBodyHeightScreenPortion:
          (json['user_body_height_screen_portion'] as num).toDouble(),
      bodyCenterXScreenPortion: (json['body_center_x_screen_portion'] as num)
          .toDouble(),
      bodyCenterYScreenPortion: (json['body_center_y_screen_portion'] as num)
          .toDouble(),
    );

Map<String, dynamic> _$ProOverlayAlignmentToJson(
  ProOverlayAlignment instance,
) => <String, dynamic>{
  'user_body_height_screen_portion': instance.userBodyHeightScreenPortion,
  'body_center_x_screen_portion': instance.bodyCenterXScreenPortion,
  'body_center_y_screen_portion': instance.bodyCenterYScreenPortion,
};
