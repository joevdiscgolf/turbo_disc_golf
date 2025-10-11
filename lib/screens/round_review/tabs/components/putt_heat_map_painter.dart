import 'dart:math' as math;
import 'package:flutter/material.dart';

class PuttHeatMapPainter extends CustomPainter {
  final List<Map<String, dynamic>> puttAttempts;
  final double rangeStart; // Starting distance in feet
  final double rangeEnd;   // Ending distance in feet

  PuttHeatMapPainter({
    required this.puttAttempts,
    required this.rangeStart,
    required this.rangeEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Define constants
    final center = Offset(size.width / 2, size.height - 5);
    final maxRadius = math.min(size.width * 0.75, size.height - 10) - 5;

    // Paint objects
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Generate distance rings based on range
    final distanceRange = rangeEnd - rangeStart;
    if (rangeStart == 10 && rangeEnd == 33) {
      // Circle 1: 10-33 ft
      _drawDistanceRing(canvas, center, _scaleRadius(15, maxRadius), '15 ft', gridPaint, labelPaint);
      _drawDistanceRing(canvas, center, _scaleRadius(20, maxRadius), '20 ft', gridPaint, labelPaint);
      _drawDistanceRing(canvas, center, _scaleRadius(25, maxRadius), '25 ft', gridPaint, labelPaint);
      _drawDistanceRing(canvas, center, _scaleRadius(30, maxRadius), '30 ft', gridPaint, labelPaint);
      _drawDistanceRing(canvas, center, _scaleRadius(33, maxRadius), '33 ft', gridPaint, labelPaint);
    } else if (rangeStart == 33 && rangeEnd == 66) {
      // Circle 2: 33-66 ft
      _drawDistanceRing(canvas, center, _scaleRadius(40, maxRadius), '40 ft', gridPaint, labelPaint);
      _drawDistanceRing(canvas, center, _scaleRadius(45, maxRadius), '45 ft', gridPaint, labelPaint);
      _drawDistanceRing(canvas, center, _scaleRadius(50, maxRadius), '50 ft', gridPaint, labelPaint);
      _drawDistanceRing(canvas, center, _scaleRadius(55, maxRadius), '55 ft', gridPaint, labelPaint);
      _drawDistanceRing(canvas, center, _scaleRadius(60, maxRadius), '60 ft', gridPaint, labelPaint);
      _drawDistanceRing(canvas, center, _scaleRadius(66, maxRadius), '66 ft', gridPaint, labelPaint);
    }

    // Draw radial grid lines (every 30 degrees, rotated 45 degrees right)
    // For Circle 2, start lines from inner radius to create ring effect
    final startRadius = (rangeStart == 33 && rangeEnd == 66) ? maxRadius * 0.5 : 0.0;
    for (int angle = -45; angle <= 45; angle += 30) {
      _drawRadialLine(canvas, center, maxRadius, angle.toDouble(), gridPaint, startRadius: startRadius);
    }

    // For Circle 2, draw inner boundary arc to show ring shape
    if (rangeStart == 33 && rangeEnd == 66) {
      final innerBoundaryPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final innerRect = Rect.fromCircle(center: center, radius: maxRadius * 0.5);
      canvas.drawArc(
        innerRect,
        math.pi + math.pi / 4, // Start at 225 degrees
        math.pi / 2, // Sweep 90 degrees to 315 degrees
        false,
        innerBoundaryPaint,
      );
    }

    // Draw basket at center (only for Circle 1)
    if (rangeStart == 10 && rangeEnd == 33) {
      _drawBasket(canvas, center);
    }

    // Draw putts with collision detection
    final List<Offset> occupiedPositions = [];
    for (var putt in puttAttempts) {
      final distance = putt['distance'] as double;
      final made = putt['made'] as bool;
      final holeNumber = putt['holeNumber'] as int;
      final throwIndex = putt['throwIndex'] as int;

      // Calculate radius based on distance scaled to the range
      final puttRadius = _scaleRadius(distance, maxRadius);

      // Use deterministic pseudo-random angle based on hole number and throw index
      // This ensures consistency - same putt always appears in same spot
      final seed =
          (holeNumber * 1000 + throwIndex * 100 + distance.toInt()).hashCode;
      final random = math.Random(seed);
      final angleDegrees =
          random.nextDouble() * 90 -
          45; // -45 to 45 degrees for rotated quarter-circle

      // Find non-overlapping position
      // For Circle 2, enforce minimum radius to create ring shape
      final minRadiusForRange = (rangeStart == 33 && rangeEnd == 66) ? maxRadius * 0.5 : maxRadius * 0.1;
      final position = _findNonOverlappingPosition(
        center,
        puttRadius,
        angleDegrees,
        occupiedPositions,
        maxRadius,
        random,
        minRadiusForRange,
      );

      occupiedPositions.add(position);
      _drawPuttAtPosition(canvas, position, made);
    }
  }

  // Scale a distance value to a radius based on the range
  double _scaleRadius(double distance, double maxRadius) {
    // Normalize distance to 0-1 range within rangeStart to rangeEnd
    final normalizedDistance = (distance - rangeStart) / (rangeEnd - rangeStart);
    // Clamp to 0-1 range
    final clampedDistance = math.max(0.0, math.min(1.0, normalizedDistance));

    if (rangeStart == 33 && rangeEnd == 66) {
      // Circle 2 (33-66 ft): Ring from 50% to 100% of maxRadius
      // This creates the donut effect by excluding the inner circle
      return maxRadius * (0.5 + (clampedDistance * 0.5));
    } else {
      // Circle 1 (10-33 ft): Full wedge from 10% to 100% of maxRadius
      return maxRadius * (0.1 + (clampedDistance * 0.9));
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
    // Draw arc (quarter-circle, symmetric above basket: 225° to 315°)
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      math.pi + math.pi / 4, // Start at 225 degrees (bottom-left)
      math.pi / 2, // Sweep 90 degrees to 315 degrees (bottom-right)
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
    {double startRadius = 0.0}
  ) {
    // Add 270 degrees to align with quarter circle (225° to 315°)
    final angleRadians = (angleDegrees + 270) * math.pi / 180;
    final startPoint = Offset(
      center.dx + startRadius * math.cos(angleRadians),
      center.dy + startRadius * math.sin(angleRadians),
    );
    final endPoint = Offset(
      center.dx + maxRadius * math.cos(angleRadians),
      center.dy + maxRadius * math.sin(angleRadians),
    );
    canvas.drawLine(startPoint, endPoint, paint);
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

  Offset _findNonOverlappingPosition(
    Offset center,
    double radius,
    double angleDegrees,
    List<Offset> occupiedPositions,
    double maxRadius,
    math.Random random,
    double minAllowedRadius,
  ) {
    const minDistance = 13.0; // Minimum distance between dot centers (dot radius is 5, so 13 gives good spacing)
    const maxAttempts = 100; // Increased attempts for better coverage

    // Clamp radius to max and ensure it's above minimum for ring shapes
    final clampedRadius = math.max(minAllowedRadius, math.min(radius, maxRadius * 0.95));

    // Convert angle to radians (add 270 to align with quarter circle 225° to 315°)
    final angleRadians = (angleDegrees + 270) * math.pi / 180;

    // Calculate initial position
    Offset position = Offset(
      center.dx + clampedRadius * math.cos(angleRadians),
      center.dy + clampedRadius * math.sin(angleRadians),
    );

    // Check if position overlaps with existing positions
    bool hasOverlap() {
      for (final occupied in occupiedPositions) {
        final distance = (position - occupied).distance;
        if (distance < minDistance) {
          return true;
        }
      }
      return false;
    }

    // If no overlap, return the position
    if (!hasOverlap()) {
      return position;
    }

    // Try to find a nearby non-overlapping position with increasing search radius
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // Gradually increase search radius with each attempt
      final searchRadius = (attempt / maxAttempts) * 30; // Up to 30 degree adjustment

      // Try systematic positions around the ideal spot
      final angleAdjust = (random.nextDouble() - 0.5) * searchRadius * 2;
      final radiusAdjust = (random.nextDouble() - 0.5) * (0.05 + (attempt / maxAttempts * 0.15)) * maxRadius;

      final newAngleDegrees = angleDegrees + angleAdjust;
      // Keep angle within quarter circle bounds
      final boundedAngle = math.max(-45.0, math.min(45.0, newAngleDegrees));

      final newRadius = math.max(
        minAllowedRadius, // Respect minimum radius (important for ring shape)
        math.min(clampedRadius + radiusAdjust, maxRadius * 0.95),
      );
      final newAngleRadians = (boundedAngle + 270) * math.pi / 180;

      position = Offset(
        center.dx + newRadius * math.cos(newAngleRadians),
        center.dy + newRadius * math.sin(newAngleRadians),
      );

      if (!hasOverlap()) {
        return position;
      }
    }

    // If we still couldn't find a spot, try random positions across the entire area
    for (int attempt = 0; attempt < 50; attempt++) {
      final randomAngle = (random.nextDouble() * 90 - 45);
      // Calculate available range respecting minimum radius
      final availableRange = maxRadius * 0.95 - minAllowedRadius;
      final randomRadius = minAllowedRadius + (random.nextDouble() * availableRange);
      final randomAngleRadians = (randomAngle + 270) * math.pi / 180;

      position = Offset(
        center.dx + randomRadius * math.cos(randomAngleRadians),
        center.dy + randomRadius * math.sin(randomAngleRadians),
      );

      if (!hasOverlap()) {
        return position;
      }
    }

    // Last resort: return the original position
    return position;
  }

  void _drawPuttAtPosition(Canvas canvas, Offset position, bool made) {
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
    return oldDelegate.puttAttempts != puttAttempts ||
        oldDelegate.rangeStart != rangeStart ||
        oldDelegate.rangeEnd != rangeEnd;
  }
}
