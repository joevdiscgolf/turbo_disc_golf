import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Elegant animated gradient background with floating particles.
/// Supports both light and dark color schemes with smooth transitions.
///
/// Used across multiple screens:
/// - Auth screens (landing, login, signup) - dark mode
/// - Form analysis - light mode with transition to dark when processing
/// - Story empty state - light mode
class AnimatedParticleBackground extends StatefulWidget {
  const AnimatedParticleBackground({
    super.key,
    this.useDarkMode = false,
    this.isProcessing = false,
    this.particleOpacity = 0.5,
  });

  /// When true, uses dark color scheme (deep purple/blue gradient).
  /// Used for auth screens.
  final bool useDarkMode;

  /// When true, animates from light to dark mode.
  /// Only applies when [useDarkMode] is false.
  /// Used for form analysis processing state.
  final bool isProcessing;

  /// Base opacity multiplier for particles.
  /// Defaults to 0.5. Higher values make particles more visible.
  final double particleOpacity;

  @override
  State<AnimatedParticleBackground> createState() =>
      _AnimatedParticleBackgroundState();
}

class _AnimatedParticleBackgroundState extends State<AnimatedParticleBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _gradientController;
  late AnimationController _transitionController;

  // Light pastel gradient
  static const List<Color> _lightGradientColors = [
    Color(0xFFEEE8F5), // Soft lavender
    Color(0xFFE8EEF4), // Soft blue tint
    Color(0xFFECECEE), // Soft gray
    Color(0xFFE8ECF4), // Soft blue gray
  ];

  // Dark gradient colors
  static const List<Color> _darkGradientColors = [
    SenseiColors.darkBg1, // Deep purple/blue
    SenseiColors.darkBg2, // Midnight blue
    SenseiColors.darkBg2, // Midnight blue
    SenseiColors.darkBg3, // Very dark blue
  ];

  // Particle colors for light mode (subtle dark blue)
  static const Color _lightModeParticlePrimary = Color(0xFF1A237E);
  static const Color _lightModeParticleSecondary = Color(0xFF303F9F);

  // Particle colors for dark mode (bright cyan/teal)
  static const Color _darkModeParticlePrimary = Color(0xFF80DEEA);
  static const Color _darkModeParticleSecondary = Color(0xFF4ECDC4);

  @override
  void initState() {
    super.initState();

    // Particle animation - loops seamlessly (40 seconds for slow, elegant movement)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // Subtle gradient shift animation
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Light to dark transition animation
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Set initial state
    if (widget.useDarkMode || widget.isProcessing) {
      _transitionController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedParticleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle isProcessing changes (for form analysis transition)
    if (!widget.useDarkMode && widget.isProcessing != oldWidget.isProcessing) {
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
        // For useDarkMode, always use dark colors
        // For isProcessing, interpolate between light and dark
        final double t = widget.useDarkMode
            ? 1.0
            : Curves.easeInOut.transform(_transitionController.value);

        // Interpolate gradient colors
        final List<Color> currentColors = List.generate(4, (i) {
          return Color.lerp(_lightGradientColors[i], _darkGradientColors[i], t)!;
        });

        // Interpolate particle colors
        final Color primaryParticle = Color.lerp(
          _lightModeParticlePrimary,
          _darkModeParticlePrimary,
          t,
        )!;
        final Color secondaryParticle = Color.lerp(
          _lightModeParticleSecondary,
          _darkModeParticleSecondary,
          t,
        )!;

        // Particle opacity - higher in dark mode for visibility
        final double particleOpacityMultiplier = widget.particleOpacity + (t * 2.0);

        // Radial highlight color
        final Color highlightColor = Color.lerp(
          Colors.white.withValues(alpha: 0.4),
          _darkModeParticleSecondary.withValues(alpha: 0.12),
          t,
        )!;

        return Stack(
          children: [
            _buildGradientBackground(currentColors),
            _buildRadialHighlight(highlightColor, t),
            _buildParticles(primaryParticle, secondaryParticle, particleOpacityMultiplier),
            _buildBokehOrbs(primaryParticle, secondaryParticle, particleOpacityMultiplier),
          ],
        );
      },
    );
  }

  Widget _buildGradientBackground(List<Color> colors) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        final double gt = _gradientController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft + Alignment(gt * 0.3, gt * 0.2),
              end: Alignment.bottomRight + Alignment(-gt * 0.2, -gt * 0.3),
              colors: colors,
              stops: const [0.0, 0.35, 0.65, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadialHighlight(Color highlightColor, double darkModeT) {
    // Position highlight higher in dark mode (for auth header glow)
    final double centerY = -0.3 - (darkModeT * 0.2);

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, centerY),
            radius: 1.0,
            colors: [
              highlightColor,
              highlightColor.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticles(
    Color primaryColor,
    Color secondaryColor,
    double opacityMultiplier,
  ) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            progress: _particleController.value,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            opacityMultiplier: opacityMultiplier,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildBokehOrbs(
    Color primaryColor,
    Color secondaryColor,
    double opacityMultiplier,
  ) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _BokehPainter(
            progress: _particleController.value,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            opacityMultiplier: opacityMultiplier,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Paints small floating particles with seamless looping.
///
/// Key for seamless looping:
/// - Vertical movement uses integer speed multipliers so particles complete
///   full screen traversals within one animation cycle
/// - Horizontal drift and opacity use full sine cycles (0 to 2π)
class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
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

    for (int i = 0; i < 45; i++) {
      final double seed = i * 137.5; // Golden angle for even distribution
      final double x = (seed % size.width);
      final double baseY = (seed * 2.7) % size.height;

      // Integer speed factor ensures seamless looping (1, 2, or 3 full traversals)
      final int speedFactor = 1 + (i % 3);

      // Vertical movement downward - seamless because speedFactor is integer
      final double animatedY =
          (baseY + (progress * size.height * speedFactor)) % size.height;

      // Horizontal drift - full sine cycle for seamless loop
      // Use (i * 0.7) offset to desynchronize particles
      final double xDrift =
          math.sin((progress * math.pi * 2) + (i * 0.7)) * 18;

      // Size variation based on particle index
      final double radius = 1.2 + (i % 4) * 0.5;

      // Opacity pulsing - full sine cycle for seamless loop
      final double baseOpacity =
          (0.10 + 0.08 * math.sin((progress * math.pi * 2) + i)) *
          opacityMultiplier;

      // Alternate colors for visual variety
      final bool isPrimary = i % 3 != 0;
      final Paint paint = isPrimary ? primaryPaint : secondaryPaint;
      paint.color = (isPrimary ? primaryColor : secondaryColor)
          .withValues(alpha: baseOpacity.clamp(0.0, 1.0));

      canvas.drawCircle(Offset(x + xDrift, animatedY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacityMultiplier != opacityMultiplier ||
        oldDelegate.primaryColor != primaryColor;
  }
}

/// Paints larger, soft bokeh orbs for depth effect.
/// Uses full sine/cosine cycles for seamless looping.
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
    final List<_BokehOrb> orbs = [
      _BokehOrb(
        baseX: 0.15,
        baseY: 0.20,
        radius: 65,
        color: primaryColor,
        phaseOffset: 0,
      ),
      _BokehOrb(
        baseX: 0.85,
        baseY: 0.30,
        radius: 50,
        color: secondaryColor,
        phaseOffset: math.pi * 0.5,
      ),
      _BokehOrb(
        baseX: 0.20,
        baseY: 0.72,
        radius: 55,
        color: secondaryColor,
        phaseOffset: math.pi,
      ),
      _BokehOrb(
        baseX: 0.80,
        baseY: 0.82,
        radius: 60,
        color: primaryColor,
        phaseOffset: math.pi * 1.5,
      ),
      _BokehOrb(
        baseX: 0.50,
        baseY: 0.12,
        radius: 45,
        color: primaryColor,
        phaseOffset: math.pi * 0.75,
      ),
      _BokehOrb(
        baseX: 0.35,
        baseY: 0.50,
        radius: 40,
        color: secondaryColor,
        phaseOffset: math.pi * 1.25,
      ),
    ];

    for (final orb in orbs) {
      // Full sine/cosine cycles ensure seamless looping
      final double angle = (progress * math.pi * 2) + orb.phaseOffset;
      final double floatX = math.sin(angle) * 22;
      final double floatY = math.cos(angle) * 18;

      final double x = size.width * orb.baseX + floatX;
      final double y = size.height * orb.baseY + floatY;

      // Pulsing opacity - full sine cycle
      final double opacity =
          (0.03 + 0.025 * math.sin(angle)) * opacityMultiplier;

      final Paint paint = Paint()
        ..color = orb.color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, orb.radius * 0.6);

      canvas.drawCircle(Offset(x, y), orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BokehPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacityMultiplier != opacityMultiplier ||
        oldDelegate.primaryColor != primaryColor;
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
