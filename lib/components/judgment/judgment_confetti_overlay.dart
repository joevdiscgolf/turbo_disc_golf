import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/judgment/fire_emoji_overlay.dart';

/// Themed confetti overlay for judgment celebrations.
///
/// Displays fire emoji particles for roasts and golden star sparkles for glazes.
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
  bool _fireIsPlaying = false;

  @override
  void initState() {
    super.initState();
    // Listen to confetti controller state to trigger fire emojis
    widget.controller.addListener(_onControllerStateChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerStateChanged);
    super.dispose();
  }

  void _onControllerStateChanged() {
    if (!widget.isGlaze &&
        widget.controller.state == ConfettiControllerState.playing) {
      if (!_fireIsPlaying) {
        setState(() {
          _fireIsPlaying = true;
        });
      }
    }
  }

  void _onFireComplete() {
    setState(() {
      _fireIsPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // For roast: show fire emojis
    if (!widget.isGlaze) {
      return FireEmojiOverlay(
        isPlaying: _fireIsPlaying,
        onComplete: _onFireComplete,
      );
    }

    // For glaze: show golden star confetti
    return Stack(
      children: [
        // Center explosion
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: widget.controller,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 40,
            maxBlastForce: 20,
            minBlastForce: 8,
            gravity: 0.08,
            shouldLoop: false,
            colors: _glazeColors,
            createParticlePath: _createStarPath,
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
            gravity: 0.1,
            shouldLoop: false,
            colors: _glazeColors,
            createParticlePath: _createStarPath,
          ),
        ),
      ],
    );
  }

  // Glaze colors: gold, orange-gold, white sparkles
  static const List<Color> _glazeColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFFFFA500), // Orange-gold
    Color(0xFFFFFFFF), // White sparkle
    Color(0xFFFFE4B5), // Light gold (moccasin)
  ];

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
