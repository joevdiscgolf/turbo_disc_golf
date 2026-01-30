import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

part 'frame_pose_data_v2.g.dart';

/// Compressed frame pose data for video scrubber (V2 format)
/// Uses short JSON keys and reduced precision to minimize size
@JsonSerializable(explicitToJson: true)
class FramePoseDataV2 {
  const FramePoseDataV2({
    required this.frameNumber,
    required this.timestampSeconds,
    required this.landmarksFlat,
    this.checkpointId,
  });

  /// Frame number
  @JsonKey(name: 'f')
  final int frameNumber;

  /// Timestamp in seconds
  @JsonKey(name: 't')
  final double timestampSeconds;

  /// Landmarks as flat array [[x,y,z,visibility], ...]
  /// Reduced precision (2 decimal places) to minimize size
  @JsonKey(name: 'l')
  final List<List<double>> landmarksFlat;

  /// Checkpoint ID if this frame is a checkpoint
  @JsonKey(name: 'c')
  final String? checkpointId;

  /// Convert flat landmarks to PoseLandmark objects
  /// MediaPipe pose landmarks are always in the same order
  List<PoseLandmark> get landmarks {
    final List<String> landmarkNames = [
      'nose',
      'left_eye_inner',
      'left_eye',
      'left_eye_outer',
      'right_eye_inner',
      'right_eye',
      'right_eye_outer',
      'left_ear',
      'right_ear',
      'mouth_left',
      'mouth_right',
      'left_shoulder',
      'right_shoulder',
      'left_elbow',
      'right_elbow',
      'left_wrist',
      'right_wrist',
      'left_pinky',
      'right_pinky',
      'left_index',
      'right_index',
      'left_thumb',
      'right_thumb',
      'left_hip',
      'right_hip',
      'left_knee',
      'right_knee',
      'left_ankle',
      'right_ankle',
      'left_heel',
      'right_heel',
      'left_foot_index',
      'right_foot_index',
    ];

    return landmarksFlat.asMap().entries.map((entry) {
      final int index = entry.key;
      final List<double> coords = entry.value;
      return PoseLandmark(
        name: index < landmarkNames.length ? landmarkNames[index] : 'unknown_$index',
        x: coords[0],
        y: coords[1],
        z: coords[2],
        visibility: coords.length > 3 ? coords[3] : 1.0,
      );
    }).toList();
  }

  /// Convert PoseLandmark objects to flat array format
  static List<List<double>> landmarksToFlat(List<PoseLandmark> landmarks) {
    return landmarks.map((landmark) {
      return [
        _roundToPrecision(landmark.x, 2),
        _roundToPrecision(landmark.y, 2),
        _roundToPrecision(landmark.z, 2),
        _roundToPrecision(landmark.visibility, 2),
      ];
    }).toList();
  }

  /// Round to specified decimal places
  static double _roundToPrecision(double value, int decimals) {
    final double factor = pow(10, decimals).toDouble();
    return (value * factor).round() / factor;
  }

  factory FramePoseDataV2.fromJson(Map<String, dynamic> json) =>
      _$FramePoseDataV2FromJson(json);
  Map<String, dynamic> toJson() => _$FramePoseDataV2ToJson(this);
}
