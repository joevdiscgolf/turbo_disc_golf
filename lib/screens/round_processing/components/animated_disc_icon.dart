import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_remix/flutter_remix.dart';

/// Animated disc icon shown during round processing.
///
/// This component features a pulsing, breathing animation with organic
/// scaling and opacity changes to create a living, magical feel.
class AnimatedDiscIcon extends StatelessWidget {
  final double size;

  const AnimatedDiscIcon({
    super.key,
    this.size = 120,
  });

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
      child: Icon(
        FlutterRemix.disc_line,
        size: size * 0.5,
        color: Colors.white,
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
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
