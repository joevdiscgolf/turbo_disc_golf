import 'package:json_annotation/json_annotation.dart';

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

  factory CheckpointRecord.fromJson(Map<String, dynamic> json) =>
      _$CheckpointRecordFromJson(json);

  Map<String, dynamic> toJson() => _$CheckpointRecordToJson(this);
}
