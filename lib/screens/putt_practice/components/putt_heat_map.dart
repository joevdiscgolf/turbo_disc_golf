import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/detected_putt_attempt.dart';

/// Heat map visualization of putt attempts
class PuttHeatMap extends StatelessWidget {
  final List<DetectedPuttAttempt> attempts;
  final double size;

  const PuttHeatMap({
    super.key,
    required this.attempts,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: CustomPaint(
          painter: _HeatMapPainter(attempts: attempts),
          child: _buildLabels(),
        ),
      ),
    );
  }

  Widget _buildLabels() {
    return Stack(
      children: [
        // Direction labels
        const Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Text(
            'HIGH',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Text(
            'LOW',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'LEFT',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: RotatedBox(
              quarterTurns: 1,
              child: Text(
                'RIGHT',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        // Legend
        Positioned(
          bottom: 24,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLegendItem(Colors.green, 'Make'),
              const SizedBox(width: 8),
              _buildLegendItem(Colors.red, 'Miss'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _HeatMapPainter extends CustomPainter {
  final List<DetectedPuttAttempt> attempts;

  _HeatMapPainter({required this.attempts});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = math.min(size.width, size.height) / 2 - 30;

    // Draw background circles
    _drawBackgroundCircles(canvas, centerX, centerY, radius);

    // Draw basket (center)
    _drawBasket(canvas, centerX, centerY);

    // Draw putt attempts
    for (final DetectedPuttAttempt attempt in attempts) {
      _drawAttempt(canvas, centerX, centerY, radius, attempt);
    }
  }

  void _drawBackgroundCircles(
    Canvas canvas,
    double centerX,
    double centerY,
    double radius,
  ) {
    final Paint circlePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Inner circle (close misses)
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius * 0.3,
      circlePaint,
    );

    // Middle circle
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius * 0.6,
      circlePaint,
    );

    // Outer circle
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      circlePaint,
    );

    // Crosshairs
    final Paint linePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(centerX - radius, centerY),
      Offset(centerX + radius, centerY),
      linePaint,
    );

    canvas.drawLine(
      Offset(centerX, centerY - radius),
      Offset(centerX, centerY + radius),
      linePaint,
    );
  }

  void _drawBasket(Canvas canvas, double centerX, double centerY) {
    // Basket center point
    final Paint basketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      6,
      basketPaint,
    );

    // Basket ring
    final Paint ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(centerX, centerY),
      12,
      ringPaint,
    );
  }

  void _drawAttempt(
    Canvas canvas,
    double centerX,
    double centerY,
    double radius,
    DetectedPuttAttempt attempt,
  ) {
    // Map relative coordinates to canvas
    // relativeX: -1 (left) to 1 (right)
    // relativeY: -1 (low) to 1 (high)
    // Note: In canvas, Y increases downward, so we flip it
    final double x = centerX + attempt.relativeX * radius;
    final double y = centerY - attempt.relativeY * radius;

    final Color color = attempt.made ? Colors.green : Colors.red;

    // Draw glow
    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset(x, y), 10, glowPaint);

    // Draw point
    final Paint pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), 6, pointPaint);

    // Draw border
    final Paint borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(Offset(x, y), 6, borderPaint);
  }

  @override
  bool shouldRepaint(_HeatMapPainter oldDelegate) {
    return oldDelegate.attempts.length != attempts.length;
  }
}

/// Compact heat map widget for inline display
class CompactPuttHeatMap extends StatelessWidget {
  final List<DetectedPuttAttempt> attempts;
  final double size;

  const CompactPuttHeatMap({
    super.key,
    required this.attempts,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          painter: _CompactHeatMapPainter(attempts: attempts),
        ),
      ),
    );
  }
}

class _CompactHeatMapPainter extends CustomPainter {
  final List<DetectedPuttAttempt> attempts;

  _CompactHeatMapPainter({required this.attempts});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = math.min(size.width, size.height) / 2 - 8;

    // Draw simple background circle
    final Paint circlePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(Offset(centerX, centerY), radius, circlePaint);

    // Draw center
    final Paint centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), 3, centerPaint);

    // Draw attempts
    for (final DetectedPuttAttempt attempt in attempts) {
      final double x = centerX + attempt.relativeX * radius;
      final double y = centerY - attempt.relativeY * radius;

      final Paint pointPaint = Paint()
        ..color = attempt.made ? Colors.green : Colors.red
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_CompactHeatMapPainter oldDelegate) {
    return oldDelegate.attempts.length != attempts.length;
  }
}
