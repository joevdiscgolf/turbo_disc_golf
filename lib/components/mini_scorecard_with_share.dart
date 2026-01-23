import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/interactive_mini_scorecard.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_story_v3_content.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Wraps InteractiveMiniScorecard with an optional share button below.
///
/// Used in V3 story display to show the mini scorecard with hole scores
/// and an optional share button that opens the share preview.
class MiniScorecardWithShare extends StatelessWidget {
  const MiniScorecardWithShare({
    super.key,
    required this.holes,
    required this.highlightedHoleRangeNotifier,
    required this.story,
    required this.showShareButton,
    required this.onSharePressed,
  });

  final List<DGHole> holes;
  final ValueNotifier<int?> highlightedHoleRangeNotifier;
  final AIContent story;
  final bool showShareButton;
  final VoidCallback onSharePressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: highlightedHoleRangeNotifier,
      builder: (context, activeSectionIndex, child) {
        final HoleRange? activeRange =
            activeSectionIndex != null && story.structuredContentV3 != null
            ? story.structuredContentV3!.sections[activeSectionIndex].holeRange
            : null;

        return Container(
          padding: EdgeInsets.fromLTRB(12, 12, 12, autoBottomPadding(context)),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: SenseiColors.gray.shade100)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InteractiveMiniScorecard(
                holes: holes,
                highlightedHoleRange: activeRange,
              ),
              if (showShareButton) ...[
                const SizedBox(height: 12),
                _buildShareButton(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareButton() {
    return PrimaryButton(
      width: double.infinity,
      height: 48,
      label: 'Share story',
      icon: Icons.ios_share,
      gradientBackground: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      onPressed: onSharePressed,
    );
  }
}
