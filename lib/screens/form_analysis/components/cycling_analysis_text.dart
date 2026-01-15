import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// Messages shown during form analysis processing.
/// These cycle through in a random order.
const List<String> kAnalysisMessages = [
  'Analyzing throwing motion',
  'Detecting body positioning',
  'Measuring arm acceleration',
  'Evaluating weight transfer',
  'Checking hip rotation',
  'Assessing release angle',
  'Analyzing follow-through',
  'Measuring timing sequences',
  'Detecting balance points',
  'Evaluating power generation',
];

/// Cycles through analysis messages in a random order with fade animations.
/// Text fades when changing and fades out completely when finalization starts.
class CyclingAnalysisText extends StatefulWidget {
  const CyclingAnalysisText({
    super.key,
    required this.brainOpacityNotifier,
    this.shouldShow = true,
  });

  final ValueNotifier<double> brainOpacityNotifier;
  final bool shouldShow;

  @override
  State<CyclingAnalysisText> createState() => _CyclingAnalysisTextState();
}

class _CyclingAnalysisTextState extends State<CyclingAnalysisText>
    with SingleTickerProviderStateMixin {
  late List<String> _messageQueue;
  int _currentIndex = 0;
  Timer? _cycleTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Create random permutation of messages
    _messageQueue = List.from(kAnalysisMessages);
    _messageQueue.shuffle(Random());

    // Setup fade animation for message transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..value = 1.0; // Start visible

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Cycle through messages every 2.5 seconds
    _cycleTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _nextMessage();
    });
  }

  @override
  void didUpdateWidget(CyclingAnalysisText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When shouldShow becomes false, stop cycling and fade out
    if (oldWidget.shouldShow && !widget.shouldShow) {
      _cycleTimer?.cancel();
      _fadeController.reverse();
    }
  }

  void _nextMessage() async {
    // Don't cycle if we shouldn't show
    if (!widget.shouldShow) return;

    // Fade out
    await _fadeController.reverse();

    if (!mounted) return;

    // Move to next message
    setState(() {
      _currentIndex = (_currentIndex + 1) % _messageQueue.length;

      // If we've cycled through all messages, reshuffle for new random order
      if (_currentIndex == 0) {
        _messageQueue.shuffle(Random());
      }
    });

    // Fade in
    await _fadeController.forward();
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.brainOpacityNotifier,
      builder: (context, brainOpacity, child) {
        return Opacity(opacity: brainOpacity, child: child);
      },
      child: SizedBox(
        height: 60, // Fixed height to prevent layout shifts
        child: Center(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Text(
                  _messageQueue[_currentIndex],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
