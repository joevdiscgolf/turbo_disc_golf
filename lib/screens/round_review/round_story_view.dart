import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/coach_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/discs_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/mistakes_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/psych_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/putting_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/roast_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/summary_tab.dart';

class RoundStoryView extends StatefulWidget {
  final DGRound round;

  const RoundStoryView({super.key, required this.round});

  @override
  State<RoundStoryView> createState() => _RoundStoryViewState();
}

class _RoundStoryViewState extends State<RoundStoryView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages =
      9; // Summary, Course, Drives, Putting, Discs, Mistakes, Psych, Coach, Roast

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _dismiss() {
    Navigator.of(context).pop();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _dismiss();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildProgressIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: List.generate(_totalPages, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 3,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Main content with gesture detection
            GestureDetector(
              onTapUp: (details) {
                final double screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < screenWidth / 3) {
                  _previousPage();
                } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
                  _nextPage();
                }
              },
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildStoryPage(SummaryTab(round: widget.round), 'Summary'),
                  _buildStoryPage(CourseTab(round: widget.round), 'Course'),
                  _buildStoryPage(DrivesTab(round: widget.round), 'Drives'),
                  _buildStoryPage(PuttingTab(round: widget.round), 'Putting'),
                  _buildStoryPage(DiscsTab(round: widget.round), 'Discs'),
                  _buildStoryPage(MistakesTab(round: widget.round), 'Mistakes'),
                  _buildStoryPage(PsychTab(round: widget.round), 'Psych'),
                  _buildStoryPage(CoachTab(round: widget.round), 'Coach'),
                  _buildStoryPage(RoastTab(round: widget.round), 'Roast'),
                ],
              ),
            ),

            // Top gradient overlay for better visibility of indicators and close button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.95),
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Progress indicators
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildProgressIndicators(),
            ),

            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: _dismiss,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryPage(Widget content, String title) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const SizedBox(height: 48), // Space for progress indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: content),
        ],
      ),
    );
  }
}
