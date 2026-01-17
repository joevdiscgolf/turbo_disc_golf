import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/form_analysis_background.dart';

class StoryEmptyState extends StatefulWidget {
  final VoidCallback onGenerateStory;

  const StoryEmptyState({
    super.key,
    required this.onGenerateStory,
  });

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
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildInfoCards(),
                const SizedBox(height: 32),
                _buildButton(),
              ],
            ),
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
          child: Transform.scale(
            scale: _headerScale.value,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Round Has a Story',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        _StoryInfoCard(
          icon: '🎯',
          title: 'Uncover Key Moments',
          description:
              'That clutch birdie on hole 14, or the comeback after a tough start — see what mattered most.',
          slideDirection: _SlideDirection.left,
          animationController: _controller,
          slideInterval: const Interval(0.25, 0.458, curve: Curves.easeOutCubic),
          floatPhaseOffset: 0.0,
        ),
        _StoryInfoCard(
          icon: '📊',
          title: 'Spot Your Patterns',
          description:
              'Which disc is your go-to scorer? How do you perform under pressure? The data reveals the truth.',
          slideDirection: _SlideDirection.right,
          animationController: _controller,
          slideInterval: const Interval(0.417, 0.625, curve: Curves.easeOutCubic),
          floatPhaseOffset: 0.33,
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
        gradientBackground: const [
          Color(0xFF4ECDC4),
          Color(0xFF44CF9C),
        ],
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
  final double floatPhaseOffset;

  const _StoryInfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.slideDirection,
    required this.animationController,
    required this.slideInterval,
    required this.floatPhaseOffset,
  });

  @override
  State<_StoryInfoCard> createState() => _StoryInfoCardState();
}

class _StoryInfoCardState extends State<_StoryInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    final double startX =
        widget.slideDirection == _SlideDirection.left ? -1.0 : 1.0;

    _slideAnimation = Tween<double>(begin: startX, end: 0.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: widget.slideInterval,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: widget.slideInterval,
      ),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animationController, _floatController]),
      builder: (context, child) {
        final double floatOffset =
            math.sin((_floatController.value + widget.floatPhaseOffset) * math.pi * 2) * 4;

        final bool slideComplete = _slideAnimation.value == 0.0;
        final double effectiveFloatOffset = slideComplete ? floatOffset : 0.0;

        return Transform.translate(
          offset: Offset(
            _slideAnimation.value * MediaQuery.of(context).size.width * 0.5,
            effectiveFloatOffset,
          ),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
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
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
