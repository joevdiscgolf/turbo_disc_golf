import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/throw_type_stats.dart';

class ThrowTypeRadarChart extends StatefulWidget {
  const ThrowTypeRadarChart({super.key, required this.throwTypes});

  final List<ThrowTypeStats> throwTypes;

  @override
  State<ThrowTypeRadarChart> createState() => _ThrowTypeRadarChartState();
}

class _ThrowTypeRadarChartState extends State<ThrowTypeRadarChart> {
  final Set<String> _visibleThrowTypes = {};
  String? _highlightedThrowType;

  // Color palette for different throw types
  static const List<Color> _throwTypeColors = [
    Color(0xFF137e66), // Forehand - Green
    Color(0xFF2196F3), // Backhand - Blue
    Color(0xFF9C27B0), // Overhand - Purple
    Color(0xFFFF9800), // Thumber - Orange
    Color(0xFFF44336), // Roller - Red
    Color(0xFF009688), // Scoober - Teal
    Color(0xFF3F51B5), // Tomahawk - Indigo
    Color(0xFFFF5722), // Grenade - Deep Orange
    Color(0xFF00BCD4), // Push Putt - Cyan
    Color(0xFF9E9E9E), // Other - Grey
  ];

  @override
  void initState() {
    super.initState();
    _initializeVisibleThrowTypes();
  }

  @override
  void didUpdateWidget(ThrowTypeRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.throwTypes != widget.throwTypes) {
      _initializeVisibleThrowTypes();
    }
  }

  void _initializeVisibleThrowTypes() {
    // Show all throw types
    _visibleThrowTypes.clear();
    for (var throwType in widget.throwTypes) {
      _visibleThrowTypes.add(throwType.throwType);
    }
  }

  Color _getColorForThrowType(String throwType, int index) {
    return _throwTypeColors[index % _throwTypeColors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.throwTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _RadarChartPainter(
                  throwTypes: widget.throwTypes,
                  visibleThrowTypes: _visibleThrowTypes,
                  highlightedThrowType: _highlightedThrowType,
                  colors: _throwTypeColors,
                  colorScheme: Theme.of(context).colorScheme,
                  textTheme: Theme.of(context).textTheme,
                ),
                child: GestureDetector(
                  onTapDown: (details) {
                    setState(() {
                      _highlightedThrowType = _getThrowTypeAtPosition(
                        details.localPosition,
                      );
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            _buildLegend(context),
            if (_highlightedThrowType != null) ...[
              const SizedBox(height: 12),
              _buildHighlightedStats(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: widget.throwTypes.asMap().entries.map((entry) {
        final int index = entry.key;
        final ThrowTypeStats throwType = entry.value;
        final Color color = _getColorForThrowType(throwType.throwType, index);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              throwType.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHighlightedStats(BuildContext context) {
    ThrowTypeStats? stats;
    try {
      stats = widget.throwTypes.firstWhere(
        (t) => t.throwType == _highlightedThrowType,
      );
    } catch (e) {
      if (widget.throwTypes.isNotEmpty) {
        stats = widget.throwTypes.first;
      }
    }

    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.displayName.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Birdie rate',
            value: '${stats.birdieRate.toStringAsFixed(0)}%',
            detail: '${stats.birdieCount}/${stats.totalHoles}',
          ),
          _StatRow(
            label: 'C1 in Reg',
            value: '${stats.c1InRegPct.toStringAsFixed(0)}%',
            detail: '${stats.c1Count}/${stats.c1Total}',
          ),
          _StatRow(
            label: 'C2 in Reg',
            value: '${stats.c2InRegPct.toStringAsFixed(0)}%',
            detail: '${stats.c2Count}/${stats.c2Total}',
          ),
          _StatRow(
            label: 'Parked',
            value: '${stats.parkedPct.toStringAsFixed(0)}%',
            detail: '${stats.parkedCount}',
          ),
          _StatRow(
            label: 'Fairway',
            value: '${stats.fairwayPct.toStringAsFixed(0)}%',
            detail: '${stats.fairwayCount}',
          ),
        ],
      ),
    );
  }

  String? _getThrowTypeAtPosition(Offset position) {
    // Simplified hit detection - would need more sophisticated logic in production
    return null;
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Row(
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                '($detail)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  _RadarChartPainter({
    required this.throwTypes,
    required this.visibleThrowTypes,
    required this.highlightedThrowType,
    required this.colors,
    required this.colorScheme,
    required this.textTheme,
  });

  final List<ThrowTypeStats> throwTypes;
  final Set<String> visibleThrowTypes;
  final String? highlightedThrowType;
  final List<Color> colors;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 40;

    // Draw background grid
    _drawGrid(canvas, center, radius);

    // Draw axes and labels
    _drawAxes(canvas, center, radius);

    // Draw data polygons for all visible throw types
    for (int i = 0; i < throwTypes.length; i++) {
      final ThrowTypeStats throwType = throwTypes[i];

      // Only draw if visible
      if (!visibleThrowTypes.contains(throwType.throwType)) {
        continue;
      }

      final Color color = colors[i % colors.length];
      final bool isHighlighted = highlightedThrowType == throwType.throwType;

      _drawDataPolygon(canvas, center, radius, throwType, color, isHighlighted);
    }
  }

  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final Paint gridPaint = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric circles for percentage levels
    for (int i = 1; i <= 4; i++) {
      final double circleRadius = radius * (i / 4);
      canvas.drawCircle(center, circleRadius, gridPaint);
    }

    // Draw axes
    const int sides = 5; // Birdie, C1, C2, Parked, Fairway
    for (int i = 0; i < sides; i++) {
      final double angle = (2 * math.pi / sides) * i - math.pi / 2;
      final Offset end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, gridPaint);
    }
  }

  void _drawAxes(Canvas canvas, Offset center, double radius) {
    const List<String> labels = ['Birdie', 'C1', 'C2', 'Parked', 'Fairway'];
    const int sides = 5;

    for (int i = 0; i < sides; i++) {
      final double angle = (2 * math.pi / sides) * i - math.pi / 2;
      final Offset labelPos = Offset(
        center.dx + (radius + 25) * math.cos(angle),
        center.dy + (radius + 25) * math.sin(angle),
      );

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          labelPos.dx - textPainter.width / 2,
          labelPos.dy - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawDataPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    ThrowTypeStats stats,
    Color color,
    bool isHighlighted,
  ) {
    final List<double> values = [
      stats.birdieRate,
      stats.c1InRegPct,
      stats.c2InRegPct,
      stats.parkedPct,
      stats.fairwayPct,
    ];

    final Path path = Path();
    const int sides = 5;

    for (int i = 0; i < sides; i++) {
      final double angle = (2 * math.pi / sides) * i - math.pi / 2;
      final double normalizedValue = values[i] / 100;
      final double pointRadius = radius * normalizedValue;

      final Offset point = Offset(
        center.dx + pointRadius * math.cos(angle),
        center.dy + pointRadius * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();

    // Fill
    final Paint fillPaint = Paint()
      ..color = color.withValues(alpha: isHighlighted ? 0.2 : 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // Stroke
    final Paint strokePaint = Paint()
      ..color = color.withValues(alpha: isHighlighted ? 0.9 : 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighlighted ? 2.5 : 1.5;

    canvas.drawPath(path, strokePaint);

    // Draw points
    for (int i = 0; i < sides; i++) {
      final double angle = (2 * math.pi / sides) * i - math.pi / 2;
      final double normalizedValue = values[i] / 100;
      final double pointRadius = radius * normalizedValue;

      final Offset point = Offset(
        center.dx + pointRadius * math.cos(angle),
        center.dy + pointRadius * math.sin(angle),
      );

      canvas.drawCircle(point, isHighlighted ? 5 : 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.highlightedThrowType != highlightedThrowType;
  }
}
