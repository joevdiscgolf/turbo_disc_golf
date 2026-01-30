import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_player_models.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/video_sync_metadata.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
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
    this.returnedVideoAspectRatio,
    this.videoUrl,
    this.videoStoragePath,
    this.skeletonVideoUrl,
    this.skeletonOnlyVideoUrl,
    this.videoSyncMetadata,
    this.detectedHandedness,
    this.proComparisons,
    this.defaultProId,
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

  /// Aspect ratio (width/height) of the returned processed videos
  /// (skeleton overlay and skeleton-only share the same aspect ratio)
  @JsonKey(name: 'returned_video_aspect_ratio')
  final double? returnedVideoAspectRatio;

  /// URL of the user's form video (for video comparison feature)
  /// Network URL returned from pose analysis backend (signed URL, may expire)
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

  /// Video synchronization metadata for frame-perfect alignment with pro reference
  /// Contains playback speed multiplier and checkpoint sync points
  @JsonKey(name: 'video_sync_metadata')
  final VideoSyncMetadata? videoSyncMetadata;

  /// Detected handedness from pose analysis: left or right
  @JsonKey(name: 'detected_handedness')
  final Handedness? detectedHandedness;

  /// Multi-pro comparison data: map of pro_player_id to comparison data
  /// Only populated when enableMultiProComparison feature flag is enabled
  @JsonKey(name: 'pro_comparisons')
  final Map<String, ProComparisonData>? proComparisons;

  /// Default pro player ID to show initially
  @JsonKey(name: 'default_pro_id')
  final String? defaultProId;

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
    this.detectedFrameNumber,
    this.timestampSeconds,
    this.userIndividualAngles,
    this.referenceIndividualAngles,
    this.individualDeviations,
    this.userV2Measurements,
    this.referenceV2Measurements,
    this.v2MeasurementDeviations,
    this.userLandmarks,
    this.referenceLandmarks,
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

  /// Frame number where this checkpoint was detected by the backend
  @JsonKey(name: 'detected_frame_number')
  final int? detectedFrameNumber;

  /// Timestamp in seconds where this checkpoint occurs in the video
  @JsonKey(name: 'timestamp_seconds')
  final double? timestampSeconds;

  /// Individual joint angles for user (left/right body parts)
  @JsonKey(name: 'user_individual_angles')
  final IndividualJointAngles? userIndividualAngles;

  /// Individual joint angles for reference/pro (left/right body parts)
  @JsonKey(name: 'reference_individual_angles')
  final IndividualJointAngles? referenceIndividualAngles;

  /// Individual joint deviations (user - reference)
  @JsonKey(name: 'individual_deviations')
  final IndividualJointDeviations? individualDeviations;

  /// V2 side-view measurements for user
  @JsonKey(name: 'user_v2_measurements')
  final V2SideMeasurements? userV2Measurements;

  /// V2 side-view measurements for reference/pro
  @JsonKey(name: 'reference_v2_measurements')
  final V2SideMeasurements? referenceV2Measurements;

  /// V2 side-view measurement deviations (user - reference)
  @JsonKey(name: 'v2_measurement_deviations')
  final V2SideMeasurements? v2MeasurementDeviations;

  /// User's pose landmarks for this checkpoint (used for alignment)
  @JsonKey(name: 'user_landmarks')
  final List<PoseLandmark>? userLandmarks;

  /// Reference/pro pose landmarks for this checkpoint
  @JsonKey(name: 'reference_landmarks')
  final List<PoseLandmark>? referenceLandmarks;

  factory CheckpointRecord.fromJson(Map<String, dynamic> json) =>
      _$CheckpointRecordFromJson(json);

  Map<String, dynamic> toJson() => _$CheckpointRecordToJson(this);
}
