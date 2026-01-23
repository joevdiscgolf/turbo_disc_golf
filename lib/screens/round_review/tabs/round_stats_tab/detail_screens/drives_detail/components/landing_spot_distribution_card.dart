import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Card showing landing spot distribution for all tee shots grouped by par
/// Displays: dot grid visualization + percentage breakdown with progress bars
class LandingSpotDistributionCard extends StatelessWidget {
  const LandingSpotDistributionCard({
    super.key,
    required this.landingSpotDistributionByPar,
  });

  /// Map of par -> landing spot name -> {count, percentage, total}
  final Map<int, Map<String, Map<String, dynamic>>>
  landingSpotDistributionByPar;

  static const Color _parkedColor = Color(0xFFFFA726); // Orange
  static const Color _c1Color = Color(0xFF10B981); // Green
  static const Color _c2Color = Color(0xFF3B82F6); // Blue
  static const Color _fairwayColor = Color(0xFF8B5CF6); // Purple
  static const Color _obColor = Color(0xFFEF4444); // Red
  static const Color _otherColor = Color(0xFF9CA3AF); // Gray

  @override
  Widget build(BuildContext context) {
    if (landingSpotDistributionByPar.isEmpty) {
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
            'No landing spot data',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF9CA3AF)),
          ),
        ),
      );
    }

    // Sort pars in order (3, 4, 5, etc.)
    final sortedPars = landingSpotDistributionByPar.keys.toList()..sort();

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
            'Landing spots',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedPars.asMap().entries.map((entry) {
            final index = entry.key;
            final par = entry.value;
            final isLast = index == sortedPars.length - 1;
            final spotDistribution = landingSpotDistributionByPar[par]!;
            return _buildParSection(
              context,
              par,
              spotDistribution,
              showDivider: !isLast,
            );
          }),
        ],
      ),
    );
  }

  /// Build section for a single par
  Widget _buildParSection(
    BuildContext context,
    int par,
    Map<String, Map<String, dynamic>> spotDistribution, {
    bool showDivider = true,
  }) {
    final sortedSpots = _getSortedSpots(spotDistribution);
    final totalHoles = spotDistribution.values.first['total'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Par $par',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF9CA3AF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$totalHoles hole${totalHoles == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDotGrid(context, sortedSpots),
        const SizedBox(height: 12),
        _buildBreakdown(context, sortedSpots),
        if (showDivider) ...[
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  /// Get sorted spot entries in defined order, filtering out 0% entries
  List<MapEntry<String, Map<String, dynamic>>> _getSortedSpots(
    Map<String, Map<String, dynamic>> spotDistribution,
  ) {
    const order = [
      'parked',
      'circle1',
      'circle2',
      'fairway',
      'offFairway',
      'outOfBounds',
      'hazard',
    ];

    final result = <MapEntry<String, Map<String, dynamic>>>[];
    for (var spotName in order) {
      if (spotDistribution.containsKey(spotName)) {
        final data = spotDistribution[spotName]!;
        final percentage = data['percentage'] as double;
        // Only include spots with > 0%
        if (percentage > 0) {
          result.add(MapEntry(spotName, data));
        }
      }
    }
    return result;
  }

  /// Dot grid visualization
  Widget _buildDotGrid(
    BuildContext context,
    List<MapEntry<String, Map<String, dynamic>>> sortedEntries,
  ) {
    // Create list of dots (each dot represents one drive)
    final dots = <String>[];
    for (var entry in sortedEntries) {
      final count = entry.value['count'] as int;
      final spotName = entry.key;
      for (int i = 0; i < count; i++) {
        dots.add(spotName);
      }
    }

    // If no drives, show empty state
    if (dots.isEmpty) {
      return Center(
        child: Text(
          'No tee shot data',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF9CA3AF)),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: dots.map((spot) {
        return _buildDot(spot);
      }).toList(),
    );
  }

  /// Individual dot for dot grid
  Widget _buildDot(String spotName) {
    final color = _getSpotColor(spotName);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 2),
        ],
      ),
    );
  }

  /// Get color for a landing spot
  Color _getSpotColor(String spotName) {
    switch (spotName.toLowerCase()) {
      case 'parked':
        return _parkedColor;
      case 'circle1':
        return _c1Color;
      case 'circle2':
        return _c2Color;
      case 'fairway':
        return _fairwayColor;
      case 'offfairway':
        return _otherColor;
      case 'outofbounds':
        return _obColor;
      case 'hazard':
        return _obColor;
      case 'inbasket':
        return _c1Color;
      default:
        return _otherColor;
    }
  }

  /// Get display name for landing spot
  String _getSpotDisplayName(String spotName) {
    switch (spotName.toLowerCase()) {
      case 'parked':
        return 'Parked';
      case 'circle1':
        return 'C1';
      case 'circle2':
        return 'C2';
      case 'fairway':
        return 'Fairway';
      case 'outofbounds':
        return 'OB';
      case 'inbasket':
        return 'In Basket';
      case 'hazard':
        return 'Hazard';
      case 'offfairway':
        return 'Off Fairway';
      default:
        return spotName;
    }
  }

  /// Breakdown with progress bars
  Widget _buildBreakdown(
    BuildContext context,
    List<MapEntry<String, Map<String, dynamic>>> sortedEntries,
  ) {
    if (sortedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ...sortedEntries.map((entry) {
          final spotName = entry.key;
          final count = entry.value['count'] as int;
          final percentage = entry.value['percentage'] as double;
          final color = _getSpotColor(spotName);
          final displayName = _getSpotDisplayName(spotName);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 4,
                          backgroundColor: color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($count)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
