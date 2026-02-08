import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_measurement.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_reference.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Simplified numeric comparison showing user vs ideal vs pro measurements
class MeasurementComparisonRow extends StatelessWidget {
  const MeasurementComparisonRow({
    super.key,
    required this.measurement,
    this.proMeasurement,
    this.proName,
  });

  final ObservationMeasurement measurement;
  final ProMeasurement? proMeasurement;
  final String? proName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SenseiColors.gray[100]!),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                Icons.straighten,
                size: 14,
                color: SenseiColors.gray[500],
              ),
              const SizedBox(width: 6),
              Text(
                'MEASUREMENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: SenseiColors.gray[500],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Value cards row - use IntrinsicHeight for equal heights
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildValueCard(
                    'You',
                    measurement.measuredValue,
                    measurement.unit,
                    _getYouColor(),
                    _getDeviationLabel(),
                  ),
                ),
                const SizedBox(width: 8),
                if (measurement.idealValue != null) ...[
                  Expanded(
                    child: _buildValueCard(
                      'Ideal',
                      measurement.idealValue!,
                      measurement.unit,
                      SenseiColors.gray[600]!,
                      null,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (proMeasurement != null)
                  Expanded(
                    child: _buildValueCard(
                      proName?.split(' ').first ?? 'Pro',
                      proMeasurement!.value,
                      proMeasurement!.unit,
                      const Color(0xFF10B981),
                      null,
                    ),
                  ),
              ],
            ),
          ),
          // Deviation indicator
          if (measurement.deviation != null) ...[
            const SizedBox(height: 12),
            _buildDeviationBar(),
          ],
        ],
      ),
    );
  }

  /// Format value to avoid long decimal strings
  String _formatValue(double value) {
    if (value.abs() >= 100) {
      return value.toStringAsFixed(0);
    } else if (value.abs() >= 10) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(1);
  }

  /// Get color for "You" card - green if good, red if needs improvement
  Color _getYouColor() {
    final String lowerUnit = measurement.unit.toLowerCase();

    // For timing measurements (ms): positive/zero is good, negative is bad
    if (lowerUnit == 'milliseconds' || lowerUnit == 'ms') {
      return measurement.measuredValue >= 0
          ? const Color(0xFF10B981) // Green - good timing
          : const Color(0xFFEF4444); // Red - early (needs improvement)
    }

    // For other measurements, check deviation from ideal
    if (measurement.idealValue == null) {
      return SenseiColors.gray[600]!;
    }

    // If no deviation or deviation is very small, it's good (green)
    if (measurement.deviation == null || measurement.deviation!.abs() < 0.5) {
      return const Color(0xFF10B981); // Green
    }

    // Otherwise use red to indicate needs improvement
    return const Color(0xFFEF4444); // Red
  }

  Widget _buildValueCard(
    String label,
    double rawValue,
    String unit,
    Color color,
    String? sublabel,
  ) {
    final String lowerUnit = unit.toLowerCase();
    final bool isMilliseconds = lowerUnit == 'milliseconds' || lowerUnit == 'ms';

    // For milliseconds, use absolute value (direction shown in unit text)
    final double displayValue = isMilliseconds ? rawValue.abs() : rawValue;
    final String value = _formatValue(displayValue);
    final String formattedUnit = _formatUnitForDisplay(unit, value: rawValue);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: SenseiColors.gray[500],
            ),
          ),
          const SizedBox(height: 4),
          // Value and unit on same line with FittedBox to scale down if needed
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (formattedUnit.isNotEmpty)
                  Text(
                    formattedUnit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sublabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Format unit for display in value cards
  /// For timing measurements, includes context like "after plant" or "before plant"
  String _formatUnitForDisplay(String unit, {double? value}) {
    final String lowerUnit = unit.toLowerCase();

    // Degrees - use degree symbol
    if (lowerUnit == 'degrees' || lowerUnit == 'degree') {
      return '°';
    }

    // Milliseconds - show timing context based on sign
    if (lowerUnit == 'milliseconds' || lowerUnit == 'ms') {
      if (value != null) {
        if (value >= 0) {
          return ' ms after plant';
        } else {
          return ' ms before plant';
        }
      }
      return ' ms';
    }

    // Hide units that don't make sense to display (like slip_factor)
    if (lowerUnit.contains('factor') || lowerUnit.contains('ratio')) {
      return '';
    }

    // Other units - add space and show
    return ' ${unit.replaceAll('_', ' ').toLowerCase()}';
  }

  Widget _buildDeviationBar() {
    // Calculate position on bar (0 = left edge, 1 = right edge, 0.5 = center/ideal)
    final double maxDeviation = 200.0; // Max deviation for visualization
    final double normalizedDeviation =
        (measurement.deviation! / maxDeviation).clamp(-1.0, 1.0);
    final double position =
        (normalizedDeviation + 1) / 2; // Convert to 0-1 range

    return Column(
      children: [
        // Bar visualization
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFEF4444).withValues(alpha: 0.3),
                SenseiColors.gray[200]!,
                const Color(0xFF10B981).withValues(alpha: 0.3),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Center line (ideal)
                  Positioned(
                    left: constraints.maxWidth / 2 - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: SenseiColors.gray[500],
                    ),
                  ),
                  // User position marker
                  Positioned(
                    left: (position * constraints.maxWidth) - 6,
                    top: -4,
                    child: Container(
                      width: 12,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getLeftLabel(),
              style: TextStyle(
                fontSize: 9,
                color: SenseiColors.gray[400],
              ),
            ),
            Text(
              'IDEAL',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: SenseiColors.gray[500],
              ),
            ),
            Text(
              _getRightLabel(),
              style: TextStyle(
                fontSize: 9,
                color: SenseiColors.gray[400],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _getDeviationLabel() {
    if (measurement.deviationDirection == null) return null;
    final String direction = measurement.deviationDirection!;
    return direction.toUpperCase();
  }

  String _getLeftLabel() {
    final String? direction = measurement.deviationDirection;
    if (direction == 'early' || direction == 'late') {
      return 'EARLY';
    } else if (direction == 'forward' || direction == 'backward') {
      return 'BACKWARD';
    }
    return 'LOW';
  }

  String _getRightLabel() {
    final String? direction = measurement.deviationDirection;
    if (direction == 'early' || direction == 'late') {
      return 'LATE';
    } else if (direction == 'forward' || direction == 'backward') {
      return 'FORWARD';
    }
    return 'HIGH';
  }
}
