// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frame_pose_data_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FramePoseLandmark _$FramePoseLandmarkFromJson(Map<String, dynamic> json) =>
    FramePoseLandmark(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      v: (json['v'] as num).toDouble(),
    );

Map<String, dynamic> _$FramePoseLandmarkToJson(FramePoseLandmark instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
      'v': instance.v,
    };

FramePoseDataV2 _$FramePoseDataV2FromJson(Map<String, dynamic> json) =>
    FramePoseDataV2(
      frameNumber: (json['f'] as num).toInt(),
      timestampSeconds: (json['t'] as num).toDouble(),
      landmarkObjects: (json['l'] as List<dynamic>)
          .map((e) => FramePoseLandmark.fromJson(e as Map<String, dynamic>))
          .toList(),
      checkpointId: json['c'] as String?,
    );

Map<String, dynamic> _$FramePoseDataV2ToJson(FramePoseDataV2 instance) =>
    <String, dynamic>{
      'f': instance.frameNumber,
      't': instance.timestampSeconds,
      'l': instance.landmarkObjects.map((e) => e.toJson()).toList(),
      'c': instance.checkpointId,
    };
