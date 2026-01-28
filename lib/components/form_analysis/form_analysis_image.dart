import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/form_analysis_shimmer_placeholder.dart';

/// Smart image widget that handles both base64 data URLs and network URLs.
///
/// - Data URLs (`data:image/...`) are decoded and displayed via `Image.memory`
/// - Network URLs are displayed via `CachedNetworkImage`
class FormAnalysisImage extends StatelessWidget {
  const FormAnalysisImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    // Base64 data URL
    if (imageUrl.startsWith('data:image')) {
      try {
        final String base64String = imageUrl.split(',')[1];
        final Uint8List imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            );
          },
        );
      } catch (e) {
        return const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        );
      }
    }

    // Network URL via CachedNetworkImage
    return CachedNetworkImage(
      key: ValueKey(imageUrl),
      imageUrl: imageUrl,
      fit: fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) =>
          const FormAnalysisShimmerPlaceholder(),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }
}
