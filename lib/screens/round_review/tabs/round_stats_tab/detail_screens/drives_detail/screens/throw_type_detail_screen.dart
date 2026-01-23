import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/shot_detail.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/components/metric_row.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/components/shot_details_list.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/components/shot_shape_card.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

/// Detail screen showing shot shape breakdown for a specific throw type
class ThrowTypeDetailScreen extends StatefulWidget {
  static const String screenName = 'Throw Type Detail';
  static const String routeName = '/throw-type-detail';

  const ThrowTypeDetailScreen({
    super.key,
    required this.throwType,
    required this.overallStats,
    required this.shotShapeStats,
    required this.overallShotDetails,
    required this.shotShapeDetails,
  });

  final String throwType;
  final ThrowTypeStats overallStats;
  final List<ShotShapeStats> shotShapeStats;
  final List<ShotDetail> overallShotDetails;
  final Map<String, List<ShotDetail>> shotShapeDetails;

  @override
  State<ThrowTypeDetailScreen> createState() => _ThrowTypeDetailScreenState();
}

class _ThrowTypeDetailScreenState extends State<ThrowTypeDetailScreen> {
  bool _isOverallExpanded = false;
  final Map<String, bool> _shotShapeExpanded = {};
  late final LoggingServiceBase _logger;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': ThrowTypeDetailScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('ThrowTypeDetailScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: GenericAppBar(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        title: widget.overallStats.displayName,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: 16),
          if (widget.shotShapeStats.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Shot Shape Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            ...widget.shotShapeStats.map(
              (shape) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShotShapeCard(
                  shape: shape,
                  shotDetails: widget.shotShapeDetails[shape.shapeName] ?? [],
                  isExpanded: _shotShapeExpanded[shape.shapeName] ?? false,
                  onToggleExpand: () {
                    setState(() {
                      _shotShapeExpanded[shape.shapeName] =
                          !(_shotShapeExpanded[shape.shapeName] ?? false);
                    });
                  },
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No shot shape data available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isOverallExpanded = !_isOverallExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.overallStats.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.overallStats.averageDistance != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.overallStats.distanceDisplay,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  _isOverallExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
            const SizedBox(height: 20),
            MetricRow(
              label: 'Birdie Rate',
              percentage: widget.overallStats.birdieRate,
              count: widget.overallStats.birdieCount,
              total: widget.overallStats.totalHoles,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            MetricRow(
              label: 'C1 in Reg',
              percentage: widget.overallStats.c1InRegPct,
              count: widget.overallStats.c1Count,
              total: widget.overallStats.c1Total,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            MetricRow(
              label: 'C2 in Reg',
              percentage: widget.overallStats.c2InRegPct,
              count: widget.overallStats.c2Count,
              total: widget.overallStats.c2Total,
              color: const Color(0xFF8B5CF6),
            ),
            if (_isOverallExpanded) ...[
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
              ShotDetailsList(shotDetails: widget.overallShotDetails),
            ],
          ],
        ),
      ),
    );
  }



}
