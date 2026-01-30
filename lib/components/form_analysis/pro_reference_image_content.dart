import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/form_analysis_shimmer_placeholder.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/alignment_metadata.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/services/pro_reference_loader.dart';
import 'package:turbo_disc_golf/utils/landmark_calculations.dart';

/// Renders the pro reference image for a checkpoint.
///
/// Three-tier loading:
/// 1. `proPlayerId` → FutureBuilder + ProReferenceLoader (new records)
/// 2. Legacy `referenceImageUrl` → CachedNetworkImage
/// 3. Fallback icon
///
/// Supports optional caching to prevent jitter during loading via
/// [cachedImage], [cachedHorizontalOffset], [cachedScale], and [onImageLoaded].
///
/// Uses alignment metadata (body anchor points) when available to align
/// pro reference skeleton with user's hip center.
class ProReferenceImageContent extends StatelessWidget {
  const ProReferenceImageContent({
    super.key,
    required this.checkpoint,
    required this.throwType,
    required this.cameraAngle,
    required this.showSkeletonOnly,
    required this.proRefLoader,
    this.proPlayerId,
    this.detectedHandedness,
    this.userLandmarks,
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

  /// Optional pro player ID override. If provided, uses this instead of checkpoint.proPlayerId.
  final String? proPlayerId;

  final Handedness? detectedHandedness;

  /// User's pose landmarks for this checkpoint (used for alignment)
  final List<PoseLandmark>? userLandmarks;

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
    // Use override proPlayerId if provided, otherwise fall back to checkpoint's proPlayerId
    final String? effectiveProPlayerId = proPlayerId ?? checkpoint.proPlayerId;

    // New records with proPlayerId: Use hybrid asset loading
    if (effectiveProPlayerId != null) {
      debugPrint('[ProReferenceImageContent] Loading image:');
      debugPrint('  - proPlayerId: $effectiveProPlayerId');
      debugPrint('  - Checkpoint: ${checkpoint.checkpointId}');
      debugPrint('  - throwType: $throwType');
      debugPrint('  - cameraAngle: $cameraAngle');
      debugPrint('  - showSkeletonOnly: $showSkeletonOnly');

      // Load both image and metadata concurrently
      return FutureBuilder<(ImageProvider, AlignmentMetadata?)>(
        future: _loadImageAndMetadata(effectiveProPlayerId),
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
                verticalOffset: 0,
                scale: cachedScale ?? 1.0,
              );
            }
            return const FormAnalysisShimmerPlaceholder();
          }

          final ImageProvider imageProvider = snapshot.data!.$1;
          final AlignmentMetadata? metadata = snapshot.data!.$2;

          debugPrint('📥 [ProReferenceImageContent] Image and metadata loaded');
          debugPrint('   Metadata loaded: ${metadata != null}');
          if (metadata != null) {
            debugPrint(
                '   Available checkpoints: ${metadata.checkpoints.keys.join(", ")}');
          }

          // Calculate alignment using metadata and user landmarks
          final (double horizontalOffset, double verticalOffset, double scale) =
              _calculateAlignment(context, metadata);

          // Notify parent to cache the loaded image
          onImageLoaded?.call(imageProvider, horizontalOffset, scale);

          return _buildTransformedImage(
            context: context,
            imageProvider: imageProvider,
            horizontalOffset: horizontalOffset,
            verticalOffset: verticalOffset,
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

  /// Loads both the reference image and alignment metadata concurrently
  Future<(ImageProvider, AlignmentMetadata?)> _loadImageAndMetadata(
    String proPlayerId,
  ) async {
    final List<dynamic> results = await Future.wait([
      proRefLoader.loadReferenceImage(
        proPlayerId: proPlayerId,
        throwType: throwType,
        checkpoint: checkpoint.checkpointId,
        isSkeleton: showSkeletonOnly,
        cameraAngle: cameraAngle,
      ),
      proRefLoader.loadAlignmentMetadata(
        proPlayerId: proPlayerId,
        throwType: throwType,
        cameraAngle: cameraAngle,
      ),
    ]);

    return (results[0] as ImageProvider, results[1] as AlignmentMetadata?);
  }

  /// Calculates the alignment offset and scale for the pro reference image
  ///
  /// Returns (horizontalOffset, verticalOffset, scale)
  ///
  /// If alignment metadata and user landmarks are available:
  /// - Uses body_anchor from metadata to align with user's hip center
  /// - Uses backend-provided reference_scale
  /// - Accounts for BoxFit.contain positioning using output dimensions
  /// - Calculates both X and Y offsets
  ///
  /// Otherwise falls back to backend-provided values:
  /// - referenceHorizontalOffsetPercent
  /// - referenceScale
  /// - No vertical offset
  (double, double, double) _calculateAlignment(
    BuildContext context,
    AlignmentMetadata? metadata,
  ) {
    final double containerWidth = MediaQuery.of(context).size.width;
    final double containerHeight = MediaQuery.of(context).size.height;

    // Use backend-provided scale (already calculated based on torso height)
    final double rawScale = checkpoint.referenceScale ?? 1.0;
    final double scale = rawScale.clamp(0.3, 2.0);

    // Get effective landmarks: explicit parameter first, then checkpoint's stored landmarks
    final List<PoseLandmark>? effectiveLandmarks =
        userLandmarks ?? checkpoint.userLandmarks;

    debugPrint(
        '🎨 [ProReferenceImageContent] Calculating alignment for ${checkpoint.checkpointId}');
    debugPrint('   Metadata available: ${metadata != null}');
    debugPrint('   User landmarks available: ${effectiveLandmarks != null}');
    debugPrint('   Container size: ${containerWidth}x$containerHeight');
    debugPrint('   Reference scale: $scale');

    // Try to use alignment metadata if available
    if (metadata != null && effectiveLandmarks != null) {
      final CheckpointAlignmentData? alignmentData =
          metadata.checkpoints[checkpoint.checkpointId];

      debugPrint(
          '   Alignment data for checkpoint: ${alignmentData != null}');

      if (alignmentData != null) {
        // Calculate user's hip center from landmarks
        final (double, double)? userHipCenter =
            LandmarkCalculations.calculateHipCenter(effectiveLandmarks);

        debugPrint('   User hip center calculated: ${userHipCenter != null}');
        debugPrint(
            '   Output dimensions available: ${alignmentData.output != null}');

        if (userHipCenter != null) {
          final double userHipX = userHipCenter.$1;
          final BodyAnchor bodyAnchor = alignmentData.bodyAnchor;

          // User's hip X position in container pixels (for horizontal alignment)
          final double targetX = userHipX * containerWidth;

          // Calculate where the image is displayed with BoxFit.contain
          double displayedWidth;
          double displayedHeight;
          double imageOffsetX;
          double imageOffsetY;

          if (alignmentData.output != null) {
            // Use actual image dimensions for precise BoxFit.contain calculation
            final double imageAspectRatio = alignmentData.output!.aspectRatio;
            final double containerAspectRatio =
                containerWidth / containerHeight;

            debugPrint(
                '   Image dimensions: ${alignmentData.output!.width}x${alignmentData.output!.height}');
            debugPrint('   Image aspect ratio: $imageAspectRatio');
            debugPrint('   Container aspect ratio: $containerAspectRatio');

            if (imageAspectRatio > containerAspectRatio) {
              // Image is wider than container - constrained by width
              displayedWidth = containerWidth;
              displayedHeight = containerWidth / imageAspectRatio;
              imageOffsetX = 0;
              imageOffsetY = (containerHeight - displayedHeight) / 2;
            } else {
              // Image is taller than container - constrained by height
              displayedHeight = containerHeight;
              displayedWidth = containerHeight * imageAspectRatio;
              imageOffsetX = (containerWidth - displayedWidth) / 2;
              imageOffsetY = 0;
            }
          } else {
            // Fallback: assume image fills container
            displayedWidth = containerWidth;
            displayedHeight = containerHeight;
            imageOffsetX = 0;
            imageOffsetY = 0;
          }

          debugPrint(
              '   Displayed image size: ${displayedWidth.toStringAsFixed(1)}x${displayedHeight.toStringAsFixed(1)}');
          debugPrint(
              '   Image offset in container: (${imageOffsetX.toStringAsFixed(1)}, ${imageOffsetY.toStringAsFixed(1)})');

          // Body anchor position in container coordinates (before Transform.scale)
          // bodyAnchor is normalized (0-1) within the image
          final double anchorXInContainer =
              imageOffsetX + bodyAnchor.x * displayedWidth;
          final double anchorYInContainer =
              imageOffsetY + bodyAnchor.y * displayedHeight;

          // Container center (Transform.scale uses Alignment.center)
          final double centerX = containerWidth / 2;
          final double centerY = containerHeight / 2;

          // Body anchor X position AFTER scaling around container center
          // Formula: new_pos = center + (old_pos - center) * scale
          final double anchorXAfterScale =
              centerX + (anchorXInContainer - centerX) * scale;

          // Offset to move scaled anchor to user's hip position
          // Only apply horizontal offset - vertical alignment doesn't make sense
          // since user video and pro reference are in separate containers
          final double offsetX = targetX - anchorXAfterScale;
          // Keep pro image vertically centered (don't try to match absolute Y position)
          const double offsetY = 0.0;

          debugPrint('✅ [ProReferenceImageContent] Using alignment metadata:');
          debugPrint('   User hip X (normalized): $userHipX');
          debugPrint('   User hip target X (pixels): $targetX');
          debugPrint(
              '   Body anchor (normalized): (${bodyAnchor.x}, ${bodyAnchor.y})');
          debugPrint(
              '   Body anchor in container (before scale): (${anchorXInContainer.toStringAsFixed(1)}, ${anchorYInContainer.toStringAsFixed(1)})');
          debugPrint('   Container center: ($centerX, $centerY)');
          debugPrint(
              '   Body anchor after scale X: ${anchorXAfterScale.toStringAsFixed(1)}');
          debugPrint(
              '   Calculated offset X: ${offsetX.toStringAsFixed(1)} (Y forced to 0)');

          return (offsetX, offsetY, scale);
        }
      }
    }

    // Fallback to backend-provided horizontal offset (current behavior)
    final double horizontalOffset = containerWidth *
        (checkpoint.referenceHorizontalOffsetPercent ?? 0) /
        100;

    debugPrint('⚠️ [ProReferenceImageContent] Using fallback alignment');
    debugPrint('   Reason: ${metadata == null ? 'No metadata' : effectiveLandmarks == null ? 'No landmarks' : 'No alignment data for checkpoint'}');
    debugPrint('   Horizontal offset: $horizontalOffset');
    debugPrint('   Vertical offset: 0');

    return (horizontalOffset, 0, scale);
  }

  Widget _buildTransformedImage({
    required BuildContext context,
    required ImageProvider imageProvider,
    required double horizontalOffset,
    required double verticalOffset,
    required double scale,
  }) {
    final bool isLeftHanded = detectedHandedness == Handedness.left;
    final Widget image = Image(image: imageProvider, fit: BoxFit.contain);

    return Transform.translate(
      offset: Offset(horizontalOffset, verticalOffset),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: isLeftHanded ? Transform.flip(flipX: true, child: image) : image,
      ),
    );
  }
}
