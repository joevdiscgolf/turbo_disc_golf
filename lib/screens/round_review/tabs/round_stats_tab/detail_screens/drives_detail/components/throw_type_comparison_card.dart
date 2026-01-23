import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';
import 'package:turbo_disc_golf/utils/throw_technique_constants.dart';

/// Displays throw type statistics in a card-based comparison layout
/// with interactive hover states and clear affordances for tapping
class ThrowTypeComparisonCard extends StatefulWidget {
  const ThrowTypeComparisonCard({
    super.key,
    required this.throwTypes,
    required this.onThrowTypeTap,
  });

  final List<ThrowTypeStats> throwTypes;
  final Function(ThrowTypeStats) onThrowTypeTap;

  @override
  State<ThrowTypeComparisonCard> createState() =>
      _ThrowTypeComparisonCardState();
}

class _ThrowTypeComparisonCardState extends State<ThrowTypeComparisonCard> {
  int? _hoveredIndex;

  static const _textColor = Color(0xFF1F2937);
  static const _typeColumnWidth = 38.0;

  @override
  Widget build(BuildContext context) {
    if (widget.throwTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayTypes = widget.throwTypes.take(2).toList();

    return Column(
      children: addRunSpacing([
        _buildHeaderCard(),
        ...List.generate(
          displayTypes.length,
          (index) => _buildThrowTypeCard(displayTypes[index], index),
        ),
      ], axis: Axis.vertical),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _typeColumnWidth,
            child: Text(
              'Type',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SenseiColors.gray[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                _buildHeaderColumn('C1 Reg'),
                _buildHeaderColumn('Parked'),
                _buildHeaderColumn('OB'),
                _buildHeaderColumn('Birdie'),
              ],
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderColumn(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: SenseiColors.gray[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThrowTypeCard(ThrowTypeStats throwType, int index) {
    final bool isHovered = _hoveredIndex == index;

    return GestureDetector(
      onTap: () => widget.onThrowTypeTap(throwType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: defaultCardBoxShadow(),
        ),
        child: Row(
          children: [
            _buildTypeColumn(throwType),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricsRow(throwType)),
            SizedBox(width: 24, child: _buildChevron(isHovered)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeColumn(ThrowTypeStats throwType) {
    final abbreviation = ThrowTechniqueAbbreviations.getAbbreviation(
      throwType.throwType,
    );

    return SizedBox(
      width: _typeColumnWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          abbreviation,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow(ThrowTypeStats throwType) {
    return Row(
      children: [
        _buildMetricColumn(
          throwType.c1InRegPct,
          throwType.totalHoles,
          MetricType.c1InReg,
        ),
        _buildMetricColumn(
          throwType.parkedPct,
          throwType.totalHoles,
          MetricType.parked,
        ),
        _buildMetricColumn(
          throwType.obPct,
          throwType.totalHoles,
          MetricType.ob,
        ),
        _buildMetricColumn(
          throwType.birdieRate,
          throwType.totalHoles,
          MetricType.birdieRate,
        ),
      ],
    );
  }

  Widget _buildMetricColumn(
    double value,
    int totalHoles,
    MetricType metricType,
  ) {
    final double percentage = value > 1 ? value / 100 : value;
    final int percentageInt = (percentage * 100).round();
    final int count = (percentage * totalHoles).round();
    final Color color = _getColorForMetric(percentage, metricType);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$percentageInt%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '($count/$totalHoles)',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.normal,
                    color: SenseiColors.gray[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChevron(bool isHovered) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      offset: isHovered ? const Offset(0.15, 0) : Offset.zero,
      child: Icon(Icons.chevron_right, color: SenseiColors.gray[500], size: 20),
    );
  }

  Color _getColorForMetric(double percentage, MetricType metricType) {
    final MetricThresholds thresholds =
        MetricThresholdsConfig.getThresholds(metricType);
    return getMetricColor(percentage, thresholds);
  }
}
