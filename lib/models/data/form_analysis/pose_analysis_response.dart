import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_record_builder.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_player_models.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/video_sync_metadata.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/models/video_orientation.dart';

part 'pose_analysis_response.g.dart';

Handedness? _handednessFromJson(String? value) => Handedness.fromApiString(value);

/// Response from the Cloud Run pose analysis API
@JsonSerializable(anyMap: true, explicitToJson: true)
class PoseAnalysisResponse {
  const PoseAnalysisResponse({
    required this.sessionId,
    required this.status,
    required this.throwType,
    required this.cameraAngle,
    this.videoOrientation,
    this.videoAspectRatio,
    this.returnedVideoAspectRatio,
    required this.videoDurationSeconds,
    required this.totalFrames,
    required this.checkpoints,
    required this.framePoses,
    this.overallFormScore,
    this.errorMessage,
    this.roundThumbnailBase64,
    this.videoUrl,
    this.videoStoragePath,
    this.skeletonVideoUrl,
    this.skeletonOnlyVideoUrl,
    this.videoSyncMetadata,
    this.proVideoReference,
    this.detectedHandedness,
    this.proComparisons,
    this.defaultProId,
    this.userVideoWidth,
    this.userVideoHeight,
  });

  @JsonKey(name: 'session_id')
  final String sessionId;

  final String status;

  @JsonKey(name: 'throw_type')
  final String throwType;

  @JsonKey(name: 'camera_angle')
  final CameraAngle cameraAngle;

  @JsonKey(name: 'video_orientation')
  final VideoOrientation? videoOrientation;

  @JsonKey(name: 'video_aspect_ratio')
  final double? videoAspectRatio;

  /// Aspect ratio (width/height) of the returned processed videos
  @JsonKey(name: 'returned_video_aspect_ratio')
  final double? returnedVideoAspectRatio;

  @JsonKey(name: 'video_duration_seconds')
  final double videoDurationSeconds;

  @JsonKey(name: 'total_frames')
  final int totalFrames;

  final List<CheckpointPoseData> checkpoints;

  @JsonKey(name: 'frame_poses')
  final List<FramePoseData> framePoses;

  @JsonKey(name: 'overall_form_score')
  final int? overallFormScore;

  @JsonKey(name: 'error_message')
  final String? errorMessage;

  @JsonKey(name: 'round_thumbnail_base64')
  final String? roundThumbnailBase64;

  @JsonKey(name: 'video_url')
  final String? videoUrl;

  /// Cloud Storage path for the video (e.g., "{uid}/{session_id}.mp4")
  /// Used to generate fresh signed URLs when the original expires
  @JsonKey(name: 'video_storage_path')
  final String? videoStoragePath;

  /// URL of the skeleton-only video (user pose rendered as skeleton overlay)
  /// Used for video comparison when useSkeletonVideoInTimelinePlayer is enabled
  @JsonKey(name: 'skeleton_video_url')
  final String? skeletonVideoUrl;

  /// URL of the skeleton-only video (skeleton on black background, no video)
  @JsonKey(name: 'skeleton_only_video_url')
  final String? skeletonOnlyVideoUrl;

  @JsonKey(name: 'video_sync_metadata')
  final VideoSyncMetadata? videoSyncMetadata;

  @JsonKey(name: 'pro_video_reference')
  final String? proVideoReference;

  @JsonKey(name: 'detected_handedness', fromJson: _handednessFromJson)
  final Handedness? detectedHandedness;

  /// Multi-pro comparison data: map of pro_player_id to comparison data
  /// Only populated when enableMultiProComparison feature flag is enabled
  @JsonKey(name: 'pro_comparisons')
  final Map<String, ProComparisonPoseData>? proComparisons;

  /// Default pro player ID to show initially
  @JsonKey(name: 'default_pro_id')
  final String? defaultProId;

  /// Width of user's video in pixels (after rotation correction)
  @JsonKey(name: 'user_video_width')
  final int? userVideoWidth;

  /// Height of user's video in pixels (after rotation correction)
  @JsonKey(name: 'user_video_height')
  final int? userVideoHeight;

  /// Convert PoseAnalysisResponse to FormAnalysisRecord for storage/display.
  /// Optionally accepts topCoachingTips from external analysis results.
  FormAnalysisRecord toFormAnalysisRecord({List<String>? topCoachingTips}) {
    // Helper function to convert base64 to data URL
    String? toDataUrl(String? base64Data, String imageName) {
      if (base64Data == null) return null;
      return 'data:image/jpeg;base64,$base64Data';
    }

    // Convert checkpoints using the unified builder
    final List<CheckpointRecord> checkpointRecords = checkpoints.map((cp) {
      return CheckpointRecordBuilder.build(
        checkpoint: cp,
        imageUrlProvider: toDataUrl,
        cameraAngle: cameraAngle,
      );
    }).toList();

    // Calculate worst deviation severity from checkpoints
    final String? worstSeverity = _calculateWorstSeverity(checkpointRecords);

    // Convert pro comparisons if present
    Map<String, ProComparisonData>? convertedProComparisons;
    if (proComparisons != null) {
      convertedProComparisons = proComparisons!.map((proId, poseData) {
        final List<CheckpointRecord> proCheckpoints =
            poseData.checkpoints.map((cp) {
          return CheckpointRecordBuilder.build(
            checkpoint: cp,
            imageUrlProvider: toDataUrl,
            cameraAngle: cameraAngle,
          );
        }).toList();

        return MapEntry(
          proId,
          ProComparisonData(
            proPlayerId: poseData.proPlayerId,
            checkpoints: proCheckpoints,
            overallFormScore: poseData.overallFormScore,
          ),
        );
      });
    }

    return FormAnalysisRecord(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      uid: 'temp',
      createdAt: DateTime.now().toIso8601String(),
      throwType: throwType,
      overallFormScore: overallFormScore,
      worstDeviationSeverity: worstSeverity,
      checkpoints: checkpointRecords,
      topCoachingTips: topCoachingTips,
      cameraAngle: cameraAngle,
      videoOrientation: videoOrientation,
      videoAspectRatio: videoAspectRatio,
      returnedVideoAspectRatio: returnedVideoAspectRatio,
      videoUrl: videoUrl,
      videoStoragePath: videoStoragePath,
      skeletonVideoUrl: skeletonVideoUrl,
      skeletonOnlyVideoUrl: skeletonOnlyVideoUrl,
      detectedHandedness: detectedHandedness,
      proComparisons: convertedProComparisons,
      defaultProId: defaultProId,
      userVideoWidth: userVideoWidth,
      userVideoHeight: userVideoHeight,
    );
  }

  static String? _calculateWorstSeverity(List<CheckpointRecord> checkpoints) {
    if (checkpoints.isEmpty) return null;

    const List<String> severityOrder = [
      'good',
      'minor',
      'moderate',
      'significant',
    ];

    String? worstSeverity;
    int worstIndex = -1;

    for (final checkpoint in checkpoints) {
      final int index = severityOrder.indexOf(
        checkpoint.deviationSeverity.toLowerCase(),
      );
      if (index > worstIndex) {
        worstIndex = index;
        worstSeverity = checkpoint.deviationSeverity;
      }
    }

    return worstSeverity;
  }

  factory PoseAnalysisResponse.fromJson(Map<String, dynamic> json) =>
      _$PoseAnalysisResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PoseAnalysisResponseToJson(this);
}

/// Pose data for a detected checkpoint
@JsonSerializable(anyMap: true, explicitToJson: true)
class CheckpointPoseData {
  const CheckpointPoseData({
    required this.checkpointId,
    required this.checkpointName,
    required this.frameNumber,
    required this.timestampSeconds,
    required this.userLandmarks,
    required this.userAngles,
    this.referenceLandmarks,
    this.referenceAngles,
    required this.deviationsRaw,
    required this.deviationSeverity,
    this.comparisonImageBase64,
    this.sideBySideImageBase64,
    this.userImageBase64,
    this.referenceImageBase64,
    this.userSkeletonOnlyBase64,
    this.referenceSkeletonOnlyBase64,
    this.referenceSilhouetteBase64,
    this.referenceSilhouetteWithSkeletonBase64,
    this.comparisonWithSilhouetteBase64,
    this.proPlayerId,
    required this.coachingTips,
    this.userIndividualAngles,
    this.referenceIndividualAngles,
    this.individualDeviations,
    this.userV2Measurements,
    this.referenceV2Measurements,
    this.v2MeasurementDeviations,
    this.detectedFrameNumber,
    this.userBodyAnchor,
    this.userBodyHeightScreenPortion,
  });

  @JsonKey(name: 'checkpoint_id')
  final String checkpointId;

  @JsonKey(name: 'checkpoint_name')
  final String checkpointName;

  @JsonKey(name: 'frame_number')
  final int frameNumber;

  @JsonKey(name: 'timestamp_seconds')
  final double timestampSeconds;

  @JsonKey(name: 'user_landmarks')
  final List<PoseLandmark> userLandmarks;

  @JsonKey(name: 'user_angles')
  final PoseAngles userAngles;

  @JsonKey(name: 'reference_landmarks')
  final List<PoseLandmark>? referenceLandmarks;

  @JsonKey(name: 'reference_angles')
  final PoseAngles? referenceAngles;

  /// Raw deviations object from backend
  @JsonKey(name: 'deviations')
  final AngleDeviations deviationsRaw;

  @JsonKey(name: 'deviation_severity')
  final String deviationSeverity;

  @JsonKey(name: 'comparison_image_base64')
  final String? comparisonImageBase64;

  @JsonKey(name: 'side_by_side_image_base64')
  final String? sideBySideImageBase64;

  @JsonKey(name: 'user_image_base64')
  final String? userImageBase64;

  @JsonKey(name: 'reference_image_base64')
  final String? referenceImageBase64;

  @JsonKey(name: 'user_skeleton_only_base64')
  final String? userSkeletonOnlyBase64;

  @JsonKey(name: 'reference_skeleton_only_base64')
  final String? referenceSkeletonOnlyBase64;

  @JsonKey(name: 'reference_silhouette_base64')
  final String? referenceSilhouetteBase64;

  @JsonKey(name: 'reference_silhouette_with_skeleton_base64')
  final String? referenceSilhouetteWithSkeletonBase64;

  @JsonKey(name: 'comparison_with_silhouette_base64')
  final String? comparisonWithSilhouetteBase64;

  /// Pro player ID for reference images (e.g., "paul_mcbeth")
  /// Used to load reference from bundled assets, cache, or cloud storage
  @JsonKey(name: 'pro_player_id')
  final String? proPlayerId;

  @JsonKey(name: 'coaching_tips')
  final List<String> coachingTips;

  /// Individual joint angles for user (left/right body parts)
  @JsonKey(name: 'user_individual_angles')
  final IndividualJointAngles? userIndividualAngles;

  /// Individual joint angles for reference/pro (left/right body parts)
  @JsonKey(name: 'reference_individual_angles')
  final IndividualJointAngles? referenceIndividualAngles;

  /// Individual joint deviations (user - reference)
  @JsonKey(name: 'individual_deviations')
  final IndividualJointDeviations? individualDeviations;

  /// V2 measurements by camera angle for user
  @JsonKey(name: 'user_v2_measurements')
  final V2MeasurementsByAngle? userV2Measurements;

  /// V2 measurements by camera angle for reference/pro
  @JsonKey(name: 'reference_v2_measurements')
  final V2MeasurementsByAngle? referenceV2Measurements;

  /// V2 measurement deviations by camera angle (user - reference)
  @JsonKey(name: 'v2_measurement_deviations')
  final V2MeasurementsByAngle? v2MeasurementDeviations;

  /// Frame number detected by the backend for this checkpoint
  @JsonKey(name: 'detected_frame_number')
  final int? detectedFrameNumber;

  /// User body anchor point (hip center) for alignment with pro overlays
  @JsonKey(name: 'user_body_anchor')
  final UserBodyAnchor? userBodyAnchor;

  /// User's body height (excluding head) as a fraction of the video frame height.
  /// Measured from neck to ankles at this specific checkpoint.
  /// e.g., 0.75 means the user's body takes up 75% of the frame height.
  @JsonKey(name: 'user_body_height_screen_portion')
  final double? userBodyHeightScreenPortion;

  /// Get checkpoint description based on checkpoint ID
  String get checkpointDescription {
    switch (checkpointId) {
      case 'heisman':
        return 'Player has just stepped onto their back leg on the ball of their foot. Front leg has started to drift in front of their back leg. They are on their back leg but have not started to coil yet, and their elbow is still roughly at 90 degrees and neutral.';
      case 'loaded':
        return 'The player\'s front (plant) foot is about to touch the ground, and they are fully coiled, and their back leg is bowed out.';
      case 'magic':
        return 'Disc is just starting to move forward, both knees are bent inward, in an athletic position.';
      case 'pro':
        return 'The pull-through is well in progress, and the elbow is at a 90-degree angle, and the back leg is bent at almost a 90-degree angle, and the front leg is pretty straight.';
      default:
        return checkpointName;
    }
  }

  /// Convert raw deviations object to a list for UI display
  List<AngleDeviation> get deviations {
    final List<AngleDeviation> result = [];

    if (deviationsRaw.shoulderRotation != null &&
        userAngles.shoulderRotation != null) {
      result.add(
        AngleDeviation(
          angleName: 'shoulder_rotation',
          userValue: userAngles.shoulderRotation!,
          referenceValue: referenceAngles?.shoulderRotation,
          deviation: deviationsRaw.shoulderRotation,
          withinTolerance: (deviationsRaw.shoulderRotation?.abs() ?? 0) <= 15,
        ),
      );
    }

    if (deviationsRaw.elbowAngle != null && userAngles.elbowAngle != null) {
      result.add(
        AngleDeviation(
          angleName: 'elbow_angle',
          userValue: userAngles.elbowAngle!,
          referenceValue: referenceAngles?.elbowAngle,
          deviation: deviationsRaw.elbowAngle,
          withinTolerance: (deviationsRaw.elbowAngle?.abs() ?? 0) <= 15,
        ),
      );
    }

    if (deviationsRaw.hipRotation != null && userAngles.hipRotation != null) {
      result.add(
        AngleDeviation(
          angleName: 'hip_rotation',
          userValue: userAngles.hipRotation!,
          referenceValue: referenceAngles?.hipRotation,
          deviation: deviationsRaw.hipRotation,
          withinTolerance: (deviationsRaw.hipRotation?.abs() ?? 0) <= 15,
        ),
      );
    }

    if (deviationsRaw.kneeBend != null && userAngles.kneeBend != null) {
      result.add(
        AngleDeviation(
          angleName: 'knee_bend',
          userValue: userAngles.kneeBend!,
          referenceValue: referenceAngles?.kneeBend,
          deviation: deviationsRaw.kneeBend,
          withinTolerance: (deviationsRaw.kneeBend?.abs() ?? 0) <= 15,
        ),
      );
    }

    if (deviationsRaw.spineTilt != null && userAngles.spineTilt != null) {
      result.add(
        AngleDeviation(
          angleName: 'spine_tilt',
          userValue: userAngles.spineTilt!,
          referenceValue: referenceAngles?.spineTilt,
          deviation: deviationsRaw.spineTilt,
          withinTolerance: (deviationsRaw.spineTilt?.abs() ?? 0) <= 15,
        ),
      );
    }

    return result;
  }

  factory CheckpointPoseData.fromJson(Map<String, dynamic> json) =>
      _$CheckpointPoseDataFromJson(json);
  Map<String, dynamic> toJson() => _$CheckpointPoseDataToJson(this);
}

/// A single pose landmark
@JsonSerializable(anyMap: true, explicitToJson: true)
class PoseLandmark {
  const PoseLandmark({
    required this.name,
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });

  final String name;
  final double x;
  final double y;
  final double z;
  final double visibility;

  factory PoseLandmark.fromJson(Map<String, dynamic> json) =>
      _$PoseLandmarkFromJson(json);
  Map<String, dynamic> toJson() => _$PoseLandmarkToJson(this);
}

/// Calculated pose angles (matches backend PoseAngles)
@JsonSerializable(anyMap: true, explicitToJson: true)
class PoseAngles {
  const PoseAngles({
    this.shoulderRotation,
    this.elbowAngle,
    this.hipRotation,
    this.kneeBend,
    this.spineTilt,
    this.wristAngle,
  });

  @JsonKey(name: 'shoulder_rotation')
  final double? shoulderRotation;

  @JsonKey(name: 'elbow_angle')
  final double? elbowAngle;

  @JsonKey(name: 'hip_rotation')
  final double? hipRotation;

  @JsonKey(name: 'knee_bend')
  final double? kneeBend;

  @JsonKey(name: 'spine_tilt')
  final double? spineTilt;

  @JsonKey(name: 'wrist_angle')
  final double? wristAngle;

  factory PoseAngles.fromJson(Map<String, dynamic> json) =>
      _$PoseAnglesFromJson(json);
  Map<String, dynamic> toJson() => _$PoseAnglesToJson(this);
}

/// Individual joint angles for left/right body parts
@JsonSerializable(anyMap: true, explicitToJson: true)
class IndividualJointAngles {
  const IndividualJointAngles({
    this.leftKneeBendAngle,
    this.rightKneeBendAngle,
    this.leftElbowFlexionAngle,
    this.rightElbowFlexionAngle,
    this.leftShoulderAbductionAngle,
    this.rightShoulderAbductionAngle,
    this.leftWristExtensionAngle,
    this.rightWristExtensionAngle,
    this.leftHipFlexionAngle,
    this.rightHipFlexionAngle,
    this.leftAnkleAngle,
    this.rightAnkleAngle,
  });

  @JsonKey(name: 'left_knee_bend_angle')
  final double? leftKneeBendAngle;

  @JsonKey(name: 'right_knee_bend_angle')
  final double? rightKneeBendAngle;

  @JsonKey(name: 'left_elbow_flexion_angle')
  final double? leftElbowFlexionAngle;

  @JsonKey(name: 'right_elbow_flexion_angle')
  final double? rightElbowFlexionAngle;

  @JsonKey(name: 'left_shoulder_abduction_angle')
  final double? leftShoulderAbductionAngle;

  @JsonKey(name: 'right_shoulder_abduction_angle')
  final double? rightShoulderAbductionAngle;

  @JsonKey(name: 'left_wrist_extension_angle')
  final double? leftWristExtensionAngle;

  @JsonKey(name: 'right_wrist_extension_angle')
  final double? rightWristExtensionAngle;

  @JsonKey(name: 'left_hip_flexion_angle')
  final double? leftHipFlexionAngle;

  @JsonKey(name: 'right_hip_flexion_angle')
  final double? rightHipFlexionAngle;

  @JsonKey(name: 'left_ankle_angle')
  final double? leftAnkleAngle;

  @JsonKey(name: 'right_ankle_angle')
  final double? rightAnkleAngle;

  factory IndividualJointAngles.fromJson(Map<String, dynamic> json) =>
      _$IndividualJointAnglesFromJson(json);
  Map<String, dynamic> toJson() => _$IndividualJointAnglesToJson(this);
}

/// Individual joint deviations for left/right body parts
@JsonSerializable(anyMap: true, explicitToJson: true)
class IndividualJointDeviations {
  const IndividualJointDeviations({
    this.leftKneeBendAngle,
    this.rightKneeBendAngle,
    this.leftElbowFlexionAngle,
    this.rightElbowFlexionAngle,
    this.leftShoulderAbductionAngle,
    this.rightShoulderAbductionAngle,
    this.leftWristExtensionAngle,
    this.rightWristExtensionAngle,
    this.leftHipFlexionAngle,
    this.rightHipFlexionAngle,
    this.leftAnkleAngle,
    this.rightAnkleAngle,
  });

  @JsonKey(name: 'left_knee_bend_angle')
  final double? leftKneeBendAngle;

  @JsonKey(name: 'right_knee_bend_angle')
  final double? rightKneeBendAngle;

  @JsonKey(name: 'left_elbow_flexion_angle')
  final double? leftElbowFlexionAngle;

  @JsonKey(name: 'right_elbow_flexion_angle')
  final double? rightElbowFlexionAngle;

  @JsonKey(name: 'left_shoulder_abduction_angle')
  final double? leftShoulderAbductionAngle;

  @JsonKey(name: 'right_shoulder_abduction_angle')
  final double? rightShoulderAbductionAngle;

  @JsonKey(name: 'left_wrist_extension_angle')
  final double? leftWristExtensionAngle;

  @JsonKey(name: 'right_wrist_extension_angle')
  final double? rightWristExtensionAngle;

  @JsonKey(name: 'left_hip_flexion_angle')
  final double? leftHipFlexionAngle;

  @JsonKey(name: 'right_hip_flexion_angle')
  final double? rightHipFlexionAngle;

  @JsonKey(name: 'left_ankle_angle')
  final double? leftAnkleAngle;

  @JsonKey(name: 'right_ankle_angle')
  final double? rightAnkleAngle;

  factory IndividualJointDeviations.fromJson(Map<String, dynamic> json) =>
      _$IndividualJointDeviationsFromJson(json);
  Map<String, dynamic> toJson() => _$IndividualJointDeviationsToJson(this);
}

/// Angle deviations from reference (matches backend AngleDeviations)
@JsonSerializable(anyMap: true, explicitToJson: true)
class AngleDeviations {
  const AngleDeviations({
    this.shoulderRotation,
    this.elbowAngle,
    this.hipRotation,
    this.kneeBend,
    this.spineTilt,
  });

  @JsonKey(name: 'shoulder_rotation')
  final double? shoulderRotation;

  @JsonKey(name: 'elbow_angle')
  final double? elbowAngle;

  @JsonKey(name: 'hip_rotation')
  final double? hipRotation;

  @JsonKey(name: 'knee_bend')
  final double? kneeBend;

  @JsonKey(name: 'spine_tilt')
  final double? spineTilt;

  factory AngleDeviations.fromJson(Map<String, dynamic> json) =>
      _$AngleDeviationsFromJson(json);
  Map<String, dynamic> toJson() => _$AngleDeviationsToJson(this);
}

/// V2 side-view measurements for form analysis
@JsonSerializable(anyMap: true, explicitToJson: true)
class V2SideMeasurements {
  const V2SideMeasurements({
    this.frontKneeAngle,
    this.backKneeAngle,
    this.frontElbowAngle,
    this.frontFootDirectionAngle,
    this.backFootDirectionAngle,
    this.hipRotationAngle,
    this.shoulderRotationAngle,
  });

  @JsonKey(name: 'front_knee_angle')
  final double? frontKneeAngle;

  @JsonKey(name: 'back_knee_angle')
  final double? backKneeAngle;

  @JsonKey(name: 'front_elbow_angle')
  final double? frontElbowAngle;

  @JsonKey(name: 'front_foot_direction_angle')
  final double? frontFootDirectionAngle;

  @JsonKey(name: 'back_foot_direction_angle')
  final double? backFootDirectionAngle;

  @JsonKey(name: 'hip_rotation_angle')
  final double? hipRotationAngle;

  @JsonKey(name: 'shoulder_rotation_angle')
  final double? shoulderRotationAngle;

  factory V2SideMeasurements.fromJson(Map<String, dynamic> json) =>
      _$V2SideMeasurementsFromJson(json);
  Map<String, dynamic> toJson() => _$V2SideMeasurementsToJson(this);
}

/// V2 rear-view measurements for form analysis
@JsonSerializable(anyMap: true, explicitToJson: true)
class V2RearMeasurements {
  const V2RearMeasurements({
    this.frontKneeAngle,
    this.backKneeAngle,
    this.frontElbowAngle,
    this.frontFootDirectionAngle,
    this.backFootDirectionAngle,
    this.hipRotationAngle,
    this.shoulderRotationAngle,
  });

  @JsonKey(name: 'front_knee_angle')
  final double? frontKneeAngle;

  @JsonKey(name: 'back_knee_angle')
  final double? backKneeAngle;

  @JsonKey(name: 'front_elbow_angle')
  final double? frontElbowAngle;

  @JsonKey(name: 'front_foot_direction_angle')
  final double? frontFootDirectionAngle;

  @JsonKey(name: 'back_foot_direction_angle')
  final double? backFootDirectionAngle;

  @JsonKey(name: 'hip_rotation_angle')
  final double? hipRotationAngle;

  @JsonKey(name: 'shoulder_rotation_angle')
  final double? shoulderRotationAngle;

  factory V2RearMeasurements.fromJson(Map<String, dynamic> json) =>
      _$V2RearMeasurementsFromJson(json);
  Map<String, dynamic> toJson() => _$V2RearMeasurementsToJson(this);
}

/// Container for V2 measurements by camera angle
@JsonSerializable(anyMap: true, explicitToJson: true)
class V2MeasurementsByAngle {
  const V2MeasurementsByAngle({
    this.side,
    this.rear,
    this.front,
  });

  /// Side-view measurements
  final V2SideMeasurements? side;

  /// Rear-view measurements
  final V2RearMeasurements? rear;

  /// Front-view measurements (reserved for future use)
  final Map<String, dynamic>? front;

  factory V2MeasurementsByAngle.fromJson(Map<String, dynamic> json) =>
      _$V2MeasurementsByAngleFromJson(json);
  Map<String, dynamic> toJson() => _$V2MeasurementsByAngleToJson(this);
}

/// Single angle deviation for UI display
class AngleDeviation {
  const AngleDeviation({
    required this.angleName,
    required this.userValue,
    this.referenceValue,
    this.deviation,
    required this.withinTolerance,
  });

  final String angleName;
  final double userValue;
  final double? referenceValue;
  final double? deviation;
  final bool withinTolerance;
}

/// User body anchor point for alignment with pro reference overlays
@JsonSerializable(anyMap: true, explicitToJson: true)
class UserBodyAnchor {
  const UserBodyAnchor({
    required this.name,
    required this.x,
    required this.y,
  });

  /// Anchor point name (always "hip_center")
  final String name;

  /// Normalized x position (0-1)
  final double x;

  /// Normalized y position (0-1)
  final double y;

  factory UserBodyAnchor.fromJson(Map<String, dynamic> json) =>
      _$UserBodyAnchorFromJson(json);
  Map<String, dynamic> toJson() => _$UserBodyAnchorToJson(this);
}

/// Frame pose data for video scrubber
@JsonSerializable(anyMap: true, explicitToJson: true)
class FramePoseData {
  const FramePoseData({
    required this.frameNumber,
    required this.timestampSeconds,
    required this.landmarks,
    required this.thumbnailBase64,
    required this.isCheckpoint,
    this.checkpointId,
  });

  @JsonKey(name: 'frame_number')
  final int frameNumber;

  @JsonKey(name: 'timestamp_seconds')
  final double timestampSeconds;

  final List<PoseLandmark> landmarks;

  @JsonKey(name: 'thumbnail_base64')
  final String thumbnailBase64;

  @JsonKey(name: 'is_checkpoint')
  final bool isCheckpoint;

  @JsonKey(name: 'checkpoint_id')
  final String? checkpointId;

  factory FramePoseData.fromJson(Map<String, dynamic> json) =>
      _$FramePoseDataFromJson(json);
  Map<String, dynamic> toJson() => _$FramePoseDataToJson(this);
}
