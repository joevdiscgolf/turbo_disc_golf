import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/detected_putt_attempt.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/miss_direction.dart';

/// Animated feedback for made/missed putts
class PuttResultAnimation extends StatefulWidget {
  final DetectedPuttAttempt attempt;

  const PuttResultAnimation({
    super.key,
    required this.attempt,
  });

  @override
  State<PuttResultAnimation> createState() => _PuttResultAnimationState();
}

class _PuttResultAnimationState extends State<PuttResultAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Haptic feedback
    if (widget.attempt.made) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

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
        return Center(
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildResultIndicator(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultIndicator() {
    final bool made = widget.attempt.made;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: (made ? Colors.green : Colors.red).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (made ? Colors.green : Colors.red).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            made ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 8),
          Text(
            made ? 'MAKE!' : 'MISS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          if (!made && widget.attempt.missDirection != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.attempt.missDirection!.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
