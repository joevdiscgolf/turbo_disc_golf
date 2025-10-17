import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/round_story_view.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/coach_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/discs_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/mistakes_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/psych_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/putting_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/roast_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/summary_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/throws_tab.dart';

class RoundReviewScreen extends StatefulWidget {
  final DGRound round;
  final bool showStoryOnLoad;

  const RoundReviewScreen({
    super.key,
    required this.round,
    this.showStoryOnLoad = false,
  });

  @override
  State<RoundReviewScreen> createState() => _RoundReviewScreenState();
}

class _RoundReviewScreenState extends State<RoundReviewScreen>
    with SingleTickerProviderStateMixin {
  late DGRound _round;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _round = widget.round;
    _tabController = TabController(length: 10, vsync: this);

    // Show story view if requested
    if (widget.showStoryOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RoundStoryView(round: _round),
              fullscreenDialog: true,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Old methods (kept for reference):
  // Color _getScoreColor(int score) { ... }
  // IconData _getThrowTypeIcon(ThrowPurpose? type) { ... }
  // void _showAddThrowDialog(BuildContext context, DGHole hole) { ... }
  // Widget _buildThrowsTab() { ... }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_round.courseName),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories),
            tooltip: 'View as Story',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RoundStoryView(round: _round),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // todo: Implement save functionality
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Round saved!')));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          labelColor: Theme.of(context).colorScheme.secondary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.6),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Throws'),
            Tab(text: 'Course'),
            Tab(text: 'Drives'),
            Tab(text: 'Putting'),
            Tab(text: 'Discs'),
            Tab(text: 'Mistakes'),
            Tab(text: 'Psych'),
            Tab(text: 'Summary'),
            Tab(text: 'Coach'),
            Tab(text: 'Roast'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ThrowsTab(round: _round),
          CourseTab(round: _round),
          DrivesTab(round: _round),
          PuttingTab(round: _round),
          DiscsTab(round: _round),
          MistakesTab(round: _round),
          PsychTab(round: _round),
          SummaryTab(round: _round),
          CoachTab(round: _round),
          RoastTab(round: _round),
        ],
      ),
    );
  }
}
