import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

/// Callback for converting base64 image data to a URL.
/// Returns the URL for the image, or null if no image is available.
typedef ImageUrlProvider = String? Function(String? base64Data, String imageName);

/// Single source of truth for CheckpointPoseData -> CheckpointRecord conversion.
///
/// This builder ensures all fields are consistently copied between the API response
/// and the Firestore storage format. Any new fields added to CheckpointPoseData
/// should be added here, and both conversion paths will automatically include them.
class CheckpointRecordBuilder {
  /// Build a CheckpointRecord from a CheckpointPoseData.
  ///
  /// [checkpoint] - The checkpoint data from the pose analysis API response.
  /// [imageUrlProvider] - Callback to convert base64 image data to URLs.
  ///   For toFormAnalysisRecord(): returns data URLs (data:image/jpeg;base64,...)
  ///   For saveAnalysis(): returns Cloud Storage URLs after uploading images.
  /// [proPlayerIdOverride] - Optional override for proPlayerId (e.g., default to 'paul_mcbeth').
  static CheckpointRecord build({
    required CheckpointPoseData checkpoint,
    required ImageUrlProvider imageUrlProvider,
    String? proPlayerIdOverride,
  }) {
    final CheckpointPoseData cp = checkpoint;

    return CheckpointRecord(
      // === Core Identification ===
      checkpointId: cp.checkpointId,
      checkpointName: cp.checkpointName,
      deviationSeverity: cp.deviationSeverity,
      coachingTips: cp.coachingTips,

      // === Timing/Position ===
      timestampSeconds: cp.timestampSeconds,
      detectedFrameNumber: cp.detectedFrameNumber,

      // === Pro Reference Alignment ===
      proPlayerId: proPlayerIdOverride ?? cp.proPlayerId,
      referenceHorizontalOffsetPercent: cp.referenceHorizontalOffsetPercent,
      referenceScale: cp.referenceScale,

      // === Angle Deviations (legacy map format) ===
      angleDeviations: _buildAngleDeviationsMap(cp.deviationsRaw),

      // === Images ===
      userImageUrl: imageUrlProvider(cp.userImageBase64, 'user'),
      userSkeletonUrl: imageUrlProvider(cp.userSkeletonOnlyBase64, 'user_skeleton'),
      referenceImageUrl: imageUrlProvider(
        cp.referenceSilhouetteWithSkeletonBase64 ?? cp.referenceImageBase64,
        'reference',
      ),
      referenceSkeletonUrl: imageUrlProvider(
        cp.referenceSkeletonOnlyBase64,
        'reference_skeleton',
      ),

      // === Joint Angles - Just copy the nested objects directly! ===
      userIndividualAngles: cp.userIndividualAngles,
      referenceIndividualAngles: cp.referenceIndividualAngles,
      individualDeviations: cp.individualDeviations,
    );
  }

  /// Build angle deviations map from AngleDeviations object.
  static Map<String, double>? _buildAngleDeviationsMap(
    AngleDeviations deviations,
  ) {
    final Map<String, double> map = {};

    if (deviations.shoulderRotation != null) {
      map['shoulder_rotation'] = deviations.shoulderRotation!;
    }
    if (deviations.elbowAngle != null) {
      map['elbow_angle'] = deviations.elbowAngle!;
    }
    if (deviations.hipRotation != null) {
      map['hip_rotation'] = deviations.hipRotation!;
    }
    if (deviations.kneeBend != null) {
      map['knee_bend'] = deviations.kneeBend!;
    }
    if (deviations.spineTilt != null) {
      map['spine_tilt'] = deviations.spineTilt!;
    }

    return map.isNotEmpty ? map : null;
  }
}
