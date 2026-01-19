import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/screens/auth/components/c1x_preview_card.dart';
import 'package:turbo_disc_golf/screens/auth/components/form_analysis_preview_card.dart';
import 'package:turbo_disc_golf/screens/auth/components/judge_preview_card.dart';
import 'package:turbo_disc_golf/screens/auth/components/landing_background.dart';
import 'package:turbo_disc_golf/screens/auth/components/landing_preview_card.dart';
import 'package:turbo_disc_golf/screens/auth/components/record_preview_card.dart';
import 'package:turbo_disc_golf/screens/auth/components/shot_preview_card.dart';
import 'package:turbo_disc_golf/screens/auth/components/story_preview_card.dart';
import 'package:turbo_disc_golf/screens/auth/login_screen.dart';
import 'package:turbo_disc_golf/screens/auth/sign_up_screen.dart';

class LandingScreen extends StatefulWidget {
  static const String routeName = '/landing';
  static const String screenName = 'Landing';

  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _taglineOpacity;
  late Animation<double> _buttonsOpacity;
  late PageController _pageController;
  late Timer _autoScrollTimer;
  late final LoggingServiceBase _logger;
  int _currentPage = 0;
  static const int _autoScrollDuration = 4000; // 4 seconds per page

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': LandingScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('LandingScreen');

    // Set status bar to light content for dark background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Logo: 0-400ms
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.133, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.133, curve: Curves.easeOut),
      ),
    );

    // Tagline: 400-700ms
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.133, 0.233, curve: Curves.easeOut),
      ),
    );

    // Buttons: 2400-2700ms
    _buttonsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.8, 0.9, curve: Curves.easeOut),
      ),
    );

    _mainController.forward();

    // Initialize PageController
    _pageController = PageController();

    // Start auto-scroll after initial animations complete
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _pageController.dispose();
    _mainController.dispose();
    // Reset status bar style when leaving
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const LandingBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  Expanded(child: _buildCards()),
                  const SizedBox(height: 16),
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(scale: _logoScale.value, child: child),
        );
      },
      child: Column(
        children: [
          // Logo with glow effect
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Image.asset(
              'assets/icon/app_icon_clear_bg.png',
              height: 80,
              width: 80,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ScoreSensei',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _taglineOpacity,
            builder: (context, child) {
              return Opacity(opacity: _taglineOpacity.value, child: child);
            },
            child: Text(
              'See the story behind every throw',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCards() {
    // Define pages - each page has 2 cards
    final List<List<Map<String, dynamic>>> pages = [
      // Page 1: Recording + Putting
      [
        {
          'card': const RecordPreviewCard(),
          'color': RecordPreviewCard.accentColor,
          'direction': SlideDirection.left,
          'floatOffset': 0.0,
        },
        {
          'card': const C1xPreviewCard(),
          'color': C1xPreviewCard.accentColor,
          'direction': SlideDirection.right,
          'floatOffset': 0.33,
        },
      ],
      // Page 2: Story + Judge
      [
        {
          'card': const StoryPreviewCard(),
          'color': StoryPreviewCard.accentColor,
          'direction': SlideDirection.left,
          'floatOffset': 0.0,
        },
        {
          'card': const JudgePreviewCard(),
          'color': JudgePreviewCard.accentColor,
          'direction': SlideDirection.right,
          'floatOffset': 0.33,
        },
      ],
      // Page 3: Form Analysis + Shot Analysis
      [
        {
          'card': const FormAnalysisPreviewCard(),
          'color': FormAnalysisPreviewCard.accentColor,
          'direction': SlideDirection.left,
          'floatOffset': 0.0,
        },
        {
          'card': const ShotPreviewCard(),
          'color': ShotPreviewCard.accentColor,
          'direction': SlideDirection.right,
          'floatOffset': 0.33,
        },
      ],
    ];

    return Column(
      children: [
        // PageView expands to fill available space
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: pages.length,
            itemBuilder: (context, pageIndex) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Each card has vertical margin (4 top + 4 bottom = 8px per card)
                  // For 2 cards: 16px margins + 12px safety buffer = 28px total
                  final double cardHeight = (constraints.maxHeight - 28) / 2;

                  return ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: pages[pageIndex].map<Widget>((cardData) {
                      return SizedBox(
                        height: cardHeight,
                        child: LandingPreviewCard(
                          accentColor: cardData['color'],
                          slideDirection: cardData['direction'],
                          animationController: _mainController,
                          slideInterval: const Interval(
                            0.267,
                            0.433,
                            curve: Curves.easeOutCubic,
                          ),
                          floatPhaseOffset: cardData['floatOffset'],
                          child: cardData['card'],
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Page indicator
        SmoothPageIndicator(
          controller: _pageController,
          count: pages.length,
          effect: WormEffect(
            dotColor: Colors.white.withValues(alpha: 0.3),
            activeDotColor: const Color(0xFF4ECDC4),
            dotHeight: 8,
            dotWidth: 8,
            spacing: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return AnimatedBuilder(
      animation: _buttonsOpacity,
      builder: (context, child) {
        return Opacity(opacity: _buttonsOpacity.value, child: child);
      },
      child: Column(
        children: [
          PrimaryButton(
            width: double.infinity,
            height: 56,
            label: 'Get Started',
            labelColor: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
            gradientBackground: const [Color(0xFF4ECDC4), Color(0xFF44CF9C)],
            onPressed: _navigateToSignUp,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _navigateToLogin,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Have an account? ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSignUp() {
    HapticFeedback.mediumImpact();
    _logger.track('Get Started Button Tapped');
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  void _navigateToLogin() {
    HapticFeedback.lightImpact();
    _logger.track('Sign In Link Tapped');
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: _autoScrollDuration),
      (timer) {
        if (_pageController.hasClients && mounted) {
          final int nextPage = (_currentPage + 1) % 3; // 3 total pages
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      },
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);

    // Reset auto-scroll timer on manual swipe
    _autoScrollTimer.cancel();
    _startAutoScroll();
  }
}
