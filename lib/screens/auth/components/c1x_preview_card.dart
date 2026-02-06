import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class C1xPreviewCard extends StatelessWidget {
  const C1xPreviewCard({super.key});

  static const Color accentColor = Color(0xFF4ECDC4);
  static const double percentage = 0.72;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCircularIndicator(),
        const SizedBox(height: 8),
        _buildTextContent(),
      ],
    );
  }

  Widget _buildCircularIndicator() {
    return SizedBox(
      width: 60,
      height: 60,
      child: CustomPaint(
        painter: _CircularProgressPainter(
          progress: percentage,
          progressColor: accentColor,
          backgroundColor: SenseiColors.gray[200]!,
        ),
        child: Center(
          child: Text(
            '${(percentage * 100).toInt()}%',
            style: TextStyle(
              color: SenseiColors.gray[700],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'C1X Putting',
          style: TextStyle(
            color: SenseiColors.gray[700],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '(11-33 ft)',
          style: TextStyle(
            color: SenseiColors.gray[500],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 180,
          child: _buildProgressBar(),
        ),
        const SizedBox(height: 5),
        Text(
          'Above Average',
          style: TextStyle(
            color: accentColor.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: SenseiColors.gray[200],
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4ECDC4), Color(0xFF44CF9C)],
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 6;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // Background circle
    final Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final Paint progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: const [Color(0xFF4ECDC4), Color(0xFF44CF9C)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
