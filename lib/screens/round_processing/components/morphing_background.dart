import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Organic, fluid background with morphing gradients and smooth wave animations.
///
/// This component creates a living, breathing background that feels natural
/// and organic, like the round data is coming to life.
class MorphingBackground extends StatelessWidget {
  const MorphingBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient layer
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEEE8F5), // Light purple tint
                Color(0xFFE8F4E8), // Light green tint
                Color(0xFFECECEE), // Light gray
                Color(0xFFEAE8F0), // Light purple
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),

        // Animated overlay blobs - Top left
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFB8E986).withValues(alpha: 0.3),
                  const Color(0xFFB8E986).withValues(alpha: 0.0),
                ],
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .scale(
                duration: const Duration(milliseconds: 3000),
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: const Duration(milliseconds: 3000),
                begin: const Offset(1.2, 1.2),
                end: const Offset(0.8, 0.8),
                curve: Curves.easeInOut,
              ),
        ),

        // Animated overlay blobs - Bottom right
        Positioned(
          bottom: -150,
          right: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF5B7EFF).withValues(alpha: 0.25),
                  const Color(0xFF5B7EFF).withValues(alpha: 0.0),
                ],
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .scale(
                duration: const Duration(milliseconds: 4000),
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.3, 1.3),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: const Duration(milliseconds: 4000),
                begin: const Offset(1.3, 1.3),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeInOut,
              ),
        ),

        // Animated overlay blobs - Center
        Positioned(
          top: MediaQueryData.fromView(
            WidgetsBinding.instance.platformDispatcher.views.first,
          ).size.height * 0.5 - 150,
          left: MediaQueryData.fromView(
            WidgetsBinding.instance.platformDispatcher.views.first,
          ).size.width * 0.5 - 150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFB8E986).withValues(alpha: 0.2),
                  const Color(0xFF5B7EFF).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .scale(
                duration: const Duration(milliseconds: 3500),
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.15, 1.15),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: const Duration(milliseconds: 3500),
                begin: const Offset(1.15, 1.15),
                end: const Offset(0.9, 0.9),
                curve: Curves.easeInOut,
              ),
        ),
      ],
    );
  }
}
