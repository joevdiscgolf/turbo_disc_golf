import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/wrist_speed_data.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Card displaying wrist speed data with a line chart and max speed stat
class WristSpeedChartCard extends StatelessWidget {
  const WristSpeedChartCard({
    super.key,
    required this.wristSpeedData,
  });

  final WristSpeedData wristSpeedData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SenseiColors.gray[100]!),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildMaxSpeedStat(),
          const SizedBox(height: 16),
          _buildChart(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.speed,
          size: 16,
          color: SenseiColors.gray[500],
        ),
        const SizedBox(width: 8),
        Text(
          'WRIST SPEED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: SenseiColors.gray[500],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMaxSpeedStat() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.1),
            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.flash_on,
              color: Color(0xFF6366F1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Max wrist speed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: SenseiColors.gray[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      wristSpeedData.maxSpeedMph.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'mph',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6366F1).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.show_chart,
              size: 14,
              color: SenseiColors.gray[500],
            ),
            const SizedBox(width: 6),
            Text(
              'Speed over time',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: SenseiColors.gray[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: SenseiColors.gray[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              painter: _WristSpeedChartPainter(
                speeds: wristSpeedData.speedsMph,
                maxSpeed: wristSpeedData.maxSpeedMph,
                maxSpeedIndex: wristSpeedData.maxSpeedFrame -
                    wristSpeedData.startFrame,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Start',
              style: TextStyle(
                fontSize: 10,
                color: SenseiColors.gray[400],
              ),
            ),
            Text(
              'Frame ${wristSpeedData.startFrame} - ${wristSpeedData.endFrame}',
              style: TextStyle(
                fontSize: 10,
                color: SenseiColors.gray[400],
              ),
            ),
            Text(
              'Release',
              style: TextStyle(
                fontSize: 10,
                color: SenseiColors.gray[400],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WristSpeedChartPainter extends CustomPainter {
  _WristSpeedChartPainter({
    required this.speeds,
    required this.maxSpeed,
    required this.maxSpeedIndex,
  });

  final List<double> speeds;
  final double maxSpeed;
  final int maxSpeedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (speeds.isEmpty) return;

    const double leftPadding = 35.0;
    const double rightPadding = 10.0;
    const double topPadding = 15.0;
    const double bottomPadding = 20.0;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;
    final double chartLeft = leftPadding;
    final double chartTop = topPadding;

    // Draw grid and axes
    _drawGrid(canvas, chartLeft, chartTop, chartWidth, chartHeight);
    _drawYAxisLabels(canvas, chartLeft, chartTop, chartHeight);

    // Draw the speed line and area
    _drawSpeedArea(canvas, chartLeft, chartTop, chartWidth, chartHeight);
    _drawSpeedLine(canvas, chartLeft, chartTop, chartWidth, chartHeight);

    // Highlight max speed point
    _drawMaxSpeedPoint(canvas, chartLeft, chartTop, chartWidth, chartHeight);
  }

  void _drawGrid(
    Canvas canvas,
    double chartLeft,
    double chartTop,
    double chartWidth,
    double chartHeight,
  ) {
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Horizontal grid lines
    const int gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final double y = chartTop + (chartHeight / gridLines) * i;
      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartLeft + chartWidth, y),
        gridPaint,
      );
    }
  }

  void _drawYAxisLabels(
    Canvas canvas,
    double chartLeft,
    double chartTop,
    double chartHeight,
  ) {
    // Round maxSpeed up to nearest 10 for clean axis
    final double axisMax = (maxSpeed / 10).ceil() * 10.0;
    const int steps = 4;

    for (int i = 0; i <= steps; i++) {
      final double value = axisMax * (1 - i / steps);
      final double y = chartTop + (chartHeight / steps) * i;

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: value.toInt().toString(),
          style: TextStyle(
            color: Colors.grey.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(chartLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }
  }

  void _drawSpeedArea(
    Canvas canvas,
    double chartLeft,
    double chartTop,
    double chartWidth,
    double chartHeight,
  ) {
    if (speeds.length < 2) return;

    final double axisMax = (maxSpeed / 10).ceil() * 10.0;
    final Path areaPath = Path();

    // Start at bottom left
    areaPath.moveTo(chartLeft, chartTop + chartHeight);

    // Draw to first point
    final double firstY =
        chartTop + chartHeight - (speeds[0] / axisMax) * chartHeight;
    areaPath.lineTo(chartLeft, firstY);

    // Draw through all points
    for (int i = 0; i < speeds.length; i++) {
      final double x = chartLeft + (i / (speeds.length - 1)) * chartWidth;
      final double y =
          chartTop + chartHeight - (speeds[i] / axisMax) * chartHeight;
      areaPath.lineTo(x, y);
    }

    // Close the path back to bottom
    areaPath.lineTo(chartLeft + chartWidth, chartTop + chartHeight);
    areaPath.close();

    // Fill with gradient
    final Paint areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF6366F1).withValues(alpha: 0.3),
          const Color(0xFF6366F1).withValues(alpha: 0.05),
        ],
      ).createShader(
        Rect.fromLTWH(chartLeft, chartTop, chartWidth, chartHeight),
      );

    canvas.drawPath(areaPath, areaPaint);
  }

  void _drawSpeedLine(
    Canvas canvas,
    double chartLeft,
    double chartTop,
    double chartWidth,
    double chartHeight,
  ) {
    if (speeds.length < 2) return;

    final double axisMax = (maxSpeed / 10).ceil() * 10.0;
    final Path linePath = Path();

    for (int i = 0; i < speeds.length; i++) {
      final double x = chartLeft + (i / (speeds.length - 1)) * chartWidth;
      final double y =
          chartTop + chartHeight - (speeds[i] / axisMax) * chartHeight;

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final Paint linePaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  void _drawMaxSpeedPoint(
    Canvas canvas,
    double chartLeft,
    double chartTop,
    double chartWidth,
    double chartHeight,
  ) {
    if (maxSpeedIndex < 0 || maxSpeedIndex >= speeds.length) return;

    final double axisMax = (maxSpeed / 10).ceil() * 10.0;
    final double x =
        chartLeft + (maxSpeedIndex / (speeds.length - 1)) * chartWidth;
    final double y =
        chartTop + chartHeight - (maxSpeed / axisMax) * chartHeight;

    // Outer glow
    final Paint glowPaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 10, glowPaint);

    // Outer ring
    final Paint outerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 6, outerPaint);

    // Inner dot
    final Paint innerPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 4, innerPaint);

    // Draw "MAX" label above the point
    final TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: 'MAX',
        style: TextStyle(
          color: Color(0xFF6366F1),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position label above the point, ensuring it stays within bounds
    double labelX = x - textPainter.width / 2;
    labelX = labelX.clamp(chartLeft, chartLeft + chartWidth - textPainter.width);
    final double labelY = math.max(chartTop - 2, y - 22);

    textPainter.paint(canvas, Offset(labelX, labelY));
  }

  @override
  bool shouldRepaint(covariant _WristSpeedChartPainter oldDelegate) {
    return oldDelegate.speeds != speeds ||
        oldDelegate.maxSpeed != maxSpeed ||
        oldDelegate.maxSpeedIndex != maxSpeedIndex;
  }
}
