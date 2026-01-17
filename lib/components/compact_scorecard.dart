import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

/// A compact scorecard widget that displays hole-by-hole scores in two rows.
///
/// Shows hole numbers with scores, where non-par scores are displayed
/// in colored circles (green for under par, red for over par).
class CompactScorecard extends StatelessWidget {
  const CompactScorecard({
    super.key,
    required this.holes,
    this.holeNumberColor,
    this.parScoreColor,
    this.useWhiteCircleText = true,
    this.circleSize = 24.0,
  });

  final List<DGHole> holes;

  /// Color for hole number text. Defaults to grey.
  final Color? holeNumberColor;

  /// Color for par score text. Defaults to black87.
  final Color? parScoreColor;

  /// Whether to use white text inside colored circles.
  /// Set to false for light backgrounds where you want dark circle text.
  final bool useWhiteCircleText;

  /// Size of the circular score indicators. Defaults to 24.0.
  final double circleSize;

  @override
  Widget build(BuildContext context) {
    // Split into two rows (first 9, second 9)
    final int halfLength = (holes.length / 2).ceil();
    final List<DGHole> firstNine = holes.take(halfLength).toList();
    final List<DGHole> secondNine = holes.skip(halfLength).toList();

    return Column(
      children: [
        _buildScoreRow(firstNine),
        const SizedBox(height: 12),
        _buildScoreRow(secondNine),
      ],
    );
  }

  /// Returns the appropriate color for a score based on how far it is from par.
  Color _getScoreColor(int scoreToPar) {
    if (scoreToPar == 0) {
      return const Color(0xFFF5F5F5); // Par (not used for circles)
    } else if (scoreToPar <= -3) {
      return const Color(0xFFFFD700); // Albatross or better - gold
    } else if (scoreToPar == -2) {
      return const Color(0xFF2196F3); // Eagle - blue
    } else if (scoreToPar == -1) {
      return const Color(0xFF137e66); // Birdie - green
    } else if (scoreToPar == 1) {
      return const Color(0xFFFF7A7A); // Bogey - light red
    } else if (scoreToPar == 2) {
      return const Color(0xFFE53935); // Double bogey - medium red
    } else {
      return const Color(0xFFB71C1C); // Triple bogey+ - dark red
    }
  }

  Widget _buildScoreRow(List<DGHole> rowHoles) {
    // Scale font sizes based on circle size
    final double scoreFontSize = circleSize * 0.5;
    final double holeNumberFontSize = circleSize * 0.42;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: rowHoles.map((hole) {
        final int score = hole.holeScore;
        final int scoreToPar = hole.relativeHoleScore;
        final Color color = _getScoreColor(scoreToPar);
        final bool isPar = scoreToPar == 0;

        return Expanded(
          child: Column(
            children: [
              Text(
                '${hole.number}',
                style: TextStyle(
                  fontSize: holeNumberFontSize,
                  color: holeNumberColor ?? TurbColors.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showHoleDistancesInScorecard && hole.feet > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${hole.feet}',
                  style: TextStyle(
                    fontSize: holeNumberFontSize - 2,
                    color: holeNumberColor ?? TurbColors.gray[400]!,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              isPar
                  ? SizedBox(
                      height: circleSize,
                      child: Center(
                        child: Text(
                          '$score',
                          style: TextStyle(
                            fontSize: scoreFontSize,
                            fontWeight: FontWeight.w600,
                            color: parScoreColor ?? Colors.black87,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                      child: Center(
                        child: Text(
                          '$score',
                          style: TextStyle(
                            fontSize: scoreFontSize,
                            fontWeight: FontWeight.w600,
                            color: useWhiteCircleText
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
