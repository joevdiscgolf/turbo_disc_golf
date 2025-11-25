import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/course_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/scores_tab/scores_tab.dart';

/// Detail screen that shows course and scores information
class ScoreDetailScreen extends StatelessWidget {
  final DGRound round;

  const ScoreDetailScreen({super.key, required this.round});

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
          title: const Text('Score Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: Colors.transparent,
                child: TabBar(
                  labelColor: Colors.black,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                  indicatorColor: Colors.black,
                  tabs: const [
                    Tab(text: 'Course'),
                    Tab(text: 'Scores'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    CourseTab(round: round),
                    ScoresTab(round: round),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
