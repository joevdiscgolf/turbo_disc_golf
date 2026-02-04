import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

part 'user_pose_data.g.dart';

/// User's pose data for a checkpoint
@JsonSerializable(explicitToJson: true)
class UserPoseData {
  const UserPoseData({
    required this.landmarks,
    this.individualAngles,
    required this.v2Measurements,
  });

  /// User's pose landmarks
  final List<PoseLandmark> landmarks;

  /// Individual joint angles for user (left/right body parts)
  @JsonKey(name: 'individual_angles')
  final IndividualJointAngles? individualAngles;

  /// V2 measurements by camera angle (side/rear/front)
  @JsonKey(name: 'v2_measurements')
  final V2MeasurementsByAngle v2Measurements;

  factory UserPoseData.fromJson(Map<String, dynamic> json) =>
      _$UserPoseDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserPoseDataToJson(this);
}
