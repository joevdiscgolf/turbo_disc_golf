import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/editable_hole_detail_dialog.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

/// Grid of holes that opens editable dialogs when tapped.
///
/// Reuses the visual style from HolesGrid but with editing functionality.
class EditableHolesGrid extends StatelessWidget {
  const EditableHolesGrid({
    super.key,
    required this.round,
    required this.roundParser,
  });

  final DGRound round;
  final RoundParser roundParser;

  @override
  Widget build(BuildContext context) {
    // Calculate width for 3 columns with no spacing
    final double screenWidth =
        MediaQuery.of(context).size.width - 32; // minus horizontal margin
    final double itemWidth = screenWidth / 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 0,
        runSpacing: 0,
        children: round.holes.asMap().entries.map((entry) {
          final int holeIndex = entry.key;
          final DGHole hole = entry.value;

          return SizedBox(
            width: itemWidth,
            child: _HoleGridItem(
              hole: hole,
              holeIndex: holeIndex,
              roundParser: roundParser,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HoleGridItem extends StatelessWidget {
  const _HoleGridItem({
    required this.hole,
    required this.holeIndex,
    required this.roundParser,
  });

  final DGHole hole;
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
              hole: hole,
              holeIndex: holeIndex,
              roundParser: roundParser,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int score = hole.holeScore;
    final int relativeScore = hole.relativeHoleScore;

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
                  tag: 'editable_hole_${hole.number}',
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
                              '${hole.number}',
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
                  ),
                ),
                const SizedBox(height: 6),
                // Par and distance
                Text(
                  'Par ${hole.par}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                if (hole.feet != null)
                  Text(
                    '${hole.feet} ft',
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
