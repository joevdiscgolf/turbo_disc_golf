import 'dart:ui';

import 'package:flutter/material.dart';

/// A glass-style card component for the walkthrough screens.
///
/// Features a frosted glass effect with semi-transparent background,
/// colored border/glow based on the accent color, and backdrop blur.
class WalkthroughGlassCard extends StatelessWidget {
  const WalkthroughGlassCard({
    super.key,
    required this.child,
    required this.accentColor,
    this.opacity = 0.7,
    this.blurSigma = 12,
    this.borderRadius = 20,
    this.padding,
    this.width,
    this.height,
  });

  final Widget child;

  /// The accent color used for the border and glow effect.
  final Color accentColor;

  /// Background opacity - lower values allow more see-through effect.
  /// Default is 0.7 for a balanced glass effect with good readability.
  final double opacity;

  /// Blur intensity for the frosted glass effect.
  /// Default is 12 for a subtle frosted look.
  final double blurSigma;

  /// Border radius for the card corners. Default is 20.
  final double borderRadius;

  /// Optional padding inside the card.
  final EdgeInsetsGeometry? padding;

  /// Optional fixed width for the card.
  final double? width;

  /// Optional fixed height for the card.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final double effectiveBlur = blurSigma * opacity;
    final bool shouldApplyBlur = effectiveBlur > 0.5;

    final Widget container = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );

    if (!shouldApplyBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: container,
      ),
    );
  }
}
