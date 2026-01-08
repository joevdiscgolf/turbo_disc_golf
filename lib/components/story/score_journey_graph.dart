import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';

/// A visual graph showing the cumulative score journey through a round.
///
/// Displays a smooth bezier curve with filled area under/over the even-par line,
/// showing how the player's score evolved hole by hole.
class ScoreJourneyGraph extends StatelessWidget {
  const ScoreJourneyGraph({
    super.key,
    required this.holes,
    this.lineColor = const Color(0xFF4ADE80), // Green for under par
    this.overParLineColor = const Color(0xFFFF6B6B), // Red for over par
    this.height = 120,
    this.showLabels = true,
    this.labelColor = Colors.white,
  });

  final List<DGHole> holes;
  final Color lineColor;
  final Color overParLineColor;
  final double height;
  final bool showLabels;
  final Color labelColor;

  /// Calculate cumulative scores at each hole
  List<int> _getCumulativeScores() {
    final List<int> cumulative = [];
    int running = 0;
    for (final DGHole hole in holes) {
      running += hole.relativeHoleScore;
      cumulative.add(running);
    }
    return cumulative;
  }

  @override
  Widget build(BuildContext context) {
    final List<int> scores = _getCumulativeScores();
    if (scores.isEmpty) {
      return SizedBox(height: height);
    }

    // Calculate min/max for Y-axis range
    final int minScore = scores.reduce(math.min);
    final int maxScore = scores.reduce(math.max);

    // Ensure we have a reasonable range (at least 4 units)
    final int range = math.max(4, maxScore - minScore + 2);
    final int yMin = minScore - 1;
    final int yMax = yMin + range;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, height),
            painter: _ScoreJourneyPainter(
              scores: scores,
              yMin: yMin,
              yMax: yMax,
              lineColor: lineColor,
              overParLineColor: overParLineColor,
              showLabels: showLabels,
              labelColor: labelColor,
            ),
          );
        },
      ),
    );
  }
}

class _ScoreJourneyPainter extends CustomPainter {
  _ScoreJourneyPainter({
    required this.scores,
    required this.yMin,
    required this.yMax,
    required this.lineColor,
    required this.overParLineColor,
    required this.showLabels,
    required this.labelColor,
  });

  final List<int> scores;
  final int yMin;
  final int yMax;
  final Color lineColor;
  final Color overParLineColor;
  final bool showLabels;
  final Color labelColor;

  /// Padding for labels
  static const double leftPadding = 28;
  static const double rightPadding = 8;
  static const double topPadding = 8;
  static const double bottomPadding = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final double graphWidth = size.width - leftPadding - rightPadding;
    final double graphHeight = size.height - topPadding - bottomPadding;

    // Calculate even par Y position
    final double evenParY = _scoreToY(0, graphHeight);

    // Draw Y-axis labels and grid lines
    if (showLabels) {
      _drawYAxisLabels(canvas, size, graphHeight);
      _drawGridLines(canvas, size, graphHeight);
    }

    // Draw even par line (baseline)
    _drawEvenParLine(canvas, size, evenParY);

    // Build the curve path
    final Path curvePath = _buildCurvePath(graphWidth, graphHeight);

    // Draw filled area under/over curve
    _drawFilledArea(canvas, curvePath, graphWidth, graphHeight, evenParY);

    // Draw the curve line on top
    _drawCurveLine(canvas, curvePath);

    // Draw X-axis hole numbers
    if (showLabels) {
      _drawXAxisLabels(canvas, size, graphWidth);
    }
  }

  double _scoreToY(int score, double graphHeight) {
    final double ratio = (score - yMin) / (yMax - yMin);
    return topPadding + graphHeight * (1 - ratio);
  }

  double _holeToX(int holeIndex, double graphWidth) {
    if (scores.length <= 1) return leftPadding;
    final double ratio = holeIndex / (scores.length - 1);
    return leftPadding + graphWidth * ratio;
  }

  void _drawYAxisLabels(Canvas canvas, Size size, double graphHeight) {
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    // Generate 4 evenly spaced labels across the full graph range
    const int numLabels = 4;
    final double step = (yMax - yMin) / (numLabels - 1);

    for (int i = 0; i < numLabels; i++) {
      final int value = (yMin + i * step).round();
      final double y = _scoreToY(value, graphHeight);

      String label;
      if (value == 0) {
        label = 'E';
      } else if (value > 0) {
        label = '+$value';
      } else {
        label = '$value';
      }

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: labelColor.withValues(alpha: 0.7),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 4, y - textPainter.height / 2),
      );
    }
  }

  void _drawGridLines(Canvas canvas, Size size, double graphHeight) {
    final Paint gridPaint = Paint()
      ..color = labelColor.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // Draw horizontal grid lines at key values
    for (int value = yMin; value <= yMax; value++) {
      if (value == 0 || value.abs() % 2 == 0) {
        final double y = _scoreToY(value, graphHeight);
        canvas.drawLine(
          Offset(leftPadding, y),
          Offset(size.width - rightPadding, y),
          gridPaint,
        );
      }
    }
  }

  void _drawEvenParLine(Canvas canvas, Size size, double evenParY) {
    final Paint evenParPaint = Paint()
      ..color = labelColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(leftPadding, evenParY),
      Offset(size.width - rightPadding, evenParY),
      evenParPaint,
    );
  }

  Path _buildCurvePath(double graphWidth, double graphHeight) {
    final Path path = Path();

    if (scores.isEmpty) return path;

    // Start at first point
    final double startX = _holeToX(0, graphWidth);
    final double startY = _scoreToY(scores[0], graphHeight);
    path.moveTo(startX, startY);

    // Use straight lines between points
    for (int i = 1; i < scores.length; i++) {
      final double currX = _holeToX(i, graphWidth);
      final double currY = _scoreToY(scores[i], graphHeight);
      path.lineTo(currX, currY);
    }

    return path;
  }

  void _drawFilledArea(
    Canvas canvas,
    Path curvePath,
    double graphWidth,
    double graphHeight,
    double evenParY,
  ) {
    // Create a closed path for the fill
    final Path fillPath = Path.from(curvePath);

    // Close the path to the baseline (even par)
    final double lastX = _holeToX(scores.length - 1, graphWidth);
    final double firstX = _holeToX(0, graphWidth);

    fillPath.lineTo(lastX, evenParY);
    fillPath.lineTo(firstX, evenParY);
    fillPath.close();

    // Determine if overall score is under or over par
    final int finalScore = scores.isNotEmpty ? scores.last : 0;
    final Color fillColor = finalScore <= 0 ? lineColor : overParLineColor;

    // Create gradient fill
    final Paint fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, topPadding),
        Offset(0, evenParY),
        [
          fillColor.withValues(alpha: 0.4),
          fillColor.withValues(alpha: 0.05),
        ],
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  void _drawCurveLine(Canvas canvas, Path curvePath) {
    // Determine line color based on final score
    final int finalScore = scores.isNotEmpty ? scores.last : 0;
    final Color strokeColor = finalScore <= 0 ? lineColor : overParLineColor;

    final Paint linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(curvePath, linePaint);
  }

  void _drawXAxisLabels(Canvas canvas, Size size, double graphWidth) {
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Determine which hole numbers to show based on count
    List<int> labelsToShow;
    if (scores.length <= 9) {
      // Show all holes for 9-hole rounds
      labelsToShow = List.generate(scores.length, (i) => i + 1);
    } else {
      // For 18-hole rounds, show 5 evenly spaced labels
      // Calculate step size to get ~5 labels including first and last
      const int numLabels = 5;
      final double step = (scores.length - 1) / (numLabels - 1);
      labelsToShow = [];
      for (int i = 0; i < numLabels; i++) {
        final int holeNum = (i * step).round() + 1;
        if (!labelsToShow.contains(holeNum)) {
          labelsToShow.add(holeNum);
        }
      }
    }

    for (final int holeNum in labelsToShow) {
      final int index = holeNum - 1;
      final double x = _holeToX(index, graphWidth);

      textPainter.text = TextSpan(
        text: '$holeNum',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: labelColor.withValues(alpha: 0.6),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          size.height - bottomPadding + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreJourneyPainter oldDelegate) {
    return scores != oldDelegate.scores ||
        yMin != oldDelegate.yMin ||
        yMax != oldDelegate.yMax ||
        lineColor != oldDelegate.lineColor;
  }
}
