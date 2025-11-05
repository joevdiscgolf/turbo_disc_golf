import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated triangle icon shown during round processing.
///
/// This component features a pulsing, breathing animation with organic
/// scaling and opacity changes to create a living, magical feel.
class AnimatedSquareIcon extends StatelessWidget {
  final double size;

  const AnimatedSquareIcon({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFB8E986).withValues(alpha: 0.8), // Mint green
                const Color(0xFF5B7EFF).withValues(alpha: 0.8), // Vibrant blue
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB8E986).withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFF5B7EFF).withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CustomPaint(painter: _TrianglePainter()),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          duration: const Duration(milliseconds: 1800),
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.1, 1.1),
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          duration: const Duration(milliseconds: 1800),
          begin: const Offset(1.1, 1.1),
          end: const Offset(0.9, 0.9),
          curve: Curves.easeInOut,
        );
  }
}

/// Painter for white triangle outline
class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double triangleSize = size.width * 0.35;

    // Create equilateral triangle pointing up
    final Path path = Path();
    path.moveTo(centerX, centerY - triangleSize / 2); // Top point
    path.lineTo(
      centerX - triangleSize / 2,
      centerY + triangleSize / 3,
    ); // Bottom left
    path.lineTo(
      centerX + triangleSize / 2,
      centerY + triangleSize / 3,
    ); // Bottom right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => false;
}
