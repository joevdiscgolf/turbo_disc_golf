// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_analysis_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormAnalysisRecord _$FormAnalysisRecordFromJson(Map<String, dynamic> json) =>
    FormAnalysisRecord(
      id: json['id'] as String,
      uid: json['uid'] as String,
      createdAt: json['created_at'] as String,
      throwType: json['throw_type'] as String,
      checkpoints: (json['checkpoints'] as List<dynamic>)
          .map((e) => CheckpointRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallFormScore: (json['overall_form_score'] as num?)?.toInt(),
      worstDeviationSeverity: json['worst_deviation_severity'] as String?,
      topCoachingTips: (json['top_coaching_tips'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      thumbnailBase64: json['thumbnail_base64'] as String?,
      cameraAngle: $enumDecodeNullable(
        _$CameraAngleEnumMap,
        json['camera_angle'],
      ),
    );

Map<String, dynamic> _$FormAnalysisRecordToJson(FormAnalysisRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uid': instance.uid,
      'created_at': instance.createdAt,
      'throw_type': instance.throwType,
      'overall_form_score': instance.overallFormScore,
      'worst_deviation_severity': instance.worstDeviationSeverity,
      'checkpoints': instance.checkpoints.map((e) => e.toJson()).toList(),
      'top_coaching_tips': instance.topCoachingTips,
      'thumbnail_base64': instance.thumbnailBase64,
      'camera_angle': _$CameraAngleEnumMap[instance.cameraAngle],
    };

const _$CameraAngleEnumMap = {
  CameraAngle.side: 'side',
  CameraAngle.rear: 'rear',
};

CheckpointRecord _$CheckpointRecordFromJson(
  Map<String, dynamic> json,
) => CheckpointRecord(
  checkpointId: json['checkpoint_id'] as String,
  checkpointName: json['checkpoint_name'] as String,
  deviationSeverity: json['deviation_severity'] as String,
  coachingTips: (json['coaching_tips'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  angleDeviations: (json['angle_deviations'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  userImageUrl: json['user_image_url'] as String?,
  userSkeletonUrl: json['user_skeleton_url'] as String?,
  referenceImageUrl: json['reference_image_url'] as String?,
  referenceSkeletonUrl: json['reference_skeleton_url'] as String?,
  proPlayerId: json['pro_player_id'] as String?,
  referenceHorizontalOffsetPercent:
      (json['reference_horizontal_offset_percent'] as num?)?.toDouble(),
  referenceScale: (json['reference_scale'] as num?)?.toDouble(),
  userLeftKneeBendAngle: (json['user_left_knee_bend_angle'] as num?)
      ?.toDouble(),
  userRightKneeBendAngle: (json['user_right_knee_bend_angle'] as num?)
      ?.toDouble(),
  userLeftElbowFlexionAngle: (json['user_left_elbow_flexion_angle'] as num?)
      ?.toDouble(),
  userRightElbowFlexionAngle: (json['user_right_elbow_flexion_angle'] as num?)
      ?.toDouble(),
  userLeftShoulderAbductionAngle:
      (json['user_left_shoulder_abduction_angle'] as num?)?.toDouble(),
  userRightShoulderAbductionAngle:
      (json['user_right_shoulder_abduction_angle'] as num?)?.toDouble(),
  userLeftWristExtensionAngle: (json['user_left_wrist_extension_angle'] as num?)
      ?.toDouble(),
  userRightWristExtensionAngle:
      (json['user_right_wrist_extension_angle'] as num?)?.toDouble(),
  userLeftHipFlexionAngle: (json['user_left_hip_flexion_angle'] as num?)
      ?.toDouble(),
  userRightHipFlexionAngle: (json['user_right_hip_flexion_angle'] as num?)
      ?.toDouble(),
  userLeftAnkleAngle: (json['user_left_ankle_angle'] as num?)?.toDouble(),
  userRightAnkleAngle: (json['user_right_ankle_angle'] as num?)?.toDouble(),
  refLeftKneeBendAngle: (json['ref_left_knee_bend_angle'] as num?)?.toDouble(),
  refRightKneeBendAngle: (json['ref_right_knee_bend_angle'] as num?)
      ?.toDouble(),
  refLeftElbowFlexionAngle: (json['ref_left_elbow_flexion_angle'] as num?)
      ?.toDouble(),
  refRightElbowFlexionAngle: (json['ref_right_elbow_flexion_angle'] as num?)
      ?.toDouble(),
  refLeftShoulderAbductionAngle:
      (json['ref_left_shoulder_abduction_angle'] as num?)?.toDouble(),
  refRightShoulderAbductionAngle:
      (json['ref_right_shoulder_abduction_angle'] as num?)?.toDouble(),
  refLeftWristExtensionAngle: (json['ref_left_wrist_extension_angle'] as num?)
      ?.toDouble(),
  refRightWristExtensionAngle: (json['ref_right_wrist_extension_angle'] as num?)
      ?.toDouble(),
  refLeftHipFlexionAngle: (json['ref_left_hip_flexion_angle'] as num?)
      ?.toDouble(),
  refRightHipFlexionAngle: (json['ref_right_hip_flexion_angle'] as num?)
      ?.toDouble(),
  refLeftAnkleAngle: (json['ref_left_ankle_angle'] as num?)?.toDouble(),
  refRightAnkleAngle: (json['ref_right_ankle_angle'] as num?)?.toDouble(),
  devLeftKneeBendAngle: (json['dev_left_knee_bend_angle'] as num?)?.toDouble(),
  devRightKneeBendAngle: (json['dev_right_knee_bend_angle'] as num?)
      ?.toDouble(),
  devLeftElbowFlexionAngle: (json['dev_left_elbow_flexion_angle'] as num?)
      ?.toDouble(),
  devRightElbowFlexionAngle: (json['dev_right_elbow_flexion_angle'] as num?)
      ?.toDouble(),
  devLeftShoulderAbductionAngle:
      (json['dev_left_shoulder_abduction_angle'] as num?)?.toDouble(),
  devRightShoulderAbductionAngle:
      (json['dev_right_shoulder_abduction_angle'] as num?)?.toDouble(),
  devLeftWristExtensionAngle: (json['dev_left_wrist_extension_angle'] as num?)
      ?.toDouble(),
  devRightWristExtensionAngle: (json['dev_right_wrist_extension_angle'] as num?)
      ?.toDouble(),
  devLeftHipFlexionAngle: (json['dev_left_hip_flexion_angle'] as num?)
      ?.toDouble(),
  devRightHipFlexionAngle: (json['dev_right_hip_flexion_angle'] as num?)
      ?.toDouble(),
  devLeftAnkleAngle: (json['dev_left_ankle_angle'] as num?)?.toDouble(),
  devRightAnkleAngle: (json['dev_right_ankle_angle'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CheckpointRecordToJson(
  CheckpointRecord instance,
) => <String, dynamic>{
  'checkpoint_id': instance.checkpointId,
  'checkpoint_name': instance.checkpointName,
  'deviation_severity': instance.deviationSeverity,
  'coaching_tips': instance.coachingTips,
  'angle_deviations': instance.angleDeviations,
  'user_image_url': instance.userImageUrl,
  'user_skeleton_url': instance.userSkeletonUrl,
  'reference_image_url': instance.referenceImageUrl,
  'reference_skeleton_url': instance.referenceSkeletonUrl,
  'pro_player_id': instance.proPlayerId,
  'reference_horizontal_offset_percent':
      instance.referenceHorizontalOffsetPercent,
  'reference_scale': instance.referenceScale,
  'user_left_knee_bend_angle': instance.userLeftKneeBendAngle,
  'user_right_knee_bend_angle': instance.userRightKneeBendAngle,
  'user_left_elbow_flexion_angle': instance.userLeftElbowFlexionAngle,
  'user_right_elbow_flexion_angle': instance.userRightElbowFlexionAngle,
  'user_left_shoulder_abduction_angle': instance.userLeftShoulderAbductionAngle,
  'user_right_shoulder_abduction_angle':
      instance.userRightShoulderAbductionAngle,
  'user_left_wrist_extension_angle': instance.userLeftWristExtensionAngle,
  'user_right_wrist_extension_angle': instance.userRightWristExtensionAngle,
  'user_left_hip_flexion_angle': instance.userLeftHipFlexionAngle,
  'user_right_hip_flexion_angle': instance.userRightHipFlexionAngle,
  'user_left_ankle_angle': instance.userLeftAnkleAngle,
  'user_right_ankle_angle': instance.userRightAnkleAngle,
  'ref_left_knee_bend_angle': instance.refLeftKneeBendAngle,
  'ref_right_knee_bend_angle': instance.refRightKneeBendAngle,
  'ref_left_elbow_flexion_angle': instance.refLeftElbowFlexionAngle,
  'ref_right_elbow_flexion_angle': instance.refRightElbowFlexionAngle,
  'ref_left_shoulder_abduction_angle': instance.refLeftShoulderAbductionAngle,
  'ref_right_shoulder_abduction_angle': instance.refRightShoulderAbductionAngle,
  'ref_left_wrist_extension_angle': instance.refLeftWristExtensionAngle,
  'ref_right_wrist_extension_angle': instance.refRightWristExtensionAngle,
  'ref_left_hip_flexion_angle': instance.refLeftHipFlexionAngle,
  'ref_right_hip_flexion_angle': instance.refRightHipFlexionAngle,
  'ref_left_ankle_angle': instance.refLeftAnkleAngle,
  'ref_right_ankle_angle': instance.refRightAnkleAngle,
  'dev_left_knee_bend_angle': instance.devLeftKneeBendAngle,
  'dev_right_knee_bend_angle': instance.devRightKneeBendAngle,
  'dev_left_elbow_flexion_angle': instance.devLeftElbowFlexionAngle,
  'dev_right_elbow_flexion_angle': instance.devRightElbowFlexionAngle,
  'dev_left_shoulder_abduction_angle': instance.devLeftShoulderAbductionAngle,
  'dev_right_shoulder_abduction_angle': instance.devRightShoulderAbductionAngle,
  'dev_left_wrist_extension_angle': instance.devLeftWristExtensionAngle,
  'dev_right_wrist_extension_angle': instance.devRightWristExtensionAngle,
  'dev_left_hip_flexion_angle': instance.devLeftHipFlexionAngle,
  'dev_right_hip_flexion_angle': instance.devRightHipFlexionAngle,
  'dev_left_ankle_angle': instance.devLeftAnkleAngle,
  'dev_right_ankle_angle': instance.devRightAnkleAngle,
};
