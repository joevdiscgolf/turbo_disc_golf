import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

/// A compact scorecard widget that displays hole-by-hole scores in rows.
///
/// Shows hole numbers with scores, where non-par scores are displayed
/// in colored circles (green for under par, red for over par).
/// Each row displays a maximum of 9 holes.
class CompactScorecard extends StatelessWidget {
  const CompactScorecard({
    super.key,
    required this.holes,
    this.holeNumberColor,
    this.parScoreColor,
    this.useWhiteCircleText = true,
    this.circleSize = 24.0,
  });

  static const int _maxHolesPerRow = 9;

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
    // Split holes into rows of maximum 9 holes each
    final List<List<DGHole>> rows = [];
    for (int i = 0; i < holes.length; i += _maxHolesPerRow) {
      final int end = (i + _maxHolesPerRow < holes.length)
          ? i + _maxHolesPerRow
          : holes.length;
      rows.add(holes.sublist(i, end));
    }

    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          _buildScoreRow(rows[i], rows[0].length),
          if (i < rows.length - 1) const SizedBox(height: 12),
        ],
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

  Widget _buildScoreRow(List<DGHole> rowHoles, int totalColumns) {
    // Scale font sizes based on circle size
    final double scoreFontSize = circleSize * 0.5;
    final double holeNumberFontSize = circleSize * 0.42;

    // Build hole widgets
    final List<Widget> children = rowHoles.map((hole) {
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
                color: holeNumberColor ?? SenseiColors.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (locator
                    .get<FeatureFlagService>()
                    .showHoleDistancesInScorecard &&
                hole.feet > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${hole.feet}',
                style: TextStyle(
                  fontSize: holeNumberFontSize - 2,
                  color: holeNumberColor ?? SenseiColors.gray[400]!,
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
    }).toList();

    // Add empty spacers for alignment if this row has fewer holes
    final int emptySlots = totalColumns - rowHoles.length;
    for (int i = 0; i < emptySlots; i++) {
      children.add(const Expanded(child: SizedBox()));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: children,
    );
  }
}
