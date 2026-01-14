import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Loading animation with brain nucleus + orbiting particles.
/// Goal: "side-ish" orbital view (almost horizontal ellipse) + slight off-axis angle.
/// Uses 3D ring projection with pitch + yaw, depth sorting, and depth-based size/opacity.
/// Tails follow screen-space velocity so they always trail correctly.
class GPTAtomicNucleusLoader extends StatelessWidget {
  const GPTAtomicNucleusLoader({
    super.key,
    this.size = 240.0,
    this.particleCount = 3, // particles per orbit
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
          // Morphing background blobs - commented out but kept for future use
          // _MorphingBackground(size: size),

          // Orbit A: tilted one way (lower-left to upper-right)
          _AtomicOrbit(
            size: size,
            radius: size * 0.395, // ~95px when size=240
            particleCount: particleCount,
            orbitDuration: const Duration(milliseconds: 2700), // 3x faster
            pitchDeg: 76, // horizontal-ish ellipse
            yawDeg: 28, // tilted one direction
            yScale: 0.46, // compress vertical movement
            yOffset: 0, // centered
            reverseDirection: false, // clockwise
            particleColor: const Color(0xFF00E5FF), // More vibrant cyan
          ),

          // Orbit B: tilted opposite way (upper-left to lower-right) - creates X pattern
          _AtomicOrbit(
            size: size,
            radius: size * 0.395, // same radius for symmetry
            particleCount: particleCount,
            orbitDuration: const Duration(milliseconds: 2500), // slightly different speed
            pitchDeg: 76, // same pitch for symmetry
            yawDeg: -28, // opposite yaw angle - creates crossed rings
            yScale: 0.46, // same compression
            yOffset: 0, // centered
            reverseDirection: true, // counter-clockwise for opposite motion
            particleColor: const Color(0xFF00E5FF), // More vibrant cyan
          ),

          // Center brain emoji with pink glow (nucleus)
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

// ignore: unused_element
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
    required this.pitchDeg,
    required this.yawDeg,
    required this.yScale,
    required this.yOffset,
    required this.reverseDirection,
    required this.particleColor,
  });

  final double size;
  final double radius;
  final int particleCount;
  final Duration orbitDuration;

  /// High pitch (70–82) creates near-horizontal ellipse feel.
  final double pitchDeg;

  /// Small yaw (~15–25) gives "slightly off to the side angle".
  final double yawDeg;

  /// Further compress the vertical movement on screen.
  final double yScale;

  /// Optional subtle vertical offset to avoid perfect symmetry.
  final double yOffset;

  /// Reverse rotation direction for opposite orbital motion.
  final bool reverseDirection;

  final Color particleColor;

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
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AtomicOrbitPainter(
            progress: _controller.value,
            radius: widget.radius,
            particleCount: widget.particleCount,
            pitchDeg: widget.pitchDeg,
            yawDeg: widget.yawDeg,
            yScale: widget.yScale,
            yOffset: widget.yOffset,
            reverseDirection: widget.reverseDirection,
            particleColor: widget.particleColor,
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
    required this.tailDx,
    required this.tailDy,
  });

  final double x;
  final double y;
  final double z; // depth for sorting
  final double opacity;
  final double size; // particle radius
  final double tailDx; // normalized tail dir x (screen space)
  final double tailDy; // normalized tail dir y (screen space)
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
    required this.reverseDirection,
    required this.particleColor,
  });

  final double progress;
  final double radius;
  final int particleCount;

  final double pitchDeg;
  final double yawDeg;
  final double yScale;
  final double yOffset;
  final bool reverseDirection;

  final Color particleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final double pitch = pitchDeg * math.pi / 180.0;
    final double yaw = yawDeg * math.pi / 180.0;

    const double baseParticleRadius = 5.0;

    // Draw the orbital ring path first (so particles appear on top)
    _drawOrbitRing(
      canvas: canvas,
      cx: cx,
      cy: cy,
      pitch: pitch,
      yaw: yaw,
      radius: radius,
      yScale: yScale,
      yOffset: yOffset,
    );

    // For tails: sample a slightly earlier position along the orbit.
    const double tailDelta = 0.08; // radians

    final List<_ParticleDrawData> particles = [];

    // Apply direction multiplier to reverse rotation if needed
    final double directionMultiplier = reverseDirection ? -1.0 : 1.0;

    // Random speed multipliers for each particle to create organic motion
    final List<double> speedMultipliers = [1.0, 0.75, 1.28, 0.92, 1.15, 0.85];

    for (int i = 0; i < particleCount; i++) {
      // Each particle gets its own speed from the list
      final double particleSpeed = speedMultipliers[i % speedMultipliers.length];
      final double a =
          (2 * math.pi / particleCount) * i + (progress * 2 * math.pi * directionMultiplier * particleSpeed);

      // Current 3D-projected position
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

      // Slightly previous point for screen-space velocity / tail direction
      // Account for direction when calculating tail
      final _Projected pPrev = _projectOrbitPoint(
        a: a - (tailDelta * directionMultiplier),
        r: radius,
        pitch: pitch,
        yaw: yaw,
        yScale: yScale,
        cx: cx,
        cy: cy,
        yOffset: yOffset,
      );

      // Tail direction: opposite of motion, so point from current toward previous
      final double vx = (pPrev.x - p.x);
      final double vy = (pPrev.y - p.y);
      final double vLen = math
          .sqrt(vx * vx + vy * vy)
          .clamp(0.0001, double.infinity);
      final double tailDx = vx / vLen;
      final double tailDy = vy / vLen;

      // Depth normalization roughly -1..1
      final double zNorm = (p.z / radius).clamp(-1.0, 1.0);
      final double t = (zNorm + 1.0) / 2.0; // 0 (back) -> 1 (front)

      // Smoother depth-based opacity - gradual fade instead of sudden disappearance
      // Use a curve that fades out smoothly when behind brain
      double opacity;
      if (zNorm < 0) {
        // Behind brain: fade from 0.95 (barely behind) to 0.0 (far behind)
        final double backT = (zNorm + 1.0); // 0 (far back) to 1 (just behind center)
        opacity = _lerp(0.0, 0.20, backT * backT); // Smooth curve
      } else {
        // In front: bright and vibrant - increased max opacity for more luminous particles
        opacity = _lerp(0.60, 1.0, t);
      }

      final double pr = baseParticleRadius * _lerp(0.85, 1.30, t);

      particles.add(
        _ParticleDrawData(
          x: p.x,
          y: p.y,
          z: p.z,
          opacity: opacity,
          size: pr,
          tailDx: tailDx,
          tailDy: tailDy,
        ),
      );
    }

    // Depth-sort: draw back first, then front on top
    particles.sort((a, b) => a.z.compareTo(b.z));

    for (final p in particles) {
      // Tail first (behind particle)
      _drawCometTailScreen(
        canvas: canvas,
        x: p.x,
        y: p.y,
        dirX: p.tailDx,
        dirY: p.tailDy,
        particleOpacity: p.opacity,
        particleRadius: p.size,
      );

      // Particle glow + core - ultra bright and luminous
      final Paint glowPaint = Paint()
        ..color = particleColor.withValues(alpha: p.opacity * 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
        ..style = PaintingStyle.fill;

      final Paint particlePaint = Paint()
        ..color = particleColor.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      // Even larger glow for maximum luminosity
      canvas.drawCircle(Offset(p.x, p.y), p.size * 3.0, glowPaint);
      canvas.drawCircle(Offset(p.x, p.y), p.size, particlePaint);
    }
  }

  void _drawOrbitRing({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double pitch,
    required double yaw,
    required double radius,
    required double yScale,
    required double yOffset,
  }) {
    const int segments = 120; // High segment count for smooth ring
    final List<Offset> frontPoints = [];
    final List<Offset> backPoints = [];

    // Sample points around the orbit and separate by depth
    for (int i = 0; i <= segments; i++) {
      final double angle = (i / segments) * 2 * math.pi;
      final _Projected p = _projectOrbitPoint(
        a: angle,
        r: radius,
        pitch: pitch,
        yaw: yaw,
        yScale: yScale,
        cx: cx,
        cy: cy,
        yOffset: yOffset,
      );

      final double zNorm = (p.z / radius).clamp(-1.0, 1.0);
      if (zNorm < 0) {
        backPoints.add(Offset(p.x, p.y));
      } else {
        frontPoints.add(Offset(p.x, p.y));
      }
    }

    // Draw back portion first (behind brain) - very subtle to avoid diagonal line artifact
    if (backPoints.length > 1) {
      final Path backPath = Path();
      backPath.moveTo(backPoints.first.dx, backPoints.first.dy);
      for (int i = 1; i < backPoints.length; i++) {
        backPath.lineTo(backPoints[i].dx, backPoints[i].dy);
      }

      // Much more subtle to avoid visible diagonal line
      final Paint backRingPaint = Paint()
        ..color = particleColor.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawPath(backPath, backRingPaint);
    }

    // Draw front portion (in front of brain) - brighter
    if (frontPoints.length > 1) {
      final Path frontPath = Path();
      frontPath.moveTo(frontPoints.first.dx, frontPoints.first.dy);
      for (int i = 1; i < frontPoints.length; i++) {
        frontPath.lineTo(frontPoints[i].dx, frontPoints[i].dy);
      }

      // Outer glow
      final Paint glowPaint = Paint()
        ..color = particleColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      // Main ring
      final Paint ringPaint = Paint()
        ..color = particleColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

      canvas.drawPath(frontPath, glowPaint);
      canvas.drawPath(frontPath, ringPaint);
    }
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
    // Start with a ring in the XZ plane (y=0), which naturally gives depth.
    final double x0 = r * math.cos(a);
    final double y0 = 0.0;
    final double z0 = r * math.sin(a);

    // Pitch: rotate around X axis
    final double y1 = y0 * math.cos(pitch) - z0 * math.sin(pitch);
    final double z1 = y0 * math.sin(pitch) + z0 * math.cos(pitch);
    final double x1 = x0;

    // Yaw: rotate around Y axis (side angle)
    final double x2 = x1 * math.cos(yaw) + z1 * math.sin(yaw);
    final double z2 = -x1 * math.sin(yaw) + z1 * math.cos(yaw);
    final double y2 = y1;

    // Simple projection to screen (orthographic-ish) + vertical compression.
    final double sx = cx + x2;
    final double sy = cy + (y2 * yScale) + yOffset;

    return _Projected(x: sx, y: sy, z: z2);
  }

  void _drawCometTailScreen({
    required Canvas canvas,
    required double x,
    required double y,
    required double dirX,
    required double dirY,
    required double particleOpacity,
    required double particleRadius,
  }) {
    const int tailSegments = 6; // More segments for smoother tail
    const double segmentSpacing = 5.0; // Closer spacing for smooth gradient

    for (int i = 1; i <= tailSegments; i++) {
      final double t = i / tailSegments; // 0 to 1
      final double distance = segmentSpacing * i;
      final double segmentX = x + distance * dirX;
      final double segmentY = y + distance * dirY;

      // Smooth exponential fade for comet effect
      final double segmentOpacityFactor = math.pow(1.0 - t, 2.2).toDouble();
      final double segmentOpacity = (particleOpacity * segmentOpacityFactor)
          .clamp(0.0, 1.0);

      // Gradual size decrease
      final double segmentSize = particleRadius * (1.0 - (t * 0.65));

      // Draw with more blur for smoother appearance
      final Paint tailGlowPaint = Paint()
        ..color = particleColor.withValues(alpha: segmentOpacity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.fill;

      final Paint tailPaint = Paint()
        ..color = particleColor.withValues(alpha: segmentOpacity * 0.85)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(segmentX, segmentY),
        segmentSize * 2.0,
        tailGlowPaint,
      );
      canvas.drawCircle(Offset(segmentX, segmentY), segmentSize, tailPaint);
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_AtomicOrbitPainter oldDelegate) => true;
}

class _Projected {
  const _Projected({required this.x, required this.y, required this.z});
  final double x;
  final double y;
  final double z;
}
