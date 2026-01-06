import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Themed confetti overlay for judgment celebrations.
///
/// Displays red flame-like particles for roasts and golden sparkles for glazes.
class JudgmentConfettiOverlay extends StatefulWidget {
  const JudgmentConfettiOverlay({
    super.key,
    required this.isGlaze,
    required this.controller,
  });

  /// Whether this is a glaze (true) or roast (false) celebration.
  final bool isGlaze;

  /// The confetti controller to manage the animation.
  final ConfettiController controller;

  @override
  State<JudgmentConfettiOverlay> createState() =>
      _JudgmentConfettiOverlayState();
}

class _JudgmentConfettiOverlayState extends State<JudgmentConfettiOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Center explosion
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: widget.controller,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: widget.isGlaze ? 40 : 30,
            maxBlastForce: widget.isGlaze ? 20 : 25,
            minBlastForce: widget.isGlaze ? 8 : 10,
            gravity: widget.isGlaze ? 0.08 : 0.15,
            shouldLoop: false,
            colors: widget.isGlaze ? _glazeColors : _roastColors,
            createParticlePath: widget.isGlaze
                ? _createStarPath
                : _createFlamePath,
          ),
        ),
        // Top bursts for extra drama
        Align(
          alignment: const Alignment(0, -0.5),
          child: ConfettiWidget(
            confettiController: widget.controller,
            blastDirection: pi / 2, // Downward
            emissionFrequency: 0.03,
            numberOfParticles: 15,
            maxBlastForce: 15,
            minBlastForce: 5,
            gravity: widget.isGlaze ? 0.1 : 0.2,
            shouldLoop: false,
            colors: widget.isGlaze ? _glazeColors : _roastColors,
            createParticlePath: widget.isGlaze
                ? _createStarPath
                : _createFlamePath,
          ),
        ),
      ],
    );
  }

  // Roast colors: red, orange, yellow flames
  static const List<Color> _roastColors = [
    Color(0xFFFF6B6B), // Primary red
    Color(0xFFFF8C42), // Orange
    Color(0xFFFFD93D), // Yellow
    Color(0xFFD32F2F), // Dark red
  ];

  // Glaze colors: gold, orange-gold, white sparkles
  static const List<Color> _glazeColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFFFFA500), // Orange-gold
    Color(0xFFFFFFFF), // White sparkle
    Color(0xFFFFE4B5), // Light gold (moccasin)
  ];

  /// Creates a flame-like teardrop shape for roast particles.
  Path _createFlamePath(Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;

    // Flame shape: teardrop pointing up
    path.moveTo(w / 2, 0); // Top point
    path.quadraticBezierTo(w, h * 0.3, w * 0.7, h * 0.6);
    path.quadraticBezierTo(w / 2, h, w / 2, h); // Bottom curve
    path.quadraticBezierTo(w / 2, h, w * 0.3, h * 0.6);
    path.quadraticBezierTo(0, h * 0.3, w / 2, 0);
    path.close();

    return path;
  }

  /// Creates a 4-point star shape for glaze sparkle particles.
  Path _createStarPath(Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    // 4-point star
    path.moveTo(cx, 0); // Top
    path.lineTo(cx + w * 0.15, cy - h * 0.15);
    path.lineTo(w, cy); // Right
    path.lineTo(cx + w * 0.15, cy + h * 0.15);
    path.lineTo(cx, h); // Bottom
    path.lineTo(cx - w * 0.15, cy + h * 0.15);
    path.lineTo(0, cy); // Left
    path.lineTo(cx - w * 0.15, cy - h * 0.15);
    path.close();

    return path;
  }
}

/// Helper class to create and manage confetti controllers.
class JudgmentConfettiManager {
  JudgmentConfettiManager() {
    _controller = ConfettiController(
      duration: const Duration(milliseconds: 2000),
    );
  }

  late final ConfettiController _controller;

  ConfettiController get controller => _controller;

  /// Triggers the confetti celebration.
  void play() {
    _controller.play();
  }

  /// Stops the confetti.
  void stop() {
    _controller.stop();
  }

  /// Disposes the controller.
  void dispose() {
    _controller.dispose();
  }
}
