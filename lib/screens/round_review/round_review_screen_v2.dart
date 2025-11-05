import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/round_story_view.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/overview_tab.dart';

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

class _RoundReviewScreenV2State extends State<RoundReviewScreenV2> {
  late DGRound _round;

  @override
  void initState() {
    super.initState();
    _round = widget.round;

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
          ],
        ),
        body: OverviewTab(
          round: _round,
          isReviewV2Screen: true,
        ),
      ),
    );
  }
}
