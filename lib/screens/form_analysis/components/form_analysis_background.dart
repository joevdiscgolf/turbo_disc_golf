import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Elegant animated gradient background with floating particles for form analysis.
/// Uses the app's light pastel color scheme with subtle teal and purple accents.
/// Supports animated transition to dark mode when processing.
class FormAnalysisBackground extends StatefulWidget {
  const FormAnalysisBackground({
    super.key,
    this.isProcessing = false,
  });

  /// When true, animates the background from light to dark mode
  final bool isProcessing;

  @override
  State<FormAnalysisBackground> createState() => _FormAnalysisBackgroundState();
}

class _FormAnalysisBackgroundState extends State<FormAnalysisBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _gradientController;
  late AnimationController _transitionController;

  // Light pastel gradient matching the rest of the app
  static const List<Color> _lightGradientColors = [
    Color(0xFFEEE8F5), // Soft lavender
    Color(0xFFE8EEF4), // Soft blue tint
    Color(0xFFECECEE), // Soft gray
    Color(0xFFE8ECF4), // Soft blue gray
  ];

  // Dark gradient colors (from landing screen)
  static const List<Color> _darkGradientColors = [
    SenseiColors.darkBg1, // Deep purple/blue
    SenseiColors.darkBg2, // Midnight blue
    SenseiColors.darkBg2, // Midnight blue (repeated for 4 stops)
    SenseiColors.darkBg3, // Very dark blue
  ];

  // Dark blue accent colors for particles (low opacity)
  static const Color _darkBlueAccent = Color(0xFF1A237E); // Dark indigo
  static const Color _mediumBlueAccent = Color(0xFF303F9F); // Medium indigo

  // Light particle colors for dark mode
  static const Color _lightParticleAccent = Color(0xFF80DEEA); // Light cyan

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Set initial state based on isProcessing
    if (widget.isProcessing) {
      _transitionController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FormAnalysisBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isProcessing != oldWidget.isProcessing) {
      if (widget.isProcessing) {
        _transitionController.forward();
      } else {
        _transitionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _gradientController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        final double t = Curves.easeInOut.transform(_transitionController.value);

        // Interpolate between light and dark gradient colors
        final List<Color> currentColors = List.generate(4, (i) {
          return Color.lerp(_lightGradientColors[i], _darkGradientColors[i], t)!;
        });

        // Interpolate particle colors
        final Color primaryParticle = Color.lerp(
          _darkBlueAccent,
          _lightParticleAccent,
          t,
        )!;
        final Color secondaryParticle = Color.lerp(
          _mediumBlueAccent,
          SenseiColors.cyan,
          t,
        )!;

        // Interpolate particle opacity (higher in dark mode for visibility)
        final double particleOpacityMultiplier = 1.0 + (t * 2.0);

        // Interpolate radial highlight (white in light mode, teal glow in dark)
        final Color highlightColor = Color.lerp(
          Colors.white.withValues(alpha: 0.4),
          SenseiColors.cyan.withValues(alpha: 0.15),
          t,
        )!;

        return Stack(
          children: [
            // Animated gradient background with subtle shift
            AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                final double gt = _gradientController.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft + Alignment(gt * 0.3, gt * 0.2),
                      end: Alignment.bottomRight +
                          Alignment(-gt * 0.2, -gt * 0.3),
                      colors: currentColors,
                      stops: const [0.0, 0.35, 0.65, 1.0],
                    ),
                  ),
                );
              },
            ),

            // Soft radial highlight in center (where loader will be)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      highlightColor,
                      highlightColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Floating particles layer
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LightParticlePainter(
                    progress: _particleController.value,
                    primaryColor: primaryParticle,
                    secondaryColor: secondaryParticle,
                    opacityMultiplier: particleOpacityMultiplier,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Subtle bokeh orbs
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BokehPainter(
                    progress: _particleController.value,
                    primaryColor: primaryParticle,
                    secondaryColor: secondaryParticle,
                    opacityMultiplier: particleOpacityMultiplier,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Paints small floating particles in dark blue colors with low opacity
class _LightParticlePainter extends CustomPainter {
  _LightParticlePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    this.opacityMultiplier = 1.0,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double opacityMultiplier;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint primaryPaint = Paint();
    final Paint secondaryPaint = Paint();

    // Generate deterministic particles
    for (int i = 0; i < 40; i++) {
      final double seed = i * 137.5; // Golden angle
      final double x = (seed % size.width);
      final double baseY = (seed * 2.7) % size.height;

      // Floating upward animation with varying speeds
      final double speedFactor = 0.3 + (i % 5) * 0.15;
      final double animatedY =
          (baseY - (progress * size.height * speedFactor) + size.height) %
          size.height;

      // Horizontal drift
      final double xDrift = math.sin(progress * math.pi * 2 + i * 0.5) * 15;

      // Size variation
      final double radius = 1.5 + (i % 4) * 0.8;

      // Opacity pulsing - scaled by opacity multiplier
      final double baseOpacity =
          (0.08 + 0.08 * math.sin(progress * math.pi * 2 + i)) *
          opacityMultiplier;

      // Alternate between primary and secondary
      final bool isPrimary = i % 3 != 0;
      final Paint paint = isPrimary ? primaryPaint : secondaryPaint;
      paint.color = (isPrimary ? primaryColor : secondaryColor)
          .withValues(alpha: baseOpacity.clamp(0.0, 1.0));

      canvas.drawCircle(Offset(x + xDrift, animatedY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_LightParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacityMultiplier != opacityMultiplier;
  }
}

/// Paints larger, soft bokeh orbs for depth
class _BokehPainter extends CustomPainter {
  _BokehPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    this.opacityMultiplier = 1.0,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double opacityMultiplier;

  @override
  void paint(Canvas canvas, Size size) {
    // Create a few large, soft bokeh orbs
    final List<_BokehOrb> orbs = [
      _BokehOrb(
        baseX: 0.15,
        baseY: 0.25,
        radius: 60,
        color: primaryColor,
        phaseOffset: 0,
      ),
      _BokehOrb(
        baseX: 0.85,
        baseY: 0.35,
        radius: 45,
        color: secondaryColor,
        phaseOffset: 1.5,
      ),
      _BokehOrb(
        baseX: 0.25,
        baseY: 0.75,
        radius: 50,
        color: secondaryColor,
        phaseOffset: 3.0,
      ),
      _BokehOrb(
        baseX: 0.75,
        baseY: 0.8,
        radius: 55,
        color: primaryColor,
        phaseOffset: 4.5,
      ),
      _BokehOrb(
        baseX: 0.5,
        baseY: 0.15,
        radius: 40,
        color: primaryColor,
        phaseOffset: 2.2,
      ),
    ];

    for (final orb in orbs) {
      // Gentle floating motion
      final double floatX =
          math.sin(progress * math.pi * 2 + orb.phaseOffset) * 20;
      final double floatY =
          math.cos(progress * math.pi * 2 + orb.phaseOffset) * 15;

      final double x = size.width * orb.baseX + floatX;
      final double y = size.height * orb.baseY + floatY;

      // Pulsing opacity - scaled by opacity multiplier
      final double opacity =
          (0.025 + 0.02 * math.sin(progress * math.pi * 2 + orb.phaseOffset)) *
          opacityMultiplier;

      final Paint paint = Paint()
        ..color = orb.color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, orb.radius * 0.6);

      canvas.drawCircle(Offset(x, y), orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BokehPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacityMultiplier != opacityMultiplier;
  }
}

class _BokehOrb {
  const _BokehOrb({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.color,
    required this.phaseOffset,
  });

  final double baseX; // 0-1 relative to screen width
  final double baseY; // 0-1 relative to screen height
  final double radius;
  final Color color;
  final double phaseOffset;
}
