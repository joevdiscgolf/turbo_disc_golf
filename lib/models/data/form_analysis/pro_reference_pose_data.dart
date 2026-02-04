import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

part 'pro_reference_pose_data.g.dart';

/// Pro reference pose data for a checkpoint
@JsonSerializable(explicitToJson: true)
class ProReferencePoseData {
  const ProReferencePoseData({
    required this.proPlayerId,
    required this.landmarks,
    required this.angles,
    this.individualAngles,
    required this.v2Measurements,
  });

  /// Pro player ID for reference (e.g., "paul_mcbeth")
  @JsonKey(name: 'pro_player_id')
  final String proPlayerId;

  /// Pro reference pose landmarks
  final List<PoseLandmark> landmarks;

  /// Pro reference pose angles
  final PoseAngles angles;

  /// Individual joint angles for reference/pro (left/right body parts)
  @JsonKey(name: 'individual_angles')
  final IndividualJointAngles? individualAngles;

  /// V2 measurements by camera angle (side/rear/front)
  @JsonKey(name: 'v2_measurements')
  final V2MeasurementsByAngle v2Measurements;

  factory ProReferencePoseData.fromJson(Map<String, dynamic> json) =>
      _$ProReferencePoseDataFromJson(json);
  Map<String, dynamic> toJson() => _$ProReferencePoseDataToJson(this);
}
