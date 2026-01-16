import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/video_sync_metadata.dart';
import 'package:turbo_disc_golf/models/video_orientation.dart';

part 'form_analysis_record.g.dart';

/// Record of a form analysis saved to Firestore.
/// Contains metadata and image URLs (images stored in Cloud Storage).
@JsonSerializable(explicitToJson: true)
class FormAnalysisRecord {
  const FormAnalysisRecord({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.throwType,
    required this.checkpoints,
    this.overallFormScore,
    this.worstDeviationSeverity,
    this.topCoachingTips,
    this.thumbnailBase64,
    this.cameraAngle,
    this.videoOrientation,
    this.videoAspectRatio,
    this.videoUrl,
    this.videoSyncMetadata,
  });

  /// Unique identifier for this analysis
  final String id;

  /// User's UID
  final String uid;

  /// ISO 8601 timestamp when analysis was created
  @JsonKey(name: 'created_at')
  final String createdAt;

  /// Type of throw analyzed: "backhand" or "forehand"
  @JsonKey(name: 'throw_type')
  final String throwType;

  /// Overall form score from pose analysis (0-100)
  @JsonKey(name: 'overall_form_score')
  final int? overallFormScore;

  /// Worst deviation severity across all checkpoints
  /// Values: "good", "minor", "moderate", "significant"
  @JsonKey(name: 'worst_deviation_severity')
  final String? worstDeviationSeverity;

  /// Checkpoint data with images and deviations
  final List<CheckpointRecord> checkpoints;

  /// Top coaching tips aggregated from all checkpoints (max 3)
  @JsonKey(name: 'top_coaching_tips')
  final List<String>? topCoachingTips;

  /// Compressed thumbnail image (base64-encoded JPEG, ~15-25 KB)
  /// Generated from first checkpoint's skeleton image
  @JsonKey(name: 'thumbnail_base64')
  final String? thumbnailBase64;

  /// Camera angle used for recording: side or rear
  @JsonKey(name: 'camera_angle')
  final CameraAngle? cameraAngle;

  /// Video orientation: portrait or landscape
  @JsonKey(name: 'video_orientation')
  final VideoOrientation? videoOrientation;

  /// Video aspect ratio (width/height)
  /// Examples: 0.5625 for 9:16 portrait, 1.778 for 16:9 landscape
  @JsonKey(name: 'video_aspect_ratio')
  final double? videoAspectRatio;

  /// URL of the user's form video (for video comparison feature)
  /// Network URL returned from pose analysis backend
  @JsonKey(name: 'video_url')
  final String? videoUrl;

  /// Video synchronization metadata for frame-perfect alignment with pro reference
  /// Contains playback speed multiplier and checkpoint sync points
  @JsonKey(name: 'video_sync_metadata')
  final VideoSyncMetadata? videoSyncMetadata;

  factory FormAnalysisRecord.fromJson(Map<String, dynamic> json) =>
      _$FormAnalysisRecordFromJson(json);

  Map<String, dynamic> toJson() => _$FormAnalysisRecordToJson(this);
}

/// Record of a single checkpoint in the analysis.
@JsonSerializable(explicitToJson: true)
class CheckpointRecord {
  const CheckpointRecord({
    required this.checkpointId,
    required this.checkpointName,
    required this.deviationSeverity,
    required this.coachingTips,
    this.angleDeviations,
    this.userImageUrl,
    this.userSkeletonUrl,
    this.referenceImageUrl,
    this.referenceSkeletonUrl,
    this.proPlayerId,
    this.referenceHorizontalOffsetPercent,
    this.referenceScale,
    this.userLeftKneeBendAngle,
    this.userRightKneeBendAngle,
    this.userLeftElbowFlexionAngle,
    this.userRightElbowFlexionAngle,
    this.userLeftShoulderAbductionAngle,
    this.userRightShoulderAbductionAngle,
    this.userLeftWristExtensionAngle,
    this.userRightWristExtensionAngle,
    this.userLeftHipFlexionAngle,
    this.userRightHipFlexionAngle,
    this.userLeftAnkleAngle,
    this.userRightAnkleAngle,
    this.refLeftKneeBendAngle,
    this.refRightKneeBendAngle,
    this.refLeftElbowFlexionAngle,
    this.refRightElbowFlexionAngle,
    this.refLeftShoulderAbductionAngle,
    this.refRightShoulderAbductionAngle,
    this.refLeftWristExtensionAngle,
    this.refRightWristExtensionAngle,
    this.refLeftHipFlexionAngle,
    this.refRightHipFlexionAngle,
    this.refLeftAnkleAngle,
    this.refRightAnkleAngle,
    this.devLeftKneeBendAngle,
    this.devRightKneeBendAngle,
    this.devLeftElbowFlexionAngle,
    this.devRightElbowFlexionAngle,
    this.devLeftShoulderAbductionAngle,
    this.devRightShoulderAbductionAngle,
    this.devLeftWristExtensionAngle,
    this.devRightWristExtensionAngle,
    this.devLeftHipFlexionAngle,
    this.devRightHipFlexionAngle,
    this.devLeftAnkleAngle,
    this.devRightAnkleAngle,
  });

  /// Checkpoint identifier: "heisman", "loaded", "magic", "pro"
  @JsonKey(name: 'checkpoint_id')
  final String checkpointId;

  /// Display name: "Heisman Position", etc.
  @JsonKey(name: 'checkpoint_name')
  final String checkpointName;

  /// Deviation severity for this checkpoint
  /// Values: "good", "minor", "moderate", "significant"
  @JsonKey(name: 'deviation_severity')
  final String deviationSeverity;

  /// Coaching tips for this checkpoint
  @JsonKey(name: 'coaching_tips')
  final List<String> coachingTips;

  /// Angle deviations from reference (in degrees)
  /// Keys: "shoulder_rotation", "elbow_angle", "hip_rotation", "knee_bend", "spine_tilt"
  @JsonKey(name: 'angle_deviations')
  final Map<String, double>? angleDeviations;

  /// Cloud Storage URL for user's form image (video mode)
  @JsonKey(name: 'user_image_url')
  final String? userImageUrl;

  /// Cloud Storage URL for user's skeleton-only image
  @JsonKey(name: 'user_skeleton_url')
  final String? userSkeletonUrl;

  /// Cloud Storage URL for pro reference image (silhouette + skeleton)
  @JsonKey(name: 'reference_image_url')
  final String? referenceImageUrl;

  /// Cloud Storage URL for pro reference skeleton-only image
  @JsonKey(name: 'reference_skeleton_url')
  final String? referenceSkeletonUrl;

  /// Pro player ID for reference images (e.g., "paul_mcbeth")
  /// Used with hybrid asset loading: bundled assets, cache, or cloud storage
  @JsonKey(name: 'pro_player_id')
  final String? proPlayerId;

  /// Horizontal offset percentage for aligning pro reference with user pose
  /// Positive values shift right, negative values shift left
  @JsonKey(name: 'reference_horizontal_offset_percent')
  final double? referenceHorizontalOffsetPercent;

  /// Scale factor for aligning pro reference with user pose
  /// Values typically range from 0.7 to 1.3 (e.g., 1.2 = scale up 20%, 0.8 = scale down 20%)
  @JsonKey(name: 'reference_scale')
  final double? referenceScale;

  // Individual joint angles - User
  @JsonKey(name: 'user_left_knee_bend_angle')
  final double? userLeftKneeBendAngle;

  @JsonKey(name: 'user_right_knee_bend_angle')
  final double? userRightKneeBendAngle;

  @JsonKey(name: 'user_left_elbow_flexion_angle')
  final double? userLeftElbowFlexionAngle;

  @JsonKey(name: 'user_right_elbow_flexion_angle')
  final double? userRightElbowFlexionAngle;

  @JsonKey(name: 'user_left_shoulder_abduction_angle')
  final double? userLeftShoulderAbductionAngle;

  @JsonKey(name: 'user_right_shoulder_abduction_angle')
  final double? userRightShoulderAbductionAngle;

  @JsonKey(name: 'user_left_wrist_extension_angle')
  final double? userLeftWristExtensionAngle;

  @JsonKey(name: 'user_right_wrist_extension_angle')
  final double? userRightWristExtensionAngle;

  @JsonKey(name: 'user_left_hip_flexion_angle')
  final double? userLeftHipFlexionAngle;

  @JsonKey(name: 'user_right_hip_flexion_angle')
  final double? userRightHipFlexionAngle;

  @JsonKey(name: 'user_left_ankle_angle')
  final double? userLeftAnkleAngle;

  @JsonKey(name: 'user_right_ankle_angle')
  final double? userRightAnkleAngle;

  // Individual joint angles - Reference
  @JsonKey(name: 'ref_left_knee_bend_angle')
  final double? refLeftKneeBendAngle;

  @JsonKey(name: 'ref_right_knee_bend_angle')
  final double? refRightKneeBendAngle;

  @JsonKey(name: 'ref_left_elbow_flexion_angle')
  final double? refLeftElbowFlexionAngle;

  @JsonKey(name: 'ref_right_elbow_flexion_angle')
  final double? refRightElbowFlexionAngle;

  @JsonKey(name: 'ref_left_shoulder_abduction_angle')
  final double? refLeftShoulderAbductionAngle;

  @JsonKey(name: 'ref_right_shoulder_abduction_angle')
  final double? refRightShoulderAbductionAngle;

  @JsonKey(name: 'ref_left_wrist_extension_angle')
  final double? refLeftWristExtensionAngle;

  @JsonKey(name: 'ref_right_wrist_extension_angle')
  final double? refRightWristExtensionAngle;

  @JsonKey(name: 'ref_left_hip_flexion_angle')
  final double? refLeftHipFlexionAngle;

  @JsonKey(name: 'ref_right_hip_flexion_angle')
  final double? refRightHipFlexionAngle;

  @JsonKey(name: 'ref_left_ankle_angle')
  final double? refLeftAnkleAngle;

  @JsonKey(name: 'ref_right_ankle_angle')
  final double? refRightAnkleAngle;

  // Individual joint angle deviations
  @JsonKey(name: 'dev_left_knee_bend_angle')
  final double? devLeftKneeBendAngle;

  @JsonKey(name: 'dev_right_knee_bend_angle')
  final double? devRightKneeBendAngle;

  @JsonKey(name: 'dev_left_elbow_flexion_angle')
  final double? devLeftElbowFlexionAngle;

  @JsonKey(name: 'dev_right_elbow_flexion_angle')
  final double? devRightElbowFlexionAngle;

  @JsonKey(name: 'dev_left_shoulder_abduction_angle')
  final double? devLeftShoulderAbductionAngle;

  @JsonKey(name: 'dev_right_shoulder_abduction_angle')
  final double? devRightShoulderAbductionAngle;

  @JsonKey(name: 'dev_left_wrist_extension_angle')
  final double? devLeftWristExtensionAngle;

  @JsonKey(name: 'dev_right_wrist_extension_angle')
  final double? devRightWristExtensionAngle;

  @JsonKey(name: 'dev_left_hip_flexion_angle')
  final double? devLeftHipFlexionAngle;

  @JsonKey(name: 'dev_right_hip_flexion_angle')
  final double? devRightHipFlexionAngle;

  @JsonKey(name: 'dev_left_ankle_angle')
  final double? devLeftAnkleAngle;

  @JsonKey(name: 'dev_right_ankle_angle')
  final double? devRightAnkleAngle;

  /// Get individual joint angles in user format
  IndividualJointAngles? get userIndividualAngles {
    if (userLeftKneeBendAngle == null && userRightKneeBendAngle == null) {
      return null; // No individual data available
    }

    return IndividualJointAngles(
      leftKneeBendAngle: userLeftKneeBendAngle,
      rightKneeBendAngle: userRightKneeBendAngle,
      leftElbowFlexionAngle: userLeftElbowFlexionAngle,
      rightElbowFlexionAngle: userRightElbowFlexionAngle,
      leftShoulderAbductionAngle: userLeftShoulderAbductionAngle,
      rightShoulderAbductionAngle: userRightShoulderAbductionAngle,
      leftWristExtensionAngle: userLeftWristExtensionAngle,
      rightWristExtensionAngle: userRightWristExtensionAngle,
      leftHipFlexionAngle: userLeftHipFlexionAngle,
      rightHipFlexionAngle: userRightHipFlexionAngle,
      leftAnkleAngle: userLeftAnkleAngle,
      rightAnkleAngle: userRightAnkleAngle,
    );
  }

  /// Get individual joint angles in reference format
  IndividualJointAngles? get referenceIndividualAngles {
    if (refLeftKneeBendAngle == null && refRightKneeBendAngle == null) {
      return null;
    }

    return IndividualJointAngles(
      leftKneeBendAngle: refLeftKneeBendAngle,
      rightKneeBendAngle: refRightKneeBendAngle,
      leftElbowFlexionAngle: refLeftElbowFlexionAngle,
      rightElbowFlexionAngle: refRightElbowFlexionAngle,
      leftShoulderAbductionAngle: refLeftShoulderAbductionAngle,
      rightShoulderAbductionAngle: refRightShoulderAbductionAngle,
      leftWristExtensionAngle: refLeftWristExtensionAngle,
      rightWristExtensionAngle: refRightWristExtensionAngle,
      leftHipFlexionAngle: refLeftHipFlexionAngle,
      rightHipFlexionAngle: refRightHipFlexionAngle,
      leftAnkleAngle: refLeftAnkleAngle,
      rightAnkleAngle: refRightAnkleAngle,
    );
  }

  /// Get individual joint deviations
  IndividualJointDeviations? get individualDeviations {
    if (devLeftKneeBendAngle == null && devRightKneeBendAngle == null) {
      return null;
    }

    return IndividualJointDeviations(
      leftKneeBendAngle: devLeftKneeBendAngle,
      rightKneeBendAngle: devRightKneeBendAngle,
      leftElbowFlexionAngle: devLeftElbowFlexionAngle,
      rightElbowFlexionAngle: devRightElbowFlexionAngle,
      leftShoulderAbductionAngle: devLeftShoulderAbductionAngle,
      rightShoulderAbductionAngle: devRightShoulderAbductionAngle,
      leftWristExtensionAngle: devLeftWristExtensionAngle,
      rightWristExtensionAngle: devRightWristExtensionAngle,
      leftHipFlexionAngle: devLeftHipFlexionAngle,
      rightHipFlexionAngle: devRightHipFlexionAngle,
      leftAnkleAngle: devLeftAnkleAngle,
      rightAnkleAngle: devRightAnkleAngle,
    );
  }

  factory CheckpointRecord.fromJson(Map<String, dynamic> json) =>
      _$CheckpointRecordFromJson(json);

  Map<String, dynamic> toJson() => _$CheckpointRecordToJson(this);
}
