import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/form_analysis_background.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class StoryEmptyState extends StatefulWidget {
  final VoidCallback onGenerateStory;

  const StoryEmptyState({super.key, required this.onGenerateStory});

  @override
  State<StoryEmptyState> createState() => _StoryEmptyStateState();
}

class _StoryEmptyStateState extends State<StoryEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headerOpacity;
  late Animation<double> _headerScale;
  late Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Header: 0-500ms
    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.208, curve: Curves.easeOut),
      ),
    );
    _headerScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.208, curve: Curves.easeOut),
      ),
    );

    // Button: 1800-2100ms
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 0.875, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const FormAnalysisBackground(),
        Padding(
          padding: EdgeInsets.only(
            top: 8,
            left: 16,
            right: 16,
            bottom: autoBottomPadding(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              Expanded(child: _buildInfoCards()),
              const SizedBox(height: 16),
              _buildButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _headerOpacity.value,
          child: Transform.scale(scale: _headerScale.value, child: child),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
              height: 64,
              width: 64,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Your round has a story',
            style: GoogleFonts.exo2(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.5,
              color: SenseiColors.gray[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        Expanded(
          child: _StoryInfoCard(
            icon: '🎯',
            title: 'Uncover key moments',
            description:
                'That clutch birdie on hole 14, or the comeback after a tough start — see what mattered most.',
            slideDirection: _SlideDirection.right,
            animationController: _controller,
            slideInterval: const Interval(
              0.25,
              0.417,
              curve: Curves.easeOutBack,
            ),
          ),
        ),
        Expanded(
          child: _StoryInfoCard(
            icon: '📊',
            title: 'Spot your patterns',
            description:
                'Which disc is your go-to scorer? How do you perform under pressure? The data reveals the truth.',
            slideDirection: _SlideDirection.left,
            animationController: _controller,
            slideInterval: const Interval(
              0.333,
              0.5,
              curve: Curves.easeOutBack,
            ),
          ),
        ),
        Expanded(
          child: _StoryInfoCard(
            icon: '💡',
            title: 'Get personalized tips',
            description:
                'Receive AI-powered insights tailored to your playing style and areas where you can improve.',
            slideDirection: _SlideDirection.right,
            animationController: _controller,
            slideInterval: const Interval(
              0.417,
              0.583,
              curve: Curves.easeOutBack,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton() {
    return AnimatedBuilder(
      animation: _buttonOpacity,
      builder: (context, child) {
        return Opacity(opacity: _buttonOpacity.value, child: child);
      },
      child: PrimaryButton(
        width: double.infinity,
        height: 56,
        label: 'Tell my story',
        gradientBackground: const [Color(0xFF4ECDC4), Color(0xFF44CF9C)],
        fontSize: 18,
        fontWeight: FontWeight.bold,
        onPressed: widget.onGenerateStory,
      ),
    );
  }
}

enum _SlideDirection { left, right }

class _StoryInfoCard extends StatefulWidget {
  final String icon;
  final String title;
  final String description;
  final _SlideDirection slideDirection;
  final AnimationController animationController;
  final Interval slideInterval;

  const _StoryInfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.slideDirection,
    required this.animationController,
    required this.slideInterval,
  });

  @override
  State<_StoryInfoCard> createState() => _StoryInfoCardState();
}

class _StoryInfoCardState extends State<_StoryInfoCard> {
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    final double startX = widget.slideDirection == _SlideDirection.left
        ? -1.0
        : 1.0;

    _slideAnimation = Tween<double>(begin: startX, end: 0.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: widget.slideInterval,
      ),
    );

    // Fade in during the first half of the slide animation
    final double opacityEnd =
        widget.slideInterval.begin +
        (widget.slideInterval.end - widget.slideInterval.begin) * 0.5;
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(
          widget.slideInterval.begin,
          opacityEnd,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxCardWidth = MediaQuery.of(context).size.width - 32;

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _slideAnimation.value * MediaQuery.of(context).size.width * 0.5,
            0,
          ),
          child: Opacity(opacity: _opacityAnimation.value, child: child),
        );
      },
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: maxCardWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: const Color(0xFF4ECDC4).withValues(alpha: 0.04),
                          blurRadius: 40,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(widget.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Text(
                              widget.title,
                              style: TextStyle(
                                color: SenseiColors.darkGray,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: SenseiColors.gray[600],
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
