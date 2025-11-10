import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_hole_detail_dialog.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/hole_re_record_dialog.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

/// Grid of holes that opens editable dialogs when tapped.
///
/// Supports both complete holes (DGHole) and incomplete holes (PotentialDGHole).
class EditableHolesGrid extends StatelessWidget {
  const EditableHolesGrid({
    super.key,
    required this.potentialRound,
    required this.roundParser,
  });

  final PotentialDGRound potentialRound;
  final RoundParser roundParser;

  @override
  Widget build(BuildContext context) {
    if (potentialRound.holes == null || potentialRound.holes!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No holes found'),
        ),
      );
    }

    // Calculate width for 3 columns with no spacing
    final double screenWidth =
        MediaQuery.of(context).size.width - 32; // minus horizontal margin
    final double itemWidth = screenWidth / 3;

    return Wrap(
      spacing: 0,
      runSpacing: 0,
      children: potentialRound.holes!.asMap().entries.map((entry) {
        final int holeIndex = entry.key;
        final PotentialDGHole hole = entry.value;

        return SizedBox(
          width: itemWidth,
          child: _HoleGridItem(
            potentialHole: hole,
            holeIndex: holeIndex,
            roundParser: roundParser,
          ),
        );
      }).toList(),
    );
  }
}

class _HoleGridItem extends StatelessWidget {
  const _HoleGridItem({
    required this.potentialHole,
    required this.holeIndex,
    required this.roundParser,
  });

  final PotentialDGHole potentialHole;
  final int holeIndex;
  final RoundParser roundParser;

  void _showEditableHoleDialog(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: EditableHoleDetailDialog(
              potentialHole: potentialHole,
              holeIndex: holeIndex,
              roundParser: roundParser,
            ),
          );
        },
      ),
    );
  }

  void _showReRecordDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => HoleReRecordDialog(
        holeNumber: potentialHole.number ?? holeIndex + 1,
        holeIndex: holeIndex,
        holePar: potentialHole.par,
        holeFeet: potentialHole.feet,
      ),
    );
  }

  bool _hasCriticalIssues() {
    return (potentialHole.throws == null || potentialHole.throws!.isEmpty) ||
        potentialHole.feet == null;
  }

  bool _isIncomplete() {
    return !potentialHole.hasRequiredFields;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty =
        potentialHole.throws == null || potentialHole.throws!.isEmpty;
    final bool isIncomplete = _isIncomplete();

    // Incomplete hole (missing required fields) - RED/AMBER WARNING STATE
    if (isIncomplete) {
      final List<String> missingFields = potentialHole.getMissingFields();
      final Color borderColor = const Color(0xFFD32F2F); // Red for required
      final Color backgroundColor = const Color(0xFFFFEBEE); // Light red

      return GestureDetector(
        onTap: () => _showEditableHoleDialog(context),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: borderColor,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with hole icon/number and warning icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: borderColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${potentialHole.number ?? '?'}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: borderColor,
                                ),
                          ),
                        ],
                      ),
                      // Warning badge
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: borderColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.priority_high,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Par and distance (show "—" for missing)
                  Text(
                    'Par ${potentialHole.par ?? '—'}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: borderColor.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    potentialHole.feet != null
                        ? '${potentialHole.feet} ft'
                        : '— ft',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: borderColor.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Missing info label
                  Text(
                    'Missing: ${missingFields.take(2).join(', ')}${missingFields.length > 2 ? '...' : ''}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: borderColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to fix',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: borderColor,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Empty hole styling (has structure but no throws)
    if (isEmpty) {
      return GestureDetector(
        onTap: () => _showEditableHoleDialog(context),

        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.grey.withValues(alpha: 0.5),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Container(
            height: 94,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with hole icon/number and add icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 16,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${potentialHole.number ?? '?'}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                    // Empty indicator
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.add, size: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Par and distance
                Text(
                  'Par ${potentialHole.par ?? '?'}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
                if (potentialHole.feet != null)
                  Text(
                    '${potentialHole.feet} ft',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  )
                else
                  Text(
                    'Tap to add',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF137e66),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Regular/Complete hole styling
    // Calculate score manually since PotentialDGHole doesn't have computed properties
    final int throwsCount = potentialHole.throws?.length ?? 0;
    final int penaltyStrokes =
        potentialHole.throws?.fold<int>(
          0,
          (prev, t) => prev + (t.penaltyStrokes ?? 0),
        ) ??
        0;
    final int score = throwsCount + penaltyStrokes;
    final int par = potentialHole.par ?? 3;
    final int relativeScore = score - par;

    // Determine gradient colors based on relative score
    List<Color> gradientColors;
    Color scoreColor;
    if (relativeScore < 0) {
      // Birdie - green gradient
      gradientColors = [
        const Color(0xFF137e66).withValues(alpha: 0.25),
        const Color(0xFF137e66).withValues(alpha: 0.15),
      ];
      scoreColor = const Color(0xFF137e66);
    } else if (relativeScore == 0) {
      // Par - darker grey gradient
      gradientColors = [
        Colors.grey.withValues(alpha: 0.35),
        Colors.grey.withValues(alpha: 0.25),
      ];
      scoreColor = Colors.grey;
    } else if (relativeScore == 1) {
      // Bogey - light red gradient
      gradientColors = [
        const Color(0xFFFF7A7A).withValues(alpha: 0.25),
        const Color(0xFFFF7A7A).withValues(alpha: 0.15),
      ];
      scoreColor = const Color(0xFFFF7A7A);
    } else {
      // Double bogey+ - dark red gradient
      gradientColors = [
        const Color(0xFFD32F2F).withValues(alpha: 0.25),
        const Color(0xFFD32F2F).withValues(alpha: 0.15),
      ];
      scoreColor = const Color(0xFFD32F2F);
    }

    return InkWell(
      onTap: () => _showEditableHoleDialog(context),
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with hole icon/number and score circle
                Hero(
                  tag: 'editable_hole_${potentialHole.number}',
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
                              '${potentialHole.number}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Re-record button for holes with critical issues
                            if (_hasCriticalIssues())
                              GestureDetector(
                                onTap: () => _showReRecordDialog(context),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9D4EDD),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mic,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
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
                                  '$score',
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Par and distance
                Text(
                  'Par ${potentialHole.par}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                if (potentialHole.feet != null)
                  Text(
                    '${potentialHole.feet} ft',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    size: 12,
                    FlutterRemix.arrow_right_s_line,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
