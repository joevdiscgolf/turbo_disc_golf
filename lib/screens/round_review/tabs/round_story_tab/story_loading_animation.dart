import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Premium animated loading widget for story generation.
///
/// Features morphing background, orbiting icons, pulsing center element,
/// and animated text - matching the quality of judgment animations.
class StoryLoadingAnimation extends StatelessWidget {
  const StoryLoadingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _StoryMorphingBackground(),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _OrbitingIconsWithCenter(),
              const SizedBox(height: 32),
              Text(
                'Crafting your story',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C2C2C),
                    ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 500)),
              const SizedBox(height: 8),
              const _AnimatedLoadingDots(),
              const SizedBox(height: 16),
              const _RotatingSubtitle(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Morphing background with animated gradient blobs.
class _StoryMorphingBackground extends StatelessWidget {
  const _StoryMorphingBackground();

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Base solid color layer
        Container(color: const Color(0xFFF8F6FC)),

        // Top left blob - purple/creative tones
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

        // Bottom right blob - teal/insight tones
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

        // Center blob - blue/knowledge tones
        Positioned(
          top: screenSize.height * 0.4 - 150,
          left: screenSize.width * 0.5 - 150,
          child: Container(
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

/// Orbiting icons around a pulsing center element.
class _OrbitingIconsWithCenter extends StatefulWidget {
  const _OrbitingIconsWithCenter();

  @override
  State<_OrbitingIconsWithCenter> createState() =>
      _OrbitingIconsWithCenterState();
}

class _OrbitingIconsWithCenterState extends State<_OrbitingIconsWithCenter>
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _orbitController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing background glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double scale = 1.0 + (_pulseController.value * 0.3);
              final double opacity = 0.3 + (_pulseController.value * 0.2);
              return Container(
                width: 110 * scale,
                height: 110 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF9C7AE8).withValues(alpha: opacity),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Center book icon with scale animation
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double scale = 1.0 + (_pulseController.value * 0.1);
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
                        color: const Color(0xFF9C7AE8).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.5,
                      child: const Icon(
                        Icons.auto_stories,
                        size: 54,
                        color: Color(0xFF9C7AE8),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Orbiting sparkle icon
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              return _buildOrbitingIcon(
                icon: Icons.auto_awesome,
                color: const Color(0xFFFFD700),
                angle: _orbitController.value * 2 * pi,
                radius: 95,
                size: 36,
              );
            },
          ),

          // Orbiting chart icon (opposite side)
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              return _buildOrbitingIcon(
                icon: Icons.insights,
                color: const Color(0xFF4ECDC4),
                angle: (_orbitController.value * 2 * pi) + pi,
                radius: 95,
                size: 36,
              );
            },
          ),

          // Orbiting trophy icon (offset orbit)
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              return _buildOrbitingIcon(
                icon: Icons.emoji_events,
                color: const Color(0xFFFFB74D),
                angle: (_orbitController.value * 2 * pi) + (pi / 2),
                radius: 110,
                size: 30,
              );
            },
          ),

          // Orbiting target icon (offset orbit)
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              return _buildOrbitingIcon(
                icon: Icons.gps_fixed,
                color: const Color(0xFF74B9FF),
                angle: (_orbitController.value * 2 * pi) + (3 * pi / 2),
                radius: 110,
                size: 30,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitingIcon({
    required IconData icon,
    required Color color,
    required double angle,
    required double radius,
    required double size,
  }) {
    final double x = cos(angle) * radius;
    final double y = sin(angle) * radius;

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

/// Animated loading dots with staggered bounce.
class _AnimatedLoadingDots extends StatefulWidget {
  const _AnimatedLoadingDots();

  @override
  State<_AnimatedLoadingDots> createState() => _AnimatedLoadingDotsState();
}

class _AnimatedLoadingDotsState extends State<_AnimatedLoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
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
    );
  }

  Widget _buildDot(int index) {
    final double progress = (_controller.value + (index * 0.33)) % 1.0;
    final double scale = 0.5 + (sin(progress * pi) * 0.5);
    final double opacity = 0.3 + (sin(progress * pi) * 0.7);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF9C7AE8).withValues(alpha: opacity),
        ),
      ),
    );
  }
}

/// Rotating subtitle messages with fade transition.
class _RotatingSubtitle extends StatefulWidget {
  const _RotatingSubtitle();

  @override
  State<_RotatingSubtitle> createState() => _RotatingSubtitleState();
}

class _RotatingSubtitleState extends State<_RotatingSubtitle> {
  static const List<String> _messages = [
    'Finding the highlights from your round',
    'Analyzing your best moments',
    'Calculating your performance',
    'Building your narrative',
  ];

  int _messageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Text(
        _messages[_messageIndex],
        key: ValueKey<int>(_messageIndex),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
