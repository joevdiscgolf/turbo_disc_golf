import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/screens/auth/components/c1x_preview_card.dart';
import 'package:turbo_disc_golf/screens/auth/components/landing_background.dart';
import 'package:turbo_disc_golf/screens/auth/components/landing_preview_card.dart';
import 'package:turbo_disc_golf/screens/auth/components/shot_preview_card.dart';
import 'package:turbo_disc_golf/screens/auth/components/story_preview_card.dart';
import 'package:turbo_disc_golf/screens/auth/login_screen.dart';
import 'package:turbo_disc_golf/screens/auth/sign_up_screen.dart';

class LandingScreen extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
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
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 32),
                Expanded(child: _buildCards()),
                _buildButtons(),
                const SizedBox(height: 24),
              ],
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
          child: Transform.scale(
            scale: _logoScale.value,
            child: child,
          ),
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
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Card 1: C1X Putting - slides from left (800-1300ms)
          LandingPreviewCard(
            accentColor: C1xPreviewCard.accentColor,
            slideDirection: SlideDirection.left,
            animationController: _mainController,
            slideInterval: const Interval(0.267, 0.433, curve: Curves.easeOutCubic),
            floatPhaseOffset: 0.0,
            child: const C1xPreviewCard(),
          ),

          // Card 2: Story - slides from right (1200-1700ms)
          LandingPreviewCard(
            accentColor: StoryPreviewCard.accentColor,
            slideDirection: SlideDirection.right,
            animationController: _mainController,
            slideInterval: const Interval(0.4, 0.567, curve: Curves.easeOutCubic),
            floatPhaseOffset: 0.33,
            child: const StoryPreviewCard(),
          ),

          // Card 3: Shot Analysis - slides from left (1600-2100ms)
          LandingPreviewCard(
            accentColor: ShotPreviewCard.accentColor,
            slideDirection: SlideDirection.left,
            animationController: _mainController,
            slideInterval: const Interval(0.533, 0.7, curve: Curves.easeOutCubic),
            floatPhaseOffset: 0.66,
            child: const ShotPreviewCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return AnimatedBuilder(
      animation: _buttonsOpacity,
      builder: (context, child) {
        return Opacity(opacity: _buttonsOpacity.value, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      'Already a member? ',
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
      ),
    );
  }

  void _navigateToSignUp() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  void _navigateToLogin() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}
