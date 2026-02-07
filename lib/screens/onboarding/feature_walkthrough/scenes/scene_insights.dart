import 'dart:async';

import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/screens/onboarding/feature_walkthrough/components/walkthrough_glass_card.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class SceneInsights extends StatefulWidget {
  const SceneInsights({super.key, required this.isActive});

  final bool isActive;

  @override
  State<SceneInsights> createState() => _SceneInsightsState();
}

class _SceneInsightsState extends State<SceneInsights>
    with TickerProviderStateMixin {
  late AnimationController _statsCardController;
  late AnimationController _storyCardController;
  late AnimationController _progressController;
  late AnimationController _floatController;

  late Animation<double> _statsSlide;
  late Animation<double> _statsOpacity;
  late Animation<double> _storySlide;
  late Animation<double> _storyOpacity;
  late Animation<double> _progressValue1;
  late Animation<double> _progressValue2;
  late Animation<double> _progressValue3;

  bool _hasStarted = false;
  bool _showStatsContent = false;
  bool _showStoryContent = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Stats card entrance
    _statsCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _statsSlide = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _statsCardController, curve: Curves.easeOutBack),
    );
    _statsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _statsCardController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Story card entrance
    _storyCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _storySlide = Tween<double>(begin: 100, end: 0).animate(
      CurvedAnimation(parent: _storyCardController, curve: Curves.easeOutBack),
    );
    _storyOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _storyCardController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Progress bar animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressValue1 = Tween<double>(begin: 0, end: 0.87).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _progressValue2 = Tween<double>(begin: 0, end: 0.78).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _progressValue3 = Tween<double>(begin: 0, end: 0.92).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Float animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didUpdateWidget(SceneInsights oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_hasStarted) {
      _startAnimationSequence();
    }
  }

  void _startAnimationSequence() {
    _hasStarted = true;

    // 0.3s - Stats card drops in
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _statsCardController.forward();
    });

    // 0.8s - Show stats content
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showStatsContent = true);
      }
    });

    // 1.0s - Progress bars animate
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _progressController.forward();
    });

    // 2.2s - Story card slides in
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) _storyCardController.forward();
    });

    // 2.5s - Show story content
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) {
        setState(() => _showStoryContent = true);
      }
    });

    // 3.8s - Start floating animation
    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) _floatController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _statsCardController.dispose();
    _storyCardController.dispose();
    _progressController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 1),
          _buildCards(),
          const Spacer(flex: 1),
          _buildCopyText(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCards() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final double floatOffset =
            _floatController.value * 6 - 3; // -3 to +3 pixels

        return Column(
          children: [
            // Stats Card
            Transform.translate(
              offset: Offset(0, floatOffset),
              child: _buildStatsCard(),
            ),
            const SizedBox(height: 16),
            // Story Card
            Transform.translate(
              offset: Offset(0, -floatOffset),
              child: _buildStoryCard(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCard() {
    return AnimatedBuilder(
      animation: _statsCardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _statsSlide.value),
          child: Opacity(
            opacity: _statsOpacity.value,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: WalkthroughGlassCard(
                accentColor: const Color(0xFF3498DB),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📊', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _showStatsContent ? 1.0 : 0.0,
                          child: Text(
                            'YOUR STATS',
                            style: TextStyle(
                              color: SenseiColors.gray[700],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 400),
                      crossFadeState: _showStatsContent
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildStatRow('Backhand Birdie %', _progressValue1, '87%'),
                          const SizedBox(height: 12),
                          _buildStatRow('FD3 Birdie %', _progressValue2, '78%'),
                          const SizedBox(height: 12),
                          _buildStatRow('C1 in Reg %', _progressValue3, '92%'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(
    String label,
    Animation<double> progress,
    String percentage,
  ) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        final int displayPercentage = (progress.value * 100).round();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: SenseiColors.gray[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: SenseiColors.gray[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress.value,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4ECDC4), Color(0xFF44CF9C)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF4ECDC4,
                                ).withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$displayPercentage%',
                  style: TextStyle(
                    color: SenseiColors.gray[700],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStoryCard() {
    return AnimatedBuilder(
      animation: _storyCardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_storySlide.value, 0),
          child: Opacity(
            opacity: _storyOpacity.value,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: WalkthroughGlassCard(
                accentColor: const Color(0xFF9B59B6),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📖', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _showStoryContent ? 1.0 : 0.0,
                          child: Text(
                            'YOUR STORY',
                            style: TextStyle(
                              color: SenseiColors.gray[700],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showStoryContent) ...[
                      const SizedBox(height: 12),
                      _AnimatedStoryText(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCopyText() {
    return AnimatedBuilder(
      animation: _statsCardController,
      builder: (context, child) {
        return Opacity(
          opacity: _statsOpacity.value,
          child: Column(
            children: [
              Text(
                'Instant insights.',
                style: TextStyle(
                  color: SenseiColors.gray[700],
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Stats and AI analysis appear\nlike magic.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SenseiColors.gray[600],
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedStoryText extends StatefulWidget {
  @override
  State<_AnimatedStoryText> createState() => _AnimatedStoryTextState();
}

class _AnimatedStoryTextState extends State<_AnimatedStoryText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const String _storyText =
      'Your C1 putting was on fire today - 85% conversion rate. Focus on forehand approaches...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final int charCount = (_controller.value * _storyText.length).floor();
        final String displayText = _storyText.substring(0, charCount);

        return Text(
          displayText,
          style: TextStyle(
            color: SenseiColors.gray[600],
            fontSize: 14,
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
        );
      },
    );
  }
}
