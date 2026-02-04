import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';

/// Card displaying V2 measurements comparing user vs pro angles.
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

    final List<_V2MeasurementRow> rows = [
      if (userMeasurements.frontKneeAngle != null)
        _V2MeasurementRow(
          label: 'Front knee',
          userValue: userMeasurements.frontKneeAngle!,
          proValue: referenceMeasurements?.frontKneeAngle,
          deviation: deviationMeasurements?.frontKneeAngle,
        ),
      if (userMeasurements.backKneeAngle != null)
        _V2MeasurementRow(
          label: 'Back knee',
          userValue: userMeasurements.backKneeAngle!,
          proValue: referenceMeasurements?.backKneeAngle,
          deviation: deviationMeasurements?.backKneeAngle,
        ),
      if (userMeasurements.frontElbowAngle != null)
        _V2MeasurementRow(
          label: 'Elbow',
          userValue: userMeasurements.frontElbowAngle!,
          proValue: referenceMeasurements?.frontElbowAngle,
          deviation: deviationMeasurements?.frontElbowAngle,
        ),
      // Only show foot direction angles for side view (null for rear view)
      if (cameraAngle == CameraAngle.side &&
          userMeasurements.frontFootDirectionAngle != null)
        _V2MeasurementRow(
          label: 'Front foot direction',
          userValue: userMeasurements.frontFootDirectionAngle!,
          proValue: referenceMeasurements?.frontFootDirectionAngle,
          deviation: deviationMeasurements?.frontFootDirectionAngle,
        ),
      if (cameraAngle == CameraAngle.side &&
          userMeasurements.backFootDirectionAngle != null)
        _V2MeasurementRow(
          label: 'Back foot direction',
          userValue: userMeasurements.backFootDirectionAngle!,
          proValue: referenceMeasurements?.backFootDirectionAngle,
          deviation: deviationMeasurements?.backFootDirectionAngle,
        ),
      if (userMeasurements.hipRotationAngle != null)
        _V2MeasurementRow(
          label: 'Hip rotation',
          userValue: userMeasurements.hipRotationAngle!,
          proValue: referenceMeasurements?.hipRotationAngle,
          deviation: deviationMeasurements?.hipRotationAngle,
        ),
      if (userMeasurements.shoulderRotationAngle != null)
        _V2MeasurementRow(
          label: 'Shoulder rotation',
          userValue: userMeasurements.shoulderRotationAngle!,
          proValue: referenceMeasurements?.shoulderRotationAngle,
          deviation: deviationMeasurements?.shoulderRotationAngle,
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    final bool hasPro = referenceMeasurements != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Form measurements',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map((row) => _buildRow(row, hasPro: hasPro)),
        ],
      ),
    );
  }

  Widget _buildRow(_V2MeasurementRow row, {required bool hasPro}) {
    Color? deviationColor;
    if (row.deviation != null) {
      final double absDeviation = row.deviation!.abs();
      if (absDeviation <= 10) {
        deviationColor = const Color(0xFF137e66);
      } else if (absDeviation <= 20) {
        deviationColor = const Color(0xFFD97706);
      } else {
        deviationColor = const Color(0xFFDC2626);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'You: ${row.userValue.toStringAsFixed(1)}°',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          if (hasPro) ...[
            Expanded(
              flex: 2,
              child: Text(
                row.proValue != null
                    ? 'Pro: ${row.proValue!.toStringAsFixed(1)}°'
                    : '',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
            SizedBox(
              width: 50,
              child: deviationColor != null
                  ? Text(
                      '${row.deviation! >= 0 ? '+' : ''}${row.deviation!.toStringAsFixed(1)}°',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: deviationColor,
                      ),
                      textAlign: TextAlign.right,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}

class _V2MeasurementRow {
  const _V2MeasurementRow({
    required this.label,
    required this.userValue,
    this.proValue,
    this.deviation,
  });

  final String label;
  final double userValue;
  final double? proValue;
  final double? deviation;
}
