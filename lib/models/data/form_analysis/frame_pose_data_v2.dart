import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

part 'frame_pose_data_v2.g.dart';

/// Compressed landmark data for frame poses (V2 format)
/// Uses short JSON keys to minimize payload size
@JsonSerializable(explicitToJson: true)
class FramePoseLandmark {
  const FramePoseLandmark({
    required this.x,
    required this.y,
    required this.z,
    required this.v,
  });

  /// X coordinate (0-1 normalized)
  final double x;

  /// Y coordinate (0-1 normalized)
  final double y;

  /// Z depth
  final double z;

  /// Visibility (0-1)
  final double v;

  factory FramePoseLandmark.fromJson(Map<String, dynamic> json) =>
      _$FramePoseLandmarkFromJson(json);
  Map<String, dynamic> toJson() => _$FramePoseLandmarkToJson(this);
}

/// Compressed frame pose data for video scrubber (V2 format)
/// Uses short JSON keys and reduced precision to minimize size
@JsonSerializable(explicitToJson: true)
class FramePoseDataV2 {
  const FramePoseDataV2({
    required this.frameNumber,
    required this.timestampSeconds,
    required this.landmarkObjects,
    this.checkpointId,
  });

  /// Frame number
  @JsonKey(name: 'f')
  final int frameNumber;

  /// Timestamp in seconds
  @JsonKey(name: 't')
  final double timestampSeconds;

  /// Landmarks as objects [{x,y,z,v}, ...]
  @JsonKey(name: 'l')
  final List<FramePoseLandmark> landmarkObjects;

  /// Checkpoint ID if this frame is a checkpoint
  @JsonKey(name: 'c')
  final String? checkpointId;

  /// Convert landmark objects to PoseLandmark objects with names
  /// MediaPipe pose landmarks are always in the same order
  List<PoseLandmark> get landmarks {
    const List<String> landmarkNames = [
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

    return landmarkObjects.asMap().entries.map((entry) {
      final int index = entry.key;
      final FramePoseLandmark landmark = entry.value;
      return PoseLandmark(
        name: index < landmarkNames.length ? landmarkNames[index] : 'unknown_$index',
        x: landmark.x,
        y: landmark.y,
        z: landmark.z,
        visibility: landmark.v,
      );
    }).toList();
  }

  /// Convert PoseLandmark objects to FramePoseLandmark format
  static List<FramePoseLandmark> poseLandmarksToObjects(List<PoseLandmark> landmarks) {
    return landmarks.map((landmark) {
      return FramePoseLandmark(
        x: landmark.x,
        y: landmark.y,
        z: landmark.z,
        v: landmark.visibility,
      );
    }).toList();
  }

  factory FramePoseDataV2.fromJson(Map<String, dynamic> json) =>
      _$FramePoseDataV2FromJson(json);
  Map<String, dynamic> toJson() => _$FramePoseDataV2ToJson(this);
}
