import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class SceneRecording extends StatefulWidget {
  const SceneRecording({super.key, required this.isActive});

  final bool isActive;

  @override
  State<SceneRecording> createState() => _SceneRecordingState();
}

class _SceneRecordingState extends State<SceneRecording>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _micPulseController;
  late AnimationController _waveController;
  late AnimationController _textController;
  late AnimationController _glowController;

  late Animation<double> _cardOpacity;
  late Animation<double> _cardScale;
  late Animation<double> _micScale;
  late Animation<double> _textProgress;
  late Animation<double> _glowOpacity;

  static const String _typingText =
      '"Hole 1, par 3. Threw my Wraith backhand, parked it for birdie..."';

  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Start animation if already active on initial build
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasStarted) {
          _startAnimationSequence();
        }
      });
    }
  }

  void _initAnimations() {
    // Card fade in and scale
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
    _cardScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    // Mic pulse animation (continuous)
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _micScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _micPulseController, curve: Curves.easeInOut),
    );

    // Sound wave animation (continuous)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Text typing animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _textProgress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.linear));

    // Glow animation at the end
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowOpacity = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(SceneRecording oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_hasStarted) {
      _startAnimationSequence();
    }
  }

  void _startAnimationSequence() {
    _hasStarted = true;

    // 0.3s - Card fades in
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardController.forward();
    });

    // 0.9s - Mic starts pulsing
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _micPulseController.repeat(reverse: true);
    });

    // 1.0s - Sound waves start
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _waveController.repeat();
    });

    // 1.2s - Text starts typing
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _textController.forward();
    });

    // 4.5s - Glow effect
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) _glowController.forward();
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _micPulseController.dispose();
    _waveController.dispose();
    _textController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 1),
          _buildAnimatedCard(),
          const Spacer(flex: 1),
          _buildCopyText(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_cardController, _glowController]),
      builder: (context, child) {
        return Opacity(
          opacity: _cardOpacity.value,
          child: Transform.scale(
            scale: _cardScale.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF4ECDC4,
                    ).withValues(alpha: _glowOpacity.value),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMicButton(),
                  const SizedBox(height: 20),
                  _buildSoundWaves(),
                  const SizedBox(height: 20),
                  _buildTypingText(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMicButton() {
    return AnimatedBuilder(
      animation: _micPulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _micScale.value,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF6B6B).withValues(alpha: 0.9),
                  const Color(0xFFEE5A5A),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFFF6B6B,
                  ).withValues(alpha: 0.4 * _micScale.value - 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 28),
          ),
        );
      },
    );
  }

  Widget _buildSoundWaves() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return SizedBox(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              final double delay = index * 0.1;
              final double progress = (_waveController.value + delay) % 1.0;
              final double height = 10 + 15 * math.sin(progress * math.pi);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildTypingText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        final int charCount = (_textProgress.value * _typingText.length)
            .floor();
        final String displayText = _typingText.substring(0, charCount);
        final bool showCursor =
            _textController.isAnimating &&
            (DateTime.now().millisecond ~/ 500).isEven;

        return Container(
          constraints: const BoxConstraints(minHeight: 80),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: displayText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                if (showCursor || _textController.isAnimating)
                  TextSpan(
                    text: '|',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: showCursor ? 1.0 : 0.0,
                      ),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildCopyText() {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Opacity(
          opacity: _cardOpacity.value,
          child: Column(
            children: [
              const Text(
                'Just talk.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Describe your round naturally.\nWe\'ll handle the rest.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
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
