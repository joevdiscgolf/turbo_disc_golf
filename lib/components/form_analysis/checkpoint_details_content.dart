import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_checkpoint.dart';
import 'package:turbo_disc_golf/services/form_analysis/form_reference_positions.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Content widget for checkpoint details education panel.
///
/// Shows all backhand checkpoint positions with their descriptions and key points.
class CheckpointDetailsContent extends StatelessWidget {
  const CheckpointDetailsContent({super.key, required this.checkpoint});

  final CheckpointDataV2 checkpoint;

  @override
  Widget build(BuildContext context) {
    final List<FormCheckpoint> allPositions =
        FormReferencePositions.backhandCheckpoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allPositions
          .map((position) => _buildPositionCard(context, position))
          .toList(),
    );
  }

  Widget _buildPositionCard(BuildContext context, FormCheckpoint position) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${position.orderIndex + 1}. ${position.name}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: SenseiColors.darkGray,
            ),
          ),
          // const SizedBox(height: 8),
          // Text(
          //   position.description,
          //   style: TextStyle(
          //     fontSize: 14,
          //     color: Colors.grey[700],
          //     height: 1.4,
          //   ),
          // ),
          if (position.keyPoints.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...position.keyPoints.map(
              (keyPoint) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${keyPoint.name}: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                                height: 1.4,
                              ),
                            ),
                            TextSpan(
                              text: keyPoint.idealState,
                              style: TextStyle(
                                fontSize: 13,
                                color: SenseiColors.gray[500],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
