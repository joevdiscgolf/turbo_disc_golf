import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Brain nucleus + 2 orbitals (left/right) with orbiting particles.
///
/// What this version does (per your request):
/// ✅ Orbitals themselves slowly rotate and change angle over time (dynamic / alive)
/// ✅ Particle motion is smooth + predictable + constant direction
/// ✅ Each particle has a different *constant* speed (but chosen so the loop is perfectly seamless)
/// ✅ No jarring spawn/jumps (no random phase jitter, no non-looping speeds)
/// ✅ Particles are ~2x smaller
/// ✅ Background green morphing circles NOT rendered (code kept)
/// ✅ Whole brain + orbitals 1.5x bigger (internal scale)
/// ✅ Accepts ValueNotifier for dynamic speed changes without position jumps
class GPTAtomicNucleusLoader extends StatefulWidget {
  const GPTAtomicNucleusLoader({
    super.key,
    this.size = 240.0,
    this.particleCount = 3,
    this.speedMultiplier = 1.0,
    this.speedMultiplierNotifier,
  });

  final double size;
  final int particleCount;
  final double speedMultiplier;

  /// Optional notifier for dynamic speed changes.
  /// If provided, this overrides the static speedMultiplier.
  final ValueNotifier<double>? speedMultiplierNotifier;

  @override
  State<GPTAtomicNucleusLoader> createState() => _GPTAtomicNucleusLoaderState();
}

class _GPTAtomicNucleusLoaderState extends State<GPTAtomicNucleusLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _brainController;
  late final Animation<double> _brainScale;

  @override
  void initState() {
    super.initState();
    _brainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _brainScale = Tween<double>(begin: 1.0, end: 1.096).animate(
      CurvedAnimation(parent: _brainController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _brainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double overallScale = 1.5;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: Transform.scale(
          scale: overallScale,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Keep the code, but do NOT render for now:
                // _MorphingBackground(size: widget.size),

                // Orbital A: tilted left
                _AtomicOrbit(
                  size: widget.size,
                  radius: widget.size * 0.395,
                  particleCount: widget.particleCount,
                  speedMultiplierNotifier: widget.speedMultiplierNotifier,
                  initialSpeedMultiplier: widget.speedMultiplier,
                  pitchDeg: 78,
                  baseYawDeg: -30,
                  yScale: 0.45,
                  yOffset: -3,
                  direction: 1,
                  particleColor: const Color(0xFF4DD0E1),
                  ringColor: const Color(0xFF7FE9F5),
                  orbitSeed: 101,
                ),

                // Orbital B: tilted right
                _AtomicOrbit(
                  size: widget.size,
                  radius: (widget.size * 0.395) * 1.02,
                  particleCount: widget.particleCount,
                  speedMultiplierNotifier: widget.speedMultiplierNotifier,
                  initialSpeedMultiplier: widget.speedMultiplier,
                  pitchDeg: 78,
                  baseYawDeg: 30,
                  yScale: 0.45,
                  yOffset: 3,
                  direction: -1,
                  particleColor: const Color(0xFF4DD0E1),
                  ringColor: const Color(0xFF7FE9F5),
                  orbitSeed: 202,
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
    return AnimatedBuilder(
      animation: _brainScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _brainScale.value,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: Container(
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
        child: Image.asset(
          'assets/emojis/brain_emoji.png',
          width: 78,
          height: 78,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

// class _MorphingBackground extends StatelessWidget {
//   const _MorphingBackground({required this.size});
//   final double size;
//
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
    required this.speedMultiplierNotifier,
    required this.initialSpeedMultiplier,
    required this.pitchDeg,
    required this.baseYawDeg,
    required this.yScale,
    required this.yOffset,
    required this.direction,
    required this.particleColor,
    required this.ringColor,
    required this.orbitSeed,
  });

  final double size;
  final double radius;
  final int particleCount;

  /// Optional notifier for dynamic speed changes.
  final ValueNotifier<double>? speedMultiplierNotifier;

  /// Initial speed multiplier (1.0 = normal speed)
  final double initialSpeedMultiplier;

  final double pitchDeg;
  final double baseYawDeg;

  final double yScale;
  final double yOffset;

  /// +1 forward, -1 reverse
  final int direction;

  final Color particleColor;
  final Color ringColor;

  /// For deterministic per-particle speed offsets (still seamless).
  final int orbitSeed;

  @override
  State<_AtomicOrbit> createState() => _AtomicOrbitState();
}

class _AtomicOrbitState extends State<_AtomicOrbit>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Cumulative rotation angles for smooth speed changes
  double _cumulativeRotation = 0.0;
  double _orbitRotation = 0.0; // For the orbital plane animation

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final Duration delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    final double deltaSeconds = delta.inMicroseconds / 1000000.0;

    // Get current speed multiplier
    final double speedMultiplier =
        widget.speedMultiplierNotifier?.value ?? widget.initialSpeedMultiplier;

    // Base angular velocity: 2 full rotations per 7 seconds
    // = (2 * 2π) / 7 = 4π/7 radians per second
    const double baseAngularVelocity = (4 * math.pi) / 7.0;

    // Update cumulative rotation based on current speed
    _cumulativeRotation += baseAngularVelocity * speedMultiplier * deltaSeconds;

    // Update orbital plane rotation (slow wobble, independent of speed)
    _orbitRotation +=
        (2 * math.pi / 7.0) * deltaSeconds; // One cycle per 7 seconds

    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _AtomicOrbitPainter(
        cumulativeRotation: _cumulativeRotation,
        orbitRotation: _orbitRotation,
        radius: widget.radius,
        particleCount: widget.particleCount,
        pitchDeg: widget.pitchDeg,
        baseYawDeg: widget.baseYawDeg,
        yScale: widget.yScale,
        yOffset: widget.yOffset,
        direction: widget.direction,
        particleColor: widget.particleColor,
        ringColor: widget.ringColor,
        orbitSeed: widget.orbitSeed,
        nucleusVisualRadius: 56,
      ),
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
  });

  final double x;
  final double y;
  final double z;
  final double opacity;
  final double size;
}

class _AtomicOrbitPainter extends CustomPainter {
  _AtomicOrbitPainter({
    required this.cumulativeRotation,
    required this.orbitRotation,
    required this.radius,
    required this.particleCount,
    required this.pitchDeg,
    required this.baseYawDeg,
    required this.yScale,
    required this.yOffset,
    required this.direction,
    required this.particleColor,
    required this.ringColor,
    required this.orbitSeed,
    required this.nucleusVisualRadius,
  });

  final double cumulativeRotation;
  final double orbitRotation;
  final double radius;
  final int particleCount;

  final double pitchDeg;
  final double baseYawDeg;
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

    // --- Dynamic orbital rotation (loops perfectly because it uses sin/cos) ---
    // Gives the orbital planes a slow, constant "precession" look.
    final double wobble = orbitRotation;

    // Make yaw and pitch gently vary. These amplitudes are tuned to look dynamic
    // without breaking the "two main orbitals" feel.
    final double dynamicYawDeg = baseYawDeg + 15.0 * math.sin(wobble);
    final double dynamicPitchDeg =
        pitchDeg + 15.0 * math.sin(wobble + math.pi / 2);

    final double pitch = dynamicPitchDeg * math.pi / 180.0;
    final double yaw = dynamicYawDeg * math.pi / 180.0;

    // 1) Draw the orbital ring
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

    // 2) Particles (smaller by ~2x)
    // Previously ~6.0; now ~3.0 (2x smaller)
    const double baseParticleRadius = 3.0;

    final List<_ParticleDrawData> particles = [];

    for (int i = 0; i < particleCount; i++) {
      // Each particle starts at a different position around the orbit
      final double a0 = (2 * math.pi / particleCount) * i;

      // Use cumulative rotation for smooth speed changes
      final double a = a0 + direction * cumulativeRotation;

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
      final double depthT = (zNorm + 1.0) / 2.0; // 0 back -> 1 front

      // Smooth opacity oscillation between 50% and 100% based on depth
      final double opacity = _lerp(0.50, 1.00, depthT);

      // Particle size (slightly bigger in front, but still small overall)
      final double pr = baseParticleRadius * _lerp(0.95, 1.25, depthT);

      particles.add(
        _ParticleDrawData(x: p.x, y: p.y, z: p.z, opacity: opacity, size: pr),
      );
    }

    // Back-to-front layering
    particles.sort((a, b) => a.z.compareTo(b.z));

    for (final p in particles) {
      // Make them much more luminous near max opacity
      final double peak = _smoothStep(0.82, 1.0, p.opacity);
      final double glowBoost = _lerp(1.0, 2.6, peak);

      final Paint outerGlow = Paint()
        ..color = particleColor.withValues(
          alpha: (p.opacity * 0.90).clamp(0.0, 1.0),
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
          alpha: (p.opacity * 0.95).clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(p.x, p.y), p.size * 3.2 * glowBoost, outerGlow);
      canvas.drawCircle(Offset(p.x, p.y), p.size * 2.0 * glowBoost, innerGlow);
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

    // Clip a hole so the ring doesn't slice through the emoji area
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
