import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

enum ScoreMode { relative, raw }

class HoleScoreScatterplot extends StatefulWidget {
  static const bool groupOverlappingPoints = false;

  final DGRound round;

  const HoleScoreScatterplot({super.key, required this.round});

  @override
  State<HoleScoreScatterplot> createState() => _HoleScoreScatterplotState();
}

class _HoleScoreScatterplotState extends State<HoleScoreScatterplot> {
  ScoreMode _scoreMode = ScoreMode.raw;

  @override
  Widget build(BuildContext context) {
    final List<HoleDataPoint> dataPoints = _prepareDataPoints();

    if (dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scores by distance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildModeToggle(),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: _ScatterplotChart(
                dataPoints: dataPoints,
                scoreMode: _scoreMode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: 'Raw',
            mode: ScoreMode.raw,
            isSelected: _scoreMode == ScoreMode.raw,
          ),
          _buildToggleButton(
            label: 'Relative',
            mode: ScoreMode.relative,
            isSelected: _scoreMode == ScoreMode.relative,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required ScoreMode mode,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _scoreMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  List<HoleDataPoint> _prepareDataPoints() {
    final List<HoleDataPoint> points = [];

    for (final hole in widget.round.holes) {
      if (hole.feet > 0) {
        points.add(
          HoleDataPoint(
            holeNumber: hole.number,
            distance: hole.feet.toDouble(),
            relativeToPar: hole.relativeHoleScore,
            rawScore: hole.holeScore,
          ),
        );
      }
    }

    return points;
  }
}

class HoleDataPoint {
  final int holeNumber;
  final double distance;
  final int relativeToPar;
  final int rawScore;

  HoleDataPoint({
    required this.holeNumber,
    required this.distance,
    required this.relativeToPar,
    required this.rawScore,
  });
}

class _ScatterplotChart extends StatelessWidget {
  final List<HoleDataPoint> dataPoints;
  final ScoreMode scoreMode;

  const _ScatterplotChart({required this.dataPoints, required this.scoreMode});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScatterplotPainter(
        dataPoints: dataPoints,
        scoreMode: scoreMode,
        groupOverlappingPoints: HoleScoreScatterplot.groupOverlappingPoints,
        textStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        gridColor: SenseiColors.gray[50]!,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ScatterplotPainter extends CustomPainter {
  final List<HoleDataPoint> dataPoints;
  final ScoreMode scoreMode;
  final bool groupOverlappingPoints;
  final TextStyle textStyle;
  final Color gridColor;

  _ScatterplotPainter({
    required this.dataPoints,
    required this.scoreMode,
    required this.groupOverlappingPoints,
    required this.textStyle,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    const double leftPadding = 20.0;
    const double rightPadding = 20.0;
    const double topPadding = 12.0;
    const double bottomPadding = 40.0;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    // Calculate data ranges
    final double minDistance = dataPoints
        .map((p) => p.distance)
        .reduce(math.min);
    final double maxDistance = dataPoints
        .map((p) => p.distance)
        .reduce(math.max);

    final int minScore;
    final int maxScore;
    final int yMin;
    final int yMax;

    if (scoreMode == ScoreMode.relative) {
      minScore = dataPoints.map((p) => p.relativeToPar).reduce(math.min);
      maxScore = dataPoints.map((p) => p.relativeToPar).reduce(math.max);
      // Ensure we include par line (y=0) in the range
      yMin = math.min(minScore, -1);
      yMax = math.max(maxScore, 2);
    } else {
      minScore = dataPoints.map((p) => p.rawScore).reduce(math.min);
      maxScore = dataPoints.map((p) => p.rawScore).reduce(math.max);
      // Use exact min/max for raw scores (no padding)
      yMin = minScore;
      yMax = maxScore;
    }

    // Add some padding to the distance range
    final double distancePadding = (maxDistance - minDistance) * 0.1;
    final double xMin = math.max(0, minDistance - distancePadding);
    final double xMax = maxDistance + distancePadding;

    // Draw grid and axes
    _drawGrid(
      canvas,
      size,
      leftPadding,
      topPadding,
      chartWidth,
      chartHeight,
      xMin,
      xMax,
      yMin,
      yMax,
    );

    if (groupOverlappingPoints) {
      // Group points that would overlap
      final Map<String, List<HoleDataPoint>> groupedPoints = {};
      for (final point in dataPoints) {
        final int scoreValue = scoreMode == ScoreMode.relative
            ? point.relativeToPar
            : point.rawScore;
        final String key = '${point.distance.toInt()}_$scoreValue';
        groupedPoints.putIfAbsent(key, () => []).add(point);
      }

      // Separate single and grouped points for proper z-ordering
      final List<MapEntry<String, List<HoleDataPoint>>> singlePoints = [];
      final List<MapEntry<String, List<HoleDataPoint>>> multiPoints = [];

      for (final entry in groupedPoints.entries) {
        if (entry.value.length == 1) {
          singlePoints.add(entry);
        } else {
          multiPoints.add(entry);
        }
      }

      // Draw single points first (bottom layer)
      for (final entry in singlePoints) {
        final HoleDataPoint point = entry.value.first;
        final int scoreValue = scoreMode == ScoreMode.relative
            ? point.relativeToPar
            : point.rawScore;
        final double x =
            leftPadding +
            ((point.distance - xMin) / (xMax - xMin)) * chartWidth;
        final double y =
            topPadding +
            chartHeight -
            ((scoreValue - yMin) / (yMax - yMin)) * chartHeight;

        _drawSinglePoint(canvas, Offset(x, y), point, scoreMode);
      }

      // Draw grouped points last (top layer)
      for (final entry in multiPoints) {
        final List<HoleDataPoint> points = entry.value;
        final HoleDataPoint firstPoint = points.first;
        final int scoreValue = scoreMode == ScoreMode.relative
            ? firstPoint.relativeToPar
            : firstPoint.rawScore;
        final double x =
            leftPadding +
            ((firstPoint.distance - xMin) / (xMax - xMin)) * chartWidth;
        final double y =
            topPadding +
            chartHeight -
            ((scoreValue - yMin) / (yMax - yMin)) * chartHeight;

        _drawGroupedPoint(canvas, Offset(x, y), points, textStyle, scoreMode);
      }
    } else {
      // Draw all points individually without grouping
      // Track x positions to offset overlapping points
      final Map<int, int> xPositionCounts = {};

      for (final point in dataPoints) {
        final int scoreValue = scoreMode == ScoreMode.relative
            ? point.relativeToPar
            : point.rawScore;
        final double baseX =
            leftPadding +
            ((point.distance - xMin) / (xMax - xMin)) * chartWidth;
        final double y =
            topPadding +
            chartHeight -
            ((scoreValue - yMin) / (yMax - yMin)) * chartHeight;

        // Round x to nearest pixel to detect same-column points
        final int xKey = baseX.round();
        final int count = xPositionCounts[xKey] ?? 0;
        xPositionCounts[xKey] = count + 1;

        // Offset horizontally if multiple points at same x position
        // Use a small offset (3 pixels) to separate dots horizontally
        final double xOffset = count * 6.0;
        final double adjustedX = baseX + xOffset;

        _drawSinglePoint(canvas, Offset(adjustedX, y), point, scoreMode);
      }
    }
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    double leftPadding,
    double topPadding,
    double chartWidth,
    double chartHeight,
    double xMin,
    double xMax,
    int yMin,
    int yMax,
  ) {
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw Y-axis labels and horizontal grid lines (only at integer values)
    for (int score = yMin; score <= yMax; score++) {
      final double y =
          topPadding +
          chartHeight -
          ((score - yMin) / (yMax - yMin)) * chartHeight;

      // Draw horizontal grid line (all the same style)
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );

      // Draw Y-axis label (format depends on mode)
      final String label = scoreMode == ScoreMode.relative
          ? (score > 0 ? '+$score' : '$score')
          : '$score';
      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Draw X-axis labels with consistent intervals (no vertical grid lines)
    // Determine appropriate interval based on range
    final double range = xMax - xMin;
    final int interval = _getConsistentInterval(range);

    // Find the first interval mark at or after xMin
    final int firstMark = ((xMin / interval).ceil() * interval).toInt();

    // Draw labels at consistent intervals
    for (int distance = firstMark; distance <= xMax; distance += interval) {
      final double x =
          leftPadding + ((distance - xMin) / (xMax - xMin)) * chartWidth;

      // Draw X-axis label
      final String label = '${distance}ft';
      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, topPadding + chartHeight + 20),
      );
    }
  }

  int _getConsistentInterval(double range) {
    if (range <= 200) {
      return 50;
    } else if (range <= 400) {
      return 100;
    } else if (range <= 800) {
      return 150;
    } else {
      return 200;
    }
  }

  void _drawSinglePoint(
    Canvas canvas,
    Offset position,
    HoleDataPoint point,
    ScoreMode scoreMode,
  ) {
    // Always color code according to relative score
    final Color dotColor = _getColorForRelativeScore(point.relativeToPar);

    // Draw outer glow/shadow
    final Paint glowPaint = Paint()
      ..color = dotColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(position, 4, glowPaint);

    // Draw main circle
    final Paint circlePaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 4, circlePaint);

    // Draw white outer ring for delineation (drawn last so it's on top)
    final Paint whiteRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(position, 4, whiteRingPaint);
  }

  void _drawGroupedPoint(
    Canvas canvas,
    Offset position,
    List<HoleDataPoint> points,
    TextStyle textStyle,
    ScoreMode scoreMode,
  ) {
    // Use the color of the first point (they all have the same score)
    // Always color code according to relative score
    final Color dotColor = _getColorForRelativeScore(
      points.first.relativeToPar,
    );

    // Draw outer glow/shadow (larger to accommodate text)
    final Paint glowPaint = Paint()
      ..color = dotColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(position, 16, glowPaint);

    // Draw main circle (larger to fit text comfortably)
    final Paint circlePaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 14, circlePaint);

    // Draw count number
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '${points.length}',
        style: textStyle.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  Color _getColorForRelativeScore(int relativeToPar) {
    if (relativeToPar <= -2) {
      return const Color(0xFF2196F3); // Eagle or better - blue
    } else if (relativeToPar == -1) {
      return const Color(0xFF4CAF50); // Birdie - green
    } else if (relativeToPar == 0) {
      return Colors.grey; // Par - matches performance card
    } else if (relativeToPar == 1) {
      return const Color(0xFFFF7A7A); // Bogey - red
    } else {
      return const Color(0xFFD32F2F); // Double bogey or worse - dark red
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterplotPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.scoreMode != scoreMode ||
        oldDelegate.groupOverlappingPoints != groupOverlappingPoints;
  }
}
