import 'dart:math';

import 'package:flutter/material.dart';

/// A particle system that emits fire emojis for roast celebrations.
///
/// Creates an explosive burst of 🔥 emojis that fly outward and fall with gravity.
class FireEmojiOverlay extends StatefulWidget {
  const FireEmojiOverlay({
    super.key,
    required this.isPlaying,
    required this.onComplete,
  });

  /// Whether the animation should be playing.
  final bool isPlaying;

  /// Callback when the animation completes.
  final VoidCallback? onComplete;

  @override
  State<FireEmojiOverlay> createState() => _FireEmojiOverlayState();
}

class _FireEmojiOverlayState extends State<FireEmojiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_FireParticle> _particles = [];
  final Random _random = Random();

  static const int _particleCount = 35;
  static const Duration _duration = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _duration,
      vsync: this,
    );
    _controller.addListener(_updateParticles);
    _controller.addStatusListener(_onAnimationStatus);
  }

  @override
  void didUpdateWidget(FireEmojiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _spawnParticles();
    _controller.forward(from: 0.0);
  }

  void _spawnParticles() {
    _particles = List.generate(_particleCount, (index) {
      // Random angle for explosion direction
      final double angle = _random.nextDouble() * 2 * pi;
      // Random velocity magnitude
      final double velocity = 200 + _random.nextDouble() * 300;

      return _FireParticle(
        // Start from center
        x: 0,
        y: 0,
        // Velocity based on angle
        vx: cos(angle) * velocity,
        vy: sin(angle) * velocity - 150, // Bias upward
        // Random size
        size: 20 + _random.nextDouble() * 16,
        // Random rotation
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
        // Slight delay for staggered effect
        delay: _random.nextDouble() * 0.1,
      );
    });
  }

  void _updateParticles() {
    setState(() {});
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onComplete?.call();
      _particles = [];
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParticles);
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();

    final Size screenSize = MediaQuery.of(context).size;
    final Offset center = Offset(screenSize.width / 2, screenSize.height / 2);

    return IgnorePointer(
      child: Stack(
        children: _particles.map((particle) {
          return _buildParticle(particle, center);
        }).toList(),
      ),
    );
  }

  Widget _buildParticle(_FireParticle particle, Offset center) {
    final double t = _controller.value;

    // Apply delay
    if (t < particle.delay) {
      return const SizedBox.shrink();
    }

    final double localT = (t - particle.delay) / (1.0 - particle.delay);

    // Physics simulation
    const double gravity = 800;
    const double drag = 0.98;

    // Calculate position with physics
    final double time = localT * 2.5; // Scale time for animation duration
    final double dragFactor = pow(drag, time * 60).toDouble();

    final double x = particle.x + particle.vx * time * dragFactor;
    final double y =
        particle.y + particle.vy * time * dragFactor + 0.5 * gravity * time * time;

    // Fade out in the last 40%
    double opacity = 1.0;
    if (localT > 0.6) {
      opacity = 1.0 - ((localT - 0.6) / 0.4);
    }

    // Scale down slightly as they fall
    final double scale = 1.0 - (localT * 0.3);

    // Current rotation
    final double rotation = particle.rotation + particle.rotationSpeed * time;

    return Positioned(
      left: center.dx + x - particle.size / 2,
      top: center.dy + y - particle.size / 2,
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale.clamp(0.3, 1.0),
            child: Text(
              '🔥',
              style: TextStyle(fontSize: particle.size),
            ),
          ),
        ),
      ),
    );
  }
}

/// Represents a single fire emoji particle.
class _FireParticle {
  _FireParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.delay,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double delay;
}
