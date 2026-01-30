// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_pose_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPoseData _$UserPoseDataFromJson(Map<String, dynamic> json) => UserPoseData(
  landmarks: (json['landmarks'] as List<dynamic>)
      .map((e) => PoseLandmark.fromJson(e as Map<String, dynamic>))
      .toList(),
  angles: PoseAngles.fromJson(json['angles'] as Map<String, dynamic>),
  individualAngles: json['individual_angles'] == null
      ? null
      : IndividualJointAngles.fromJson(
          json['individual_angles'] as Map<String, dynamic>,
        ),
  v2Measurements: json['v2_measurements'] == null
      ? null
      : V2SideMeasurements.fromJson(
          json['v2_measurements'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$UserPoseDataToJson(UserPoseData instance) =>
    <String, dynamic>{
      'landmarks': instance.landmarks.map((e) => e.toJson()).toList(),
      'angles': instance.angles.toJson(),
      'individual_angles': instance.individualAngles?.toJson(),
      'v2_measurements': instance.v2Measurements?.toJson(),
    };
