// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pose_analysis_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PoseAnalysisResponse _$PoseAnalysisResponseFromJson(
  Map json,
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
  returnedVideoAspectRatio: (json['returned_video_aspect_ratio'] as num?)
      ?.toDouble(),
  videoDurationSeconds: (json['video_duration_seconds'] as num).toDouble(),
  totalFrames: (json['total_frames'] as num).toInt(),
  checkpoints: (json['checkpoints'] as List<dynamic>)
      .map(
        (e) => CheckpointPoseData.fromJson(Map<String, dynamic>.from(e as Map)),
      )
      .toList(),
  framePoses: (json['frame_poses'] as List<dynamic>)
      .map((e) => FramePoseData.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  overallFormScore: (json['overall_form_score'] as num?)?.toInt(),
  errorMessage: json['error_message'] as String?,
  roundThumbnailBase64: json['round_thumbnail_base64'] as String?,
  videoUrl: json['video_url'] as String?,
  videoStoragePath: json['video_storage_path'] as String?,
  skeletonVideoUrl: json['skeleton_video_url'] as String?,
  skeletonOnlyVideoUrl: json['skeleton_only_video_url'] as String?,
  videoSyncMetadata: json['video_sync_metadata'] == null
      ? null
      : VideoSyncMetadata.fromJson(
          Map<String, dynamic>.from(json['video_sync_metadata'] as Map),
        ),
  proVideoReference: json['pro_video_reference'] as String?,
  detectedHandedness: _handednessFromJson(
    json['detected_handedness'] as String?,
  ),
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
  'returned_video_aspect_ratio': instance.returnedVideoAspectRatio,
  'video_duration_seconds': instance.videoDurationSeconds,
  'total_frames': instance.totalFrames,
  'checkpoints': instance.checkpoints.map((e) => e.toJson()).toList(),
  'frame_poses': instance.framePoses.map((e) => e.toJson()).toList(),
  'overall_form_score': instance.overallFormScore,
  'error_message': instance.errorMessage,
  'round_thumbnail_base64': instance.roundThumbnailBase64,
  'video_url': instance.videoUrl,
  'video_storage_path': instance.videoStoragePath,
  'skeleton_video_url': instance.skeletonVideoUrl,
  'skeleton_only_video_url': instance.skeletonOnlyVideoUrl,
  'video_sync_metadata': instance.videoSyncMetadata?.toJson(),
  'pro_video_reference': instance.proVideoReference,
  'detected_handedness': _$HandednessEnumMap[instance.detectedHandedness],
};

const _$CameraAngleEnumMap = {
  CameraAngle.side: 'side',
  CameraAngle.rear: 'rear',
};

const _$VideoOrientationEnumMap = {
  VideoOrientation.portrait: 'portrait',
  VideoOrientation.landscape: 'landscape',
};

const _$HandednessEnumMap = {
  Handedness.left: 'left',
  Handedness.right: 'right',
};

CheckpointPoseData _$CheckpointPoseDataFromJson(Map json) => CheckpointPoseData(
  checkpointId: json['checkpoint_id'] as String,
  checkpointName: json['checkpoint_name'] as String,
  frameNumber: (json['frame_number'] as num).toInt(),
  timestampSeconds: (json['timestamp_seconds'] as num).toDouble(),
  userLandmarks: (json['user_landmarks'] as List<dynamic>)
      .map((e) => PoseLandmark.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  userAngles: PoseAngles.fromJson(
    Map<String, dynamic>.from(json['user_angles'] as Map),
  ),
  referenceLandmarks: (json['reference_landmarks'] as List<dynamic>?)
      ?.map((e) => PoseLandmark.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  referenceAngles: json['reference_angles'] == null
      ? null
      : PoseAngles.fromJson(
          Map<String, dynamic>.from(json['reference_angles'] as Map),
        ),
  deviationsRaw: AngleDeviations.fromJson(
    Map<String, dynamic>.from(json['deviations'] as Map),
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
          Map<String, dynamic>.from(json['user_individual_angles'] as Map),
        ),
  referenceIndividualAngles: json['reference_individual_angles'] == null
      ? null
      : IndividualJointAngles.fromJson(
          Map<String, dynamic>.from(json['reference_individual_angles'] as Map),
        ),
  individualDeviations: json['individual_deviations'] == null
      ? null
      : IndividualJointDeviations.fromJson(
          Map<String, dynamic>.from(json['individual_deviations'] as Map),
        ),
  userV2Measurements: json['user_v2_measurements'] == null
      ? null
      : V2SideMeasurements.fromJson(
          Map<String, dynamic>.from(json['user_v2_measurements'] as Map),
        ),
  referenceV2Measurements: json['reference_v2_measurements'] == null
      ? null
      : V2SideMeasurements.fromJson(
          Map<String, dynamic>.from(json['reference_v2_measurements'] as Map),
        ),
  v2MeasurementDeviations: json['v2_measurement_deviations'] == null
      ? null
      : V2SideMeasurements.fromJson(
          Map<String, dynamic>.from(json['v2_measurement_deviations'] as Map),
        ),
  detectedFrameNumber: (json['detected_frame_number'] as num?)?.toInt(),
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
  'user_v2_measurements': instance.userV2Measurements?.toJson(),
  'reference_v2_measurements': instance.referenceV2Measurements?.toJson(),
  'v2_measurement_deviations': instance.v2MeasurementDeviations?.toJson(),
  'detected_frame_number': instance.detectedFrameNumber,
};

PoseLandmark _$PoseLandmarkFromJson(Map json) => PoseLandmark(
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

PoseAngles _$PoseAnglesFromJson(Map json) => PoseAngles(
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
  Map json,
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
  Map json,
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

AngleDeviations _$AngleDeviationsFromJson(Map json) => AngleDeviations(
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

V2SideMeasurements _$V2SideMeasurementsFromJson(Map json) => V2SideMeasurements(
  frontKneeAngle: (json['front_knee_angle'] as num?)?.toDouble(),
  backKneeAngle: (json['back_knee_angle'] as num?)?.toDouble(),
  frontElbowAngle: (json['front_elbow_angle'] as num?)?.toDouble(),
  frontFootDirectionAngle: (json['front_foot_direction_angle'] as num?)
      ?.toDouble(),
  backFootDirectionAngle: (json['back_foot_direction_angle'] as num?)
      ?.toDouble(),
  hipRotationAngle: (json['hip_rotation_angle'] as num?)?.toDouble(),
  shoulderRotationAngle: (json['shoulder_rotation_angle'] as num?)?.toDouble(),
);

Map<String, dynamic> _$V2SideMeasurementsToJson(V2SideMeasurements instance) =>
    <String, dynamic>{
      'front_knee_angle': instance.frontKneeAngle,
      'back_knee_angle': instance.backKneeAngle,
      'front_elbow_angle': instance.frontElbowAngle,
      'front_foot_direction_angle': instance.frontFootDirectionAngle,
      'back_foot_direction_angle': instance.backFootDirectionAngle,
      'hip_rotation_angle': instance.hipRotationAngle,
      'shoulder_rotation_angle': instance.shoulderRotationAngle,
    };

FramePoseData _$FramePoseDataFromJson(Map json) => FramePoseData(
  frameNumber: (json['frame_number'] as num).toInt(),
  timestampSeconds: (json['timestamp_seconds'] as num).toDouble(),
  landmarks: (json['landmarks'] as List<dynamic>)
      .map((e) => PoseLandmark.fromJson(Map<String, dynamic>.from(e as Map)))
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
