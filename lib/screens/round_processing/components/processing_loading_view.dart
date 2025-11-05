import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/animated_square_icon.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/morphing_background.dart';

/// Reusable loading view component shown during round processing.
///
/// Features:
/// - Morphing animated background
/// - Pulsing triangle icon
/// - Cycling loading messages
/// - Shimmer progress indicator
class ProcessingLoadingView extends StatefulWidget {
  const ProcessingLoadingView({super.key});

  @override
  State<ProcessingLoadingView> createState() => _ProcessingLoadingViewState();
}

class _ProcessingLoadingViewState extends State<ProcessingLoadingView> {
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  final List<String> _loadingMessages = [
    'Processing your round...',
    'Analyzing your throws...',
    'Calculating statistics...',
    'Generating insights...',
  ];

  @override
  void initState() {
    super.initState();
    _startMessageCycle();
  }

  void _startMessageCycle() {
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated morphing background
        const MorphingBackground(),

        // Content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated pulsing triangle icon
              const AnimatedSquareIcon(size: 120),

              const SizedBox(height: 48),

              // Cycling loading message with fade animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _loadingMessages[_currentMessageIndex],
                  key: ValueKey<int>(_currentMessageIndex),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Shimmer loading indicator
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
                child:
                    Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFB8E986).withValues(alpha: 0.3),
                                const Color(0xFFB8E986),
                                const Color(0xFF5B7EFF),
                                const Color(0xFF5B7EFF).withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                          duration: const Duration(milliseconds: 2000),
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
              ),

              const SizedBox(height: 16),

              // Subtle hint text with breathing animation
              Text(
                    'Creating something special...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontStyle: FontStyle.italic,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .fadeIn(duration: const Duration(milliseconds: 1500))
                  .then()
                  .fadeOut(duration: const Duration(milliseconds: 1500)),
            ],
          ),
        ),
      ],
    );
  }
}
