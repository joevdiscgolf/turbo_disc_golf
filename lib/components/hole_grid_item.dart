import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/utils/hole_score_colors.dart';

/// A reusable visual component for displaying a hole in a grid layout.
///
/// This component renders either:
/// - An incomplete hole with yellow border and warning icon
/// - A complete hole with score-based gradient background and score circle
///
/// The component is stateless and delegates all interactions via callbacks,
/// making it suitable for use with different state management approaches.
class HoleGridItem extends StatelessWidget {
  const HoleGridItem({
    super.key,
    required this.holeNumber,
    required this.holePar,
    this.holeFeet,
    this.score,
    this.relativeScore,
    required this.isIncomplete,
    required this.onTap,
    this.heroTag,
  });

  /// The hole number to display (e.g., 1, 2, 3...)
  final int holeNumber;

  /// The par value for this hole (e.g., 3, 4, 5)
  final int? holePar;

  /// Optional distance in feet for this hole
  final int? holeFeet;

  /// The total score for this hole (only used when isIncomplete=false)
  final int? score;

  /// The relative score (score - par) for this hole (only used when isIncomplete=false)
  final int? relativeScore;

  /// Whether this hole is incomplete (missing required data)
  final bool isIncomplete;

  /// Callback when the hole item is tapped
  final VoidCallback onTap;

  /// Optional hero tag for animations. If null, uses 'hole_{holeNumber}'
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    if (isIncomplete) {
      return _buildIncompleteHole(context);
    } else {
      return _buildCompleteHole(context);
    }
  }

  Widget _buildIncompleteHole(BuildContext context) {
    const Color borderColor = Color(0xFFFFEB3B);
    const Color backgroundColor = Color(0xFFFFFDE7);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: borderColor,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with hole number and warning icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$holeNumber',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Warning badge
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: borderColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.priority_high,
                          size: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Bottom row with par/distance and edit icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          holePar != null ? 'Par $holePar' : 'Par —',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        Text(
                          holeFeet != null ? '$holeFeet ft' : '— ft',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    const Icon(Icons.edit, size: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteHole(BuildContext context) {
    // Use provided values or fallback to 0
    final int displayScore = score ?? 0;
    final int displayRelativeScore = relativeScore ?? 0;

    // Get colors from utility class
    final List<Color> gradientColors = HoleScoreColors.getGradientColors(
      displayRelativeScore,
    );
    final Color scoreColor = HoleScoreColors.getScoreColor(
      displayRelativeScore,
    );

    // For par (0), use white background; otherwise use gradient

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with hole icon/number and score circle
                Hero(
                  tag: heroTag ?? 'hole_$holeNumber',
                  child: Material(
                    color: Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.golf_course,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$holeNumber',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        // Score circle (smaller, in top right)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: scoreColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$displayScore',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Bottom row with par/distance and arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          holePar != null ? 'Par $holePar' : 'Par —',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        if (holeFeet != null)
                          Text(
                            '$holeFeet ft',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                      ],
                    ),
                    Icon(
                      size: 12,
                      FlutterRemix.arrow_right_s_line,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
