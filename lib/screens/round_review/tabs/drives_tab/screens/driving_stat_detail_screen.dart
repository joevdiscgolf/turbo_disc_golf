import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/indicators/circular_stat_indicator.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

enum HoleResultStatus { success, failure, noData }

class HoleResult {
  final int holeNumber;
  final HoleResultStatus status;

  const HoleResult({required this.holeNumber, required this.status});
}

class DrivingStatDetailScreen extends StatelessWidget {
  static const String screenName = 'Driving Stat Detail';
  static const String routeName = '/driving-stat-detail';

  final String statName;
  final double percentage;
  final Color color;
  final int successCount;
  final int totalHoles;
  final List<HoleResult> holeResults;

  const DrivingStatDetailScreen({
    super.key,
    required this.statName,
    required this.percentage,
    required this.color,
    required this.successCount,
    required this.totalHoles,
    required this.holeResults,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator.get<LoggingService>().track('Screen Impression', properties: {
        'screen_name': DrivingStatDetailScreen.screenName,
        'screen_class': 'DrivingStatDetailScreen',
        'stat_name': statName,
      });
    });
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: GenericAppBar(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        title: '$statName details',
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularStatIndicator(
                        label: 'C1 reg',
                        percentage: percentage,
                        color: color,
                        size: 200,
                        internalLabel: '$successCount / $totalHoles',
                        internalLabelFontSize: 12,
                      ),
                      const SizedBox(width: 16),
                      _DotsGrid(holeResults: holeResults),
                    ],
                  ),
                  // const SizedBox(height: 16),
                  // Text(
                  //   '$successCount of $totalHoles holes hit $statName',
                  //   style: Theme.of(context).textTheme.bodyLarge,
                  // ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final HoleResult result = holeResults[index];
                return _HoleResultTile(result: result);
              }, childCount: holeResults.length),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsGrid extends StatelessWidget {
  final List<HoleResult> holeResults;

  const _DotsGrid({required this.holeResults});

  @override
  Widget build(BuildContext context) {
    const int maxDotsPerRow = 6;
    const double dotSize = 12;
    const double spacing = 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate((holeResults.length / maxDotsPerRow).ceil(), (
        rowIndex,
      ) {
        final int startIndex = rowIndex * maxDotsPerRow;
        final int endIndex = (startIndex + maxDotsPerRow > holeResults.length)
            ? holeResults.length
            : startIndex + maxDotsPerRow;

        return Padding(
          padding: EdgeInsets.only(
            bottom: rowIndex < (holeResults.length / maxDotsPerRow).ceil() - 1
                ? spacing
                : 0,
          ),
          child: Row(
            children: List.generate(endIndex - startIndex, (colIndex) {
              final HoleResult result = holeResults[startIndex + colIndex];
              Color dotColor;
              if (result.status == HoleResultStatus.success) {
                dotColor = const Color(0xFF4CAF50);
              } else if (result.status == HoleResultStatus.failure) {
                dotColor = const Color(0xFFFF7A7A);
              } else {
                dotColor = Colors.grey;
              }

              return Container(
                width: dotSize,
                height: dotSize,
                margin: EdgeInsets.only(
                  right: colIndex < endIndex - startIndex - 1 ? spacing : 0,
                ),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _HoleResultTile extends StatelessWidget {
  final HoleResult result;

  const _HoleResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (result.status) {
      case HoleResultStatus.success:
        icon = Icons.check_circle;
        iconColor = const Color(0xFF4CAF50);
        break;
      case HoleResultStatus.failure:
        icon = Icons.cancel;
        iconColor = const Color(0xFFE57373);
        break;
      case HoleResultStatus.noData:
        icon = Icons.chevron_right;
        iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          'Hole ${result.holeNumber}',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        trailing: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}
