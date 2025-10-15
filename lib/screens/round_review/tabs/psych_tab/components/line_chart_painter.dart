import 'dart:math' as math;
import 'package:flutter/material.dart';

class LineChartPainter extends CustomPainter {
  final List<LineChartDataPoint> dataPoints;
  final double maxAbsScore;
  final int totalHoles;

  LineChartPainter({
    required this.dataPoints,
    required this.maxAbsScore,
    required this.totalHoles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // Define padding
    const leftPadding = 40.0;
    const rightPadding = 20.0;
    const topPadding = 20.0;
    const bottomPadding = 30.0;

    // Calculate chart area
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartLeft = leftPadding;
    final chartTop = topPadding;

    // Draw background grid
    _drawGrid(
      canvas,
      size,
      chartLeft,
      chartTop,
      chartWidth,
      chartHeight,
      maxAbsScore,
    );

    // Draw axes
    _drawAxes(
      canvas,
      size,
      chartLeft,
      chartTop,
      chartWidth,
      chartHeight,
      maxAbsScore,
      totalHoles,
    );

    // Draw the line and points
    _drawLineAndPoints(
      canvas,
      chartLeft,
      chartTop,
      chartWidth,
      chartHeight,
      maxAbsScore,
    );
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    double chartLeft,
    double chartTop,
    double chartWidth,
    double chartHeight,
    double maxScore,
  ) {
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Horizontal grid lines (for scores)
    final centerY = chartTop + chartHeight / 2;

    // Draw center line (par)
    final centerLinePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(chartLeft, centerY),
      Offset(chartLeft + chartWidth, centerY),
      centerLinePaint,
    );

    // Draw grid lines above and below par
    final scoreRange = math.max(maxScore, 2.0); // At least show +/- 2
    final gridSteps = scoreRange <= 2 ? 1 : 2;

    for (int i = gridSteps; i <= scoreRange; i += gridSteps) {
      // Above par (positive scores)
      final yAbove = centerY + (i / scoreRange) * (chartHeight / 2);
      if (yAbove <= chartTop + chartHeight) {
        canvas.drawLine(
          Offset(chartLeft, yAbove),
          Offset(chartLeft + chartWidth, yAbove),
          gridPaint,
        );
      }

      // Below par (negative scores)
      final yBelow = centerY - (i / scoreRange) * (chartHeight / 2);
      if (yBelow >= chartTop) {
        canvas.drawLine(
          Offset(chartLeft, yBelow),
          Offset(chartLeft + chartWidth, yBelow),
          gridPaint,
        );
      }
    }
  }

  void _drawAxes(
    Canvas canvas,
    Size size,
    double chartLeft,
    double chartTop,
    double chartWidth,
    double chartHeight,
    double maxScore,
    int totalHoles,
  ) {
    final axisPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Y-axis
    canvas.drawLine(
      Offset(chartLeft, chartTop),
      Offset(chartLeft, chartTop + chartHeight),
      axisPaint,
    );

    // X-axis (at par line)
    final centerY = chartTop + chartHeight / 2;
    canvas.drawLine(
      Offset(chartLeft, centerY),
      Offset(chartLeft + chartWidth, centerY),
      axisPaint,
    );

    // Y-axis labels (scores)
    _drawYAxisLabels(
      canvas,
      chartLeft,
      chartTop,
      chartHeight,
      maxScore,
    );

    // X-axis labels (hole numbers)
    _drawXAxisLabels(
      canvas,
      chartLeft,
      chartTop,
      chartWidth,
      chartHeight,
      totalHoles,
    );
  }

  void _drawYAxisLabels(
    Canvas canvas,
    double chartLeft,
    double chartTop,
    double chartHeight,
    double maxScore,
  ) {
    final centerY = chartTop + chartHeight / 2;
    final scoreRange = math.max(maxScore, 2.0);

    // Draw labels for scores
    final labelsToShow = <int>[];
    if (scoreRange <= 2) {
      labelsToShow.addAll([-2, -1, 0, 1, 2]);
    } else {
      for (int i = -scoreRange.ceil(); i <= scoreRange.ceil(); i += 2) {
        labelsToShow.add(i);
      }
    }

    for (final score in labelsToShow) {
      final y = centerY - (score / scoreRange) * (chartHeight / 2);
      if (y >= chartTop && y <= chartTop + chartHeight) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: score > 0 ? '+$score' : score.toString(),
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: score == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(chartLeft - textPainter.width - 8, y - textPainter.height / 2),
        );
      }
    }
  }

  void _drawXAxisLabels(
    Canvas canvas,
    double chartLeft,
    double chartTop,
    double chartWidth,
    double chartHeight,
    int totalHoles,
  ) {
    // Show hole numbers, but limit labels to avoid crowding
    final labelInterval = totalHoles > 12 ? 3 : (totalHoles > 6 ? 2 : 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      if (point.holeNumber % labelInterval == 0 || point.holeNumber == 1) {
        final x = chartLeft + (i / (dataPoints.length - 1)) * chartWidth;
        final textPainter = TextPainter(
          text: TextSpan(
            text: point.holeNumber.toString(),
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, chartTop + chartHeight + 8),
        );
      }
    }
  }

  void _drawLineAndPoints(
    Canvas canvas,
    double chartLeft,
    double chartTop,
    double chartWidth,
    double chartHeight,
    double maxScore,
  ) {
    if (dataPoints.isEmpty) return;

    final centerY = chartTop + chartHeight / 2;
    final scoreRange = math.max(maxScore, 2.0);

    // Calculate positions for all points
    final positions = <Offset>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final x = chartLeft + (i / (dataPoints.length - 1)) * chartWidth;
      final y = centerY - (point.score / scoreRange) * (chartHeight / 2);
      positions.add(Offset(x, y.clamp(chartTop, chartTop + chartHeight)));
    }

    // Draw connecting lines
    for (int i = 0; i < positions.length - 1; i++) {
      final start = positions[i];
      final end = positions[i + 1];

      final linePaint = Paint()
        ..color = const Color(0xFF2196F3).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawLine(start, end, linePaint);
    }

    // Draw points
    for (int i = 0; i < positions.length; i++) {
      final point = dataPoints[i];
      final position = positions[i];

      // Point color based on score
      final Color pointColor;
      if (point.score > 0) {
        pointColor = const Color(0xFFFF7A7A); // Red for over par
      } else if (point.score < 0) {
        pointColor = const Color(0xFF4CAF50); // Green for under par
      } else {
        pointColor = const Color(0xFF2196F3); // Blue for par
      }

      // Draw point
      final pointPaint = Paint()
        ..color = pointColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, 4, pointPaint);

      // Draw white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(position, 4, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.maxAbsScore != maxAbsScore ||
        oldDelegate.totalHoles != totalHoles;
  }
}

class LineChartDataPoint {
  final int holeNumber;
  final double score;

  LineChartDataPoint({
    required this.holeNumber,
    required this.score,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineChartDataPoint &&
          runtimeType == other.runtimeType &&
          holeNumber == other.holeNumber &&
          score == other.score;

  @override
  int get hashCode => holeNumber.hashCode ^ score.hashCode;
}
