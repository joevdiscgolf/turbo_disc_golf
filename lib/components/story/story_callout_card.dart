import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Compact callout card component for Story V2
/// Displays a stat card with a "reason" text underneath explaining impact
class StoryCalloutCard extends StatelessWidget {
  const StoryCalloutCard({
    super.key,
    required this.statWidget,
    required this.reason,
  });

  /// The stat visualization widget (from StatCardRegistry)
  final Widget statWidget;

  /// 1-2 sentences explaining the impact/cause-effect of this stat
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TurbColors.gray[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: TurbColors.gray[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statWidget,
            const SizedBox(height: 8),
            Text(
              reason,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: TurbColors.gray[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
