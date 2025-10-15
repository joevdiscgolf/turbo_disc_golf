import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/components/round_review_stat_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/screens/generic_stats_screen.dart';
import 'package:turbo_disc_golf/utils/naming_constants.dart';

class ShotTypeBirdieRatesCard extends StatefulWidget {
  const ShotTypeBirdieRatesCard({
    super.key,
    required this.teeShotBirdieRateStats,
    required this.teeShotBirdieDetails,
  });

  final Map<String, BirdieRateStats> teeShotBirdieRateStats;
  final Map<String, List<MapEntry<DGHole, DiscThrow>>> teeShotBirdieDetails;

  @override
  State<ShotTypeBirdieRatesCard> createState() =>
      _ShotTypeBirdieRatesCardState();
}

class _ShotTypeBirdieRatesCardState extends State<ShotTypeBirdieRatesCard> {
  @override
  Widget build(BuildContext context) {
    return RoundReviewStatCard(
      title: 'Birdie %',
      hasArrow: true,
      accentColor: const Color(0xFF00F5D4),

      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GenericStatsScreen(statsWidget: _buildBirdieDetailsList()),
          ),
        );
      },
      children: [
        ...widget.teeShotBirdieRateStats.entries.map(
          (entry) =>
              _buildTeeShotBirdieRateRow(context, entry.key, entry.value),
        ),
        const SizedBox(height: 16),

        // Expandable details section
      ],
    );
  }

  Widget _buildBirdieDetailsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: widget.teeShotBirdieDetails.entries.map((entry) {
          final throwType = entry.key;
          final holeThrowPairs = entry.value;

          // Convert throwType to readable name
          String displayName = throwType;
          try {
            final technique = ThrowTechnique.values.firstWhere(
              (t) => t.name == throwType,
            );
            displayName = throwTechniqueToName[technique] ?? throwType;
          } catch (e) {
            displayName = throwType;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.toUpperCase(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00F5D4),
                  ),
                ),
                const SizedBox(height: 8),
                ...holeThrowPairs.map(
                  (pair) => _buildBirdieDetailRow(pair.key, pair.value),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBirdieDetailRow(DGHole hole, DiscThrow teeShot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF00F5D4).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Hole number
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${hole.number}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00F5D4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Hole details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Par ${hole.par} • ${hole.feet} ft',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (teeShot.distanceFeetBeforeThrow != null &&
                    teeShot.distanceFeetBeforeThrow! > 0)
                  Text(
                    'Threw ${teeShot.distanceFeetBeforeThrow} ft',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (teeShot.technique != null)
                  Text(
                    throwTechniqueToName[teeShot.technique] ??
                        teeShot.technique!.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeeShotBirdieRateRow(
    BuildContext context,
    String throwType,
    BirdieRateStats stats,
  ) {
    // Convert throwType string to readable name
    String displayName = throwType;
    try {
      final technique = ThrowTechnique.values.firstWhere(
        (t) => t.name == throwType,
      );
      displayName = throwTechniqueToName[technique] ?? throwType;
    } catch (e) {
      // If conversion fails, use the raw throwType
      displayName = throwType;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Throw type name on the left
          SizedBox(
            width: 100,
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          // Progress bar in the middle (expanded)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stats.percentage / 100,
                minHeight: 12,
                backgroundColor: const Color(0xFF00F5D4).withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF00F5D4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Percentage and counts on the right
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stats.percentage.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00F5D4),
                  ),
                ),
                Text(
                  '${stats.birdieCount}/${stats.totalAttempts}',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
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
