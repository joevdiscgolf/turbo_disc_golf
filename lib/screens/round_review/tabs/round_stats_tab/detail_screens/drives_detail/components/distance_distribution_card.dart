import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Card showing throw distance analysis and distribution
/// Displays: Summary stats (min/max/avg) + histogram + breakdown by throw type
class DistanceDistributionCard extends StatelessWidget {
  const DistanceDistributionCard({
    super.key,
    required this.distanceStats,
    required this.distanceBucketDistribution,
    required this.throwTypeDistanceStats,
  });

  /// Overall distance stats: {min, max, average, count}
  final Map<String, dynamic> distanceStats;

  /// Distance bucket distribution: {bucket -> {count, percentage, total}}
  /// Buckets: '<200 ft', '200-250 ft', '250-300 ft', '300-350 ft', '350-400 ft', '400+ ft'
  final Map<String, Map<String, dynamic>> distanceBucketDistribution;

  /// Distance stats by throw type: {type -> {min, max, average, count}}
  final Map<String, Map<String, dynamic>> throwTypeDistanceStats;

  @override
  Widget build(BuildContext context) {
    final minDistance = (distanceStats['min'] as int?) ?? 0;
    final maxDistance = (distanceStats['max'] as int?) ?? 0;
    final avgDistance = (distanceStats['average'] as double?) ?? 0.0;
    final totalThrows = (distanceStats['count'] as int?) ?? 0;

    if (totalThrows == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: defaultCardBoxShadow(),
        ),
        child: Center(
          child: Text(
            'No throw distance data',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Throw Distance Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryStats(context, minDistance, maxDistance, avgDistance),
          const SizedBox(height: 20),
          _buildHistogram(context),
          const SizedBox(height: 20),
          _buildTypeComparison(context),
        ],
      ),
    );
  }

  /// Summary statistics row
  Widget _buildSummaryStats(
    BuildContext context,
    int minDistance,
    int maxDistance,
    double avgDistance,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatBox(
          context,
          label: 'Average',
          value: '${avgDistance.round()} ft',
          icon: '📊',
        ),
        _buildStatBox(
          context,
          label: 'Longest',
          value: '$maxDistance ft',
          icon: '🚀',
        ),
        _buildStatBox(
          context,
          label: 'Shortest',
          value: '$minDistance ft',
          icon: '📏',
        ),
      ],
    );
  }

  /// Individual stat box
  Widget _buildStatBox(
    BuildContext context, {
    required String label,
    required String value,
    required String icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: const Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Histogram of distance buckets
  Widget _buildHistogram(BuildContext context) {
    final sortedBuckets = _getSortedBuckets();

    if (sortedBuckets.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find max count for scaling
    final maxCount = sortedBuckets
        .map((e) => e.value['count'] as int)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance Distribution',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        ...sortedBuckets.map((entry) {
          final bucket = entry.key;
          final count = entry.value['count'] as int;
          final percentage = entry.value['percentage'] as double;
          final total = entry.value['total'] as int;

          return _buildHistogramBar(
            context,
            bucket: bucket,
            count: count,
            percentage: percentage,
            total: total,
            maxCount: maxCount,
          );
        }),
      ],
    );
  }

  /// Individual histogram bar
  Widget _buildHistogramBar(
    BuildContext context, {
    required String bucket,
    required int count,
    required double percentage,
    required int total,
    required int maxCount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  bucket,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 24,
                    backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Breakdown by throw type
  Widget _buildTypeComparison(BuildContext context) {
    if (throwTypeDistanceStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        const SizedBox(height: 16),
        Text(
          'By Throw Type',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        ...throwTypeDistanceStats.entries
            .map((entry) {
              final throwType = entry.key;
              final stats = entry.value;
              final avgDist = (stats['average'] as double?) ?? 0.0;
              final count = (stats['count'] as int?) ?? 0;

              if (count == 0) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        _formatThrowType(throwType),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: avgDist / 400, // Scale to 400ft max
                          minHeight: 20,
                          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${avgDist.round()} ft',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
      ],
    );
  }

  /// Get sorted bucket entries (in order)
  List<MapEntry<String, Map<String, dynamic>>> _getSortedBuckets() {
    const order = [
      '<200 ft',
      '200-250 ft',
      '250-300 ft',
      '300-350 ft',
      '350-400 ft',
      '400+ ft'
    ];

    final result = <MapEntry<String, Map<String, dynamic>>>[];
    for (var bucket in order) {
      if (distanceBucketDistribution.containsKey(bucket)) {
        result.add(
          MapEntry(bucket, distanceBucketDistribution[bucket]!),
        );
      }
    }
    return result;
  }

  /// Format throw type name
  String _formatThrowType(String type) {
    return type.substring(0, 1).toUpperCase() + type.substring(1);
  }
}
