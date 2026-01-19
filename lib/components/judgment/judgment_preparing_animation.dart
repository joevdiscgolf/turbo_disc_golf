import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// An engaging animation shown while waiting for the judgment API response.
///
/// Features orbiting emojis, pulsing glow, and animated text to keep users
/// engaged during the loading period.
class JudgmentPreparingAnimation extends StatefulWidget {
  const JudgmentPreparingAnimation({super.key});

  @override
  State<JudgmentPreparingAnimation> createState() =>
      _JudgmentPreparingAnimationState();
}

class _JudgmentPreparingAnimationState extends State<JudgmentPreparingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();

    // Orbit animation - emojis circle around
    _orbitController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Pulse animation - center glow pulses
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Dots animation - loading dots cycle
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _JudgmentMorphingBackground(),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Orbiting emojis with pulsing center
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing background glow
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final double scale =
                            1.0 + (_pulseController.value * 0.3);
                        final double opacity =
                            0.3 + (_pulseController.value * 0.2);
                        return Container(
                          width: 110 * scale,
                          height: 110 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(
                                  0xFF5B7EFF,
                                ).withValues(alpha: opacity),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Center gavel icon with scale animation
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final double scale =
                            1.0 + (_pulseController.value * 0.1);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF5B7EFF,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.gavel,
                                size: 48,
                                color: SenseiColors.darkGray,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Orbiting fire emoji
                    AnimatedBuilder(
                      animation: _orbitController,
                      builder: (context, child) {
                        return _buildOrbitingEmoji(
                          emoji: '🔥',
                          angle: _orbitController.value * 2 * pi,
                          radius: 95,
                          size: 36,
                        );
                      },
                    ),
                    // Orbiting donut emoji (opposite side)
                    AnimatedBuilder(
                      animation: _orbitController,
                      builder: (context, child) {
                        return _buildOrbitingEmoji(
                          emoji: '🍩',
                          angle: (_orbitController.value * 2 * pi) + pi,
                          radius: 95,
                          size: 36,
                        );
                      },
                    ),
                    // Additional fire emoji (offset orbit)
                    AnimatedBuilder(
                      animation: _orbitController,
                      builder: (context, child) {
                        return _buildOrbitingEmoji(
                          emoji: '🔥',
                          angle: (_orbitController.value * 2 * pi) + (pi / 2),
                          radius: 110,
                          size: 30,
                        );
                      },
                    ),
                    // Additional donut emoji (offset orbit)
                    AnimatedBuilder(
                      animation: _orbitController,
                      builder: (context, child) {
                        return _buildOrbitingEmoji(
                          emoji: '🍩',
                          angle:
                              (_orbitController.value * 2 * pi) + (3 * pi / 2),
                          radius: 110,
                          size: 30,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Animated text
              Text(
                'Preparing your judgment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              // Animated loading dots
              AnimatedBuilder(
                animation: _dotsController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(0),
                      const SizedBox(width: 6),
                      _buildDot(1),
                      const SizedBox(width: 6),
                      _buildDot(2),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'The wheel of fate awaits',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrbitingEmoji({
    required String emoji,
    required double angle,
    required double radius,
    required double size,
  }) {
    final double x = cos(angle) * radius;
    final double y = sin(angle) * radius;

    return Transform.translate(
      offset: Offset(x, y),
      child: Text(emoji, style: TextStyle(fontSize: size)),
    );
  }

  Widget _buildDot(int index) {
    // Stagger the animation for each dot
    final double progress = (_dotsController.value + (index * 0.33)) % 1.0;
    final double scale = 0.5 + (sin(progress * pi) * 0.5);
    final double opacity = 0.3 + (sin(progress * pi) * 0.7);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF5B7EFF).withValues(alpha: opacity),
        ),
      ),
    );
  }
}

/// Morphing background with animated gradient blobs (matching story loading).
class _JudgmentMorphingBackground extends StatelessWidget {
  const _JudgmentMorphingBackground();

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Base solid color layer - slightly purple
        Container(color: const Color(0xFFF8F6FC)),

        // Top left blob - purple tones
        Positioned(
          top: -100,
          left: -100,
          child:
              Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF9C7AE8).withValues(alpha: 0.3),
                          const Color(0xFF9C7AE8).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    duration: const Duration(milliseconds: 2500),
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    duration: const Duration(milliseconds: 2500),
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(0.8, 0.8),
                    curve: Curves.easeInOut,
                  ),
        ),

        // Bottom right blob - teal tones
        Positioned(
          bottom: -150,
          right: -150,
          child:
              Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF4ECDC4).withValues(alpha: 0.25),
                          const Color(0xFF4ECDC4).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    duration: const Duration(milliseconds: 3000),
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.3, 1.3),
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    duration: const Duration(milliseconds: 3000),
                    begin: const Offset(1.3, 1.3),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.easeInOut,
                  ),
        ),

        // Center blob - blue/purple tones
        Positioned(
          top: screenSize.height * 0.4 - 150,
          left: screenSize.width * 0.5 - 150,
          child:
              Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF74B9FF).withValues(alpha: 0.15),
                          const Color(0xFF9C7AE8).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    duration: const Duration(milliseconds: 2000),
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.15, 1.15),
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    duration: const Duration(milliseconds: 2000),
                    begin: const Offset(1.15, 1.15),
                    end: const Offset(0.9, 0.9),
                    curve: Curves.easeInOut,
                  ),
        ),
      ],
    );
  }
}
