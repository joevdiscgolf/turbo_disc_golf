import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';

class SceneComplete extends StatefulWidget {
  const SceneComplete({
    super.key,
    required this.isActive,
    this.onComplete,
  });

  final bool isActive;
  final VoidCallback? onComplete;

  @override
  State<SceneComplete> createState() => _SceneCompleteState();
}

class _SceneCompleteState extends State<SceneComplete>
    with TickerProviderStateMixin {
  late AnimationController _statsCardController;
  late AnimationController _storyCardController;
  late AnimationController _glazeCardController;
  late AnimationController _roastCardController;
  late AnimationController _buttonController;
  late AnimationController _floatController;
  late AnimationController _sparkleController;

  late Animation<double> _statsSlide;
  late Animation<double> _statsRotation;
  late Animation<double> _storySlide;
  late Animation<double> _storyRotation;
  late Animation<double> _glazeSlide;
  late Animation<double> _roastSlide;
  late Animation<double> _buttonOpacity;
  late Animation<double> _buttonScale;

  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Stats card (top-left)
    _statsCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _statsSlide = Tween<double>(begin: -400, end: 0).animate(
      CurvedAnimation(parent: _statsCardController, curve: Curves.easeOutBack),
    );
    _statsRotation = Tween<double>(begin: -0.1, end: -0.02).animate(
      CurvedAnimation(parent: _statsCardController, curve: Curves.easeOutBack),
    );

    // Story card (top-right)
    _storyCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _storySlide = Tween<double>(begin: 200, end: 0).animate(
      CurvedAnimation(parent: _storyCardController, curve: Curves.easeOutBack),
    );
    _storyRotation = Tween<double>(begin: 0.1, end: 0.02).animate(
      CurvedAnimation(parent: _storyCardController, curve: Curves.easeOutBack),
    );

    // Glaze card (bottom left) - slides in from left
    _glazeCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glazeSlide = Tween<double>(begin: -300, end: 0).animate(
      CurvedAnimation(parent: _glazeCardController, curve: Curves.easeOutBack),
    );

    // Roast card (bottom right) - slides in from right
    _roastCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _roastSlide = Tween<double>(begin: 300, end: 0).animate(
      CurvedAnimation(parent: _roastCardController, curve: Curves.easeOutBack),
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

    // Float animation (continuous)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Sparkle animation (continuous)
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didUpdateWidget(SceneComplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_hasStarted) {
      _startAnimationSequence();
    }
  }

  void _startAnimationSequence() {
    _hasStarted = true;

    // 0.3s - Stats card flies in
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _statsCardController.forward();
    });

    // 0.6s - Story card flies in
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _storyCardController.forward();
    });

    // 0.9s - Glaze and Roast cards slide in from opposite sides
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _glazeCardController.forward();
        _roastCardController.forward();
      }
    });

    // 1.5s - Start floating
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _floatController.repeat(reverse: true);
    });

    // 1.8s - Sparkles start
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _sparkleController.repeat();
    });

    // 2.5s - Button appears
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _statsCardController.dispose();
    _storyCardController.dispose();
    _glazeCardController.dispose();
    _roastCardController.dispose();
    _buttonController.dispose();
    _floatController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Spacer(flex: 1),
            _buildCardsStack(),
            const Spacer(flex: 1),
            _buildCopyText(),
            if (widget.onComplete != null) ...[
              const SizedBox(height: 24),
              _buildButton(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsStack() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _sparkleController]),
      builder: (context, child) {
        return SizedBox(
          height: 340,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Sparkles layer
              ..._buildSparkles(),
              // Stats card (top-left)
              Positioned(
                left: 0,
                top: 0 + _getFloatOffset(0),
                child: _buildStatsCard(),
              ),
              // Story card (top-right)
              Positioned(
                right: 0,
                top: 20 + _getFloatOffset(1),
                child: _buildStoryCard(),
              ),
              // Glaze card (bottom left)
              Positioned(
                left: 0,
                bottom: 0 + _getFloatOffset(2),
                child: _buildGlazeCard(),
              ),
              // Roast card (bottom right)
              Positioned(
                right: 0,
                bottom: 0 + _getFloatOffset(3),
                child: _buildRoastCard(),
              ),
            ],
          ),
        );
      },
    );
  }

  double _getFloatOffset(int index) {
    final double phase = index * 0.3;
    return math.sin((_floatController.value + phase) * 2 * math.pi) * 5;
  }

  List<Widget> _buildSparkles() {
    final List<Widget> sparkles = [];
    final List<Offset> positions = [
      const Offset(30, 50),
      const Offset(280, 30),
      const Offset(150, 120),
      const Offset(50, 200),
      const Offset(300, 180),
      const Offset(180, 280),
    ];

    for (int i = 0; i < positions.length; i++) {
      final double phase = i * 0.15;
      final double opacity =
          (math.sin((_sparkleController.value + phase) * 2 * math.pi) + 1) / 2;

      sparkles.add(
        Positioned(
          left: positions[i].dx,
          top: positions[i].dy,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: opacity * 0.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: opacity * 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return sparkles;
  }

  Widget _buildStatsCard() {
    return AnimatedBuilder(
      animation: _statsCardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_statsSlide.value, 0),
          child: Transform.rotate(
            angle: _statsRotation.value,
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF3498DB).withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3498DB).withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Text('📊', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        'YOUR STATS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMiniStat('Backhand Birdie %', 0.87, '87%'),
                  const SizedBox(height: 8),
                  _buildMiniStat('FD3 Birdie %', 0.78, '78%'),
                  const SizedBox(height: 8),
                  _buildMiniStat('C1 in Reg %', 0.92, '92%'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, double value, String percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4ECDC4), Color(0xFF44CF9C)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              percentage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoryCard() {
    return AnimatedBuilder(
      animation: _storyCardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_storySlide.value, 0),
          child: Transform.rotate(
            angle: _storyRotation.value,
            child: Container(
              width: 165,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Text('📖', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        'YOUR STORY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('✅', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Text(
                        'What You Did Well',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your C1 putting was on fire today at 85%...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Text(
                        'Practice Focus',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Work on forehand approaches from 150ft...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
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

  Widget _buildGlazeCard() {
    return AnimatedBuilder(
      animation: _glazeCardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_glazeSlide.value, 0),
          child: Container(
            width: 165,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF39C12).withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF39C12).withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Text('✨', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text(
                      'GLAZE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Spacer(),
                    Text('🍯', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"That 50-footer on hole 7? Pure butter."',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoastCard() {
    return AnimatedBuilder(
      animation: _roastCardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_roastSlide.value, 0),
          child: Container(
            width: 165,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text(
                      'ROAST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Spacer(),
                    Text('🍖', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"3 OBs? Were you aiming for the parking lot?"',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ],
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
          opacity: _statsCardController.value,
          child: Column(
            children: [
              const Text(
                'All this. Every round.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Record once. Get everything.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
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
              onPressed: widget.onComplete!,
            ),
          ),
        );
      },
    );
  }
}
