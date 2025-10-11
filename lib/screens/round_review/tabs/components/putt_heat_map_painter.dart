import 'dart:math' as math;
import 'package:flutter/material.dart';

class PuttHeatMapPainter extends CustomPainter {
  final List<Map<String, dynamic>> puttAttempts;

  PuttHeatMapPainter({required this.puttAttempts});

  @override
  void paint(Canvas canvas, Size size) {
    // Define constants
    final center = Offset(size.width / 2, size.height - 20);
    final maxRadius = math.min(size.width / 2, size.height - 40) - 20;

    // Scale factors for different distances
    final c1Radius = maxRadius * 0.5; // 33 feet
    final c2Radius = maxRadius; // 66 feet

    // Paint objects
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Draw distance arcs
    _drawDistanceRing(canvas, center, maxRadius * 0.15, '10 ft', gridPaint, labelPaint);
    _drawDistanceRing(canvas, center, maxRadius * 0.30, '20 ft', gridPaint, labelPaint);
    _drawDistanceRing(canvas, center, c1Radius, 'C1 (33 ft)', gridPaint, labelPaint);
    _drawDistanceRing(canvas, center, maxRadius * 0.75, '50 ft', gridPaint, labelPaint);
    _drawDistanceRing(canvas, center, c2Radius, 'C2 (66 ft)', gridPaint, labelPaint);

    // Draw radial grid lines (every 30 degrees)
    for (int angle = 0; angle <= 180; angle += 30) {
      _drawRadialLine(canvas, center, maxRadius, angle.toDouble(), gridPaint);
    }

    // Draw basket at center
    _drawBasket(canvas, center);

    // Draw putts
    for (var putt in puttAttempts) {
      final distance = putt['distance'] as double;
      final made = putt['made'] as bool;
      final holeNumber = putt['holeNumber'] as int;
      final throwIndex = putt['throwIndex'] as int;

      // Calculate radius based on distance (max 66 feet = c2Radius)
      final puttRadius = (distance / 66) * c2Radius;

      // Use deterministic pseudo-random angle based on hole number and throw index
      // This ensures consistency - same putt always appears in same spot
      final seed = (holeNumber * 1000 + throwIndex * 100 + distance.toInt()).hashCode;
      final random = math.Random(seed);
      final angleDegrees = random.nextDouble() * 180; // 0 to 180 degrees for semi-circle

      _drawPutt(canvas, center, puttRadius, angleDegrees, made);
    }
  }

  void _drawDistanceRing(
    Canvas canvas,
    Offset center,
    double radius,
    String label,
    Paint paint,
    TextPainter textPainter,
  ) {
    // Draw arc (semi-circle)
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      math.pi, // Start at 180 degrees (left side)
      math.pi, // Sweep 180 degrees to right side
      false,
      paint,
    );

    // Draw label at top center of arc
    textPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.grey.withValues(alpha: 0.6),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();

    final labelOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - radius - textPainter.height - 2,
    );
    textPainter.paint(canvas, labelOffset);
  }

  void _drawRadialLine(
    Canvas canvas,
    Offset center,
    double maxRadius,
    double angleDegrees,
    Paint paint,
  ) {
    final angleRadians = (angleDegrees + 180) * math.pi / 180;
    final endPoint = Offset(
      center.dx + maxRadius * math.cos(angleRadians),
      center.dy + maxRadius * math.sin(angleRadians),
    );
    canvas.drawLine(center, endPoint, paint);
  }

  void _drawBasket(Canvas canvas, Offset center) {
    // Draw basket icon (simple representation)
    final basketPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..style = PaintingStyle.fill;

    // Outer circle
    canvas.drawCircle(center, 8, basketPaint);

    // Inner circle (white)
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, innerPaint);

    // Pole representation
    final polePaint = Paint()
      ..color = const Color(0xFF757575)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 3, polePaint);
  }

  void _drawPutt(
    Canvas canvas,
    Offset center,
    double radius,
    double angleDegrees,
    bool made,
  ) {
    // Clamp radius to max (don't draw putts outside C2)
    final clampedRadius = math.min(radius, center.dy - 20);

    // Convert angle to radians (add 180 to flip to correct orientation)
    final angleRadians = (angleDegrees + 180) * math.pi / 180;

    // Calculate position
    final position = Offset(
      center.dx + clampedRadius * math.cos(angleRadians),
      center.dy + clampedRadius * math.sin(angleRadians),
    );

    // Draw putt dot
    final puttPaint = Paint()
      ..color = made ? const Color(0xFF4CAF50) : const Color(0xFFFF7A7A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 5, puttPaint);

    // Draw white border for better visibility
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(position, 5, borderPaint);
  }

  @override
  bool shouldRepaint(covariant PuttHeatMapPainter oldDelegate) {
    return oldDelegate.puttAttempts != puttAttempts;
  }
}
