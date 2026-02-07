import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/story/base_story_card.dart';
// import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Compact callout card component for Story V2
/// Displays a stat card with a "reason" text underneath explaining impact
class StoryCalloutCard extends StatelessWidget {
  const StoryCalloutCard({super.key, required this.statWidget});

  /// The stat visualization widget (from StatCardRegistry)
  final Widget statWidget;

  /// 1-2 sentences explaining the impact/cause-effect of this stat

  @override
  Widget build(BuildContext context) {
    return BaseStoryCard(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: statWidget,
    );
  }
}
