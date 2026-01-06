import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Suspense buildup animation shown before the slot reel spins.
///
/// Features morphing background blobs and a pulsing central icon
/// that builds anticipation for the judgment.
class JudgmentBuildingAnimation extends StatelessWidget {
  const JudgmentBuildingAnimation({
    super.key,
    this.onComplete,
  });

  /// Callback fired when the buildup animation completes.
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Morphing background
        const _JudgmentMorphingBackground(),
        // Center content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing icon
              const _PulsingJudgmentIcon(),
              const SizedBox(height: 32),
              // Text
              Text(
                'Determining your fate...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C2C2C),
                ),
              )
                  .animate(
                    onComplete: (controller) => onComplete?.call(),
                  )
                  .fadeIn(duration: const Duration(milliseconds: 500))
                  .then(delay: const Duration(milliseconds: 1000)),
              const SizedBox(height: 16),
              // Subtitle with shimmer
              Text(
                'Will you be roasted or glazed?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF666666),
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 500),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Morphing background adapted for judgment theme.
class _JudgmentMorphingBackground extends StatelessWidget {
  const _JudgmentMorphingBackground();

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Base solid color layer
        Container(
          color: const Color(0xFFFAF8FC), // Light purple-gray
        ),

        // Top left blob - warm tones
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFB74D).withValues(alpha: 0.3), // Orange
                  const Color(0xFFFFB74D).withValues(alpha: 0.0),
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                duration: const Duration(milliseconds: 2500),
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: const Duration(milliseconds: 2500),
                begin: const Offset(1.2, 1.2),
                end: const Offset(0.8, 0.8),
                curve: Curves.easeInOut,
              ),
        ),

        // Bottom right blob - cool tones
        Positioned(
          bottom: -150,
          right: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF64B5F6).withValues(alpha: 0.25), // Blue
                  const Color(0xFF64B5F6).withValues(alpha: 0.0),
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                duration: const Duration(milliseconds: 3000),
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.3, 1.3),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: const Duration(milliseconds: 3000),
                begin: const Offset(1.3, 1.3),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeInOut,
              ),
        ),

        // Center blob - mixed
        Positioned(
          top: screenSize.height * 0.4 - 150,
          left: screenSize.width * 0.5 - 150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF6B6B).withValues(alpha: 0.15), // Red
                  const Color(0xFFFFD700).withValues(alpha: 0.1), // Gold
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                duration: const Duration(milliseconds: 2000),
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.15, 1.15),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: const Duration(milliseconds: 2000),
                begin: const Offset(1.15, 1.15),
                end: const Offset(0.9, 0.9),
                curve: Curves.easeInOut,
              ),
        ),
      ],
    );
  }
}

/// Pulsing icon that alternates between fire and donut.
class _PulsingJudgmentIcon extends StatefulWidget {
  const _PulsingJudgmentIcon();

  @override
  State<_PulsingJudgmentIcon> createState() => _PulsingJudgmentIconState();
}

class _PulsingJudgmentIconState extends State<_PulsingJudgmentIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _showFire = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Alternate icons every 400ms
    _startIconSwitch();
  }

  void _startIconSwitch() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _showFire = !_showFire;
        });
      }
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
        final Color glowColor = _showFire
            ? const Color(0xFFFF6B6B)
            : const Color(0xFFFFD700);

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: _glowAnimation.value),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _showFire
                  ? Icon(
                      Icons.local_fire_department,
                      key: const ValueKey('fire'),
                      size: 80,
                      color: const Color(0xFFFF6B6B),
                    )
                  : const Text(
                      '\u{1F369}', // Donut emoji
                      key: ValueKey('donut'),
                      style: TextStyle(fontSize: 70),
                    ),
            ),
          ),
        );
      },
    );
  }
}
