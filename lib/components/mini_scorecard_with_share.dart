import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// The scorecard can be collapsed/expanded via a toggle arrow.
class MiniScorecardWithShare extends StatefulWidget {
  const MiniScorecardWithShare({
    super.key,
    required this.holes,
    required this.highlightedHoleRangeNotifier,
    required this.story,
    required this.showShareButton,
    required this.onSharePressed,
    required this.isExpandedNotifier,
  });

  final List<DGHole> holes;
  final ValueNotifier<int?> highlightedHoleRangeNotifier;
  final AIContent story;
  final bool showShareButton;
  final VoidCallback onSharePressed;
  final ValueNotifier<bool> isExpandedNotifier;

  @override
  State<MiniScorecardWithShare> createState() => _MiniScorecardWithShareState();
}

class _MiniScorecardWithShareState extends State<MiniScorecardWithShare>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    // Start expanded
    _animationController.value = widget.isExpandedNotifier.value ? 1.0 : 0.0;

    // Listen to external changes to expanded state
    widget.isExpandedNotifier.addListener(_onExpandedChanged);
  }

  @override
  void dispose() {
    widget.isExpandedNotifier.removeListener(_onExpandedChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onExpandedChanged() {
    if (widget.isExpandedNotifier.value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    final bool newValue = !widget.isExpandedNotifier.value;
    widget.isExpandedNotifier.value = newValue;

    if (!newValue) {
      // Clear highlighting when collapsing
      widget.highlightedHoleRangeNotifier.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isExpandedNotifier,
      builder: (context, isExpanded, child) {
        return ValueListenableBuilder<int?>(
          valueListenable: widget.highlightedHoleRangeNotifier,
          builder: (context, activeSectionIndex, child) {
            // Only show highlighting when expanded
            final HoleRange? activeRange =
                isExpanded &&
                    activeSectionIndex != null &&
                    widget.story.structuredContentV3 != null
                ? widget
                      .story
                      .structuredContentV3!
                      .sections[activeSectionIndex]
                      .holeRange
                : null;

            // Minimal top padding - the toggle arrow has its own padding
            const double topPadding = 0.0;

            return Container(
              padding: EdgeInsets.fromLTRB(
                12,
                topPadding,
                12,
                autoBottomPadding(context),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: SenseiColors.gray.shade100),
                ),
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
                  _buildToggleArrow(isExpanded),
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _toggleExpanded,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            color: Colors.transparent,
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InteractiveMiniScorecard(
                              holes: widget.holes,
                              highlightedHoleRange: activeRange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showShareButton) ...[_buildShareButton()],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToggleArrow(bool isExpanded) {
    return GestureDetector(
      onTap: _toggleExpanded,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: AnimatedRotation(
            turns: isExpanded ? 0.0 : 0.5,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 24,
              color: SenseiColors.gray[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return PrimaryButton(
      width: double.infinity,
      height: 48,
      label: 'Share story',
      icon: Icons.ios_share,
      gradientBackground: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
      onPressed: widget.onSharePressed,
    );
  }
}
