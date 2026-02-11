import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
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

    return Card(
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
      color: isActive ? SenseiColors.gray[50] : Colors.white,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (!compact) ...[
                const SizedBox(height: 8),
                _buildSummary(),
                const SizedBox(height: 8),
                _buildFooter(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _toSentenceCase(observation.observationName),
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w600,
              color: SenseiColors.gray[800],
            ),
          ),
        ),
        // Show score percentage if available
        if (observation.score != null) _buildScorePercentage(),
        if (observation.hasVideoSegment) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: SenseiColors.gray[400],
          ),
        ],
      ],
    );
  }

  Widget _buildScorePercentage() {
    final int scorePercent = (observation.score! * 100).round();
    final Color color = _getScoreColor(scorePercent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$scorePercent%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getScoreColor(int scorePercent) {
    if (scorePercent >= 80) {
      return const Color(0xFF059669); // Darker green for contrast
    } else if (scorePercent >= 60) {
      return const Color(0xFFD97706); // Darker amber for contrast
    } else {
      return const Color(0xFFDC2626); // Darker red for contrast
    }
  }

  /// Convert string to sentence case (capitalize first letter only)
  String _toSentenceCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Type indicator temporarily disabled
  // Widget _buildTypeIndicator() {
  //   final Color color = _getTypeColor(observation.observationType);
  //   final IconData icon = _getTypeIcon(observation.observationType);
  //
  //   return Container(
  //     width: compact ? 20 : 24,
  //     height: compact ? 20 : 24,
  //     decoration: BoxDecoration(
  //       color: color.withValues(alpha: 0.15),
  //       shape: BoxShape.circle,
  //     ),
  //     child: Icon(
  //       icon,
  //       size: compact ? 12 : 14,
  //       color: color,
  //     ),
  //   );
  // }

  Widget _buildSummary() {
    return Text(
      observation.coaching.summary,
      style: TextStyle(
        fontSize: 13,
        color: SenseiColors.gray[600],
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // Show measurement value for numerical, or "Detected" badge for qualitative
        if (isNumerical)
          _buildMeasurementBadge()
        else
          _buildDetectedBadge(),
      ],
    );
  }

  Widget _buildMeasurementBadge() {
    final double value = observation.measurement!.measuredValue;
    final String unit = observation.measurement!.unit;
    final String formattedValue = _formatMeasurement(value, unit);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SenseiColors.gray[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.straighten,
            size: 12,
            color: SenseiColors.gray[500],
          ),
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

  /// Format measurement value with appropriate unit display
  String _formatMeasurement(double value, String unit) {
    final String lowerUnit = unit.toLowerCase();

    // Handle degrees - use degree symbol
    if (lowerUnit == 'degrees' || lowerUnit == 'degree') {
      return '${value.toStringAsFixed(1)}°';
    }

    // Handle milliseconds - show timing context (after/before plant)
    if (lowerUnit == 'milliseconds' || lowerUnit == 'ms') {
      final int absValue = value.abs().round();
      if (value >= 0) {
        return '$absValue ms after plant';
      } else {
        return '$absValue ms before plant';
      }
    }

    // Handle other units - format nicely
    final String formattedUnit = unit
        .replaceAll('_', ' ')
        .toLowerCase();

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
