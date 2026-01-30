// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frame_pose_data_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FramePoseDataV2 _$FramePoseDataV2FromJson(Map<String, dynamic> json) =>
    FramePoseDataV2(
      frameNumber: (json['f'] as num).toInt(),
      timestampSeconds: (json['t'] as num).toDouble(),
      landmarksFlat: (json['l'] as List<dynamic>)
          .map(
            (e) =>
                (e as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          )
          .toList(),
      checkpointId: json['c'] as String?,
    );

Map<String, dynamic> _$FramePoseDataV2ToJson(FramePoseDataV2 instance) =>
    <String, dynamic>{
      'f': instance.frameNumber,
      't': instance.timestampSeconds,
      'l': instance.landmarksFlat,
      'c': instance.checkpointId,
    };
