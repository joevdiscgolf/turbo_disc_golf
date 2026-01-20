import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A generic shimmer placeholder box for loading states.
///
/// Displays a colored box with a shimmer animation effect.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.color,
    this.borderRadius = 4,
    this.shimmerColor,
    this.duration = const Duration(milliseconds: 1200),
  });

  /// Width of the shimmer box. If null, expands to fill available width.
  final double? width;

  /// Height of the shimmer box.
  final double? height;

  /// Background color of the box. Defaults to Colors.grey[300].
  final Color? color;

  /// Border radius of the box. Defaults to 4.
  final double borderRadius;

  /// Color of the shimmer effect. Defaults to white with 0.5 alpha.
  final Color? shimmerColor;

  /// Duration of the shimmer animation. Defaults to 1200ms.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: duration,
          color: shimmerColor ?? Colors.white.withValues(alpha: 0.5),
        );
  }
}
