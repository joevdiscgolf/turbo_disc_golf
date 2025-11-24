import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/round_story_view.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_overview_body.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab.dart';
import 'package:turbo_disc_golf/services/animation_state_service.dart';

class RoundReviewScreenV2 extends StatefulWidget {
  final DGRound round;
  final bool showStoryOnLoad;

  const RoundReviewScreenV2({
    super.key,
    required this.round,
    this.showStoryOnLoad = false,
  });

  @override
  State<RoundReviewScreenV2> createState() => _RoundReviewScreenV2State();
}

class _RoundReviewScreenV2State extends State<RoundReviewScreenV2>
    with SingleTickerProviderStateMixin {
  late DGRound _round;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _round = widget.round;
    _tabController = TabController(length: 2, vsync: this);

    // Show story view if requested - navigate to Story tab instead
    if (widget.showStoryOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(1); // Navigate to Story tab
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Clear animation state so animations play fresh when re-entering this screen
    AnimationStateService.instance.clearRound(_round.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEEE8F5), // Light gray with faint purple tint
            Color(0xFFECECEE), // Light gray
            Color(0xFFE8F4E8), // Light gray with faint green tint
            Color(0xFFEAE8F0), // Light gray with subtle purple
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(_round.courseName),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_stories),
              tooltip: 'View Fullscreen Story',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RoundStoryView(round: _round),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.black,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            labelPadding: const EdgeInsets.symmetric(vertical: 8),
            tabs: const [
              Tab(text: 'Stats'),
              Tab(text: 'Story'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            RoundOverviewBody(
              round: _round,
              isReviewV2Screen: true,
            ),
            RoundStoryTab(round: _round),
          ],
        ),
      ),
    );
  }
}
