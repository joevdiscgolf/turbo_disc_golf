import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Base card component for story cards with consistent styling
///
/// Provides:
/// - White background
/// - Default card box shadow
/// - Rounded corners (10px)
/// - Standard padding (10px)
///
/// Use this as a wrapper for any content that should appear as a card.
class BaseStoryCard extends StatelessWidget {
  const BaseStoryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
  });

  /// The content to display inside the card
  final Widget child;

  /// Padding around the child content (default: 10px all sides)
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SenseiColors.gray.shade100),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
