import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/knee_comparison_card.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';

/// Card displaying V2 measurements comparing user vs pro angles.
/// Uses visual knee comparison for back knee angle.
/// Supports both side-view and rear-view camera angles.
class V2MeasurementsCard extends StatelessWidget {
  const V2MeasurementsCard({
    super.key,
    required this.checkpoint,
    required this.cameraAngle,
  });

  final CheckpointDataV2 checkpoint;
  final CameraAngle cameraAngle;

  @override
  Widget build(BuildContext context) {
    // Get measurements based on camera angle
    final dynamic userMeasurements = cameraAngle == CameraAngle.side
        ? checkpoint.userPose.v2Measurements.side
        : checkpoint.userPose.v2Measurements.rear;

    if (userMeasurements == null) {
      return const SizedBox.shrink();
    }

    final dynamic referenceMeasurements = cameraAngle == CameraAngle.side
        ? checkpoint.proReferencePose?.v2Measurements.side
        : checkpoint.proReferencePose?.v2Measurements.rear;

    final dynamic deviationMeasurements = cameraAngle == CameraAngle.side
        ? checkpoint.deviationAnalysis.v2MeasurementDeviations.side
        : checkpoint.deviationAnalysis.v2MeasurementDeviations.rear;

    // Only show back knee data
    if (userMeasurements.backKneeAngle == null) {
      return const SizedBox.shrink();
    }

    return AngleComparisonCard(
      backKneeUser: userMeasurements.backKneeAngle,
      backKneePro: referenceMeasurements?.backKneeAngle,
      backKneeDeviation: deviationMeasurements?.backKneeAngle,
    );
  }
}
