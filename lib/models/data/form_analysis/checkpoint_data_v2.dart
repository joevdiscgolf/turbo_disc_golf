import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_metadata.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/deviation_analysis.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/user_alignment_metadata.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_reference_pose_data.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/user_pose_data.dart';

part 'checkpoint_data_v2.g.dart';

/// Per-checkpoint data in V2 format
/// Organized into logical sub-objects for better structure
@JsonSerializable(explicitToJson: true)
class CheckpointDataV2 {
  const CheckpointDataV2({
    required this.metadata,
    required this.userPose,
    this.proReferencePose,
    required this.deviationAnalysis,
    this.userAlignmentMetadata,
    required this.coachingTips,
  });

  /// Checkpoint identification and timing
  final CheckpointMetadata metadata;

  /// User's pose data
  @JsonKey(name: 'user_pose')
  final UserPoseData userPose;

  /// Pro reference pose data (null if no pro comparison)
  @JsonKey(name: 'pro_reference_pose')
  final ProReferencePoseData? proReferencePose;

  /// Deviation analysis
  @JsonKey(name: 'deviation_analysis')
  final DeviationAnalysis deviationAnalysis;

  /// Pro overlay alignment data (null if no pro comparison)
  @JsonKey(name: 'user_alignment_metadata')
  final UserAlignmentMetadata? userAlignmentMetadata;

  /// Coaching tips for this checkpoint
  @JsonKey(name: 'coaching_tips')
  final List<String> coachingTips;

  factory CheckpointDataV2.fromJson(Map<String, dynamic> json) =>
      _$CheckpointDataV2FromJson(json);
  Map<String, dynamic> toJson() => _$CheckpointDataV2ToJson(this);
}
