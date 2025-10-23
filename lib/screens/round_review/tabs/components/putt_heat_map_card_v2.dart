import 'dart:math';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';

class PuttHeatMapCardV2 extends StatefulWidget {
  const PuttHeatMapCardV2({super.key, required this.round});

  final DGRound round;

  /// Segment colors for the heat map gradient
  /// Index 0: Closest segments (highest make rate) - Very light green
  /// Index 1: Middle segments (medium make rate) - Extra light green
  /// Index 2: Farthest segments (lowest make rate) - White
  static const List<Color> segmentColors = [
    Color(0xFFE8F5E9), // Very light green
    Color(0xFFF1F8F0), // Extra light green (weaker)
    Colors.white, // White
  ];

  @override
  State<PuttHeatMapCardV2> createState() => _PuttHeatMapCardV2State();
}

class _PuttHeatMapCardV2State extends State<PuttHeatMapCardV2> {
  bool _showCircle1 = true;

  @override
  Widget build(BuildContext context) {
    final puttingService = locator.get<PuttingAnalysisService>();
    final allPutts = puttingService.getPuttAttempts(widget.round);

    // Filter putts by circle
    final circle1Putts = allPutts.where((putt) {
      final distance = putt['distance'] as double?;
      return distance != null && distance <= 33;
    }).toList();

    final circle2Putts = allPutts.where((putt) {
      final distance = putt['distance'] as double?;
      return distance != null && distance > 33 && distance <= 66;
    }).toList();

    final displayPutts = _showCircle1 ? circle1Putts : circle2Putts;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CircleToggle(
              showCircle1: _showCircle1,
              onToggle: (value) {
                setState(() {
                  _showCircle1 = value;
                });
              },
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1,
              child: _PuttingCirclePainter(
                putts: displayPutts,
                showCircle1: _showCircle1,
              ),
            ),
            const SizedBox(height: 16),
            _buildStats(displayPutts),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(List<Map<String, dynamic>> putts) {
    final made = putts.where((p) => p['made'] as bool).length;
    final attempts = putts.length;
    final percentage = attempts > 0 ? (made / attempts * 100) : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$made/$attempts made',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        Text(
          '(${percentage.toStringAsFixed(0)}%)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CircleToggle extends StatelessWidget {
  const _CircleToggle({required this.showCircle1, required this.onToggle});

  final bool showCircle1;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ToggleButton(
          label: 'Circle 1',
          isSelected: showCircle1,
          onTap: () => onToggle(true),
        ),
        const SizedBox(width: 24),
        _ToggleButton(
          label: 'Circle 2',
          isSelected: !showCircle1,
          onTap: () => onToggle(false),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PuttingCirclePainter extends StatelessWidget {
  const _PuttingCirclePainter({required this.putts, required this.showCircle1});

  final List<Map<String, dynamic>> putts;
  final bool showCircle1;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HeatMapPainter(putts: putts, showCircle1: showCircle1),
    );
  }
}

class _HeatMapPainter extends CustomPainter {
  _HeatMapPainter({required this.putts, required this.showCircle1});

  final List<Map<String, dynamic>> putts;
  final bool showCircle1;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Define circle radii
    final basketRadius = maxRadius * 0.05;
    final circle1InnerRadius = maxRadius * 0.15;
    final circle1OuterRadiusSmall =
        maxRadius * 0.5; // For Circle 2 visualization
    final outerRadius = maxRadius * 0.95; // Same size for both visualizations

    // Paint for filled circles - monochromatic green gradient
    // Use colors from static const array for easy modification
    final closestSegmentPaint = Paint()
      ..color =
          PuttHeatMapCardV2.segmentColors[0] // Medium-light green
      ..style = PaintingStyle.fill;

    final middleSegmentPaint = Paint()
      ..color =
          PuttHeatMapCardV2.segmentColors[1] // Very light green
      ..style = PaintingStyle.fill;

    final farthestSegmentPaint = Paint()
      ..color =
          PuttHeatMapCardV2.segmentColors[2] // White
      ..style = PaintingStyle.fill;

    // Paint for circle outlines
    final strokePaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (showCircle1) {
      // Frame 1: Show Circle 1 visualization with green gradient
      // Segment 3 (22-33 ft): Outermost - white (lowest make rate ~50-60%)
      canvas.drawCircle(center, outerRadius, farthestSegmentPaint);

      // Segment 2 (11-22 ft): Middle - very light green (medium make rate ~70-80%)
      final segment2Radius =
          circle1InnerRadius + (outerRadius - circle1InnerRadius) * (2 / 3);
      canvas.drawCircle(center, segment2Radius, middleSegmentPaint);

      // Segment 1 (0-11 ft): Inner - medium-light green (highest make rate 90%+)
      final segment1Radius =
          circle1InnerRadius + (outerRadius - circle1InnerRadius) * (1 / 3);
      canvas.drawCircle(center, segment1Radius, closestSegmentPaint);

      // Draw outlines for segments
      canvas.drawCircle(center, outerRadius, strokePaint);
      canvas.drawCircle(center, segment2Radius, strokePaint);
      canvas.drawCircle(center, segment1Radius, strokePaint);

      // Center basket (filled)
      final basketPaint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, basketRadius, basketPaint);
    } else {
      // Frame 2: Show Circle 2 visualization with green gradient
      // Outermost segment (55-66 ft): white (lowest make rate ~5-15%)
      canvas.drawCircle(center, outerRadius, farthestSegmentPaint);

      // Middle segment (44-55 ft): very light green (low make rate ~15-25%)
      final c2Segment2Radius =
          circle1OuterRadiusSmall +
          (outerRadius - circle1OuterRadiusSmall) * (2 / 3);
      canvas.drawCircle(center, c2Segment2Radius, middleSegmentPaint);

      // Inner segment of Circle 2 (33-44 ft): medium-light green (highest in C2, ~30-40% make rate)
      final c2Segment1Radius =
          circle1OuterRadiusSmall +
          (outerRadius - circle1OuterRadiusSmall) * (1 / 3);
      canvas.drawCircle(center, c2Segment1Radius, closestSegmentPaint);

      // Inner filled circle (Circle 1 - white background)
      canvas.drawCircle(center, circle1OuterRadiusSmall, farthestSegmentPaint);

      // Add diagonal hash pattern to Circle 1 area to show it's excluded
      _drawHashPattern(
        canvas,
        center,
        circle1OuterRadiusSmall,
        Colors.grey[300]!,
      );

      // Draw outlines for Circle 2 segments
      canvas.drawCircle(center, c2Segment2Radius, strokePaint);
      canvas.drawCircle(center, c2Segment1Radius, strokePaint);
      canvas.drawCircle(center, circle1OuterRadiusSmall, strokePaint);

      // Outer ring outline (Circle 2 boundary)
      canvas.drawCircle(center, outerRadius, strokePaint);

      // Center basket (filled white)
      final basketPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, basketRadius, basketPaint);
    }

    // Draw putt dots - arranged symmetrically at the bottom
    // Constant angular spacing between dots (easily adjustable)
    const angularSpacing = 0.2; // ~8 degrees spacing between dots

    // Group putts by distance buckets for better spacing
    final Map<int, List<Map<String, dynamic>>> buckets = {};

    for (var putt in putts) {
      final distance = putt['distance'] as double?;
      if (distance == null) continue;

      // Create 2-foot buckets for grouping nearby putts
      final bucketKey = (distance / 2).floor();
      buckets.putIfAbsent(bucketKey, () => []).add(putt);
    }

    // Process each bucket and arrange dots symmetrically
    for (var bucket in buckets.values) {
      final count = bucket.length;
      const baseAngle = pi / 2; // Bottom center (6 o'clock position)

      for (int i = 0; i < count; i++) {
        final putt = bucket[i];
        final distance = putt['distance'] as double;
        final made = putt['made'] as bool? ?? false;

        // Use green for made putts, red for missed putts
        final dotPaint = Paint()
          ..color = made ? const Color(0xFF4CAF50) : const Color(0xFFEF5350)
          ..style = PaintingStyle.fill;

        // Calculate exact radius based on actual distance
        double radius;
        if (showCircle1) {
          // Map 0-33ft to the area between circle1InnerRadius and outerRadius
          radius =
              circle1InnerRadius +
              (distance / 33) * (outerRadius - circle1InnerRadius);
        } else {
          // Map 33-66ft to the area between circle1OuterRadiusSmall and outerRadius
          final normalizedDistance = (distance - 33) / 33;
          radius =
              circle1OuterRadiusSmall +
              normalizedDistance * (outerRadius - circle1OuterRadiusSmall);
        }

        // Calculate angle offset from center for symmetrical arrangement
        double angleOffset;
        if (count % 2 == 1) {
          // Odd count: center dot at baseAngle, others spread symmetrically
          final centerIndex = count ~/ 2;
          angleOffset = (i - centerIndex) * angularSpacing;
        } else {
          // Even count: no center dot, spread symmetrically around center
          final centerOffset = count / 2 - 0.5;
          angleOffset = (i - centerOffset) * angularSpacing;
        }

        final angle = baseAngle + angleOffset;

        // Calculate position
        final x = center.dx + radius * cos(angle);
        final y = center.dy + radius * sin(angle);

        canvas.drawCircle(Offset(x, y), 4, dotPaint);
      }
    }
  }

  void _drawHashPattern(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final hashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Save the canvas state
    canvas.save();

    // Clip to circle
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(path);

    // Draw diagonal lines at 45-degree angle
    const spacing = 8.0;
    final diameter = radius * 2;
    final numLines = (diameter * sqrt(2) / spacing).ceil();

    for (int i = -numLines; i <= numLines; i++) {
      final offset = i * spacing;
      canvas.drawLine(
        Offset(center.dx - diameter + offset, center.dy - diameter),
        Offset(center.dx + diameter + offset, center.dy + diameter),
        hashPaint,
      );
    }

    // Restore the canvas state
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeatMapPainter oldDelegate) {
    return oldDelegate.putts != putts || oldDelegate.showCircle1 != showCircle1;
  }
}
