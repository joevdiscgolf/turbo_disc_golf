import 'dart:math';

import 'package:flutter/material.dart';

/// Animated microphone button with gradient and shadow effects.
class AnimatedMicrophoneButton extends StatelessWidget {
  const AnimatedMicrophoneButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  final bool isListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isListening
                ? [const Color(0xFFEF5350), const Color(0xFFD32F2F)]
                : [const Color(0xFF64B5F6), const Color(0xFF2196F3)],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isListening
                          ? const Color(0xFFEF5350)
                          : const Color(0xFF2196F3))
                      .withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: isListening
              ? const _SoundWaveIndicator(key: ValueKey('soundwave'))
              : const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 32,
                  key: ValueKey('mic'),
                ),
        ),
      ),
    );
  }
}

/// Animated sound wave indicator displayed while recording.
class _SoundWaveIndicator extends StatefulWidget {
  const _SoundWaveIndicator({super.key});

  @override
  State<_SoundWaveIndicator> createState() => _SoundWaveIndicatorState();
}

class _SoundWaveIndicatorState extends State<_SoundWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Create staggered animation for each bar
              final double delay = index * 0.1;
              final double animationValue = (_controller.value + delay) % 1.0;

              // Use sine wave for smooth up/down motion
              final double height =
                  6 + (18 * (0.5 + 0.5 * sin(animationValue * 2 * pi)));

              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
