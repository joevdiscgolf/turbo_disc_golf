import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class PuttingSummaryCards extends StatelessWidget {
  final PuttStats puttingSummary;

  final double horizontalPadding;

  const PuttingSummaryCards({
    super.key,
    required this.puttingSummary,
    this.horizontalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SizedBox(
        height: 200,
        child: PageView(
          physics: const ClampingScrollPhysics(),
          padEnds: false,
          controller: PageController(viewportFraction: 0.9),
          children: [
            _buildCircleCard(
              context,
              0,
              'C1',
              puttingSummary.c1Percentage,
              puttingSummary.c1Makes,
              puttingSummary.c1Attempts,
              ['1-11 ft', '11-22 ft', '22-33 ft'],
              const Color(0xFF00F5D4),
            ),
            _buildCircleCard(
              context,
              1,
              'C2',
              puttingSummary.c2Percentage,
              puttingSummary.c2Makes,
              puttingSummary.c2Attempts,
              ['33-44 ft', '44-55 ft', '55-66 ft'],
              const Color(0xFF10E5FF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleCard(
    BuildContext context,
    int index,
    String circleName,
    double overallPercentage,
    int makes,
    int attempts,
    List<String> bucketLabels,
    Color accentColor,
  ) {
    return Container(
      margin: EdgeInsets.only(right: index == 0 ? 12 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Left side - Overall stats
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  circleName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${overallPercentage.toStringAsFixed(1)}%',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    fontSize: 26,
                  ),
                ),
                Text(
                  '$makes/$attempts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                // Add C1X for C1 card only
                if (index == 0 && circleName == 'C1') ...[
                  const SizedBox(height: 8),
                  Text(
                    'C1X: ${puttingSummary.c1xPercentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '${puttingSummary.c1xMakes}/${puttingSummary.c1xAttempts}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right side - Distance buckets
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bucketLabels
                  .map((label) => _buildBucketRow(context, label, accentColor))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBucketRow(
    BuildContext context,
    String bucketLabel,
    Color accentColor,
  ) {
    final bucketStat = puttingSummary.bucketStats[bucketLabel];

    if (bucketStat == null || bucketStat.attempts == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                bucketLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 45,
              child: Text(
                'N/A',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              bucketLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: bucketStat.makePercentage / 100,
                minHeight: 12,
                backgroundColor: accentColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${bucketStat.makePercentage.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                Text(
                  '${bucketStat.makes}/${bucketStat.attempts}',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
