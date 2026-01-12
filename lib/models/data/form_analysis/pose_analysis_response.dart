import 'package:json_annotation/json_annotation.dart';

part 'pose_analysis_response.g.dart';

/// Response from the Cloud Run pose analysis API
@JsonSerializable(explicitToJson: true)
class PoseAnalysisResponse {
  const PoseAnalysisResponse({
    required this.sessionId,
    required this.status,
    required this.throwType,
    required this.cameraAngle,
    required this.videoDurationSeconds,
    required this.totalFrames,
    required this.checkpoints,
    required this.framePoses,
    this.overallFormScore,
    this.errorMessage,
  });

  @JsonKey(name: 'session_id')
  final String sessionId;

  final String status;

  @JsonKey(name: 'throw_type')
  final String throwType;

  @JsonKey(name: 'camera_angle')
  final String cameraAngle;

  @JsonKey(name: 'video_duration_seconds')
  final double videoDurationSeconds;

  @JsonKey(name: 'total_frames')
  final int totalFrames;

  final List<CheckpointPoseData> checkpoints;

  @JsonKey(name: 'frame_poses')
  final List<FramePoseData> framePoses;

  @JsonKey(name: 'overall_form_score')
  final int? overallFormScore;

  @JsonKey(name: 'error_message')
  final String? errorMessage;

  factory PoseAnalysisResponse.fromJson(Map<String, dynamic> json) =>
      _$PoseAnalysisResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PoseAnalysisResponseToJson(this);
}

/// Pose data for a detected checkpoint
@JsonSerializable(explicitToJson: true)
class CheckpointPoseData {
  const CheckpointPoseData({
    required this.checkpointId,
    required this.checkpointName,
    required this.frameNumber,
    required this.timestampSeconds,
    required this.userLandmarks,
    required this.userAngles,
    this.referenceLandmarks,
    this.referenceAngles,
    required this.deviationsRaw,
    required this.deviationSeverity,
    this.comparisonImageBase64,
    this.sideBySideImageBase64,
    this.userImageBase64,
    this.referenceImageBase64,
    required this.coachingTips,
  });

  @JsonKey(name: 'checkpoint_id')
  final String checkpointId;

  @JsonKey(name: 'checkpoint_name')
  final String checkpointName;

  @JsonKey(name: 'frame_number')
  final int frameNumber;

  @JsonKey(name: 'timestamp_seconds')
  final double timestampSeconds;

  @JsonKey(name: 'user_landmarks')
  final List<PoseLandmark> userLandmarks;

  @JsonKey(name: 'user_angles')
  final PoseAngles userAngles;

  @JsonKey(name: 'reference_landmarks')
  final List<PoseLandmark>? referenceLandmarks;

  @JsonKey(name: 'reference_angles')
  final PoseAngles? referenceAngles;

  /// Raw deviations object from backend
  @JsonKey(name: 'deviations')
  final AngleDeviations deviationsRaw;

  @JsonKey(name: 'deviation_severity')
  final String deviationSeverity;

  @JsonKey(name: 'comparison_image_base64')
  final String? comparisonImageBase64;

  @JsonKey(name: 'side_by_side_image_base64')
  final String? sideBySideImageBase64;

  @JsonKey(name: 'user_image_base64')
  final String? userImageBase64;

  @JsonKey(name: 'reference_image_base64')
  final String? referenceImageBase64;

  @JsonKey(name: 'coaching_tips')
  final List<String> coachingTips;

  /// Get checkpoint description based on checkpoint ID
  String get checkpointDescription {
    switch (checkpointId) {
      case 'heisman':
        return 'Player has just stepped onto their back leg on the ball of their foot. Front leg has started to drift in front of their back leg. They are on their back leg but have not started to coil yet, and their elbow is still roughly at 90 degrees and neutral.';
      case 'loaded':
        return 'The player\'s front (plant) foot is about to touch the ground, and they are fully coiled, and their back leg is bowed out.';
      case 'magic':
        return 'Disc is just starting to move forward, both knees are bent inward, in an athletic position.';
      case 'pro':
        return 'The pull-through is well in progress, and the elbow is at a 90-degree angle, and the back leg is bent at almost a 90-degree angle, and the front leg is pretty straight.';
      default:
        return checkpointName;
    }
  }

  /// Convert raw deviations object to a list for UI display
  List<AngleDeviation> get deviations {
    final List<AngleDeviation> result = [];

    if (deviationsRaw.shoulderRotation != null &&
        userAngles.shoulderRotation != null) {
      result.add(
        AngleDeviation(
          angleName: 'shoulder_rotation',
          userValue: userAngles.shoulderRotation!,
          referenceValue: referenceAngles?.shoulderRotation,
          deviation: deviationsRaw.shoulderRotation,
          withinTolerance: (deviationsRaw.shoulderRotation?.abs() ?? 0) <= 15,
        ),
      );
    }

    if (deviationsRaw.elbowAngle != null && userAngles.elbowAngle != null) {
      result.add(
        AngleDeviation(
          angleName: 'elbow_angle',
          userValue: userAngles.elbowAngle!,
          referenceValue: referenceAngles?.elbowAngle,
          deviation: deviationsRaw.elbowAngle,
          withinTolerance: (deviationsRaw.elbowAngle?.abs() ?? 0) <= 15,
        ),
      );
    }

    if (deviationsRaw.hipRotation != null && userAngles.hipRotation != null) {
      result.add(
        AngleDeviation(
          angleName: 'hip_rotation',
          userValue: userAngles.hipRotation!,
          referenceValue: referenceAngles?.hipRotation,
          deviation: deviationsRaw.hipRotation,
          withinTolerance: (deviationsRaw.hipRotation?.abs() ?? 0) <= 15,
        ),
      );
    }

    if (deviationsRaw.kneeBend != null && userAngles.kneeBend != null) {
      result.add(
        AngleDeviation(
          angleName: 'knee_bend',
          userValue: userAngles.kneeBend!,
          referenceValue: referenceAngles?.kneeBend,
          deviation: deviationsRaw.kneeBend,
          withinTolerance: (deviationsRaw.kneeBend?.abs() ?? 0) <= 15,
        ),
      );
    }

    if (deviationsRaw.spineTilt != null && userAngles.spineTilt != null) {
      result.add(
        AngleDeviation(
          angleName: 'spine_tilt',
          userValue: userAngles.spineTilt!,
          referenceValue: referenceAngles?.spineTilt,
          deviation: deviationsRaw.spineTilt,
          withinTolerance: (deviationsRaw.spineTilt?.abs() ?? 0) <= 15,
        ),
      );
    }

    return result;
  }

  factory CheckpointPoseData.fromJson(Map<String, dynamic> json) =>
      _$CheckpointPoseDataFromJson(json);
  Map<String, dynamic> toJson() => _$CheckpointPoseDataToJson(this);
}

/// A single pose landmark
@JsonSerializable()
class PoseLandmark {
  const PoseLandmark({
    required this.name,
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });

  final String name;
  final double x;
  final double y;
  final double z;
  final double visibility;

  factory PoseLandmark.fromJson(Map<String, dynamic> json) =>
      _$PoseLandmarkFromJson(json);
  Map<String, dynamic> toJson() => _$PoseLandmarkToJson(this);
}

/// Calculated pose angles (matches backend PoseAngles)
@JsonSerializable()
class PoseAngles {
  const PoseAngles({
    this.shoulderRotation,
    this.elbowAngle,
    this.hipRotation,
    this.kneeBend,
    this.spineTilt,
    this.wristAngle,
  });

  @JsonKey(name: 'shoulder_rotation')
  final double? shoulderRotation;

  @JsonKey(name: 'elbow_angle')
  final double? elbowAngle;

  @JsonKey(name: 'hip_rotation')
  final double? hipRotation;

  @JsonKey(name: 'knee_bend')
  final double? kneeBend;

  @JsonKey(name: 'spine_tilt')
  final double? spineTilt;

  @JsonKey(name: 'wrist_angle')
  final double? wristAngle;

  factory PoseAngles.fromJson(Map<String, dynamic> json) =>
      _$PoseAnglesFromJson(json);
  Map<String, dynamic> toJson() => _$PoseAnglesToJson(this);
}

/// Angle deviations from reference (matches backend AngleDeviations)
@JsonSerializable()
class AngleDeviations {
  const AngleDeviations({
    this.shoulderRotation,
    this.elbowAngle,
    this.hipRotation,
    this.kneeBend,
    this.spineTilt,
  });

  @JsonKey(name: 'shoulder_rotation')
  final double? shoulderRotation;

  @JsonKey(name: 'elbow_angle')
  final double? elbowAngle;

  @JsonKey(name: 'hip_rotation')
  final double? hipRotation;

  @JsonKey(name: 'knee_bend')
  final double? kneeBend;

  @JsonKey(name: 'spine_tilt')
  final double? spineTilt;

  factory AngleDeviations.fromJson(Map<String, dynamic> json) =>
      _$AngleDeviationsFromJson(json);
  Map<String, dynamic> toJson() => _$AngleDeviationsToJson(this);
}

/// Single angle deviation for UI display
class AngleDeviation {
  const AngleDeviation({
    required this.angleName,
    required this.userValue,
    this.referenceValue,
    this.deviation,
    required this.withinTolerance,
  });

  final String angleName;
  final double userValue;
  final double? referenceValue;
  final double? deviation;
  final bool withinTolerance;
}

/// Frame pose data for video scrubber
@JsonSerializable(explicitToJson: true)
class FramePoseData {
  const FramePoseData({
    required this.frameNumber,
    required this.timestampSeconds,
    required this.landmarks,
    required this.thumbnailBase64,
    required this.isCheckpoint,
    this.checkpointId,
  });

  @JsonKey(name: 'frame_number')
  final int frameNumber;

  @JsonKey(name: 'timestamp_seconds')
  final double timestampSeconds;

  final List<PoseLandmark> landmarks;

  @JsonKey(name: 'thumbnail_base64')
  final String thumbnailBase64;

  @JsonKey(name: 'is_checkpoint')
  final bool isCheckpoint;

  @JsonKey(name: 'checkpoint_id')
  final String? checkpointId;

  factory FramePoseData.fromJson(Map<String, dynamic> json) =>
      _$FramePoseDataFromJson(json);
  Map<String, dynamic> toJson() => _$FramePoseDataToJson(this);
}
