import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// A standard card component with consistent styling across the app.
///
/// Uses the default card decoration:
/// - White background (or custom color)
/// - Border: SenseiColors.gray[100]
/// - Box shadow: defaultCardBoxShadow()
/// - Border radius: 12 (default)
class StandardCard extends StatelessWidget {
  const StandardCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12,
    this.backgroundColor = Colors.white,
    this.showBorder = true,
    this.showShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color backgroundColor;
  final bool showBorder;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: SenseiColors.gray[100]!, width: 1)
            : null,
        boxShadow: showShadow ? defaultCardBoxShadow() : null,
      ),
      child: child,
    );
  }
}
