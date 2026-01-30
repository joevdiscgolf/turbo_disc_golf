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
      videoOrientation: $enumDecodeNullable(
        _$VideoOrientationEnumMap,
        json['video_orientation'],
      ),
      videoAspectRatio: (json['video_aspect_ratio'] as num?)?.toDouble(),
      returnedVideoAspectRatio: (json['returned_video_aspect_ratio'] as num?)
          ?.toDouble(),
      videoUrl: json['video_url'] as String?,
      videoStoragePath: json['video_storage_path'] as String?,
      skeletonVideoUrl: json['skeleton_video_url'] as String?,
      skeletonOnlyVideoUrl: json['skeleton_only_video_url'] as String?,
      videoSyncMetadata: json['video_sync_metadata'] == null
          ? null
          : VideoSyncMetadata.fromJson(
              json['video_sync_metadata'] as Map<String, dynamic>,
            ),
      detectedHandedness: $enumDecodeNullable(
        _$HandednessEnumMap,
        json['detected_handedness'],
      ),
      proComparisons: (json['pro_comparisons'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, ProComparisonData.fromJson(e as Map<String, dynamic>)),
      ),
      defaultProId: json['default_pro_id'] as String?,
      userVideoWidth: (json['user_video_width'] as num?)?.toInt(),
      userVideoHeight: (json['user_video_height'] as num?)?.toInt(),
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
      'video_orientation': _$VideoOrientationEnumMap[instance.videoOrientation],
      'video_aspect_ratio': instance.videoAspectRatio,
      'returned_video_aspect_ratio': instance.returnedVideoAspectRatio,
      'video_url': instance.videoUrl,
      'video_storage_path': instance.videoStoragePath,
      'skeleton_video_url': instance.skeletonVideoUrl,
      'skeleton_only_video_url': instance.skeletonOnlyVideoUrl,
      'video_sync_metadata': instance.videoSyncMetadata?.toJson(),
      'detected_handedness': _$HandednessEnumMap[instance.detectedHandedness],
      'pro_comparisons': instance.proComparisons?.map(
        (k, e) => MapEntry(k, e.toJson()),
      ),
      'default_pro_id': instance.defaultProId,
      'user_video_width': instance.userVideoWidth,
      'user_video_height': instance.userVideoHeight,
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

CheckpointRecord _$CheckpointRecordFromJson(Map<String, dynamic> json) =>
    CheckpointRecord(
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
      detectedFrameNumber: (json['detected_frame_number'] as num?)?.toInt(),
      timestampSeconds: (json['timestamp_seconds'] as num?)?.toDouble(),
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
      userV2Measurements: json['user_v2_measurements'] == null
          ? null
          : V2SideMeasurements.fromJson(
              json['user_v2_measurements'] as Map<String, dynamic>,
            ),
      referenceV2Measurements: json['reference_v2_measurements'] == null
          ? null
          : V2SideMeasurements.fromJson(
              json['reference_v2_measurements'] as Map<String, dynamic>,
            ),
      v2MeasurementDeviations: json['v2_measurement_deviations'] == null
          ? null
          : V2SideMeasurements.fromJson(
              json['v2_measurement_deviations'] as Map<String, dynamic>,
            ),
      userLandmarks: (json['user_landmarks'] as List<dynamic>?)
          ?.map((e) => PoseLandmark.fromJson(e as Map<String, dynamic>))
          .toList(),
      referenceLandmarks: (json['reference_landmarks'] as List<dynamic>?)
          ?.map((e) => PoseLandmark.fromJson(e as Map<String, dynamic>))
          .toList(),
      userBodyAnchor: json['user_body_anchor'] == null
          ? null
          : UserBodyAnchor.fromJson(
              json['user_body_anchor'] as Map<String, dynamic>,
            ),
      userTorsoHeightNormalized: (json['user_torso_height_normalized'] as num?)
          ?.toDouble(),
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
  'detected_frame_number': instance.detectedFrameNumber,
  'timestamp_seconds': instance.timestampSeconds,
  'user_individual_angles': instance.userIndividualAngles?.toJson(),
  'reference_individual_angles': instance.referenceIndividualAngles?.toJson(),
  'individual_deviations': instance.individualDeviations?.toJson(),
  'user_v2_measurements': instance.userV2Measurements?.toJson(),
  'reference_v2_measurements': instance.referenceV2Measurements?.toJson(),
  'v2_measurement_deviations': instance.v2MeasurementDeviations?.toJson(),
  'user_landmarks': instance.userLandmarks?.map((e) => e.toJson()).toList(),
  'reference_landmarks': instance.referenceLandmarks
      ?.map((e) => e.toJson())
      .toList(),
  'user_body_anchor': instance.userBodyAnchor?.toJson(),
  'user_torso_height_normalized': instance.userTorsoHeightNormalized,
};
