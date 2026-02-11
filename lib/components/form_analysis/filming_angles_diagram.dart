import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// A bird's eye view diagram showing the ideal camera position for filming.
///
/// Shows a dot representing the thrower, an arrow for direction of motion,
/// and a camera icon with a dotted line showing the viewing angle.
class FilmingAnglesDiagram extends StatelessWidget {
  const FilmingAnglesDiagram({
    super.key,
    required this.cameraAngle,
    this.size = 160,
  });

  /// Whether this shows the side view or rear view camera position.
  final FilmingAngleType cameraAngle;

  /// Size of the diagram (width and height).
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FilmingAnglesPainter(
          cameraAngle: cameraAngle,
          playerColor: Colors.black,
          cameraColor: SenseiColors.gray[700]!,
          arrowColor: const Color(0xFF3B82F6), // Blue
        ),
      ),
    );
  }
}

/// The type of camera angle being illustrated.
enum FilmingAngleType {
  /// Side view: camera at 4 o'clock, thrower moving right to left.
  side,

  /// Rear view: camera at 6 o'clock, thrower moving upward.
  rear,
}

class _FilmingAnglesPainter extends CustomPainter {
  _FilmingAnglesPainter({
    required this.cameraAngle,
    required this.playerColor,
    required this.cameraColor,
    required this.arrowColor,
  });

  final FilmingAngleType cameraAngle;
  final Color playerColor;
  final Color cameraColor;
  final Color arrowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final Offset center = Offset(centerX, centerY);
    final double radius = size.width * 0.35;

    // Draw direction of motion arrow (below player)
    _drawMotionArrow(canvas, center, radius);

    // Draw camera and sight line
    _drawCameraAndSightLine(canvas, center, radius, size);

    // Draw the thrower (dot in center) - drawn last to be on top
    _drawThrower(canvas, center);
  }

  void _drawThrower(Canvas canvas, Offset center) {
    final Paint throwerPaint = Paint()
      ..color = playerColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, throwerPaint);
  }

  void _drawMotionArrow(Canvas canvas, Offset center, double radius) {
    final double arrowLength = radius * 1.05; // 1.5x longer
    final double headLength = 10;
    late Offset arrowStart;
    late Offset arrowEnd;
    late double arrowDirection; // Radians, direction the arrow points

    // Arrow starts from the center of the player dot
    arrowStart = center;

    if (cameraAngle == FilmingAngleType.side) {
      // Moving right to left (arrow pointing left from center)
      arrowEnd = Offset(center.dx - arrowLength, center.dy);
      arrowDirection = math.pi; // Pointing left
    } else {
      // Moving upward (arrow pointing up from center)
      arrowEnd = Offset(center.dx, center.dy - arrowLength);
      arrowDirection = -math.pi / 2; // Pointing up
    }

    // Calculate where the arrowhead base is (so line doesn't extend past it)
    final Offset lineEnd = Offset(
      arrowEnd.dx - (headLength - 2) * math.cos(arrowDirection),
      arrowEnd.dy - (headLength - 2) * math.sin(arrowDirection),
    );

    // Draw arrow line (stopping before arrowhead)
    final Paint arrowPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(arrowStart, lineEnd, arrowPaint);

    // Draw arrowhead at the end
    _drawArrowhead(canvas, arrowEnd, arrowDirection, arrowPaint);
  }

  void _drawArrowhead(
    Canvas canvas,
    Offset tip,
    double direction,
    Paint paint,
  ) {
    final double headLength = 10;
    final double headAngle = math.pi / 5; // 36 degrees

    // Calculate backwards direction (opposite of arrow direction)
    final double backAngle = direction + math.pi;

    final Offset left = Offset(
      tip.dx + headLength * math.cos(backAngle - headAngle),
      tip.dy + headLength * math.sin(backAngle - headAngle),
    );
    final Offset right = Offset(
      tip.dx + headLength * math.cos(backAngle + headAngle),
      tip.dy + headLength * math.sin(backAngle + headAngle),
    );

    // Draw filled arrowhead
    final Paint fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    final Path arrowHead = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(arrowHead, fillPaint);
  }

  void _drawCameraAndSightLine(
    Canvas canvas,
    Offset center,
    double radius,
    Size size,
  ) {
    late double cameraAngleRadians;

    if (cameraAngle == FilmingAngleType.side) {
      // 4 o'clock position = 65 degrees below horizontal
      cameraAngleRadians = 65 * math.pi / 180;
    } else {
      // 6 o'clock position = directly below
      cameraAngleRadians = math.pi / 2;
    }

    final double cameraDistance = radius * 1.4;
    final Offset cameraPos = Offset(
      center.dx + cameraDistance * math.cos(cameraAngleRadians),
      center.dy + cameraDistance * math.sin(cameraAngleRadians),
    );

    // Draw dotted sight line from camera to thrower
    _drawDottedLine(canvas, cameraPos, center, cameraColor);

    // Draw camera icon
    _drawCameraIcon(canvas, cameraPos, center);
  }

  void _drawDottedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
  ) {
    final Paint dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);
    final double dashLength = 5;
    final double gapLength = 4;
    final double totalDashGap = dashLength + gapLength;

    double currentDistance = 14; // Start after camera icon
    while (currentDistance < distance - 12) {
      // Stop before reaching the thrower
      final double startFraction = currentDistance / distance;
      final double endFraction =
          math.min((currentDistance + dashLength) / distance, 1.0);

      final Offset dashStart = Offset(
        start.dx + dx * startFraction,
        start.dy + dy * startFraction,
      );
      final Offset dashEnd = Offset(
        start.dx + dx * endFraction,
        start.dy + dy * endFraction,
      );

      canvas.drawLine(dashStart, dashEnd, dotPaint);
      currentDistance += totalDashGap;
    }
  }

  void _drawCameraIcon(Canvas canvas, Offset position, Offset lookingAt) {
    // Calculate rotation angle to point camera at thrower
    final double angle = math.atan2(
      lookingAt.dy - position.dy,
      lookingAt.dx - position.dx,
    );

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    final Paint cameraPaint = Paint()
      ..color = cameraColor
      ..style = PaintingStyle.fill;

    // Draw camera body (rounded rectangle)
    final RRect cameraBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(-2, 0), width: 14, height: 10),
      const Radius.circular(2),
    );
    canvas.drawRRect(cameraBody, cameraPaint);

    // Draw lens barrel (rectangle protruding from front)
    final RRect lensBarrel = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(6, 0), width: 6, height: 7),
      const Radius.circular(1),
    );
    canvas.drawRRect(lensBarrel, cameraPaint);

    // Draw lens circle at front
    canvas.drawCircle(const Offset(9, 0), 3, cameraPaint);

    // Draw viewfinder bump on top
    final RRect viewfinder = RRect.fromRectAndRadius(
      Rect.fromLTWH(-6, -7, 5, 3),
      const Radius.circular(1),
    );
    canvas.drawRRect(viewfinder, cameraPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FilmingAnglesPainter oldDelegate) {
    return cameraAngle != oldDelegate.cameraAngle ||
        playerColor != oldDelegate.playerColor ||
        cameraColor != oldDelegate.cameraColor ||
        arrowColor != oldDelegate.arrowColor;
  }
}
