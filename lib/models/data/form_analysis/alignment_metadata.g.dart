// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alignment_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BodyAnchor _$BodyAnchorFromJson(Map<String, dynamic> json) => BodyAnchor(
  name: json['name'] as String?,
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
);

Map<String, dynamic> _$BodyAnchorToJson(BodyAnchor instance) =>
    <String, dynamic>{'name': instance.name, 'x': instance.x, 'y': instance.y};

OutputDimensions _$OutputDimensionsFromJson(Map<String, dynamic> json) =>
    OutputDimensions(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$OutputDimensionsToJson(OutputDimensions instance) =>
    <String, dynamic>{'width': instance.width, 'height': instance.height};

CheckpointAlignmentData _$CheckpointAlignmentDataFromJson(
  Map<String, dynamic> json,
) => CheckpointAlignmentData(
  bodyAnchor: BodyAnchor.fromJson(json['body_anchor'] as Map<String, dynamic>),
  output: json['output'] == null
      ? null
      : OutputDimensions.fromJson(json['output'] as Map<String, dynamic>),
  torsoHeightNormalized: (json['torso_height_normalized'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CheckpointAlignmentDataToJson(
  CheckpointAlignmentData instance,
) => <String, dynamic>{
  'body_anchor': instance.bodyAnchor,
  'output': instance.output,
  'torso_height_normalized': instance.torsoHeightNormalized,
};

AlignmentMetadata _$AlignmentMetadataFromJson(Map<String, dynamic> json) =>
    AlignmentMetadata(
      player: json['player'] as String?,
      throwType: json['throw_type'] as String?,
      cameraAngle: json['camera_angle'] as String?,
      checkpoints: (json['checkpoints'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          k,
          CheckpointAlignmentData.fromJson(e as Map<String, dynamic>),
        ),
      ),
    );

Map<String, dynamic> _$AlignmentMetadataToJson(AlignmentMetadata instance) =>
    <String, dynamic>{
      'player': instance.player,
      'throw_type': instance.throwType,
      'camera_angle': instance.cameraAngle,
      'checkpoints': instance.checkpoints,
    };
