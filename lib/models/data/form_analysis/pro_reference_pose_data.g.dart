// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_reference_pose_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProReferencePoseData _$ProReferencePoseDataFromJson(
  Map<String, dynamic> json,
) => ProReferencePoseData(
  proPlayerId: json['pro_player_id'] as String,
  landmarks: (json['landmarks'] as List<dynamic>)
      .map((e) => PoseLandmark.fromJson(e as Map<String, dynamic>))
      .toList(),
  angles: PoseAngles.fromJson(json['angles'] as Map<String, dynamic>),
  individualAngles: json['individual_angles'] == null
      ? null
      : IndividualJointAngles.fromJson(
          json['individual_angles'] as Map<String, dynamic>,
        ),
  v2Measurements: V2MeasurementsByAngle.fromJson(
    json['v2_measurements'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ProReferencePoseDataToJson(
  ProReferencePoseData instance,
) => <String, dynamic>{
  'pro_player_id': instance.proPlayerId,
  'landmarks': instance.landmarks.map((e) => e.toJson()).toList(),
  'angles': instance.angles.toJson(),
  'individual_angles': instance.individualAngles?.toJson(),
  'v2_measurements': instance.v2Measurements.toJson(),
};
