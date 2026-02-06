import 'dart:ui';

import 'package:flutter/material.dart';

/// Liquid glass card component with frosted glass effect.
///
/// Used across multiple screens for a consistent glass morphism look:
/// - Auth screens (login, signup)
/// - Form analysis recording
///
/// The default opacity is set to allow some see-through effect while
/// maintaining the frosted glass blur.
class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.opacity = 0.55,
    this.blurSigma = 24,
    this.borderOpacity = 0.4,
    this.borderRadius = 24,
    this.accentColor,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.margin,
  });

  final Widget child;

  /// Background opacity - lower values allow more see-through effect.
  /// Default is 0.55 for a balanced glass effect.
  final double opacity;

  /// Blur intensity for the frosted glass effect.
  /// Higher values create more blur. Default is 24.
  final double blurSigma;

  /// Border opacity - controls visibility of the glass edge.
  /// Default is 0.4.
  final double borderOpacity;

  /// Border radius for the card corners. Default is 24.
  final double borderRadius;

  /// Optional accent color for the subtle shadow glow.
  /// If null, uses a neutral shadow without color tint.
  final Color? accentColor;

  /// Optional background color. Defaults to white.
  /// The [opacity] is applied to this color.
  final Color? backgroundColor;

  /// Optional border color. Defaults to white.
  /// The [borderOpacity] is applied to this color.
  final Color? borderColor;

  /// Optional padding inside the card.
  final EdgeInsetsGeometry? padding;

  /// Optional margin around the card.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = backgroundColor ?? Colors.white;
    final Color brdColor = borderColor ?? Colors.white;

    // Scale blur based on opacity - low opacity means less frosting effect
    // This allows the background to show through at lower opacities
    final double effectiveBlur = blurSigma * opacity;
    final bool shouldApplyBlur = effectiveBlur > 0.5;

    final Widget container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderOpacity > 0
            ? Border.all(
                color: brdColor.withValues(alpha: borderOpacity),
                width: 1.5,
              )
            : null,
        boxShadow: opacity > 0.1
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06 * opacity),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                if (accentColor != null)
                  BoxShadow(
                    color: accentColor!.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ]
            : null,
      ),
      child: child,
    );

    Widget result;
    if (!shouldApplyBlur) {
      result = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      );
    } else {
      result = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: container,
        ),
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: result);
    }
    return result;
  }
}
