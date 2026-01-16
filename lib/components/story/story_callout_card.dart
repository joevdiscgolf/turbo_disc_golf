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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat widget (slightly smaller than normal)
          Padding(
            padding: const EdgeInsets.all(10),
            child: statWidget,
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: TurbColors.gray[200],
          ),

          // Reason text (interpretation/impact)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon indicator
                Container(
                  margin: const EdgeInsets.only(top: 2, right: 8),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.insights,
                    size: 12,
                    color: Color(0xFF6366F1),
                  ),
                ),

                // Reason text
                Expanded(
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: TurbColors.gray[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
