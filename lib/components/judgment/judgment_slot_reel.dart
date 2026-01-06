import 'dart:math';

import 'package:flutter/material.dart';

/// Slot machine reel widget that cycles between ROAST and GLAZE.
///
/// Creates a vertical scrolling slot machine effect that spins continuously
/// until signaled to stop, then lands on the predetermined outcome.
class JudgmentSlotReel extends StatefulWidget {
  const JudgmentSlotReel({
    super.key,
    required this.targetIsGlaze,
    required this.onSpinComplete,
    required this.readyToStop,
    this.landingDuration = const Duration(milliseconds: 2500),
  });

  /// Whether the final outcome should be GLAZE (true) or ROAST (false).
  final bool targetIsGlaze;

  /// Callback fired when the slot reel finishes spinning.
  final VoidCallback onSpinComplete;

  /// Notifier that signals when the reel should stop spinning and land.
  final ValueNotifier<bool> readyToStop;

  /// Duration of the landing animation after signaled to stop.
  final Duration landingDuration;

  @override
  State<JudgmentSlotReel> createState() => _JudgmentSlotReelState();
}

class _JudgmentSlotReelState extends State<JudgmentSlotReel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const double _itemHeight = 100.0;
  static const double _viewportHeight = _itemHeight * 3;

  // Number of items in the continuous loop (ROAST, GLAZE pairs)
  static const int _loopItems = 20;

  // Current scroll offset for continuous spinning
  double _scrollOffset = 0.0;

  // Track last controller value to calculate delta (avoids recursive listener issue)
  double _lastControllerValue = 0.0;

  // Whether we're in landing mode
  bool _isLanding = false;

  // Landing animation values
  double _landingStartOffset = 0.0;
  double _landingTargetOffset = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Check if already ready to stop
    if (widget.readyToStop.value) {
      _startLandingAnimation();
    } else {
      // Start continuous spinning
      _startContinuousSpinning();
      widget.readyToStop.addListener(_onReadyToStopChanged);
    }
  }

  void _onReadyToStopChanged() {
    if (widget.readyToStop.value && !_isLanding) {
      _startLandingAnimation();
    }
  }

  void _startContinuousSpinning() {
    // Fast continuous spin - one full cycle (2 items) per 150ms
    _controller.duration = const Duration(milliseconds: 150);
    _controller.addListener(_onSpinTick);
    _controller.repeat();
  }

  void _onSpinTick() {
    if (_isLanding) return;

    final double currentValue = _controller.value;
    // Calculate delta since last tick (handles wrap-around from 1.0 to 0.0)
    double delta = currentValue - _lastControllerValue;
    if (delta < 0) delta += 1.0; // Animation wrapped around

    setState(() {
      // Move by a fraction of item height each tick
      _scrollOffset += _itemHeight * 2 * delta;
      // Keep offset within bounds by wrapping
      _scrollOffset = _scrollOffset % (_itemHeight * _loopItems);
    });

    _lastControllerValue = currentValue;
  }

  void _startLandingAnimation() {
    _isLanding = true;
    _controller.removeListener(_onSpinTick);
    _controller.stop();

    // Calculate where we need to land
    // Current position in terms of item index
    final double currentIndex = _scrollOffset / _itemHeight;
    final int currentWholeIndex = currentIndex.floor();

    // We want to land on target (ROAST = even index, GLAZE = odd index)
    // Add some extra spins for drama (at least 12 more items)
    int targetIndex = currentWholeIndex + 12;

    // Adjust to land on correct parity
    if (widget.targetIsGlaze) {
      // Need odd index
      if (targetIndex % 2 == 0) targetIndex++;
    } else {
      // Need even index
      if (targetIndex % 2 == 1) targetIndex++;
    }

    _landingStartOffset = _scrollOffset;
    _landingTargetOffset = targetIndex * _itemHeight;

    // Set up landing animation
    _controller.duration = widget.landingDuration;
    _controller.addListener(_onLandingTick);
    _controller.addStatusListener(_onLandingComplete);
    _controller.forward(from: 0.0);
  }

  void _onLandingTick() {
    if (!_isLanding) return;

    // Use dramatic deceleration curve
    final double t = const _DramaticSlotCurve().transform(_controller.value);
    setState(() {
      _scrollOffset =
          _landingStartOffset + (_landingTargetOffset - _landingStartOffset) * t;
    });
  }

  void _onLandingComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onSpinComplete();
    }
  }

  @override
  void dispose() {
    widget.readyToStop.removeListener(_onReadyToStopChanged);
    _controller.removeListener(_onSpinTick);
    _controller.removeListener(_onLandingTick);
    _controller.removeStatusListener(_onLandingComplete);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate visual offset (wrap for infinite scroll illusion)
    final double visualOffset =
        -(_scrollOffset % (_itemHeight * _loopItems)) + _itemHeight;

    // Calculate glow intensity - only during landing, ramps up in last 30%
    double glowIntensity = 0.0;
    if (_isLanding && _controller.value > 0.7) {
      glowIntensity = ((_controller.value - 0.7) / 0.3);
    }

    final Color accentColor = _getAccentColor();

    return SizedBox(
      height: _viewportHeight,
      child: ClipRect(
        child: Stack(
          children: [
            // Background glow that intensifies near the end
            if (glowIntensity > 0)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.15 * glowIntensity),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Scrolling items
            Positioned(
              top: visualOffset,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_loopItems, (index) {
                  final bool isGlaze = index % 2 == 1;
                  return _SlotItem(
                    isGlaze: isGlaze,
                    height: _itemHeight,
                  );
                }),
              ),
            ),

            // Gradient overlay for depth (fade edges)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFAF8FC),
                        const Color(0xFFFAF8FC).withValues(alpha: 0.0),
                        const Color(0xFFFAF8FC).withValues(alpha: 0.0),
                        const Color(0xFFFAF8FC),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Center highlight - intensifies near end
            Center(
              child: Container(
                height: _itemHeight,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: accentColor.withValues(
                        alpha: 0.3 + (glowIntensity * 0.5),
                      ),
                      width: 2 + (glowIntensity * 2),
                    ),
                  ),
                  boxShadow: glowIntensity > 0
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(
                              alpha: 0.3 * glowIntensity,
                            ),
                            blurRadius: 20 * glowIntensity,
                            spreadRadius: 5 * glowIntensity,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccentColor() {
    // During landing, transition to final color
    if (_isLanding) {
      final double progress = _controller.value;
      if (progress < 0.6) {
        return const Color(0xFF5B7EFF);
      }
      final double colorProgress = (progress - 0.6) / 0.4;
      final Color targetColor = widget.targetIsGlaze
          ? const Color(0xFFFFD700)
          : const Color(0xFFFF6B6B);
      return Color.lerp(const Color(0xFF5B7EFF), targetColor, colorProgress)!;
    }
    // During spinning, use neutral accent
    return const Color(0xFF5B7EFF);
  }
}

/// Dramatic deceleration curve - fast spin that dramatically slows at the end.
class _DramaticSlotCurve extends Curve {
  const _DramaticSlotCurve();

  @override
  double transformInternal(double t) {
    // Use a strong ease-out curve (power of 4) for dramatic deceleration
    // This means: very fast at start, dramatically slowing near the end
    return 1.0 - pow(1.0 - t, 4).toDouble();
  }
}

/// Individual slot item showing ROAST or GLAZE.
class _SlotItem extends StatelessWidget {
  const _SlotItem({
    required this.isGlaze,
    required this.height,
  });

  final bool isGlaze;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isGlaze
                ? const Text(
                    '\u{1F369}',
                    style: TextStyle(fontSize: 36),
                  )
                : const Icon(
                    Icons.local_fire_department,
                    size: 40,
                    color: Color(0xFFFF6B6B),
                  ),
            const SizedBox(width: 12),
            Text(
              isGlaze ? 'GLAZE' : 'ROAST',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: isGlaze
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFFF6B6B),
                shadows: [
                  Shadow(
                    color: (isGlaze
                            ? const Color(0xFFFFD700)
                            : const Color(0xFFFF6B6B))
                        .withValues(alpha: 0.5),
                    blurRadius: 15,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
