import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// A card that visually compares back knee angles between user and pro.
/// Shows visual angle diagrams with degree values.
class AngleComparisonCard extends StatelessWidget {
  const AngleComparisonCard({
    super.key,
    required this.backKneeUser,
    this.backKneePro,
    this.backKneeDeviation,
  });

  final double backKneeUser;
  final double? backKneePro;
  final double? backKneeDeviation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Angle comparison',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _KneeAngleComparison(
            label: 'Back knee',
            userAngle: backKneeUser,
            proAngle: backKneePro,
            deviation: backKneeDeviation,
          ),
        ],
      ),
    );
  }
}

class _KneeAngleComparison extends StatelessWidget {
  const _KneeAngleComparison({
    required this.label,
    required this.userAngle,
    this.proAngle,
    this.deviation,
  });

  final String label;
  final double userAngle;
  final double? proAngle;
  final double? deviation;

  @override
  Widget build(BuildContext context) {
    final bool hasPro = proAngle != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SenseiColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: SenseiColors.gray.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AngleDisplay(
                  label: 'You',
                  angle: userAngle,
                  color: SenseiColors.senseiBlue,
                ),
              ),
              if (hasPro) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _AngleDisplay(
                    label: 'Pro',
                    angle: proAngle!,
                    color: SenseiColors.gray.shade400,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AngleDisplay extends StatelessWidget {
  const _AngleDisplay({
    required this.label,
    required this.angle,
    required this.color,
  });

  final String label;
  final double angle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: SenseiColors.gray.shade600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          width: 80,
          child: CustomPaint(
            painter: _KneeAnglePainter(angle: angle, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${angle.toStringAsFixed(1)}°',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _KneeAnglePainter extends CustomPainter {
  _KneeAnglePainter({required this.angle, required this.color});

  final double angle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Position the knee joint at center
    final Offset kneePoint = Offset(size.width / 2, size.height * 0.6);

    final double lineLength = size.height * 0.5;

    // Lower leg: goes down and to the right (fixed direction)
    // Angle from horizontal, pointing down-right
    const double lowerLegAngle = math.pi * 0.35; // ~63° down from horizontal
    final Offset lowerLegEnd = Offset(
      kneePoint.dx + lineLength * 0.7 * math.cos(lowerLegAngle),
      kneePoint.dy + lineLength * 0.7 * math.sin(lowerLegAngle),
    );

    // Upper leg (thigh): the knee angle is the interior angle between thigh and lower leg
    // 180° = straight (thigh points opposite to lower leg)
    // 90° = right angle bend (thigh perpendicular to lower leg)
    //
    // Formula: thighAngle = lowerLegAngle - kneeAngle
    // This ensures that as knee angle increases toward 180°, thigh moves toward
    // the opposite direction of the lower leg.
    final double kneeAngleRad = angle * math.pi / 180;
    final double thighAngle = lowerLegAngle - kneeAngleRad;

    final Offset thighEnd = Offset(
      kneePoint.dx + lineLength * math.cos(thighAngle),
      kneePoint.dy + lineLength * math.sin(thighAngle),
    );

    // Draw the leg segments
    canvas.drawLine(kneePoint, thighEnd, paint);
    canvas.drawLine(kneePoint, lowerLegEnd, paint);

    // Draw the knee joint dot
    final Paint jointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(kneePoint, 4, jointPaint);
  }

  @override
  bool shouldRepaint(covariant _KneeAnglePainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.color != color;
  }
}
