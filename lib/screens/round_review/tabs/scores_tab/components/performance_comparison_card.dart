import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/percentage_distribution_bar.dart';

/// A card that displays performance comparison across categories with visual bars
class PerformanceComparisonCard extends StatelessWidget {
  const PerformanceComparisonCard({
    super.key,
    required this.title,
    required this.items,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<PerformanceComparisonItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildHeaderRow(context),
          const SizedBox(height: 8),
          ...items.map((item) => _buildComparisonRow(context, item)),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label column header
          SizedBox(
            width: 80,
            child: Text(
              _getFirstColumnLabel(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Holes played column header
          SizedBox(
            width: 40,
            child: Text(
              'Holes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 6),
          // Bar column header
          Expanded(
            child: Text(
              'Scores',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Average score column header
          SizedBox(
            width: 45,
            child: Text(
              'Avg',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getFirstColumnLabel() {
    // Determine label based on title
    if (title.contains('Par')) {
      return 'Par';
    } else if (title.contains('Distance')) {
      return 'Distance';
    } else if (title.contains('Hole Type')) {
      return 'Type';
    } else if (title.contains('Fairway')) {
      return 'Width';
    }
    return 'Category';
  }

  Widget _buildComparisonRow(
    BuildContext context,
    PerformanceComparisonItem item,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label column (fixed width)
          SizedBox(
            width: 80,
            child: Text(
              item.label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          // Holes played column (fixed width)
          if (item.subLabel != null)
            SizedBox(
              width: 40,
              child: Text(
                item.subLabel!.replaceAll(' holes played', ''),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(width: 6),
          // Bar column (flexible)
          Expanded(child: _buildPerformanceBar(item)),
          const SizedBox(width: 6),
          // Average score column (fixed width)
          SizedBox(
            width: 45,
            child: Text(
              item.valueLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getScoreColor(item.score),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar(PerformanceComparisonItem item) {
    // Create segments list with score rates and their corresponding colors
    // Using a list instead of a map to handle cases where multiple score types
    // have the same rate (e.g., 20% bogeys and 20% double bogeys)
    final List<DistributionSegment> segments = [
      DistributionSegment(
        value: item.birdieRate,
        color: const Color(0xFF137e66),
      ),
      DistributionSegment(
        value: item.parRate,
        color: Colors.grey,
      ),
      DistributionSegment(
        value: item.bogeyRate,
        color: const Color(0xFFFF7A7A),
      ),
      DistributionSegment(
        value: item.doubleBogeyPlusRate,
        color: const Color(0xFFD32F2F),
      ),
    ];

    return PercentageDistributionBar(
      segments: segments,
      height: 32,
      borderRadius: 4,
      segmentSpacing: 1,
      minSegmentWidth: 35,
      fontSize: 11,
    );
  }

  Color _getScoreColor(double score) {
    if (score < 0) {
      return const Color(0xFF137e66);
    } else if (score > 0) {
      return const Color(0xFFFF7A7A);
    } else {
      return Colors.grey;
    }
  }
}

/// Data model for a performance comparison item
class PerformanceComparisonItem {
  const PerformanceComparisonItem({
    required this.label,
    required this.score,
    required this.valueLabel,
    required this.birdieRate,
    required this.parRate,
    required this.bogeyRate,
    required this.doubleBogeyPlusRate,
    this.subLabel,
    this.badge,
  });

  final String label;
  final double score;
  final String valueLabel;
  final double birdieRate;
  final double parRate;
  final double bogeyRate;
  final double doubleBogeyPlusRate;
  final String? subLabel;
  final String? badge;
}
