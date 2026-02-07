import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/app_phase_data.dart';
import 'package:turbo_disc_golf/screens/onboarding/feature_walkthrough/scenes/scene_complete.dart';
import 'package:turbo_disc_golf/screens/onboarding/feature_walkthrough/scenes/scene_form_analysis.dart';
import 'package:turbo_disc_golf/screens/onboarding/feature_walkthrough/scenes/scene_insights.dart';
import 'package:turbo_disc_golf/screens/onboarding/feature_walkthrough/scenes/scene_processing.dart';
import 'package:turbo_disc_golf/screens/onboarding/feature_walkthrough/scenes/scene_recording.dart';
import 'package:turbo_disc_golf/services/app_phase/app_phase_controller.dart';
import 'package:turbo_disc_golf/components/backgrounds/animated_particle_background.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

class FeatureWalkthroughScreen extends StatefulWidget {
  static const String routeName = '/feature-walkthrough';
  static const String screenName = 'Feature Walkthrough';

  const FeatureWalkthroughScreen({super.key});

  @override
  State<FeatureWalkthroughScreen> createState() =>
      _FeatureWalkthroughScreenState();
}

class _FeatureWalkthroughScreenState extends State<FeatureWalkthroughScreen> {
  final PageController _pageController = PageController();
  late final LoggingServiceBase _logger;

  int _currentPage = 0;
  Timer? _autoAdvanceTimer;

  // Scene durations in milliseconds (null = no auto-advance)
  static const List<int?> _sceneDurations = [5500, 5000, 6500, 5000, null];

  static const List<String> _sceneNames = [
    'Recording',
    'Processing',
    'Insights',
    'Complete',
    'Form Analysis',
  ];

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': FeatureWalkthroughScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('FeatureWalkthroughScreen');

    _startAutoAdvanceTimer();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoAdvanceTimer() {
    _autoAdvanceTimer?.cancel();

    final int? duration = _sceneDurations[_currentPage];
    if (duration == null) return;

    _autoAdvanceTimer = Timer(Duration(milliseconds: duration), () {
      if (mounted && _currentPage < _sceneDurations.length - 1) {
        _goToPage(_currentPage + 1);
      }
    });
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int page) {
    _logger.track(
      'Walkthrough Page Changed',
      properties: {
        'page_index': page,
        'page_name': _sceneNames[page],
        'previous_page_index': _currentPage,
        'previous_page_name': _sceneNames[_currentPage],
      },
    );

    setState(() {
      _currentPage = page;
    });
    _startAutoAdvanceTimer();
  }

  void _onComplete() {
    _logger.track('Walkthrough Completed Button Tapped');

    HapticFeedback.mediumImpact();
    // User is already marked as onboarded in setupNewUser, just go to home
    locator.get<AppPhaseController>().setPhase(AppPhase.home);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
        child: Scaffold(
          body: Stack(
            children: [
              // Animated particle background
              const AnimatedParticleBackground(),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        physics: const ClampingScrollPhysics(),
                        clipBehavior: Clip.hardEdge,
                        children: [
                          SceneRecording(isActive: _currentPage == 0),
                          SceneProcessing(isActive: _currentPage == 1),
                          SceneInsights(isActive: _currentPage == 2),
                          SceneComplete(isActive: _currentPage == 3),
                          SceneFormAnalysis(
                            isActive: _currentPage == 4,
                            onComplete: _onComplete,
                          ),
                        ],
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: _buildProgressBar(),
    );
  }

  Widget _buildProgressBar() {
    final double progress = (_currentPage + 1) / _sceneDurations.length;

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: SenseiColors.gray[300],
        borderRadius: BorderRadius.circular(2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          widthFactor: progress,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44CF9C)],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _sceneDurations.length,
          (index) => _buildPageIndicator(index),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final bool isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF4ECDC4)
            : SenseiColors.gray[300],
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
