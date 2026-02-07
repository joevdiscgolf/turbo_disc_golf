import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/utils/color_helpers.dart';

class SceneProcessing extends StatefulWidget {
  const SceneProcessing({super.key, required this.isActive});

  final bool isActive;

  @override
  State<SceneProcessing> createState() => _SceneProcessingState();
}

class _SceneProcessingState extends State<SceneProcessing>
    with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _gearController;
  late AnimationController _sparkleController;
  late AnimationController _extractionController;

  late Animation<double> _orbScale;
  late Animation<double> _orbGlow;

  bool _hasStarted = false;
  final List<bool> _extractionVisible = [false, false, false];

  static const List<_ExtractionItem> _extractions = [
    _ExtractionItem('birdie', '-1', Color(0xFF4ECDC4)),
    _ExtractionItem('Wraith', 'Disc logged', Color(0xFF9B59B6)),
    _ExtractionItem('parked', '8 ft', Color(0xFFE67E22)),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Orb animation
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _orbScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _orbController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
      ),
    );
    _orbGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _orbController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    // Gear rotation (continuous)
    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Sparkle animation (continuous)
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Extraction animation
    _extractionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
  }

  @override
  void didUpdateWidget(SceneProcessing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_hasStarted) {
      _startAnimationSequence();
    }
  }

  void _startAnimationSequence() {
    _hasStarted = true;

    // 0.2s - Orb fades in
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _orbController.forward();
    });

    // 0.4s - Gears start rotating
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _gearController.repeat();
    });

    // 0.6s - Sparkles start
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _sparkleController.repeat();
    });

    // 0.8s - First extraction
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _extractionVisible[0] = true);
      }
    });

    // 1.4s - Second extraction
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _extractionVisible[1] = true);
      }
    });

    // 2.0s - Third extraction
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _extractionVisible[2] = true);
      }
    });
  }

  @override
  void dispose() {
    _orbController.dispose();
    _gearController.dispose();
    _sparkleController.dispose();
    _extractionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 1),
          _buildMagicOrb(),
          const SizedBox(height: 32),
          _buildExtractionResults(),
          const Spacer(flex: 1),
          _buildCopyText(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMagicOrb() {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbController, _gearController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _orbScale.value,
          child: SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF4ECDC4,
                        ).withValues(alpha: 0.3 * _orbGlow.value),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
                // Inner orb
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF4ECDC4).withValues(alpha: 0.4),
                        const Color(0xFF44CF9C).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
                // Rotating gears
                ..._buildGears(),
                // Center sparkle
                _buildCenterSparkle(),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildGears() {
    return [
      // Large gear
      Positioned(
        top: 30,
        left: 25,
        child: Transform.rotate(
          angle: _gearController.value * 2 * math.pi,
          child: Icon(
            Icons.settings,
            size: 36,
            color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
          ),
        ),
      ),
      // Medium gear (counter-rotate)
      Positioned(
        bottom: 35,
        right: 30,
        child: Transform.rotate(
          angle: -_gearController.value * 2 * math.pi * 1.5,
          child: Icon(
            Icons.settings,
            size: 28,
            color: const Color(0xFFCD7F32).withValues(alpha: 0.8),
          ),
        ),
      ),
      // Small gear
      Positioned(
        top: 50,
        right: 35,
        child: Transform.rotate(
          angle: _gearController.value * 2 * math.pi * 2,
          child: Icon(
            Icons.settings,
            size: 20,
            color: const Color(0xFFB8860B).withValues(alpha: 0.8),
          ),
        ),
      ),
    ];
  }

  Widget _buildCenterSparkle() {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(6, (index) {
            final double angle =
                (index / 6) * 2 * math.pi +
                _sparkleController.value * 2 * math.pi;
            final double radius =
                35 + 10 * math.sin(_sparkleController.value * 4 * math.pi);
            final double x = math.cos(angle) * radius;
            final double y = math.sin(angle) * radius;

            return Transform.translate(
              offset: Offset(x, y),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4ECDC4).withValues(
                    alpha:
                        0.5 +
                        0.5 *
                            math.sin(
                              _sparkleController.value * 2 * math.pi + index,
                            ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildExtractionResults() {
    return Column(
      children: List.generate(3, (index) {
        return _ExtractionRow(
          item: _extractions[index],
          isVisible: _extractionVisible[index],
          delay: index * 0.15,
        );
      }),
    );
  }

  Widget _buildCopyText() {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, child) {
        return Opacity(
          opacity: _orbGlow.value,
          child: Column(
            children: [
              Text(
                'We understand.',
                style: TextStyle(
                  color: SenseiColors.gray[700],
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Every throw, disc, and score\nextracted automatically.',
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

class _ExtractionItem {
  const _ExtractionItem(this.word, this.result, this.color);

  final String word;
  final String result;
  final Color color;
}

class _ExtractionRow extends StatefulWidget {
  const _ExtractionRow({
    required this.item,
    required this.isVisible,
    required this.delay,
  });

  final _ExtractionItem item;
  final bool isVisible;
  final double delay;

  @override
  State<_ExtractionRow> createState() => _ExtractionRowState();
}

class _ExtractionRowState extends State<_ExtractionRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _arrowAnimation;
  late Animation<double> _badgeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _arrowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _badgeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void didUpdateWidget(_ExtractionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward();
    }
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
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Word
                Transform.translate(
                  offset: Offset(_slideAnimation.value, 0),
                  child: Text(
                    '"${widget.item.word}"',
                    style: TextStyle(
                      color: SenseiColors.gray[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Arrow
                Opacity(
                  opacity: _arrowAnimation.value,
                  child: SizedBox(
                    width: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  SenseiColors.gray[300]!,
                                  widget.item.color,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: widget.item.color,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Result badge
                Transform.scale(
                  scale: _badgeAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.item.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.item.color.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.item.result,
                      style: TextStyle(
                        color: widget.item.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
