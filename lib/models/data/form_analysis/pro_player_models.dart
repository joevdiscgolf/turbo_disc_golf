import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

part 'pro_player_models.g.dart';

/// Supported throw type and camera angle configuration for a pro player
@JsonSerializable(anyMap: true, explicitToJson: true)
class SupportedConfiguration {
  const SupportedConfiguration({
    required this.throwType,
    required this.cameraAngle,
  });

  @JsonKey(name: 'throw_type')
  final String throwType;

  @JsonKey(name: 'camera_angle')
  final String cameraAngle;

  factory SupportedConfiguration.fromJson(Map<String, dynamic> json) =>
      _$SupportedConfigurationFromJson(json);
  Map<String, dynamic> toJson() => _$SupportedConfigurationToJson(this);
}

/// V2 measurements for a pro reference pose checkpoint (side-view only)
@JsonSerializable(anyMap: true, explicitToJson: true)
class ProV2Measurements {
  const ProV2Measurements({
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

  factory ProV2Measurements.fromJson(Map<String, dynamic> json) =>
      _$ProV2MeasurementsFromJson(json);
  Map<String, dynamic> toJson() => _$ProV2MeasurementsToJson(this);
}

/// Reference pose data for a specific checkpoint
@JsonSerializable(anyMap: true, explicitToJson: true)
class ReferencePoseCheckpoint {
  const ReferencePoseCheckpoint({
    required this.checkpointId,
    required this.checkpointName,
    this.description,
    this.v2Measurements,
  });

  @JsonKey(name: 'checkpoint_id')
  final String checkpointId;

  @JsonKey(name: 'checkpoint_name')
  final String checkpointName;

  final String? description;

  /// V2 measurements for this checkpoint (side-view only, null for rear-view)
  @JsonKey(name: 'v2_measurements')
  final ProV2Measurements? v2Measurements;

  factory ReferencePoseCheckpoint.fromJson(Map<String, dynamic> json) =>
      _$ReferencePoseCheckpointFromJson(json);
  Map<String, dynamic> toJson() => _$ReferencePoseCheckpointToJson(this);
}

/// Metadata about a pro player available for form comparison
@JsonSerializable(anyMap: true, explicitToJson: true)
class ProPlayerMetadata {
  const ProPlayerMetadata({
    required this.proPlayerId,
    required this.displayName,
    this.description,
    this.assetBaseUrl,
    this.isBundled,
    this.isActive,
    this.supportedConfigurations,
    this.referencePoses,
  });

  /// Unique identifier for the pro player (e.g., "paul_mcbeth")
  @JsonKey(name: 'pro_player_id')
  final String proPlayerId;

  /// Display name (e.g., "Paul McBeth")
  @JsonKey(name: 'display_name')
  final String displayName;

  /// Optional description of the pro player
  final String? description;

  /// Base URL for pro player assets (images, videos)
  @JsonKey(name: 'asset_base_url')
  final String? assetBaseUrl;

  /// Whether this pro's assets are bundled with the app
  @JsonKey(name: 'is_bundled')
  final bool? isBundled;

  /// Whether this pro is currently active/available
  @JsonKey(name: 'is_active')
  final bool? isActive;

  /// List of supported throw type and camera angle combinations
  @JsonKey(name: 'supported_configurations')
  final List<SupportedConfiguration>? supportedConfigurations;

  /// Reference poses organized by throw_type -> camera_angle -> checkpoint_id
  @JsonKey(name: 'reference_poses')
  final Map<String, Map<String, Map<String, ReferencePoseCheckpoint>>>?
      referencePoses;

  factory ProPlayerMetadata.fromJson(Map<String, dynamic> json) =>
      _$ProPlayerMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$ProPlayerMetadataToJson(this);
}

/// Comparison data from API response (uses CheckpointPoseData)
/// This is the format returned by the pose analysis backend
@JsonSerializable(anyMap: true, explicitToJson: true)
class ProComparisonPoseData {
  const ProComparisonPoseData({
    required this.proPlayerId,
    required this.checkpoints,
    this.overallFormScore,
  });

  /// Pro player ID this comparison is for
  @JsonKey(name: 'pro_player_id')
  final String proPlayerId;

  /// Checkpoint pose data for this pro comparison (API format)
  final List<CheckpointPoseData> checkpoints;

  /// Overall form score when compared to this pro (0-100)
  @JsonKey(name: 'overall_form_score')
  final int? overallFormScore;

  factory ProComparisonPoseData.fromJson(Map<String, dynamic> json) =>
      _$ProComparisonPoseDataFromJson(json);
  Map<String, dynamic> toJson() => _$ProComparisonPoseDataToJson(this);
}

/// Comparison data for storage (uses CheckpointRecord)
/// This is the format stored in Firestore
@JsonSerializable(anyMap: true, explicitToJson: true)
class ProComparisonData {
  const ProComparisonData({
    required this.proPlayerId,
    required this.checkpoints,
    this.overallFormScore,
  });

  /// Pro player ID this comparison is for
  @JsonKey(name: 'pro_player_id')
  final String proPlayerId;

  /// Checkpoint records for this pro comparison (storage format)
  final List<CheckpointRecord> checkpoints;

  /// Overall form score when compared to this pro (0-100)
  @JsonKey(name: 'overall_form_score')
  final int? overallFormScore;

  factory ProComparisonData.fromJson(Map<String, dynamic> json) =>
      _$ProComparisonDataFromJson(json);
  Map<String, dynamic> toJson() => _$ProComparisonDataToJson(this);
}

/// Configuration data fetched from Firestore at app startup.
/// Contains all pro player metadata and the default pro to use.
@JsonSerializable(anyMap: true, explicitToJson: true)
class ProPlayersConfig {
  const ProPlayersConfig({
    required this.pros,
    required this.defaultProId,
  });

  /// Map of pro player ID to metadata
  final Map<String, ProPlayerMetadata> pros;

  /// Default pro player ID to use
  @JsonKey(name: 'default_pro_id')
  final String defaultProId;

  factory ProPlayersConfig.fromJson(Map<String, dynamic> json) =>
      _$ProPlayersConfigFromJson(json);
  Map<String, dynamic> toJson() => _$ProPlayersConfigToJson(this);
}
