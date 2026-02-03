// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_alignment_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAlignmentMetadata _$UserAlignmentMetadataFromJson(
  Map<String, dynamic> json,
) => UserAlignmentMetadata(
  userBodyHeightScreenPortion: (json['user_body_height_screen_portion'] as num)
      .toDouble(),
  bodyCenterXScreenPortion: (json['body_center_x_screen_portion'] as num)
      .toDouble(),
  bodyCenterYScreenPortion: (json['body_center_y_screen_portion'] as num)
      .toDouble(),
);

Map<String, dynamic> _$UserAlignmentMetadataToJson(
  UserAlignmentMetadata instance,
) => <String, dynamic>{
  'user_body_height_screen_portion': instance.userBodyHeightScreenPortion,
  'body_center_x_screen_portion': instance.bodyCenterXScreenPortion,
  'body_center_y_screen_portion': instance.bodyCenterYScreenPortion,
};
