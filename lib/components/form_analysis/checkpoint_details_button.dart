import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/services/form_analysis/form_reference_positions.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Coaching tips preview with "View details" CTA for a checkpoint.
class CheckpointDetailsButton extends StatelessWidget {
  const CheckpointDetailsButton({
    super.key,
    required this.checkpoint,
    required this.onTap,
  });

  final CheckpointDataV2 checkpoint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<String> topTips =
        FormReferencePositions.getCoachingTips(checkpoint.metadata.checkpointId)
            .take(3)
            .toList();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checkpoint.metadata.checkpointName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  if (topTips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...topTips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(color: Color(0xFF137e66)),
                            ),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    'View details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SenseiColors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              color: SenseiColors.gray.shade300,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
