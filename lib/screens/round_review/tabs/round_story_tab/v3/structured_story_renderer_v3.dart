import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/stat_card_registry.dart';
import 'package:turbo_disc_golf/components/story/story_callout_card.dart';
import 'package:turbo_disc_golf/components/what_could_have_been_card.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/round_story_v2_content.dart';
import 'package:turbo_disc_golf/models/data/round_story_v3_content.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/components/practice_advice_list.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/story_navigation_helper.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/v3/story_section_tracker.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/string_helpers.dart';

class StructuredStoryRendererV3 extends StatefulWidget {
  const StructuredStoryRendererV3({
    super.key,
    required this.content,
    required this.round,
    this.tabController,
    this.onActiveSectionChanged,
    this.scrollController,
    this.isScorecardExpanded,
  });

  final RoundStoryV3Content content;
  final DGRound round;
  final TabController? tabController;
  final ValueNotifier<int?>? onActiveSectionChanged;
  final ScrollController? scrollController;
  final ValueNotifier<bool>? isScorecardExpanded;

  @override
  State<StructuredStoryRendererV3> createState() =>
      _StructuredStoryRendererV3State();
}

class _StructuredStoryRendererV3State extends State<StructuredStoryRendererV3> {
  ScrollController? _scrollController;
  bool _ownsScrollController = false;
  late StorySectionTracker _sectionTracker;
  late List<GlobalKey> _sectionKeys;
  late RoundAnalysis _analysis;

  @override
  void initState() {
    super.initState();

    // Use provided scroll controller or create our own
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController;
      _ownsScrollController = false;
    } else {
      _scrollController = ScrollController();
      _ownsScrollController = true;
    }

    _analysis = RoundAnalysisGenerator.generateAnalysis(widget.round);

    // Create GlobalKeys for each section
    _sectionKeys = List.generate(
      widget.content.sections.length,
      (index) => GlobalKey(),
    );

    // Initialize section tracker
    _sectionTracker = StorySectionTracker(
      scrollController: _scrollController!,
      sectionKeys: _sectionKeys,
      activeSectionNotifier: widget.onActiveSectionChanged,
    );

    // Set initial active section after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sectionTracker.activeSectionIndex.value == null) {
        _sectionTracker.activeSectionIndex.value =
            0; // Start with first section highlighted
      }
    });

    // Validate hole ranges (log warnings only)
    _validateHoleRanges();
  }

  void _validateHoleRanges() {
    final int totalHoles = widget.round.holes.length;

    if (widget.content.sections.isEmpty) {
      debugPrint('⚠️ V3 story has no sections');
      return;
    }

    // Check first section starts near hole 1
    if (widget.content.sections.first.holeRange.startHole > 2) {
      debugPrint(
        '⚠️ First section starts at hole ${widget.content.sections.first.holeRange.startHole}, '
        'expected near hole 1',
      );
    }

    // Check last section ends near final hole
    if (widget.content.sections.last.holeRange.endHole < totalHoles - 1) {
      debugPrint(
        '⚠️ Last section ends at hole ${widget.content.sections.last.holeRange.endHole}, '
        'expected near hole $totalHoles',
      );
    }

    // Check for invalid ranges
    for (int i = 0; i < widget.content.sections.length; i++) {
      final StorySection section = widget.content.sections[i];
      final HoleRange range = section.holeRange;

      if (range.startHole > range.endHole) {
        debugPrint(
          '⚠️ Section $i has invalid range: '
          'startHole ${range.startHole} > endHole ${range.endHole}',
        );
      }

      if (range.startHole < 1 || range.endHole > totalHoles) {
        debugPrint(
          '⚠️ Section $i has out-of-bounds range: '
          '${range.displayString} (total holes: $totalHoles)',
        );
      }
    }
  }

  @override
  void dispose() {
    _sectionTracker.dispose();
    if (_ownsScrollController) {
      _scrollController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 16),
          _buildOverview(),
          const SizedBox(height: 12),
          ..._buildStorySections(),
          if (widget.content.skillsAssessment != null)
            _buildSkillsAssessment(context),
          _buildWhatCouldHaveBeen(context),
          if (widget.content.practiceAdvice.isNotEmpty)
            _buildPracticeAdvice(context),
          if (widget.content.strategyTips.isNotEmpty)
            _buildStrategyTips(context),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        ),
      ),
      child: Stack(
        children: [
          // Emoji background pattern - fills entire container
          Positioned.fill(child: _buildEmojiBackground()),
          // Title with padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: Text(
                widget.content.roundTitle.capitalizeFirst(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiBackground() {
    final Random random = Random(42); // Fixed seed for consistency
    const String bgEmoji = '\u{1F4D6}'; // Book emoji
    final List<Widget> emojis = [];

    // Sparse grid for header: 4 columns x 2 rows
    const int cols = 4;
    const int rows = 2;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Random offset within each cell (0.2 to 0.8)
        final double offsetX = 0.2 + random.nextDouble() * 0.6;
        final double offsetY = 0.2 + random.nextDouble() * 0.6;

        // Convert to alignment (-1 to 1)
        final double alignX = ((col + offsetX) / cols) * 2 - 1;
        final double alignY = ((row + offsetY) / rows) * 2 - 1;

        // Random rotation
        final double rotation = (random.nextDouble() - 0.5) * 1.2;

        // Visible opacity (0.05 to 0.15) - reduced by 10%
        final double opacity = 0.05 + random.nextDouble() * 0.10;

        // Larger size (20 to 28)
        final double size = 20 + random.nextDouble() * 8;

        emojis.add(
          Align(
            alignment: Alignment(alignX, alignY),
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(
                opacity: opacity,
                child: Text(bgEmoji, style: TextStyle(fontSize: size)),
              ),
            ),
          ),
        );
      }
    }

    return Stack(children: emojis);
  }

  Widget _buildOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        widget.content.overview,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Widget> _buildStorySections() {
    final List<Widget> widgets = [];

    for (int i = 0; i < widget.content.sections.length; i++) {
      final StorySection section = widget.content.sections[i];
      final int sectionIndex = i;

      widgets.add(
        ValueListenableBuilder<bool>(
          valueListenable: widget.isScorecardExpanded ?? ValueNotifier(true),
          builder: (context, isScorecardExpanded, child) {
            return ValueListenableBuilder<int?>(
              valueListenable: _sectionTracker.activeSectionIndex,
              builder: (context, activeIndex, child) {
                final bool isActive = isScorecardExpanded &&
                    locator.get<FeatureFlagService>().highlightActiveStorySection &&
                    activeIndex == sectionIndex;

                return AnimatedContainer(
                  key: _sectionKeys[i], // Attach GlobalKey for tracking
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF64B5F6).withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section text
                      Text(
                        section.text,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: Colors.black87,
                        ),
                      ),

                      // Callout cards
                      if (section.callouts.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...section.callouts.map(
                          (callout) => _buildCallout(context, callout),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      );

      // Spacing handled by AnimatedContainer padding
    }

    return widgets;
  }

  Widget _buildCallout(BuildContext context, StoryCallout callout) {
    final Widget? statWidget = _buildStatWidget(callout.cardId);

    if (statWidget == null) {
      debugPrint('⚠️ Unknown cardId: ${callout.cardId}');
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          StoryNavigationHelper.navigateToDetailScreen(
            context,
            callout.cardId,
            widget.round,
          );
        },
        child: StoryCalloutCard(statWidget: statWidget, reason: callout.reason),
      ),
    );
  }

  Widget? _buildStatWidget(String cardId) {
    try {
      return StatCardRegistry.buildCard(
        cardId,
        widget.round,
        _analysis,
        showIcon: false,
      );
    } catch (e) {
      debugPrint('Failed to build stat widget for cardId: $cardId - $e');
      return null;
    }
  }

  Widget _buildWhatCouldHaveBeen(BuildContext context) {
    final WhatCouldHaveBeenV2 data = widget.content.whatCouldHaveBeen;

    // Convert scenarios to the new format
    final List<WhatCouldHaveBeenScenario> scenarios = data.scenarios
        .map(
          (s) => WhatCouldHaveBeenScenario(
            fix: s.fix,
            resultScore: s.resultScore,
            strokesSaved: s.strokesSaved.toString(),
          ),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Divider
          Container(
            height: 1,
            color: SenseiColors.gray[200],
            margin: const EdgeInsets.symmetric(vertical: 24),
          ),
          WhatCouldHaveBeenCard(
            currentScore: data.currentScore,
            potentialScore: data.potentialScore,
            scenarios: scenarios,
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeAdvice(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(
            height: 1,
            color: SenseiColors.gray[200],
            margin: const EdgeInsets.symmetric(vertical: 24),
          ),

          // Section header
          Row(
            children: [
              const Icon(
                Icons.sports_handball,
                color: Color(0xFFFFA726),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Practice Focus',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFA726),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PracticeAdviceList(advice: widget.content.practiceAdvice),
        ],
      ),
    );
  }

  Widget _buildStrategyTips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(
            height: 1,
            color: SenseiColors.gray[200],
            margin: const EdgeInsets.symmetric(vertical: 24),
          ),

          // Section header
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF2196F3), size: 20),
              const SizedBox(width: 8),
              Text(
                'Strategy Tips',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PracticeAdviceList(advice: widget.content.strategyTips),
        ],
      ),
    );
  }

  Widget _buildSkillsAssessment(BuildContext context) {
    final assessment = widget.content.skillsAssessment!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(
            height: 1,
            color: SenseiColors.gray[200],
            margin: const EdgeInsets.symmetric(vertical: 24),
          ),

          // Section header
          Row(
            children: [
              const Icon(Icons.assessment, color: Color(0xFF6366F1), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Skills Assessment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Strengths
          if (assessment.strengths.isNotEmpty) ...[
            _buildSkillsSubheading('Strengths', const Color(0xFF4CAF50)),
            const SizedBox(height: 8),
            ...assessment.strengths.map(
              (skill) => _buildSkillHighlight(skill, isStrength: true),
            ),
            const SizedBox(height: 16),
          ],

          // Weaknesses
          if (assessment.weaknesses.isNotEmpty) ...[
            _buildSkillsSubheading(
              'Areas for Improvement',
              const Color(0xFFFF9800),
            ),
            const SizedBox(height: 8),
            ...assessment.weaknesses.map(
              (skill) => _buildSkillHighlight(skill, isStrength: false),
            ),
            const SizedBox(height: 16),
          ],

          // Key Insight
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFF6366F1), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assessment.keyInsight,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
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

  Widget _buildSkillsSubheading(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillHighlight(
    SkillHighlight skill, {
    required bool isStrength,
  }) {
    final Color color =
        isStrength ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);

    // Strip "skill: " prefix if present (from legacy data)
    final String skillName = skill.skill.startsWith('skill: ')
        ? skill.skill.substring(7)
        : skill.skill;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skillName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  skill.statHighlight,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  skill.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: SenseiColors.gray[700],
                    height: 1.5,
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
