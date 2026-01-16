// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pose_analysis_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PoseAnalysisResponse _$PoseAnalysisResponseFromJson(
  Map<String, dynamic> json,
) => PoseAnalysisResponse(
  sessionId: json['session_id'] as String,
  status: json['status'] as String,
  throwType: json['throw_type'] as String,
  cameraAngle: $enumDecode(_$CameraAngleEnumMap, json['camera_angle']),
  videoOrientation: $enumDecodeNullable(
    _$VideoOrientationEnumMap,
    json['video_orientation'],
  ),
  videoAspectRatio: (json['video_aspect_ratio'] as num?)?.toDouble(),
  videoDurationSeconds: (json['video_duration_seconds'] as num).toDouble(),
  totalFrames: (json['total_frames'] as num).toInt(),
  checkpoints: (json['checkpoints'] as List<dynamic>)
      .map((e) => CheckpointPoseData.fromJson(e as Map<String, dynamic>))
      .toList(),
  framePoses: (json['frame_poses'] as List<dynamic>)
      .map((e) => FramePoseData.fromJson(e as Map<String, dynamic>))
      .toList(),
  overallFormScore: (json['overall_form_score'] as num?)?.toInt(),
  errorMessage: json['error_message'] as String?,
  roundThumbnailBase64: json['round_thumbnail_base64'] as String?,
  videoUrl: json['video_url'] as String?,
  videoSyncMetadata: json['video_sync_metadata'] == null
      ? null
      : VideoSyncMetadata.fromJson(
          json['video_sync_metadata'] as Map<String, dynamic>,
        ),
  proVideoReference: json['pro_video_reference'] as String?,
);

Map<String, dynamic> _$PoseAnalysisResponseToJson(
  PoseAnalysisResponse instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'status': instance.status,
  'throw_type': instance.throwType,
  'camera_angle': _$CameraAngleEnumMap[instance.cameraAngle]!,
  'video_orientation': _$VideoOrientationEnumMap[instance.videoOrientation],
  'video_aspect_ratio': instance.videoAspectRatio,
  'video_duration_seconds': instance.videoDurationSeconds,
  'total_frames': instance.totalFrames,
  'checkpoints': instance.checkpoints.map((e) => e.toJson()).toList(),
  'frame_poses': instance.framePoses.map((e) => e.toJson()).toList(),
  'overall_form_score': instance.overallFormScore,
  'error_message': instance.errorMessage,
  'round_thumbnail_base64': instance.roundThumbnailBase64,
  'video_url': instance.videoUrl,
  'video_sync_metadata': instance.videoSyncMetadata?.toJson(),
  'pro_video_reference': instance.proVideoReference,
};

const _$CameraAngleEnumMap = {
  CameraAngle.side: 'side',
  CameraAngle.rear: 'rear',
};

const _$VideoOrientationEnumMap = {
  VideoOrientation.portrait: 'portrait',
  VideoOrientation.landscape: 'landscape',
};

CheckpointPoseData _$CheckpointPoseDataFromJson(
  Map<String, dynamic> json,
) => CheckpointPoseData(
  checkpointId: json['checkpoint_id'] as String,
  checkpointName: json['checkpoint_name'] as String,
  frameNumber: (json['frame_number'] as num).toInt(),
  timestampSeconds: (json['timestamp_seconds'] as num).toDouble(),
  userLandmarks: (json['user_landmarks'] as List<dynamic>)
      .map((e) => PoseLandmark.fromJson(e as Map<String, dynamic>))
      .toList(),
  userAngles: PoseAngles.fromJson(json['user_angles'] as Map<String, dynamic>),
  referenceLandmarks: (json['reference_landmarks'] as List<dynamic>?)
      ?.map((e) => PoseLandmark.fromJson(e as Map<String, dynamic>))
      .toList(),
  referenceAngles: json['reference_angles'] == null
      ? null
      : PoseAngles.fromJson(json['reference_angles'] as Map<String, dynamic>),
  deviationsRaw: AngleDeviations.fromJson(
    json['deviations'] as Map<String, dynamic>,
  ),
  deviationSeverity: json['deviation_severity'] as String,
  comparisonImageBase64: json['comparison_image_base64'] as String?,
  sideBySideImageBase64: json['side_by_side_image_base64'] as String?,
  userImageBase64: json['user_image_base64'] as String?,
  referenceImageBase64: json['reference_image_base64'] as String?,
  userSkeletonOnlyBase64: json['user_skeleton_only_base64'] as String?,
  referenceSkeletonOnlyBase64:
      json['reference_skeleton_only_base64'] as String?,
  referenceSilhouetteBase64: json['reference_silhouette_base64'] as String?,
  referenceSilhouetteWithSkeletonBase64:
      json['reference_silhouette_with_skeleton_base64'] as String?,
  comparisonWithSilhouetteBase64:
      json['comparison_with_silhouette_base64'] as String?,
  referenceHorizontalOffsetPercent:
      (json['reference_horizontal_offset_percent'] as num?)?.toDouble(),
  referenceScale: (json['reference_scale'] as num?)?.toDouble(),
  proPlayerId: json['pro_player_id'] as String?,
  coachingTips: (json['coaching_tips'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  userIndividualAngles: json['user_individual_angles'] == null
      ? null
      : IndividualJointAngles.fromJson(
          json['user_individual_angles'] as Map<String, dynamic>,
        ),
  referenceIndividualAngles: json['reference_individual_angles'] == null
      ? null
      : IndividualJointAngles.fromJson(
          json['reference_individual_angles'] as Map<String, dynamic>,
        ),
  individualDeviations: json['individual_deviations'] == null
      ? null
      : IndividualJointDeviations.fromJson(
          json['individual_deviations'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$CheckpointPoseDataToJson(
  CheckpointPoseData instance,
) => <String, dynamic>{
  'checkpoint_id': instance.checkpointId,
  'checkpoint_name': instance.checkpointName,
  'frame_number': instance.frameNumber,
  'timestamp_seconds': instance.timestampSeconds,
  'user_landmarks': instance.userLandmarks.map((e) => e.toJson()).toList(),
  'user_angles': instance.userAngles.toJson(),
  'reference_landmarks': instance.referenceLandmarks
      ?.map((e) => e.toJson())
      .toList(),
  'reference_angles': instance.referenceAngles?.toJson(),
  'deviations': instance.deviationsRaw.toJson(),
  'deviation_severity': instance.deviationSeverity,
  'comparison_image_base64': instance.comparisonImageBase64,
  'side_by_side_image_base64': instance.sideBySideImageBase64,
  'user_image_base64': instance.userImageBase64,
  'reference_image_base64': instance.referenceImageBase64,
  'user_skeleton_only_base64': instance.userSkeletonOnlyBase64,
  'reference_skeleton_only_base64': instance.referenceSkeletonOnlyBase64,
  'reference_silhouette_base64': instance.referenceSilhouetteBase64,
  'reference_silhouette_with_skeleton_base64':
      instance.referenceSilhouetteWithSkeletonBase64,
  'comparison_with_silhouette_base64': instance.comparisonWithSilhouetteBase64,
  'reference_horizontal_offset_percent':
      instance.referenceHorizontalOffsetPercent,
  'reference_scale': instance.referenceScale,
  'pro_player_id': instance.proPlayerId,
  'coaching_tips': instance.coachingTips,
  'user_individual_angles': instance.userIndividualAngles?.toJson(),
  'reference_individual_angles': instance.referenceIndividualAngles?.toJson(),
  'individual_deviations': instance.individualDeviations?.toJson(),
};

PoseLandmark _$PoseLandmarkFromJson(Map<String, dynamic> json) => PoseLandmark(
  name: json['name'] as String,
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  z: (json['z'] as num).toDouble(),
  visibility: (json['visibility'] as num).toDouble(),
);

Map<String, dynamic> _$PoseLandmarkToJson(PoseLandmark instance) =>
    <String, dynamic>{
      'name': instance.name,
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
      'visibility': instance.visibility,
    };

PoseAngles _$PoseAnglesFromJson(Map<String, dynamic> json) => PoseAngles(
  shoulderRotation: (json['shoulder_rotation'] as num?)?.toDouble(),
  elbowAngle: (json['elbow_angle'] as num?)?.toDouble(),
  hipRotation: (json['hip_rotation'] as num?)?.toDouble(),
  kneeBend: (json['knee_bend'] as num?)?.toDouble(),
  spineTilt: (json['spine_tilt'] as num?)?.toDouble(),
  wristAngle: (json['wrist_angle'] as num?)?.toDouble(),
);

Map<String, dynamic> _$PoseAnglesToJson(PoseAngles instance) =>
    <String, dynamic>{
      'shoulder_rotation': instance.shoulderRotation,
      'elbow_angle': instance.elbowAngle,
      'hip_rotation': instance.hipRotation,
      'knee_bend': instance.kneeBend,
      'spine_tilt': instance.spineTilt,
      'wrist_angle': instance.wristAngle,
    };

IndividualJointAngles _$IndividualJointAnglesFromJson(
  Map<String, dynamic> json,
) => IndividualJointAngles(
  leftKneeBendAngle: (json['left_knee_bend_angle'] as num?)?.toDouble(),
  rightKneeBendAngle: (json['right_knee_bend_angle'] as num?)?.toDouble(),
  leftElbowFlexionAngle: (json['left_elbow_flexion_angle'] as num?)?.toDouble(),
  rightElbowFlexionAngle: (json['right_elbow_flexion_angle'] as num?)
      ?.toDouble(),
  leftShoulderAbductionAngle: (json['left_shoulder_abduction_angle'] as num?)
      ?.toDouble(),
  rightShoulderAbductionAngle: (json['right_shoulder_abduction_angle'] as num?)
      ?.toDouble(),
  leftWristExtensionAngle: (json['left_wrist_extension_angle'] as num?)
      ?.toDouble(),
  rightWristExtensionAngle: (json['right_wrist_extension_angle'] as num?)
      ?.toDouble(),
  leftHipFlexionAngle: (json['left_hip_flexion_angle'] as num?)?.toDouble(),
  rightHipFlexionAngle: (json['right_hip_flexion_angle'] as num?)?.toDouble(),
  leftAnkleAngle: (json['left_ankle_angle'] as num?)?.toDouble(),
  rightAnkleAngle: (json['right_ankle_angle'] as num?)?.toDouble(),
);

Map<String, dynamic> _$IndividualJointAnglesToJson(
  IndividualJointAngles instance,
) => <String, dynamic>{
  'left_knee_bend_angle': instance.leftKneeBendAngle,
  'right_knee_bend_angle': instance.rightKneeBendAngle,
  'left_elbow_flexion_angle': instance.leftElbowFlexionAngle,
  'right_elbow_flexion_angle': instance.rightElbowFlexionAngle,
  'left_shoulder_abduction_angle': instance.leftShoulderAbductionAngle,
  'right_shoulder_abduction_angle': instance.rightShoulderAbductionAngle,
  'left_wrist_extension_angle': instance.leftWristExtensionAngle,
  'right_wrist_extension_angle': instance.rightWristExtensionAngle,
  'left_hip_flexion_angle': instance.leftHipFlexionAngle,
  'right_hip_flexion_angle': instance.rightHipFlexionAngle,
  'left_ankle_angle': instance.leftAnkleAngle,
  'right_ankle_angle': instance.rightAnkleAngle,
};

IndividualJointDeviations _$IndividualJointDeviationsFromJson(
  Map<String, dynamic> json,
) => IndividualJointDeviations(
  leftKneeBendAngle: (json['left_knee_bend_angle'] as num?)?.toDouble(),
  rightKneeBendAngle: (json['right_knee_bend_angle'] as num?)?.toDouble(),
  leftElbowFlexionAngle: (json['left_elbow_flexion_angle'] as num?)?.toDouble(),
  rightElbowFlexionAngle: (json['right_elbow_flexion_angle'] as num?)
      ?.toDouble(),
  leftShoulderAbductionAngle: (json['left_shoulder_abduction_angle'] as num?)
      ?.toDouble(),
  rightShoulderAbductionAngle: (json['right_shoulder_abduction_angle'] as num?)
      ?.toDouble(),
  leftWristExtensionAngle: (json['left_wrist_extension_angle'] as num?)
      ?.toDouble(),
  rightWristExtensionAngle: (json['right_wrist_extension_angle'] as num?)
      ?.toDouble(),
  leftHipFlexionAngle: (json['left_hip_flexion_angle'] as num?)?.toDouble(),
  rightHipFlexionAngle: (json['right_hip_flexion_angle'] as num?)?.toDouble(),
  leftAnkleAngle: (json['left_ankle_angle'] as num?)?.toDouble(),
  rightAnkleAngle: (json['right_ankle_angle'] as num?)?.toDouble(),
);

Map<String, dynamic> _$IndividualJointDeviationsToJson(
  IndividualJointDeviations instance,
) => <String, dynamic>{
  'left_knee_bend_angle': instance.leftKneeBendAngle,
  'right_knee_bend_angle': instance.rightKneeBendAngle,
  'left_elbow_flexion_angle': instance.leftElbowFlexionAngle,
  'right_elbow_flexion_angle': instance.rightElbowFlexionAngle,
  'left_shoulder_abduction_angle': instance.leftShoulderAbductionAngle,
  'right_shoulder_abduction_angle': instance.rightShoulderAbductionAngle,
  'left_wrist_extension_angle': instance.leftWristExtensionAngle,
  'right_wrist_extension_angle': instance.rightWristExtensionAngle,
  'left_hip_flexion_angle': instance.leftHipFlexionAngle,
  'right_hip_flexion_angle': instance.rightHipFlexionAngle,
  'left_ankle_angle': instance.leftAnkleAngle,
  'right_ankle_angle': instance.rightAnkleAngle,
};

AngleDeviations _$AngleDeviationsFromJson(Map<String, dynamic> json) =>
    AngleDeviations(
      shoulderRotation: (json['shoulder_rotation'] as num?)?.toDouble(),
      elbowAngle: (json['elbow_angle'] as num?)?.toDouble(),
      hipRotation: (json['hip_rotation'] as num?)?.toDouble(),
      kneeBend: (json['knee_bend'] as num?)?.toDouble(),
      spineTilt: (json['spine_tilt'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AngleDeviationsToJson(AngleDeviations instance) =>
    <String, dynamic>{
      'shoulder_rotation': instance.shoulderRotation,
      'elbow_angle': instance.elbowAngle,
      'hip_rotation': instance.hipRotation,
      'knee_bend': instance.kneeBend,
      'spine_tilt': instance.spineTilt,
    };

FramePoseData _$FramePoseDataFromJson(Map<String, dynamic> json) =>
    FramePoseData(
      frameNumber: (json['frame_number'] as num).toInt(),
      timestampSeconds: (json['timestamp_seconds'] as num).toDouble(),
      landmarks: (json['landmarks'] as List<dynamic>)
          .map((e) => PoseLandmark.fromJson(e as Map<String, dynamic>))
          .toList(),
      thumbnailBase64: json['thumbnail_base64'] as String,
      isCheckpoint: json['is_checkpoint'] as bool,
      checkpointId: json['checkpoint_id'] as String?,
    );

Map<String, dynamic> _$FramePoseDataToJson(FramePoseData instance) =>
    <String, dynamic>{
      'frame_number': instance.frameNumber,
      'timestamp_seconds': instance.timestampSeconds,
      'landmarks': instance.landmarks.map((e) => e.toJson()).toList(),
      'thumbnail_base64': instance.thumbnailBase64,
      'is_checkpoint': instance.isCheckpoint,
      'checkpoint_id': instance.checkpointId,
    };
