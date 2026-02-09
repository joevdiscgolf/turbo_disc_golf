import 'package:json_annotation/json_annotation.dart';

part 'arm_speed_data.g.dart';

/// Arm speed data from form analysis
/// Contains speed measurements over frames during the throwing motion
@JsonSerializable()
class ArmSpeedData {
  const ArmSpeedData({
    required this.speedsMph,
    required this.maxSpeedMph,
    required this.maxSpeedFrame,
    required this.startFrame,
    required this.endFrame,
  });

  /// List of arm speeds in mph for each frame in the analysis window
  @JsonKey(name: 'speeds_mph')
  final List<double> speedsMph;

  /// Maximum arm speed achieved during the throw (in mph)
  @JsonKey(name: 'max_speed_mph')
  final double maxSpeedMph;

  /// Frame number where max speed occurred
  @JsonKey(name: 'max_speed_frame')
  final int maxSpeedFrame;

  /// Starting frame of the speed analysis window
  @JsonKey(name: 'start_frame')
  final int startFrame;

  /// Ending frame of the speed analysis window
  @JsonKey(name: 'end_frame')
  final int endFrame;

  /// Number of frames in the analysis window
  int get frameCount => endFrame - startFrame + 1;

  factory ArmSpeedData.fromJson(Map<String, dynamic> json) =>
      _$ArmSpeedDataFromJson(json);
  Map<String, dynamic> toJson() => _$ArmSpeedDataToJson(this);
}
