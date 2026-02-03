import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

/// Card displaying V2 side-view measurements comparing user vs pro angles.
class V2MeasurementsCard extends StatelessWidget {
  const V2MeasurementsCard({super.key, required this.checkpoint});

  final CheckpointDataV2 checkpoint;

  @override
  Widget build(BuildContext context) {
    if (checkpoint.userPose.v2Measurements == null) {
      return const SizedBox.shrink();
    }

    final V2SideMeasurements user = checkpoint.userPose.v2Measurements!;
    final V2SideMeasurements? reference =
        checkpoint.proReferencePose?.v2Measurements;
    final V2SideMeasurements? deviations =
        checkpoint.deviationAnalysis.v2MeasurementDeviations;

    final List<_V2MeasurementRow> rows = [
      if (user.frontKneeAngle != null)
        _V2MeasurementRow(
          label: 'Front knee',
          userValue: user.frontKneeAngle!,
          proValue: reference?.frontKneeAngle,
          deviation: deviations?.frontKneeAngle,
        ),
      if (user.backKneeAngle != null)
        _V2MeasurementRow(
          label: 'Back knee',
          userValue: user.backKneeAngle!,
          proValue: reference?.backKneeAngle,
          deviation: deviations?.backKneeAngle,
        ),
      if (user.frontElbowAngle != null)
        _V2MeasurementRow(
          label: 'Elbow',
          userValue: user.frontElbowAngle!,
          proValue: reference?.frontElbowAngle,
          deviation: deviations?.frontElbowAngle,
        ),
      if (user.frontFootDirectionAngle != null)
        _V2MeasurementRow(
          label: 'Front foot direction',
          userValue: user.frontFootDirectionAngle!,
          proValue: reference?.frontFootDirectionAngle,
          deviation: deviations?.frontFootDirectionAngle,
        ),
      if (user.backFootDirectionAngle != null)
        _V2MeasurementRow(
          label: 'Back foot direction',
          userValue: user.backFootDirectionAngle!,
          proValue: reference?.backFootDirectionAngle,
          deviation: deviations?.backFootDirectionAngle,
        ),
      if (user.hipRotationAngle != null)
        _V2MeasurementRow(
          label: 'Hip rotation',
          userValue: user.hipRotationAngle!,
          proValue: reference?.hipRotationAngle,
          deviation: deviations?.hipRotationAngle,
        ),
      if (user.shoulderRotationAngle != null)
        _V2MeasurementRow(
          label: 'Shoulder rotation',
          userValue: user.shoulderRotationAngle!,
          proValue: reference?.shoulderRotationAngle,
          deviation: deviations?.shoulderRotationAngle,
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    final bool hasPro = reference != null;

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
