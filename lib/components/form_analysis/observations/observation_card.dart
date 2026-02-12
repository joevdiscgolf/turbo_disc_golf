import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart'
    show SenseiColors, getSemanticColor, flattenedOverWhite;
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Card displaying a single form observation
/// Handles both numerical observations (with measurement) and qualitative observations
class ObservationCard extends StatelessWidget {
  const ObservationCard({
    super.key,
    required this.observation,
    required this.onTap,
    this.isActive = false,
    this.compact = false,
  });

  final FormObservation observation;
  final VoidCallback onTap;
  final bool isActive;
  final bool compact;

  /// Whether this observation has numerical measurement data
  bool get isNumerical => observation.measurement != null;

  @override
  Widget build(BuildContext context) {
    final Color typeColor = _getTypeColor(observation.observationType);
    final Color? scoreColor = observation.score != null
        ? getSemanticColor((observation.score! * 100))
        : null;

    return SizedBox(
      height: compact ? null : 160,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: defaultCardElevation,
        shadowColor: defaultCardShadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive ? typeColor : SenseiColors.gray[100]!,
            width: isActive ? 2 : 1,
          ),
        ),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: scoreColor != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      flattenedOverWhite(scoreColor, 0.25),
                      flattenedOverWhite(scoreColor, 0.05),
                    ],
                  )
                : null,
            color: scoreColor == null
                ? (isActive ? SenseiColors.gray[50] : Colors.white)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with right padding for arrow
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: _buildTitle(),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 8),
                        _buildScoreBar(),
                        const Spacer(),
                        _buildFooter(),
                      ],
                    ],
                  ),
                ),
                // Arrow in top right
                if (observation.hasVideoSegment)
                  Positioned(
                    top: 10,
                    right: 8,
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: SenseiColors.gray[400],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return SizedBox(
      height: compact ? null : 39,
      child: Text(
        _toSentenceCase(observation.observationName),
        style: TextStyle(
          fontSize: compact ? 13 : 15,
          fontWeight: FontWeight.w600,
          color: SenseiColors.gray[800],
          height: 1.3,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildScoreBar() {
    if (observation.score == null) return const SizedBox.shrink();

    final int scorePercent = (observation.score! * 100).round();
    final Color color = getSemanticColor(scorePercent.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Percentage text
        Text(
          '$scorePercent%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        // Progress bar
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: scorePercent / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Convert string to sentence case (capitalize first letter only)
  String _toSentenceCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // Show measurement value for numerical, or "Detected" badge for qualitative
        if (isNumerical) _buildMeasurementBadge() else _buildDetectedBadge(),
      ],
    );
  }

  Widget _buildMeasurementBadge() {
    final double value = observation.measurement!.measuredValue;
    final String unit = observation.measurement!.unit;

    final String formattedValue = _formatMeasurementValueOnly(value, unit);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.straighten, size: 12, color: SenseiColors.gray[500]),
          const SizedBox(width: 4),
          Text(
            formattedValue,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SenseiColors.gray[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Format measurement value only (just the value, not the context)
  String _formatMeasurementValueOnly(double value, String unit) {
    final String lowerUnit = unit.toLowerCase();

    // Handle degrees - use degree symbol
    if (lowerUnit == 'degrees' || lowerUnit == 'degree') {
      return '${value.toStringAsFixed(1)}°';
    }

    // Handle milliseconds - show just the value with ms
    if (lowerUnit == 'milliseconds' || lowerUnit == 'ms') {
      final int absValue = value.abs().round();
      return '$absValue ms';
    }

    // Handle factor units - just show "factor" without prefix
    if (lowerUnit.contains('factor')) {
      return '${value.toStringAsFixed(1)} factor';
    }

    // Handle score units - just show the value without "score"
    if (lowerUnit.contains('score')) {
      return value.toStringAsFixed(1);
    }

    // Handle other units - format nicely
    final String formattedUnit = unit.replaceAll('_', ' ').toLowerCase();

    return '${value.toStringAsFixed(1)} $formattedUnit';
  }

  Widget _buildDetectedBadge() {
    final Color color = _getTypeColor(observation.observationType);
    final bool isPositive =
        observation.observationType == ObservationType.positive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPositive ? 'Good form' : 'Issue detected',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getTypeColor(ObservationType type) {
    switch (type) {
      case ObservationType.positive:
        return const Color(0xFF10B981); // Green
      case ObservationType.negative:
        return const Color(0xFFEF4444); // Red
      case ObservationType.neutral:
        return SenseiColors.gray[400]!;
    }
  }

  // Type icon temporarily disabled
  // IconData _getTypeIcon(ObservationType type) {
  //   switch (type) {
  //     case ObservationType.positive:
  //       return Icons.check;
  //     case ObservationType.negative:
  //       return Icons.close;
  //     case ObservationType.neutral:
  //       return Icons.remove;
  //   }
  // }
}
