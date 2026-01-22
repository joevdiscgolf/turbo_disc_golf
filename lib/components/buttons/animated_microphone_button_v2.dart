import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flat, full-width microphone button for use in fixed footer.
/// V2 replaces the circular button with a pill-shaped, full-width design.
class AnimatedMicrophoneButtonV2 extends StatelessWidget {
  const AnimatedMicrophoneButtonV2({
    super.key,
    required this.showListeningWaveState,
    required this.onTap,
    this.isLoading = false,
  });

  final bool showListeningWaveState;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = showListeningWaveState
        ? const Color(0xFFEF5350)
        : const Color(0xFF1565C0);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: showListeningWaveState
                ? [const Color(0xFFEF5350), const Color(0xFFD32F2F)]
                : [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                        key: ValueKey('loading'),
                      ),
                    )
                  : showListeningWaveState
                      ? const _FlatSoundWaveIndicator(key: ValueKey('soundwave'))
                      : const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 22,
                          key: ValueKey('mic'),
                        ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                showListeningWaveState ? 'Listening...' : 'Tap to speak',
                key: ValueKey(showListeningWaveState ? 'listening' : 'tap'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact sound wave indicator for flat button.
class _FlatSoundWaveIndicator extends StatefulWidget {
  const _FlatSoundWaveIndicator({super.key});

  @override
  State<_FlatSoundWaveIndicator> createState() => _FlatSoundWaveIndicatorState();
}

class _FlatSoundWaveIndicatorState extends State<_FlatSoundWaveIndicator>
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
      width: 32,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double delay = index * 0.12;
              final double animationValue = (_controller.value + delay) % 1.0;
              final double height =
                  4 + (12 * (0.5 + 0.5 * sin(animationValue * 2 * pi)));

              return Container(
                width: 2.5,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
