import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// A compact grid displaying knee angle comparisons between user and pro.
/// Shows values in a clean table format with color-coded status indicators.
class KneeComparisonGrid extends StatelessWidget {
  const KneeComparisonGrid({
    super.key,
    this.frontKneeUser,
    this.frontKneePro,
    this.frontKneeDeviation,
    this.backKneeUser,
    this.backKneePro,
    this.backKneeDeviation,
  });

  final double? frontKneeUser;
  final double? frontKneePro;
  final double? frontKneeDeviation;
  final double? backKneeUser;
  final double? backKneePro;
  final double? backKneeDeviation;

  @override
  Widget build(BuildContext context) {
    final bool hasFrontKnee = frontKneeUser != null;
    final bool hasBackKnee = backKneeUser != null;
    final bool hasPro = frontKneePro != null || backKneePro != null;

    if (!hasFrontKnee && !hasBackKnee) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Knee comparison',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildHeader(hasPro: hasPro),
          const SizedBox(height: 8),
          if (hasFrontKnee)
            _buildRow(
              label: 'Front knee',
              userValue: frontKneeUser!,
              proValue: frontKneePro,
              deviation: frontKneeDeviation,
              hasPro: hasPro,
            ),
          if (hasFrontKnee && hasBackKnee) const SizedBox(height: 12),
          if (hasBackKnee)
            _buildRow(
              label: 'Back knee',
              userValue: backKneeUser!,
              proValue: backKneePro,
              deviation: backKneeDeviation,
              hasPro: hasPro,
            ),
          if (hasPro) ...[
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader({required bool hasPro}) {
    return Row(
      children: [
        const Expanded(
          flex: 3,
          child: SizedBox.shrink(),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'YOU',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: SenseiColors.gray.shade500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (hasPro) ...[
          Expanded(
            flex: 2,
            child: Text(
              'PRO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SenseiColors.gray.shade500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              'DIFF',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SenseiColors.gray.shade500,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRow({
    required String label,
    required double userValue,
    double? proValue,
    double? deviation,
    required bool hasPro,
  }) {
    final _DeviationStatus status = _getDeviationStatus(deviation);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: SenseiColors.gray.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: SenseiColors.gray.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${userValue.toStringAsFixed(1)}°',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hasPro) ...[
            Expanded(
              flex: 2,
              child: Text(
                proValue != null ? '${proValue.toStringAsFixed(1)}°' : '—',
                style: TextStyle(
                  fontSize: 14,
                  color: SenseiColors.gray.shade600,
                ),
              ),
            ),
            SizedBox(
              width: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (deviation != null)
                    Text(
                      '${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(1)}°',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: status.color,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: SenseiColors.gray.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(const Color(0xFF137e66), '<10°'),
          const SizedBox(width: 16),
          _buildLegendItem(const Color(0xFFD97706), '10-30°'),
          const SizedBox(width: 16),
          _buildLegendItem(const Color(0xFFDC2626), '>30°'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
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
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: SenseiColors.gray.shade600,
          ),
        ),
      ],
    );
  }

  _DeviationStatus _getDeviationStatus(double? deviation) {
    if (deviation == null) {
      return _DeviationStatus.good;
    }
    final double absDeviation = deviation.abs();
    if (absDeviation <= 10) {
      return _DeviationStatus.good;
    } else if (absDeviation <= 30) {
      return _DeviationStatus.warning;
    } else {
      return _DeviationStatus.poor;
    }
  }
}

enum _DeviationStatus {
  good(Color(0xFF137e66)),
  warning(Color(0xFFD97706)),
  poor(Color(0xFFDC2626));

  const _DeviationStatus(this.color);
  final Color color;
}
