import 'dart:ui';

import 'package:flutter/material.dart';

/// A particle system that emits fire emojis for roast celebrations.
class FireEmojiOverlay extends StatefulWidget {
  const FireEmojiOverlay({
    super.key,
    required this.isPlaying,
    required this.onComplete,
  });

  /// Whether the animation should be playing.
  final bool isPlaying;

  /// Callback when the animation completes.
  final VoidCallback? onComplete;

  @override
  State<FireEmojiOverlay> createState() => _FireEmojiOverlayState();
}

class _FireEmojiOverlayState extends State<FireEmojiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const Duration _duration = Duration(milliseconds: 4500);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _duration,
      vsync: this,
    );
    _controller.addListener(() => setState(() {}));
    _controller.addStatusListener(_onAnimationStatus);

    if (widget.isPlaying) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(FireEmojiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.forward(from: 0.0);
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Hardcoded emoji configs: [xPercent, startY, size]
  // 72 emojis, 4x spread vertically
  static const List<List<double>> _emojiConfigs = [
    // Batch 1
    [0.05, -1680, 60],
    [0.25, -2880, 100],
    [0.42, -1200, 45],
    [0.58, -2160, 85],
    [0.15, -3360, 70],
    [0.72, -1440, 110],
    [0.88, -2640, 55],
    [0.35, -1920, 90],
    // Batch 2
    [0.12, -2280, 75],
    [0.48, -3120, 55],
    [0.65, -1080, 95],
    [0.82, -2040, 65],
    [0.28, -2520, 80],
    [0.55, -1800, 50],
    [0.78, -2760, 105],
    [0.02, -1320, 70],
    // Batch 3
    [0.08, -1560, 65],
    [0.32, -3000, 90],
    [0.52, -1260, 55],
    [0.68, -2400, 100],
    [0.22, -3480, 75],
    [0.85, -1620, 85],
    [0.45, -2220, 60],
    [0.18, -1980, 105],
    // Batch 4
    [0.62, -1380, 70],
    [0.38, -2820, 50],
    [0.75, -1740, 95],
    [0.92, -2460, 65],
    [0.10, -2100, 80],
    [0.50, -1500, 110],
    [0.30, -2580, 55],
    [0.70, -1140, 90],
    // Batch 5
    [0.03, -1860, 75],
    [0.40, -3240, 60],
    [0.60, -1020, 100],
    [0.80, -2340, 45],
    [0.20, -2940, 85],
    [0.95, -1440, 70],
    [0.55, -2700, 95],
    [0.15, -1680, 55],
    // Batch 6
    [0.45, -2160, 80],
    [0.25, -1200, 105],
    [0.65, -3060, 65],
    [0.85, -1920, 90],
    [0.35, -2520, 50],
    [0.05, -3180, 75],
    [0.75, -1380, 100],
    [0.90, -2220, 60],
    // Batch 7
    [0.07, -2040, 70],
    [0.27, -3300, 85],
    [0.47, -1560, 55],
    [0.67, -2760, 100],
    [0.87, -1080, 75],
    [0.17, -2400, 65],
    [0.37, -1320, 90],
    [0.57, -2880, 50],
    // Batch 8
    [0.77, -1800, 105],
    [0.97, -3120, 60],
    [0.13, -1440, 80],
    [0.33, -2640, 95],
    [0.53, -3360, 70],
    [0.73, -1680, 55],
    [0.93, -2280, 85],
    [0.23, -1140, 100],
    // Batch 9
    [0.43, -3000, 65],
    [0.63, -1860, 90],
    [0.83, -3240, 75],
    [0.04, -1560, 50],
    [0.24, -2520, 110],
    [0.44, -1200, 80],
    [0.64, -2820, 55],
    [0.84, -2100, 95],
  ];

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      return const SizedBox.shrink();
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double t = _controller.value;

    // Fade out and blur in last 15% of animation
    final double fadeProgress = t > 0.85 ? (t - 0.85) / 0.15 : 0.0;
    final double opacity = 1.0 - fadeProgress;
    final double blur = fadeProgress * 8.0;

    Widget flames = Stack(
      children: [
        for (final config in _emojiConfigs)
          Positioned(
            top: config[1] + (t * 4200),
            left: screenWidth * config[0],
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Text('🔥', style: TextStyle(fontSize: config[2])),
            ),
          ),
      ],
    );

    // Apply blur during fade out
    if (blur > 0.1) {
      flames = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: flames,
      );
    }

    return flames;
  }
}
