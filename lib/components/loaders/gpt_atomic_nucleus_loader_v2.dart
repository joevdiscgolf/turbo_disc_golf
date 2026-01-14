import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Brain nucleus + orbiting particles (side-ish ellipse, slightly off-axis).
///
/// Updates for your latest request:
/// ✅ Two *different orbital planes* (two axes) AND opposite directions
/// ✅ Visible orbital rings (the paths)
/// ✅ Remove comet tails (rings replace them)
/// ✅ Particles glow brightest at max opacity (front-most)
/// ✅ Smooth fade when behind nucleus (no sudden disappearing)
///
/// Notes:
/// - Each orbit has its own pitch/yaw (orbital plane) and direction (+/-).
/// - Rings are drawn as ellipses using the same projection math as particles,
///   so particles ride exactly on the ring path.
class GPTAtomicNucleusLoaderV2 extends StatelessWidget {
  const GPTAtomicNucleusLoaderV2({
    super.key,
    this.size = 240.0,
    this.particleCount = 3,
  });

  final double size;
  final int particleCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _MorphingBackground(size: size),

          // ===== Orbit Plane A =====
          _AtomicOrbit(
            size: size,
            radius: size * 0.395,
            particleCount: particleCount,
            orbitDuration: const Duration(milliseconds: 8000),
            speedMultiplier: 3.0,
            pitchDeg: 78,
            yawDeg: 18,
            yScale: 0.45,
            yOffset: -4,
            direction: 1, // forward
            particleColor: const Color(0xFF4DD0E1),
            ringColor: const Color(0xFF7FE9F5),
          ),

          // ===== Orbit Plane B (symmetrical-ish, opposite axis & direction) =====
          _AtomicOrbit(
            size: size,
            radius: (size * 0.395) * 1.02,
            particleCount: particleCount,
            orbitDuration: const Duration(milliseconds: 8000),
            speedMultiplier: 3.0,
            pitchDeg: 78, // keep similar "side-view" feel
            yawDeg: -18, // opposite yaw => opposite plane appearance
            yScale: 0.45,
            yOffset: 4,
            direction: -1, // reverse direction
            particleColor: const Color(0xFF4DD0E1),
            ringColor: const Color(0xFF7FE9F5),
          ),

          _buildNucleus(),
        ],
      ),
    );
  }

  Widget _buildNucleus() {
    return Container(
          width: 100,
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4DA6).withValues(alpha: 0.4),
                blurRadius: 28,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Text('🧠', style: TextStyle(fontSize: 72)),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          duration: 2500.ms,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.15, 1.15),
          curve: Curves.easeInOut,
        )
        .then()
        .shimmer(
          duration: 2000.ms,
          color: const Color(0xFFFF4DA6).withValues(alpha: 0.3),
        );
  }
}

class _MorphingBackground extends StatelessWidget {
  const _MorphingBackground({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          _buildBlob(
            colors: const [Color(0xFF0C5349), Color(0xFF137e66)],
            duration: 5000.ms,
            scaleBegin: 1.0,
            scaleEnd: 1.25,
          ),
          _buildBlob(
            colors: const [Color(0xFF137e66), Color(0xFF26B39D)],
            duration: 4200.ms,
            scaleBegin: 0.95,
            scaleEnd: 1.15,
          ),
        ],
      ),
    );
  }

  Widget _buildBlob({
    required List<Color> colors,
    required Duration duration,
    required double scaleBegin,
    required double scaleEnd,
  }) {
    return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: colors, stops: const [0.0, 1.0]),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          duration: duration,
          begin: Offset(scaleBegin, scaleBegin),
          end: Offset(scaleEnd, scaleEnd),
          curve: Curves.easeInOut,
        );
  }
}

class _AtomicOrbit extends StatefulWidget {
  const _AtomicOrbit({
    required this.size,
    required this.radius,
    required this.particleCount,
    required this.orbitDuration,
    required this.speedMultiplier,
    required this.pitchDeg,
    required this.yawDeg,
    required this.yScale,
    required this.yOffset,
    required this.direction,
    required this.particleColor,
    required this.ringColor,
  });

  final double size;
  final double radius;
  final int particleCount;
  final Duration orbitDuration;

  /// 3.0 => ~3x faster
  final double speedMultiplier;

  final double pitchDeg;
  final double yawDeg;
  final double yScale;
  final double yOffset;

  /// +1 forward, -1 reverse
  final int direction;

  final Color particleColor;
  final Color ringColor;

  @override
  State<_AtomicOrbit> createState() => _AtomicOrbitState();
}

class _AtomicOrbitState extends State<_AtomicOrbit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.orbitDuration,
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
        final double p = (_controller.value * widget.speedMultiplier) % 1.0;

        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AtomicOrbitPainter(
            progress: p,
            radius: widget.radius,
            particleCount: widget.particleCount,
            pitchDeg: widget.pitchDeg,
            yawDeg: widget.yawDeg,
            yScale: widget.yScale,
            yOffset: widget.yOffset,
            direction: widget.direction,
            particleColor: widget.particleColor,
            ringColor: widget.ringColor,
            nucleusVisualRadius: 52,
          ),
        );
      },
    );
  }
}

class _ParticleDrawData {
  _ParticleDrawData({
    required this.x,
    required this.y,
    required this.z,
    required this.opacity,
    required this.size,
    required this.depthT,
  });

  final double x;
  final double y;
  final double z;
  final double opacity;
  final double size;
  final double depthT; // 0 back -> 1 front
}

class _AtomicOrbitPainter extends CustomPainter {
  _AtomicOrbitPainter({
    required this.progress,
    required this.radius,
    required this.particleCount,
    required this.pitchDeg,
    required this.yawDeg,
    required this.yScale,
    required this.yOffset,
    required this.direction,
    required this.particleColor,
    required this.ringColor,
    required this.nucleusVisualRadius,
  });

  final double progress;
  final double radius;
  final int particleCount;

  final double pitchDeg;
  final double yawDeg;
  final double yScale;
  final double yOffset;
  final int direction;

  final Color particleColor;
  final Color ringColor;

  final double nucleusVisualRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final double pitch = pitchDeg * math.pi / 180.0;
    final double yaw = yawDeg * math.pi / 180.0;

    // ---- 1) Draw the orbital ring path (visible ellipse) ----
    _drawOrbitRing(
      canvas: canvas,
      cx: cx,
      cy: cy,
      r: radius,
      pitch: pitch,
      yaw: yaw,
      yScale: yScale,
      yOffset: yOffset,
      ringColor: ringColor,
      nucleusRadius: nucleusVisualRadius,
    );

    // ---- 2) Draw particles riding on the orbit ----
    const double baseParticleRadius = 5.4;

    final List<_ParticleDrawData> particles = [];

    for (int i = 0; i < particleCount; i++) {
      final double a0 = (2 * math.pi / particleCount) * i;

      // direction (+1 or -1) flips orbital direction
      final double a = a0 + direction * (progress * 2 * math.pi);

      final _Projected p = _projectOrbitPoint(
        a: a,
        r: radius,
        pitch: pitch,
        yaw: yaw,
        yScale: yScale,
        cx: cx,
        cy: cy,
        yOffset: yOffset,
      );

      final double zNorm = (p.z / radius).clamp(-1.0, 1.0);
      final double t = (zNorm + 1.0) / 2.0; // 0 back -> 1 front

      // Opacity base (depth)
      double opacity = _lerp(0.20, 1.00, t);

      // Smooth fade behind nucleus region (no popping)
      if (zNorm < 0.0) {
        final double behindT = (-zNorm).clamp(0.0, 1.0);
        final double behindFade = 1.0 - _smoothStep(0.10, 0.90, behindT);

        final double dx = p.x - cx;
        final double dy = p.y - cy;
        final double dist = math.sqrt(dx * dx + dy * dy);

        final double fadeBand = nucleusVisualRadius * 0.30;
        final double nucleusFade = _smoothStep(
          nucleusVisualRadius - fadeBand,
          nucleusVisualRadius + fadeBand,
          dist,
        );

        // Behind + near nucleus => fade more
        opacity *= (0.25 + 0.75 * nucleusFade) * (0.25 + 0.75 * behindFade);
      }

      opacity = opacity.clamp(0.0, 1.0);

      // Slight scale up in front to emphasize glow peak
      final double pr = baseParticleRadius * _lerp(0.90, 1.35, t);

      particles.add(
        _ParticleDrawData(
          x: p.x,
          y: p.y,
          z: p.z,
          opacity: opacity,
          size: pr,
          depthT: t,
        ),
      );
    }

    // Draw back-to-front for correct layering
    particles.sort((a, b) => a.z.compareTo(b.z));

    for (final p in particles) {
      // Make glow peak very strong when near max opacity (front-most)
      // This gives you that “bright pop” moment without a hard flicker.
      final double peak = _smoothStep(0.78, 1.0, p.opacity);
      final double glowBoost = _lerp(1.0, 1.9, peak);

      final Paint outerGlow = Paint()
        ..color = particleColor.withValues(
          alpha: (p.opacity * 0.75).clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..style = PaintingStyle.fill;

      final Paint innerGlow = Paint()
        ..color = particleColor.withValues(
          alpha: (p.opacity * 0.95).clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.fill;

      final Paint core = Paint()
        ..color = particleColor.withValues(alpha: (p.opacity).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      final Paint highlight = Paint()
        ..color = Colors.white.withValues(
          alpha: (p.opacity * 0.85).clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(p.x, p.y), p.size * 2.7 * glowBoost, outerGlow);
      canvas.drawCircle(Offset(p.x, p.y), p.size * 1.8 * glowBoost, innerGlow);
      canvas.drawCircle(Offset(p.x, p.y), p.size, core);

      canvas.drawCircle(
        Offset(p.x - p.size * 0.35, p.y - p.size * 0.35),
        p.size * 0.33,
        highlight,
      );
    }
  }

  void _drawOrbitRing({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double r,
    required double pitch,
    required double yaw,
    required double yScale,
    required double yOffset,
    required Color ringColor,
    required double nucleusRadius,
  }) {
    // Sample the projected orbit into a path so it matches particle projection exactly
    const int steps = 180;
    final Path path = Path();

    for (int i = 0; i <= steps; i++) {
      final double a = (i / steps) * 2 * math.pi;
      final _Projected p = _projectOrbitPoint(
        a: a,
        r: r,
        pitch: pitch,
        yaw: yaw,
        yScale: yScale,
        cx: cx,
        cy: cy,
        yOffset: yOffset,
      );

      if (i == 0) {
        path.moveTo(p.x, p.y);
      } else {
        path.lineTo(p.x, p.y);
      }
    }

    // Ring paint: subtle, glowy, not overpowering
    // We also fade the ring slightly near the nucleus region so it doesn't slice through the emoji.
    final Paint ringSoft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = ringColor.withValues(alpha: 0.22);

    final Paint ringSharp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4
      ..color = ringColor.withValues(alpha: 0.28);

    // If you want the ring to "break" behind the nucleus, we can mask it.
    // Cheap & good: clip out a circular hole around the nucleus.
    canvas.save();
    final Path clip = Path()
      ..addRect(Rect.fromLTWH(0, 0, cx * 2, cy * 2))
      ..addOval(
        Rect.fromCircle(center: Offset(cx, cy), radius: nucleusRadius * 0.92),
      );
    // Even-odd fill clips the hole out
    canvas.clipPath(clip, doAntiAlias: true);

    canvas.drawPath(path, ringSoft);
    canvas.drawPath(path, ringSharp);

    canvas.restore();
  }

  _Projected _projectOrbitPoint({
    required double a,
    required double r,
    required double pitch,
    required double yaw,
    required double yScale,
    required double cx,
    required double cy,
    required double yOffset,
  }) {
    // Ring in XZ plane
    final double x0 = r * math.cos(a);
    final double y0 = 0.0;
    final double z0 = r * math.sin(a);

    // Pitch about X
    final double y1 = y0 * math.cos(pitch) - z0 * math.sin(pitch);
    final double z1 = y0 * math.sin(pitch) + z0 * math.cos(pitch);
    final double x1 = x0;

    // Yaw about Y
    final double x2 = x1 * math.cos(yaw) + z1 * math.sin(yaw);
    final double z2 = -x1 * math.sin(yaw) + z1 * math.cos(yaw);
    final double y2 = y1;

    final double sx = cx + x2;
    final double sy = cy + (y2 * yScale) + yOffset;

    return _Projected(x: sx, y: sy, z: z2);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _smoothStep(double edge0, double edge1, double x) {
    final double t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  @override
  bool shouldRepaint(_AtomicOrbitPainter oldDelegate) => true;
}

class _Projected {
  const _Projected({required this.x, required this.y, required this.z});
  final double x;
  final double y;
  final double z;
}
