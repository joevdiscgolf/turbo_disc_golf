import 'package:json_annotation/json_annotation.dart';

part 'arm_speed_data.g.dart';

/// Arm speed data from form analysis
/// Contains speed measurements over frames during the throwing motion
@JsonSerializable()
class ArmSpeedData {
  const ArmSpeedData({
    required this.speedsByFrameMph,
    required this.maxSpeedMph,
    required this.maxSpeedFrame,
    required this.chartStartFrame,
    required this.chartEndFrame,
  });

  /// Map of frame number to arm speed in mph.
  /// Contains speed data for every frame in the video.
  /// Key: frame number, Value: speed in mph
  @JsonKey(
    name: 'speeds_by_frame_mph',
    fromJson: _speedsFromJson,
    toJson: _speedsToJson,
  )
  final Map<int, double> speedsByFrameMph;

  /// Maximum arm speed achieved during the throw (in mph)
  @JsonKey(name: 'max_speed_mph')
  final double maxSpeedMph;

  /// Frame number where max speed occurred
  @JsonKey(name: 'max_speed_frame')
  final int maxSpeedFrame;

  /// Starting frame for the chart display (highlights the throwing motion)
  @JsonKey(name: 'chart_start_frame')
  final int chartStartFrame;

  /// Ending frame for the chart display (highlights the throwing motion)
  @JsonKey(name: 'chart_end_frame')
  final int chartEndFrame;

  /// Number of frames in the chart range
  int get chartFrameCount => chartEndFrame - chartStartFrame + 1;

  /// Get the speed at a specific frame, or null if not available
  double? getSpeedAtFrame(int frame) => speedsByFrameMph[frame];

  /// Get speeds for the chart range as a sorted list
  List<double> get chartSpeedsAsList {
    final List<double> speeds = [];
    for (int frame = chartStartFrame; frame <= chartEndFrame; frame++) {
      final double? speed = speedsByFrameMph[frame];
      if (speed != null) {
        speeds.add(speed);
      }
    }
    return speeds;
  }

  factory ArmSpeedData.fromJson(Map<String, dynamic> json) =>
      _$ArmSpeedDataFromJson(json);
  Map<String, dynamic> toJson() => _$ArmSpeedDataToJson(this);

  /// Convert JSON map with string keys to Map of int to double
  static Map<int, double> _speedsFromJson(Map<String, dynamic> json) {
    return json.map(
      (key, value) => MapEntry(int.parse(key), (value as num).toDouble()),
    );
  }

  /// Convert Map of int to double to JSON map with string keys
  static Map<String, dynamic> _speedsToJson(Map<int, double> speeds) {
    return speeds.map((key, value) => MapEntry(key.toString(), value));
  }
}
