import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Brain nucleus + 2 orbital rings (left-tilt + right-tilt) with orbiting particles.
/// Latest tweaks:
/// ✅ One orbital tilted left, one tilted right (±30° yaw base angles)
/// ✅ Orbitals continuously rotate and change angles for dynamic motion
/// ✅ Smooth particle motion along orbital paths (each particle has constant speed)
/// ✅ Per-particle speed variation (0.85-1.15x) for natural look
/// ✅ Particles flare brighter/more luminous at max opacity
/// ✅ Background green pulsing circles NOT rendered (code kept)
/// ✅ Whole brain + orbitals 1.5x bigger (via internal scale)
/// ✅ Perfect seamless looping animation
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
    // 1.5x bigger brain + orbitals *inside* the same outer box.
    // If you want the widget to also take up more layout space, increase [size] where you use it.
    const double overallScale = 1.5;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Transform.scale(
          scale: overallScale,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Keep the code, but do NOT render for now
                // _MorphingBackground(size: size),

                // Orbit LEFT tilt, clockwise-ish with slow rotation
                _AtomicOrbit(
                  size: size,
                  radius: size * 0.395,
                  particleCount: particleCount,
                  orbitDuration: const Duration(milliseconds: 7000),
                  speedMultiplier: 3.0,
                  basePitchDeg: 78,
                  baseYawDeg: -30,
                  yScale: 0.45,
                  yOffset: -3,
                  direction: 1,
                  particleColor: const Color(0xFF4DD0E1),
                  ringColor: const Color(0xFF7FE9F5),
                  orbitSeed: 101,
                  orbitRotationDuration: const Duration(milliseconds: 12000),
                ),

                // Orbit RIGHT tilt, opposite direction with slow rotation
                _AtomicOrbit(
                  size: size,
                  radius: (size * 0.395) * 1.02,
                  particleCount: particleCount,
                  orbitDuration: const Duration(milliseconds: 6500),
                  speedMultiplier: 3.0,
                  basePitchDeg: 78,
                  baseYawDeg: 30,
                  yScale: 0.45,
                  yOffset: 3,
                  direction: -1,
                  particleColor: const Color(0xFF4DD0E1),
                  ringColor: const Color(0xFF7FE9F5),
                  orbitSeed: 202,
                  orbitRotationDuration: const Duration(milliseconds: 10000),
                ),

                _buildNucleus(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNucleus() {
    // Slightly larger nucleus so the glow matches the increased scale.
    // (Remember: everything is inside a Transform.scale(1.5) too.)
    return Container(
          width: 110,
          height: 110,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4DA6).withValues(alpha: 0.45),
                blurRadius: 30,
                spreadRadius: 6,
              ),
            ],
          ),
          child: const Text('🧠', style: TextStyle(fontSize: 78)),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          duration: 2400.ms,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.12, 1.12),
          curve: Curves.easeInOut,
        )
        .then()
        .shimmer(
          duration: 1800.ms,
          color: const Color(0xFFFF4DA6).withValues(alpha: 0.28),
        );
  }
}

// class _MorphingBackground extends StatelessWidget {
//   const _MorphingBackground({required this.size});
//   final double size;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: size,
//       height: size,
//       child: Stack(
//         children: [
//           _buildBlob(
//             colors: const [Color(0xFF0C5349), Color(0xFF137e66)],
//             duration: 5000.ms,
//             scaleBegin: 1.0,
//             scaleEnd: 1.25,
//           ),
//           _buildBlob(
//             colors: const [Color(0xFF137e66), Color(0xFF26B39D)],
//             duration: 4200.ms,
//             scaleBegin: 0.95,
//             scaleEnd: 1.15,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBlob({
//     required List<Color> colors,
//     required Duration duration,
//     required double scaleBegin,
//     required double scaleEnd,
//   }) {
//     return Container(
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             gradient: RadialGradient(colors: colors, stops: const [0.0, 1.0]),
//           ),
//         )
//         .animate(onPlay: (controller) => controller.repeat(reverse: true))
//         .scale(
//           duration: duration,
//           begin: Offset(scaleBegin, scaleBegin),
//           end: Offset(scaleEnd, scaleEnd),
//           curve: Curves.easeInOut,
//         );
//   }
// }

class _AtomicOrbit extends StatefulWidget {
  const _AtomicOrbit({
    required this.size,
    required this.radius,
    required this.particleCount,
    required this.orbitDuration,
    required this.speedMultiplier,
    required this.basePitchDeg,
    required this.baseYawDeg,
    required this.yScale,
    required this.yOffset,
    required this.direction,
    required this.particleColor,
    required this.ringColor,
    required this.orbitSeed,
    required this.orbitRotationDuration,
  });

  final double size;
  final double radius;
  final int particleCount;
  final Duration orbitDuration;

  /// Base speed multiplier for the whole orbit.
  final double speedMultiplier;

  final double basePitchDeg;
  final double baseYawDeg;
  final double yScale;
  final double yOffset;

  /// +1 forward, -1 reverse
  final int direction;

  final Color particleColor;
  final Color ringColor;

  /// Used to generate deterministic "random" per-particle speeds.
  final int orbitSeed;

  /// Duration for the orbital angle rotation animation
  final Duration orbitRotationDuration;

  @override
  State<_AtomicOrbit> createState() => _AtomicOrbitState();
}

class _AtomicOrbitState extends State<_AtomicOrbit>
    with TickerProviderStateMixin {
  late final AnimationController _particleController;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: widget.orbitDuration,
    )..repeat();

    _rotationController = AnimationController(
      vsync: this,
      duration: widget.orbitRotationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_particleController, _rotationController]),
      builder: (context, child) {
        // Use controller value as base time; painter applies per-particle speed.
        final double baseTime =
            (_particleController.value * widget.speedMultiplier) % 1.0;

        // Calculate animated pitch and yaw angles
        final double rotationProgress = _rotationController.value;
        final double pitchDeg =
            widget.basePitchDeg +
            (math.sin(rotationProgress * 2 * math.pi) * 15);
        final double yawDeg =
            widget.baseYawDeg + (math.cos(rotationProgress * 2 * math.pi) * 20);

        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AtomicOrbitPainter(
            time: baseTime,
            radius: widget.radius,
            particleCount: widget.particleCount,
            pitchDeg: pitchDeg,
            yawDeg: yawDeg,
            yScale: widget.yScale,
            yOffset: widget.yOffset,
            direction: widget.direction,
            particleColor: widget.particleColor,
            ringColor: widget.ringColor,
            orbitSeed: widget.orbitSeed,
            nucleusVisualRadius: 56,
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
  final double depthT;
}

class _AtomicOrbitPainter extends CustomPainter {
  _AtomicOrbitPainter({
    required this.time,
    required this.radius,
    required this.particleCount,
    required this.pitchDeg,
    required this.yawDeg,
    required this.yScale,
    required this.yOffset,
    required this.direction,
    required this.particleColor,
    required this.ringColor,
    required this.orbitSeed,
    required this.nucleusVisualRadius,
  });

  final double time;
  final double radius;
  final int particleCount;

  final double pitchDeg;
  final double yawDeg;
  final double yScale;
  final double yOffset;
  final int direction;

  final Color particleColor;
  final Color ringColor;

  final int orbitSeed;
  final double nucleusVisualRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final double pitch = pitchDeg * math.pi / 180.0;
    final double yaw = yawDeg * math.pi / 180.0;

    // Visible ring
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

    // Particles
    const double baseParticleRadius = 6.0;
    final List<_ParticleDrawData> particles = [];

    for (int i = 0; i < particleCount; i++) {
      // Deterministic per-particle speed variation in ~[0.85..1.15]
      // More subtle variation for smoother, more predictable motion
      final double speed = _rand01(oribtSeeded(i)) * 0.30 + 0.85;

      // Initial position offset - evenly spaced around the orbit
      final double a0 = (2 * math.pi / particleCount) * i;

      // Smooth, continuous motion along the orbital path
      // Each particle moves at its own constant speed
      final double a = a0 + direction * ((time * speed) * 2 * math.pi);

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
      final double depthT = (zNorm + 1.0) / 2.0;

      // Base opacity from depth
      double opacity = _lerp(0.22, 1.00, depthT);

      // Smooth fade behind the nucleus region (no popping)
      if (zNorm < 0.0) {
        final double behindT = (-zNorm).clamp(0.0, 1.0);
        final double behindFade = 1.0 - _smoothStep(0.10, 0.90, behindT);

        final double dx = p.x - cx;
        final double dy = p.y - cy;
        final double dist = math.sqrt(dx * dx + dy * dy);

        final double fadeBand = nucleusVisualRadius * 0.32;
        final double nucleusFade = _smoothStep(
          nucleusVisualRadius - fadeBand,
          nucleusVisualRadius + fadeBand,
          dist,
        );

        opacity *= (0.25 + 0.75 * nucleusFade) * (0.25 + 0.75 * behindFade);
      }

      opacity = opacity.clamp(0.0, 1.0);

      final double pr = baseParticleRadius * _lerp(0.95, 1.45, depthT);

      particles.add(
        _ParticleDrawData(
          x: p.x,
          y: p.y,
          z: p.z,
          opacity: opacity,
          size: pr,
          depthT: depthT,
        ),
      );
    }

    particles.sort((a, b) => a.z.compareTo(b.z));

    for (final p in particles) {
      // Flare intensely near max opacity
      final double peak = _smoothStep(0.82, 1.0, p.opacity);
      final double glowBoost = _lerp(1.0, 2.4, peak);

      final Paint outerGlow = Paint()
        ..color = particleColor.withValues(
          alpha: (p.opacity * 0.85).clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
        ..style = PaintingStyle.fill;

      final Paint innerGlow = Paint()
        ..color = particleColor.withValues(alpha: (p.opacity).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9)
        ..style = PaintingStyle.fill;

      final Paint core = Paint()
        ..color = particleColor.withValues(alpha: (p.opacity).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      final Paint highlight = Paint()
        ..color = Colors.white.withValues(
          alpha: (p.opacity * 0.90).clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(p.x, p.y), p.size * 3.0 * glowBoost, outerGlow);
      canvas.drawCircle(Offset(p.x, p.y), p.size * 1.95 * glowBoost, innerGlow);
      canvas.drawCircle(Offset(p.x, p.y), p.size, core);

      canvas.drawCircle(
        Offset(p.x - p.size * 0.35, p.y - p.size * 0.35),
        p.size * 0.33,
        highlight,
      );
    }
  }

  // NOTE: "Random" helpers — deterministic per orbit + per particle.
  int oribtSeeded(int particleIndex) =>
      orbitSeed ^ (particleIndex * 0x9E3779B9);

  double _rand01(int seed) {
    // Simple integer hash -> 0..1
    int x = seed;
    x ^= (x << 13);
    x ^= (x >> 17);
    x ^= (x << 5);
    final int u = x & 0x7fffffff;
    return u / 0x7fffffff;
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

    final Paint ringSoft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = ringColor.withValues(alpha: 0.24);

    final Paint ringSharp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5
      ..color = ringColor.withValues(alpha: 0.30);

    // Clip out a hole so ring doesn't slice through the emoji area
    canvas.save();
    final Path clip = Path()
      ..addRect(Rect.fromLTWH(0, 0, cx * 2, cy * 2))
      ..addOval(
        Rect.fromCircle(center: Offset(cx, cy), radius: nucleusRadius * 0.96),
      );
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
    final double x0 = r * math.cos(a);
    final double y0 = 0.0;
    final double z0 = r * math.sin(a);

    final double y1 = y0 * math.cos(pitch) - z0 * math.sin(pitch);
    final double z1 = y0 * math.sin(pitch) + z0 * math.cos(pitch);
    final double x1 = x0;

    final double x2 = x1 * math.cos(yaw) + z1 * math.sin(yaw);
    final double z2 = -x1 * math.sin(yaw) + z1 * math.cos(yaw);
    final double y2 = y1;

    return _Projected(x: cx + x2, y: cy + (y2 * yScale) + yOffset, z: z2);
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
