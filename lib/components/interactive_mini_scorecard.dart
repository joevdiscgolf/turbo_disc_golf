import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_story_v3_content.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class InteractiveMiniScorecard extends StatelessWidget {
  const InteractiveMiniScorecard({
    super.key,
    required this.holes,
    this.highlightedHoleRange,
  });

  final List<DGHole> holes;
  final HoleRange? highlightedHoleRange;

  @override
  Widget build(BuildContext context) {
    debugPrint('🎯 InteractiveMiniScorecard building:');
    debugPrint(
      '  - highlightedHoleRange: ${highlightedHoleRange?.displayString ?? "none"}',
    );
    debugPrint('  - Total holes: ${holes.length}');

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        8 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section label (commented out to save vertical space)
          // if (highlightedHoleRange != null)
          //   _buildSectionLabel(highlightedHoleRange!),
          //
          // const SizedBox(height: 12),

          // Scorecard rows
          _buildScorecard(),
        ],
      ),
    );
  }

  // Widget _buildSectionLabel(HoleRange range) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF6366F1).withValues(alpha: 0.1),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Text(
  //       range.displayString,
  //       style: const TextStyle(
  //         fontSize: 13,
  //         fontWeight: FontWeight.w600,
  //         color: Color(0xFF6366F1),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildScorecard() {
    // Split into two rows (front/back)
    final int halfLength = (holes.length / 2).ceil();
    final List<DGHole> firstRow = holes.take(halfLength).toList();
    final List<DGHole> secondRow = holes.skip(halfLength).toList();

    return Column(
      children: [
        _buildScoreRow(firstRow),
        if (secondRow.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildScoreRow(secondRow),
        ],
      ],
    );
  }

  Widget _buildScoreRow(List<DGHole> rowHoles) {
    // Find which holes in this row are highlighted
    final List<int> highlightedIndices = [];
    for (int i = 0; i < rowHoles.length; i++) {
      if (highlightedHoleRange?.contains(rowHoles[i].number) ?? false) {
        highlightedIndices.add(i);
      }
    }

    // Determine if we need to draw a bounding box
    final bool hasHighlightedHoles = highlightedIndices.isNotEmpty;
    final int? firstHighlightedIndex = hasHighlightedHoles
        ? highlightedIndices.first
        : null;
    final int? lastHighlightedIndex = hasHighlightedHoles
        ? highlightedIndices.last
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double cellWidth = totalWidth / rowHoles.length;

        return Stack(
          children: [
            // The row of hole cells
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: rowHoles.map((hole) {
                return _buildHoleCell(hole, false);
              }).toList(),
            ),

            // Highlighted bounding box (if any holes are highlighted in this row)
            if (hasHighlightedHoles &&
                firstHighlightedIndex != null &&
                lastHighlightedIndex != null)
              Positioned(
                left: firstHighlightedIndex * cellWidth,
                width:
                    (lastHighlightedIndex - firstHighlightedIndex + 1) *
                    cellWidth,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF6366F1),
                      width: 2,
                    ),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 11), // Hole number height
                      SizedBox(height: 4), // Spacing
                      SizedBox(height: 20), // Score circle height
                      SizedBox(height: 2), // Bottom padding
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHoleCell(DGHole hole, bool isHighlighted) {
    final int score = hole.holeScore;
    final int scoreToPar = hole.relativeHoleScore;
    final bool isPar = scoreToPar == 0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hole number
            Text(
              '${hole.number}',
              style: TextStyle(
                fontSize: 11,
                color: SenseiColors.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),

            // Score circle or plain text for par
            isPar
                ? SizedBox(
                    height: 20,
                    child: Center(
                      child: Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getScoreColor(scoreToPar),
                    ),
                    child: Center(
                      child: Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 2), // Bottom padding
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int scoreToPar) {
    // Match CompactScorecard color logic
    if (scoreToPar <= -3) return const Color(0xFFFFD700); // Gold
    if (scoreToPar == -2) return const Color(0xFF2196F3); // Blue
    if (scoreToPar == -1) return const Color(0xFF137e66); // Green
    if (scoreToPar == 1) return const Color(0xFFFF7A7A); // Light red
    if (scoreToPar == 2) return const Color(0xFFE53935); // Medium red
    return const Color(0xFFB71C1C); // Dark red
  }
}
