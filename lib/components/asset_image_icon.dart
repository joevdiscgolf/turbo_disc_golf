import 'package:flutter/material.dart';

/// A generic component for rendering an asset image like an icon.
/// Provides consistent sizing, coloring, and color filtering capabilities.
class AssetImageIcon extends StatelessWidget {
  const AssetImageIcon(
    this.assetPath, {
    super.key,
    this.size = 24,
    this.color,
    this.fit = BoxFit.contain,
  });

  /// Path to the asset image file.
  final String assetPath;

  /// Size of the image (width and height).
  final double size;

  /// Color to apply to the image via ColorFiltered.
  /// If provided, the image will be tinted to this color using BlendMode.srcIn.
  final Color? color;

  /// How the image should fit within the size constraints.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final Widget image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
    );

    if (color != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: image,
      );
    }

    return image;
  }
}
