import 'dart:math';

import 'package:flutter/material.dart';

/// A composable widget for creating shareable images.
///
/// Stacks visual layers in the correct order for sharing:
/// 1. Solid background color (ensures no transparency in captured image)
/// 2. Optional background decoration (e.g., emoji pattern)
/// 3. Optional header widget (e.g., "You got glazed")
/// 4. Main content widget (e.g., share card)
/// 5. Optional footer widget (e.g., branding)
///
/// Use with [OffscreenCaptureTarget] for the full share flow:
///
/// ```dart
/// OffscreenCaptureTarget(
///   captureKey: _captureKey,
///   child: ShareableComposite(
///     backgroundColor: Colors.white,
///     backgroundWidget: EmojiBackground(...),
///     headerWidget: Text('My header'),
///     contentWidget: MyShareCard(),
///     footerWidget: ShareBrandingFooter(),
///   ),
/// )
/// ```
class ShareableComposite extends StatelessWidget {
  const ShareableComposite({
    super.key,
    required this.contentWidget,
    this.backgroundColor = Colors.white,
    this.backgroundWidget,
    this.headerWidget,
    this.footerWidget,
    this.horizontalPadding = 16.0,
    this.headerSpacing = 12.0,
    this.footerSpacing = 16.0,
  });

  /// The main content to share (typically a card widget).
  final Widget contentWidget;

  /// Background color. Defaults to white to ensure no transparency.
  final Color backgroundColor;

  /// Optional background decoration (e.g., emoji pattern).
  /// Fills the entire composite area.
  final Widget? backgroundWidget;

  /// Optional header displayed above the content (e.g., verdict text).
  final Widget? headerWidget;

  /// Optional footer displayed below the content (e.g., branding).
  final Widget? footerWidget;

  /// Horizontal padding between content and edges. Defaults to 16px.
  final double horizontalPadding;

  /// Spacing between header and content. Defaults to 12px.
  final double headerSpacing;

  /// Spacing between content and footer. Defaults to 16px.
  final double footerSpacing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: Solid background (no transparency)
        Container(color: backgroundColor),

        // Layer 2: Optional background decoration
        if (backgroundWidget != null) backgroundWidget!,

        // Layer 3: Content with padding
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (headerWidget != null) ...[
                  headerWidget!,
                  SizedBox(height: headerSpacing),
                ],
                contentWidget,
                if (footerWidget != null) ...[
                  SizedBox(height: footerSpacing),
                  footerWidget!,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A grid of randomly positioned, rotated emojis for share backgrounds.
///
/// Creates a visually interesting but subtle background pattern using
/// emojis with randomized positioning, rotation, opacity, and size.
///
/// Use [randomSeed] for deterministic placement (same seed = same pattern).
class ShareableEmojiBackground extends StatelessWidget {
  const ShareableEmojiBackground({
    super.key,
    required this.emojis,
    this.randomSeed,
    this.columns = 5,
    this.rows = 8,
  });

  /// Emojis to display. Multiple emojis cycle through the grid.
  final List<String> emojis;

  /// Seed for deterministic placement. Null = truly random.
  final int? randomSeed;

  /// Number of columns in the grid.
  final int columns;

  /// Number of rows in the grid.
  final int rows;

  @override
  Widget build(BuildContext context) {
    if (emojis.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(children: _buildEmojis(constraints));
      },
    );
  }

  List<Widget> _buildEmojis(BoxConstraints constraints) {
    final Random random = randomSeed != null ? Random(randomSeed!) : Random();
    final List<Widget> widgets = [];

    final double cellWidth = constraints.maxWidth / columns;
    final double cellHeight = constraints.maxHeight / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        // Random offset within cell (0.1-0.9 to avoid edges)
        final double offsetX = 0.1 + random.nextDouble() * 0.8;
        final double offsetY = 0.1 + random.nextDouble() * 0.8;

        final double left = col * cellWidth + offsetX * cellWidth;
        final double top = row * cellHeight + offsetY * cellHeight;

        // Random rotation (±0.6 radians)
        final double rotation = (random.nextDouble() - 0.5) * 1.2;

        // Random opacity (0.08-0.18 for subtlety)
        final double opacity = 0.08 + random.nextDouble() * 0.1;

        // Random size (14-24px)
        final double size = 14 + random.nextDouble() * 10;

        // Cycle through emojis
        final String emoji = emojis[(row * columns + col) % emojis.length];

        widgets.add(
          Positioned(
            top: top,
            left: left,
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(
                opacity: opacity,
                child: Text(emoji, style: TextStyle(fontSize: size)),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
