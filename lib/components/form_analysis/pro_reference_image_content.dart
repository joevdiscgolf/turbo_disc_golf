import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/form_analysis_shimmer_placeholder.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/services/pro_reference_loader.dart';

/// Renders the pro reference image for a checkpoint.
///
/// Three-tier loading:
/// 1. `proPlayerId` → FutureBuilder + ProReferenceLoader (new records)
/// 2. Legacy `referenceImageUrl` → CachedNetworkImage
/// 3. Fallback icon
///
/// Supports optional caching to prevent jitter during loading via
/// [cachedImage], [cachedHorizontalOffset], [cachedScale], and [onImageLoaded].
class ProReferenceImageContent extends StatelessWidget {
  const ProReferenceImageContent({
    super.key,
    required this.checkpoint,
    required this.throwType,
    required this.cameraAngle,
    required this.showSkeletonOnly,
    required this.proRefLoader,
    this.detectedHandedness,
    this.cachedImage,
    this.cachedHorizontalOffset,
    this.cachedScale,
    this.isCacheStale = false,
    this.onImageLoaded,
  });

  final CheckpointRecord checkpoint;
  final String throwType;
  final CameraAngle cameraAngle;
  final bool showSkeletonOnly;
  final ProReferenceLoader proRefLoader;
  final Handedness? detectedHandedness;

  /// Cached image for jitter prevention (timeline view only).
  final ImageProvider? cachedImage;
  final double? cachedHorizontalOffset;
  final double? cachedScale;

  /// Whether the cache is stale (different checkpoint/skeleton mode).
  final bool isCacheStale;

  /// Callback when a new image loads, for updating the cache.
  final void Function(ImageProvider image, double horizontalOffset, double scale)?
      onImageLoaded;

  @override
  Widget build(BuildContext context) {
    // New records with proPlayerId: Use hybrid asset loading
    if (checkpoint.proPlayerId != null) {
      debugPrint('[ProReferenceImageContent] Loading image:');
      debugPrint('  - Checkpoint: ${checkpoint.checkpointId}');
      debugPrint('  - throwType: $throwType');
      debugPrint('  - cameraAngle: $cameraAngle');
      debugPrint('  - showSkeletonOnly: $showSkeletonOnly');

      return FutureBuilder<ImageProvider>(
        future: proRefLoader.loadReferenceImage(
          proPlayerId: checkpoint.proPlayerId!,
          throwType: throwType,
          checkpoint: checkpoint.checkpointId,
          isSkeleton: showSkeletonOnly,
          cameraAngle: cameraAngle,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Failed to load pro reference: ${snapshot.error}');
            return const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            );
          }

          if (!snapshot.hasData) {
            // While loading: show cached image if available and cache is stale
            if (cachedImage != null && isCacheStale) {
              return _buildTransformedImage(
                context: context,
                imageProvider: cachedImage!,
                horizontalOffset: cachedHorizontalOffset ?? 0,
                scale: cachedScale ?? 1.0,
              );
            }
            return const FormAnalysisShimmerPlaceholder();
          }

          final double horizontalOffset =
              MediaQuery.of(context).size.width *
              (checkpoint.referenceHorizontalOffsetPercent ?? 0) /
              100;
          final double rawScale = checkpoint.referenceScale ?? 1.0;
          final double scale = rawScale.clamp(0.7, 1.5);

          // Notify parent to cache the loaded image
          onImageLoaded?.call(snapshot.data!, horizontalOffset, scale);

          return _buildTransformedImage(
            context: context,
            imageProvider: snapshot.data!,
            horizontalOffset: horizontalOffset,
            scale: scale,
          );
        },
      );
    }

    // Legacy records with referenceImageUrl: Use CachedNetworkImage
    final String? refImageUrl = showSkeletonOnly
        ? checkpoint.referenceSkeletonUrl
        : checkpoint.referenceImageUrl;

    if (refImageUrl != null && refImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        key: ValueKey(refImageUrl),
        imageUrl: refImageUrl,
        fit: BoxFit.contain,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) =>
            const FormAnalysisShimmerPlaceholder(),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }

    // Fallback: No image available
    return const Center(
      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
    );
  }

  Widget _buildTransformedImage({
    required BuildContext context,
    required ImageProvider imageProvider,
    required double horizontalOffset,
    required double scale,
  }) {
    final bool isLeftHanded = detectedHandedness == Handedness.left;
    final Widget image = Image(image: imageProvider, fit: BoxFit.contain);

    return Transform.translate(
      offset: Offset(horizontalOffset, 0),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: isLeftHanded ? Transform.flip(flipX: true, child: image) : image,
      ),
    );
  }
}
