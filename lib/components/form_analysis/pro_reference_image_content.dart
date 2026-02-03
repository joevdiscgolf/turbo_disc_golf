import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/form_analysis_shimmer_placeholder.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/services/pro_reference_loader.dart';

/// Renders the pro reference image for a checkpoint.
///
/// Alignment strategy:
/// 1. Normalize all pro images to same size using output.height from metadata
/// 2. Scale to match user's body height (from backend)
/// 3. Position using referenceHorizontalOffsetPercent from backend
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
    this.proPlayerId,
    this.detectedHandedness,
    this.userLandmarks,
    this.cachedImage,
    this.cachedHorizontalOffset,
    this.cachedScale,
    this.isCacheStale = false,
    this.onImageLoaded,
  });

  final CheckpointDataV2 checkpoint;
  final String throwType;
  final CameraAngle cameraAngle;
  final bool showSkeletonOnly;
  final ProReferenceLoader proRefLoader;

  /// Optional pro player ID override. If provided, uses this instead of checkpoint.proPlayerId.
  final String? proPlayerId;

  final Handedness? detectedHandedness;

  /// User's pose landmarks for this checkpoint.
  /// Note: No longer used for alignment (kept for API compatibility).
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
    final String? effectiveProPlayerId =
        proPlayerId ?? checkpoint.proReferencePose?.proPlayerId;

    // No pro reference available
    if (effectiveProPlayerId == null) {
      return const Center(
        child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
      );
    }

    // Use LayoutBuilder to get actual container dimensions (not screen size)
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get actual container dimensions
        double containerWidth = constraints.maxWidth;
        double containerHeight = constraints.maxHeight;

        // Safety fallback for unbounded constraints
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          final Size screenSize = MediaQuery.of(context).size;
          if (!constraints.hasBoundedWidth) {
            containerWidth = screenSize.width;
          }
          if (!constraints.hasBoundedHeight) {
            containerHeight = screenSize.height;
          }
          debugPrint(
            '⚠️ [ProReferenceImageContent] Unbounded constraints, using fallback: '
            '${containerWidth}x$containerHeight',
          );
        }

        return _buildContent(
          context: context,
          proPlayerId: effectiveProPlayerId,
          containerWidth: containerWidth,
          containerHeight: containerHeight,
        );
      },
    );
  }

  /// Builds the main content with proper container dimensions
  Widget _buildContent({
    required BuildContext context,
    required String proPlayerId,
    required double containerWidth,
    required double containerHeight,
  }) {
    debugPrint('[ProReferenceImageContent] Loading image:');
    debugPrint('  - proPlayerId: $proPlayerId');
    debugPrint('  - Checkpoint: ${checkpoint.metadata.checkpointId}');
    debugPrint('  - throwType: $throwType');
    debugPrint('  - cameraAngle: $cameraAngle');
    debugPrint('  - showSkeletonOnly: $showSkeletonOnly');
    debugPrint('  - Container size: ${containerWidth}x$containerHeight');

    // Load both image and metadata concurrently
    return FutureBuilder<ImageProvider>(
      future: _loadImage(proPlayerId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Failed to load pro reference: ${snapshot.error}');
          return const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          );
        }

        // Calculate bounds (can do this before image loads since it only uses user data)
        final _ProImageBounds bounds = _calculateBounds(
          containerWidth: containerWidth,
          containerHeight: containerHeight,
        );

        if (!snapshot.hasData) {
          // While loading: show cached image if available and cache is stale
          if (cachedImage != null && isCacheStale) {
            return _buildPositionedImage(
              imageProvider: cachedImage!,
              bounds: bounds,
            );
          }
          return const FormAnalysisShimmerPlaceholder();
        }

        final ImageProvider imageProvider = snapshot.data!;

        // Notify parent to cache (using box height ratio for compatibility)
        onImageLoaded?.call(
          imageProvider,
          bounds.left,
          bounds.height / containerHeight,
        );

        return _buildPositionedImage(
          imageProvider: imageProvider,
          bounds: bounds,
        );
      },
    );
  }

  /// Loads the reference image
  Future<ImageProvider> _loadImage(String proPlayerId) {
    return proRefLoader.loadReferenceImage(
      proPlayerId: proPlayerId,
      throwType: throwType,
      checkpoint: checkpoint.metadata.checkpointId,
      isSkeleton: showSkeletonOnly,
      cameraAngle: cameraAngle,
    );
  }

  /// Calculates the bounds (position and size) for the pro reference image box.
  ///
  /// Simple approach:
  /// 1. Box height = user's body height portion × container height
  /// 2. Box is centered at user's body center position
  /// 3. Image renders inside with BoxFit.contain - Flutter handles scaling
  _ProImageBounds _calculateBounds({
    required double containerWidth,
    required double containerHeight,
  }) {
    // Get user's body height as portion of frame (0-1)
    final double userBodyPortion =
        checkpoint.proOverlayAlignment?.userBodyHeightScreenPortion ?? 0.8;

    // Get user's body center position as portion of frame (0-1)
    final double userBodyCenterX =
        checkpoint.proOverlayAlignment?.bodyCenterXScreenPortion ?? 0.5;
    final double userBodyCenterY =
        checkpoint.proOverlayAlignment?.bodyCenterYScreenPortion ?? 0.5;

    // Calculate box dimensions
    // Height matches user's body height portion
    final double boxHeight = userBodyPortion * containerHeight;
    // Width is full container width (image will center itself with BoxFit.contain)
    final double boxWidth = containerWidth;

    // Position box so its center aligns with user's body center
    final double centerX = userBodyCenterX * containerWidth;
    final double centerY = userBodyCenterY * containerHeight;
    final double left = centerX - boxWidth / 2;
    final double top = centerY - boxHeight / 2;

    // Use override proPlayerId if provided, otherwise fall back to checkpoint's proPlayerId
    final String? activeProId =
        proPlayerId ?? checkpoint.proReferencePose?.proPlayerId;

    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🎨 [Alignment] ${checkpoint.metadata.checkpointId} - PRO: $activeProId');
    debugPrint('   Camera angle: $cameraAngle');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('   Container: ${containerWidth.toStringAsFixed(0)}x${containerHeight.toStringAsFixed(0)}');
    debugPrint('   User body portion: ${(userBodyPortion * 100).toStringAsFixed(1)}%');
    debugPrint('   User body center: (${(userBodyCenterX * 100).toStringAsFixed(1)}%, ${(userBodyCenterY * 100).toStringAsFixed(1)}%)');
    debugPrint('   Box size: ${boxWidth.toStringAsFixed(0)}x${boxHeight.toStringAsFixed(0)}');
    debugPrint('   Box position: (${left.toStringAsFixed(0)}, ${top.toStringAsFixed(0)})');
    debugPrint('═══════════════════════════════════════════════════════════');

    return _ProImageBounds(
      left: left,
      top: top,
      width: boxWidth,
      height: boxHeight,
    );
  }

  /// Builds the pro reference image positioned in a box.
  /// Uses a Stack to position a sized box, then renders the image inside with BoxFit.contain.
  Widget _buildPositionedImage({
    required ImageProvider imageProvider,
    required _ProImageBounds bounds,
  }) {
    final bool isLeftHanded = detectedHandedness == Handedness.left;

    // Use fitHeight to ensure all pro images match the box height
    // (body fills 100% of image height, so this normalizes body sizes)
    Widget image = Image(
      image: imageProvider,
      fit: BoxFit.fitHeight,
    );

    if (isLeftHanded) {
      image = Transform.flip(flipX: true, child: image);
    }

    // Use Stack to position a box at the calculated location
    // The image renders with fitHeight - wider images may overflow horizontally
    return Stack(
      clipBehavior: Clip.none, // Allow horizontal overflow for wider images
      children: [
        Positioned(
          left: bounds.left,
          top: bounds.top,
          width: bounds.width,
          height: bounds.height,
          child: image,
        ),
      ],
    );
  }
}

/// Bounds for positioning the pro reference image box.
class _ProImageBounds {
  const _ProImageBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}
