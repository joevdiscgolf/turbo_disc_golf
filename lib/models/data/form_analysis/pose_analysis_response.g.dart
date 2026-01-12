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
  cameraAngle: json['camera_angle'] as String,
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
);

Map<String, dynamic> _$PoseAnalysisResponseToJson(
  PoseAnalysisResponse instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'status': instance.status,
  'throw_type': instance.throwType,
  'camera_angle': instance.cameraAngle,
  'video_duration_seconds': instance.videoDurationSeconds,
  'total_frames': instance.totalFrames,
  'checkpoints': instance.checkpoints.map((e) => e.toJson()).toList(),
  'frame_poses': instance.framePoses.map((e) => e.toJson()).toList(),
  'overall_form_score': instance.overallFormScore,
  'error_message': instance.errorMessage,
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
  coachingTips: (json['coaching_tips'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
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
  'coaching_tips': instance.coachingTips,
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
