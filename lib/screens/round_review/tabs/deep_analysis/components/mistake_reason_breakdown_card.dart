import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class MistakeReasonBreakdownCard extends StatelessWidget {
  final List<MistakeTypeSummary> mistakeTypes;

  const MistakeReasonBreakdownCard({
    super.key,
    required this.mistakeTypes,
  });

  @override
  Widget build(BuildContext context) {
    final int totalMistakes = mistakeTypes.fold<int>(
      0,
      (sum, mistake) => sum + mistake.count,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mistakes Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total: $totalMistakes',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...mistakeTypes.map((mistake) {
            final percentage = totalMistakes > 0
                ? (mistake.count / totalMistakes * 100).toStringAsFixed(0)
                : '0';

            const accentColor = Color(0xFFFF7A7A);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          mistake.label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${mistake.count} ($percentage%)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalMistakes > 0 ? mistake.count / totalMistakes : 0,
                      minHeight: 12,
                      backgroundColor: accentColor.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
