import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/screens/onboarding/feature_walkthrough/components/walkthrough_glass_card.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class SceneFormAnalysis extends StatefulWidget {
  const SceneFormAnalysis({
    super.key,
    required this.isActive,
    required this.onComplete,
  });

  final bool isActive;
  final VoidCallback onComplete;

  @override
  State<SceneFormAnalysis> createState() => _SceneFormAnalysisState();
}

class _SceneFormAnalysisState extends State<SceneFormAnalysis>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _frameController;
  late AnimationController _labelController;
  late AnimationController _insightController;
  late AnimationController _floatController;
  late AnimationController _buttonController;

  // Frame animations
  late Animation<Offset> _frame1Slide;
  late Animation<Offset> _frame2Slide;
  late Animation<Offset> _frame3Slide;
  late Animation<double> _frame1Opacity;
  late Animation<double> _frame2Opacity;
  late Animation<double> _frame3Opacity;

  // Label animations
  late Animation<double> _label1Opacity;
  late Animation<double> _label2Opacity;
  late Animation<double> _label3Opacity;

  // Insight animations
  late Animation<double> _insightScale;
  late Animation<double> _insightOpacity;
  late Animation<double> _textProgress;

  // Button animations
  late Animation<double> _buttonOpacity;
  late Animation<double> _buttonScale;

  // Flash state
  bool _showFlash1 = false;
  bool _showFlash2 = false;
  bool _showFlash3 = false;

  bool _hasStarted = false;

  static const String _insightText =
      'Get lower and stay on the balls of your feet to be more athletic, and drive more with the back leg';

  // Position data
  static const List<_PositionData> _positions = [
    _PositionData(
      label: 'Heisman',
      asset: 'assets/walkthrough/form_positions/heisman.png',
    ),
    _PositionData(
      label: 'Magic',
      asset: 'assets/walkthrough/form_positions/magic.png',
    ),
    _PositionData(
      label: 'Pro',
      asset: 'assets/walkthrough/form_positions/pro.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasStarted) {
          _startAnimationSequence();
        }
      });
    }
  }

  void _initAnimations() {
    // Frame slide-in animations (staggered)
    _frameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Frame 1: 0-600ms
    _frame1Slide = Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _frameController,
            curve: const Interval(0.0, 0.33, curve: Curves.easeOutBack),
          ),
        );
    _frame1Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _frameController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // Frame 2: 300-900ms
    _frame2Slide = Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _frameController,
            curve: const Interval(0.17, 0.5, curve: Curves.easeOutBack),
          ),
        );
    _frame2Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _frameController,
        curve: const Interval(0.17, 0.37, curve: Curves.easeOut),
      ),
    );

    // Frame 3: 600-1200ms
    _frame3Slide = Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _frameController,
            curve: const Interval(0.33, 0.67, curve: Curves.easeOutBack),
          ),
        );
    _frame3Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _frameController,
        curve: const Interval(0.33, 0.53, curve: Curves.easeOut),
      ),
    );

    // Label fade-up animations
    _labelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _label1Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _labelController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _label2Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _labelController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _label3Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _labelController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Insight bubble animation
    _insightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _insightScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _insightController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOutBack),
      ),
    );
    _insightOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _insightController,
        curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
      ),
    );
    _textProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _insightController,
        curve: const Interval(0.15, 1.0, curve: Curves.linear),
      ),
    );

    // Float animation (continuous)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Button animation
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );
    _buttonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(SceneFormAnalysis oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_hasStarted) {
      _startAnimationSequence();
    }
  }

  void _startAnimationSequence() {
    _hasStarted = true;

    // 0.3s - Frames start sliding in
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _frameController.forward();
    });

    // Flash effects as each frame "develops"
    // Flash 1 at 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showFlash1 = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showFlash1 = false);
        });
      }
    });

    // Flash 2 at 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showFlash2 = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showFlash2 = false);
        });
      }
    });

    // Flash 3 at 1100ms
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) {
        setState(() => _showFlash3 = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showFlash3 = false);
        });
      }
    });

    // 2.1s - Labels fade up
    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) _labelController.forward();
    });

    // 2.8s - Insight bubble appears
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) _insightController.forward();
    });

    // 3.5s - Start floating animation
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) _floatController.repeat(reverse: true);
    });

    // 4.0s - Button appears
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _frameController.dispose();
    _labelController.dispose();
    _insightController.dispose();
    _floatController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 1),
          _buildFilmstrip(),
          const SizedBox(height: 24),
          _buildInsightBubble(),
          const Spacer(flex: 1),
          _buildCopyText(),
          const SizedBox(height: 24),
          _buildButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFilmstrip() {
    return AnimatedBuilder(
      animation: Listenable.merge([_frameController, _floatController]),
      builder: (context, child) {
        final double floatOffset =
            math.sin(_floatController.value * math.pi) * 4;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFrame(0, _frame1Slide, _frame1Opacity, _showFlash1),
                _buildArrow(),
                _buildFrame(1, _frame2Slide, _frame2Opacity, _showFlash2),
                _buildArrow(),
                _buildFrame(2, _frame3Slide, _frame3Opacity, _showFlash3),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrame(
    int index,
    Animation<Offset> slideAnimation,
    Animation<double> opacityAnimation,
    bool showFlash,
  ) {
    final List<Animation<double>> labelOpacities = [
      _label1Opacity,
      _label2Opacity,
      _label3Opacity,
    ];

    return SlideTransition(
      position: slideAnimation,
      child: Opacity(
        opacity: opacityAnimation.value,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 95,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      _positions[index].asset,
                      width: 95,
                      height: 110,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderFigure(index);
                      },
                    ),
                  ),
                ),
                // Flash overlay
                if (showFlash)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _labelController,
              builder: (context, child) {
                return Opacity(
                  opacity: labelOpacities[index].value,
                  child: Transform.translate(
                    offset: Offset(0, 4 * (1 - labelOpacities[index].value)),
                    child: Text(
                      _positions[index].label,
                      style: TextStyle(
                        color: SenseiColors.gray[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderFigure(int index) {
    // Simple stick figure placeholder if assets are missing
    return Center(
      child: Icon(
        Icons.person,
        size: 50,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: SenseiColors.gray[400],
        ),
      ),
    );
  }

  Widget _buildInsightBubble() {
    return AnimatedBuilder(
      animation: _insightController,
      builder: (context, child) {
        final int charCount = (_textProgress.value * _insightText.length)
            .floor();
        final String displayText = _insightText.substring(0, charCount);
        final bool showCursor =
            _insightController.isAnimating &&
            (DateTime.now().millisecond ~/ 500).isEven;

        return Transform.scale(
          scale: _insightScale.value,
          child: Opacity(
            opacity: _insightOpacity.value,
            child: WalkthroughGlassCard(
              accentColor: const Color(0xFF3498DB),
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 60),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '"$displayText',
                              style: TextStyle(
                                color: SenseiColors.gray[600],
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                            if (_textProgress.value >= 1.0)
                              TextSpan(
                                text: '"',
                                style: TextStyle(
                                  color: SenseiColors.gray[600],
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            if (_insightController.isAnimating &&
                                _textProgress.value < 1.0)
                              TextSpan(
                                text: '|',
                                style: TextStyle(
                                  color: SenseiColors.gray[600]!.withValues(
                                    alpha: showCursor ? 1.0 : 0.0,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCopyText() {
    return AnimatedBuilder(
      animation: _frameController,
      builder: (context, child) {
        return Opacity(
          opacity: _frame1Opacity.value,
          child: Column(
            children: [
              Text(
                'Compare to pros, perfect every throw',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SenseiColors.gray[700],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Powerful form analysis',
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

  Widget _buildButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Opacity(
          opacity: _buttonOpacity.value,
          child: Transform.scale(
            scale: _buttonScale.value,
            child: PrimaryButton(
              width: double.infinity,
              height: 56,
              label: "Let's Go!",
              gradientBackground: const [Color(0xFF4ECDC4), Color(0xFF44CF9C)],
              fontSize: 18,
              fontWeight: FontWeight.bold,
              onPressed: widget.onComplete,
            ),
          ),
        );
      },
    );
  }
}

class _PositionData {
  const _PositionData({required this.label, required this.asset});

  final String label;
  final String asset;
}
