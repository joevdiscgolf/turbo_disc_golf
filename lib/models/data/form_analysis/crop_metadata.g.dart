// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crop_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CropMetadata _$CropMetadataFromJson(Map<String, dynamic> json) => CropMetadata(
  centerX: (json['center_x'] as num).toDouble(),
  centerY: (json['center_y'] as num).toDouble(),
  scale: (json['scale'] as num).toDouble(),
  focusRegion: json['focus_region'] as String?,
);

Map<String, dynamic> _$CropMetadataToJson(CropMetadata instance) =>
    <String, dynamic>{
      'center_x': instance.centerX,
      'center_y': instance.centerY,
      'scale': instance.scale,
      'focus_region': instance.focusRegion,
    };
