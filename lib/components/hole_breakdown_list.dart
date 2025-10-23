import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';

class HoleClassification {
  final String label;
  final Color circleColor;
  final List<DGHole> holes;
  final String Function(DGHole) getBadgeLabel;
  final Color badgeColor;

  const HoleClassification({
    required this.label,
    required this.circleColor,
    required this.holes,
    required this.getBadgeLabel,
    required this.badgeColor,
  });
}

class HoleBreakdownList extends StatelessWidget {
  final List<HoleClassification> classifications;

  const HoleBreakdownList({super.key, required this.classifications});

  @override
  Widget build(BuildContext context) {
    final nonEmptyClassifications = classifications
        .where((c) => c.holes.isNotEmpty)
        .toList();

    if (nonEmptyClassifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < nonEmptyClassifications.length; i++) ...[
          _buildClassificationGroup(context, nonEmptyClassifications[i]),
          if (i < nonEmptyClassifications.length - 1) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  Widget _buildClassificationGroup(
    BuildContext context,
    HoleClassification classification,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          classification.label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...classification.holes.map((hole) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: classification.circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${hole.number}',
                      style: TextStyle(
                        color: _getTextColor(
                          context,
                          classification.circleColor,
                        ),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: classification.badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    classification.getBadgeLabel(hole),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: classification.badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getTextColor(BuildContext context, Color backgroundColor) {
    // Use white text for solid colors (alpha >= 0.5), theme-based for transparent
    final alpha = backgroundColor.a;
    if (alpha >= 0.5) {
      return Colors.white;
    } else {
      return Theme.of(context).colorScheme.onSurface;
    }
  }
}
