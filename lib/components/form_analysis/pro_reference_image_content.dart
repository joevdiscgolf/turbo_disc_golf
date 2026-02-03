import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/form_analysis_shimmer_placeholder.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/alignment_metadata.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/user_alignment_metadata.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
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
    this.userAlignment,
    this.heightMultiplier,
    this.additionalVerticalSpace = 0,
    this.cachedImage,
    this.cachedHorizontalOffset,
    this.cachedScale,
    this.isCacheStale = false,
    this.preloadedImage,
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

  /// Optional user alignment metadata override.
  /// When provided, uses this instead of checkpoint.userAlignmentMetadata.
  /// This is used when the checkpoint comes from a pro-specific comparison
  /// which may not have user alignment data.
  final UserAlignmentMetadata? userAlignment;

  /// Optional height multiplier for the pro reference image.
  /// When provided, uses this instead of looking up from feature flags.
  /// Pass this from parent to avoid service lookup during build.
  final double? heightMultiplier;

  /// Additional vertical space to account for when calculating proportions.
  /// Used when the container is smaller due to other UI elements (like a selector)
  /// that should be considered part of the "full" reference area.
  /// The calculation will use (containerHeight + additionalVerticalSpace) for proportions.
  final double additionalVerticalSpace;

  /// Cached image for jitter prevention (timeline view only).
  final ImageProvider? cachedImage;
  final double? cachedHorizontalOffset;
  final double? cachedScale;

  /// Whether the cache is stale (different checkpoint/skeleton mode).
  final bool isCacheStale;

  /// Pre-loaded image for instant rendering (bypasses FutureBuilder async delay).
  /// When provided, renders synchronously without waiting for futures.
  final ImageProvider? preloadedImage;

  /// Callback when a new image loads, for updating the cache.
  final void Function(
    ImageProvider image,
    double horizontalOffset,
    double scale,
  )?
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
    debugPrint('');
    debugPrint(
      '╔═══════════════════════════════════════════════════════════════════',
    );
    debugPrint('║ 🖼️ [ProReferenceImageContent] LOADING IMAGE');
    debugPrint(
      '╠═══════════════════════════════════════════════════════════════════',
    );
    debugPrint('║ Pro Player ID: $proPlayerId');
    debugPrint('║ Checkpoint: ${checkpoint.metadata.checkpointId}');
    debugPrint('║ Throw Type: $throwType');
    debugPrint('║ Camera Angle: $cameraAngle');
    debugPrint('║ Show Skeleton Only: $showSkeletonOnly');
    debugPrint('║ Has Preloaded Image: ${preloadedImage != null}');
    debugPrint(
      '║ Container Size: ${containerWidth.toStringAsFixed(0)}x${containerHeight.toStringAsFixed(0)}',
    );
    debugPrint(
      '╚═══════════════════════════════════════════════════════════════════',
    );

    // Calculate bounds (can do this synchronously since it only uses user data)
    final _ProImageBounds bounds = _calculateBounds(
      containerWidth: containerWidth,
      containerHeight: containerHeight,
    );

    // If we have a preloaded image, render it synchronously (instant switching)
    if (preloadedImage != null) {
      // Notify parent to update cache
      onImageLoaded?.call(
        preloadedImage!,
        bounds.left,
        bounds.height / containerHeight,
      );

      return _buildPositionedImage(
        imageProvider: preloadedImage!,
        bounds: bounds,
      );
    }

    // Fallback to async loading if no preloaded image available
    final Future<ImageProvider> imageFuture = _loadImage(proPlayerId);
    final Future<AlignmentMetadata?> metadataFuture = proRefLoader
        .loadAlignmentMetadata(
          proPlayerId: proPlayerId,
          throwType: throwType,
          cameraAngle: cameraAngle,
        );

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([imageFuture, metadataFuture]),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final AlignmentMetadata? metadata =
              snapshot.data![1] as AlignmentMetadata?;
          _logAlignmentMetadata(proPlayerId, metadata);
        }

        if (snapshot.hasError) {
          debugPrint('Failed to load pro reference: ${snapshot.error}');
          return const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          );
        }

        if (!snapshot.hasData) {
          // While loading: show cached image only if cache is still valid (same checkpoint)
          // If cache is stale (different checkpoint), show shimmer to avoid showing wrong image
          if (cachedImage != null && !isCacheStale) {
            return _buildPositionedImage(
              imageProvider: cachedImage!,
              bounds: bounds,
            );
          }
          return const FormAnalysisShimmerPlaceholder();
        }

        final ImageProvider imageProvider = snapshot.data![0] as ImageProvider;

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

  /// Logs alignment metadata for debugging size differences between pros
  void _logAlignmentMetadata(String proPlayerId, AlignmentMetadata? metadata) {
    final String checkpointId = checkpoint.metadata.checkpointId;

    debugPrint('');
    debugPrint(
      '╔═══════════════════════════════════════════════════════════════════',
    );
    debugPrint('║ 📐 [ALIGNMENT METADATA] PRO: $proPlayerId');
    debugPrint(
      '╠═══════════════════════════════════════════════════════════════════',
    );

    if (metadata == null) {
      debugPrint('║ ⚠️ NO METADATA FOUND!');
      debugPrint('║ This could cause sizing issues - using defaults');
      debugPrint(
        '╚═══════════════════════════════════════════════════════════════════',
      );
      return;
    }

    debugPrint('║ Metadata player: ${metadata.player}');
    debugPrint('║ Metadata throw_type: ${metadata.throwType}');
    debugPrint('║ Metadata camera_angle: ${metadata.cameraAngle}');
    debugPrint(
      '║ Available checkpoints: ${metadata.checkpoints.keys.join(", ")}',
    );
    debugPrint(
      '╠───────────────────────────────────────────────────────────────────',
    );

    final CheckpointAlignmentData? checkpointData =
        metadata.checkpoints[checkpointId];
    if (checkpointData == null) {
      debugPrint('║ ⚠️ NO DATA FOR CHECKPOINT: $checkpointId');
      debugPrint(
        '╚═══════════════════════════════════════════════════════════════════',
      );
      return;
    }

    debugPrint('║ Checkpoint: $checkpointId');
    debugPrint(
      '║ Body Anchor: (${checkpointData.bodyAnchor.x.toStringAsFixed(3)}, ${checkpointData.bodyAnchor.y.toStringAsFixed(3)})',
    );
    if (checkpointData.output != null) {
      debugPrint(
        '║ Output Dimensions: ${checkpointData.output!.width}x${checkpointData.output!.height}',
      );
      debugPrint(
        '║ Aspect Ratio: ${checkpointData.output!.aspectRatio.toStringAsFixed(3)}',
      );
    } else {
      debugPrint('║ Output Dimensions: NOT SET');
    }
    if (checkpointData.torsoHeightNormalized != null) {
      debugPrint(
        '║ Torso Height Normalized: ${(checkpointData.torsoHeightNormalized! * 100).toStringAsFixed(1)}%',
      );
    } else {
      debugPrint('║ Torso Height Normalized: NOT SET');
    }
    debugPrint(
      '╚═══════════════════════════════════════════════════════════════════',
    );

    // Also log user alignment data for comparison
    debugPrint('');
    debugPrint(
      '╔═══════════════════════════════════════════════════════════════════',
    );
    debugPrint('║ 👤 [USER ALIGNMENT]');
    debugPrint(
      '╠═══════════════════════════════════════════════════════════════════',
    );

    // Log what the checkpoint has (might be null for pro-specific checkpoints)
    final UserAlignmentMetadata? checkpointAlignment =
        checkpoint.userAlignmentMetadata;
    debugPrint(
      '║ From checkpoint: ${checkpointAlignment != null ? "✅ HAS DATA" : "❌ NULL"}',
    );

    // Log the override parameter (passed from main analysis checkpoints)
    debugPrint(
      '║ From override param: ${userAlignment != null ? "✅ HAS DATA" : "❌ NULL"}',
    );

    // Determine which one will be used
    final UserAlignmentMetadata? effectiveAlignment =
        userAlignment ?? checkpointAlignment;
    if (effectiveAlignment == null) {
      debugPrint('║ ⚠️ NO USER ALIGNMENT DATA - will use defaults!');
    } else {
      debugPrint(
        '║ Using: ${userAlignment != null ? "OVERRIDE" : "CHECKPOINT"}',
      );
      debugPrint(
        '║ User Body Height Portion: ${(effectiveAlignment.userBodyHeightScreenPortion * 100).toStringAsFixed(1)}%',
      );
      debugPrint(
        '║ Body Center X: ${(effectiveAlignment.bodyCenterXScreenPortion * 100).toStringAsFixed(1)}%',
      );
      debugPrint(
        '║ Body Center Y: ${(effectiveAlignment.bodyCenterYScreenPortion * 100).toStringAsFixed(1)}%',
      );
    }
    debugPrint(
      '╚═══════════════════════════════════════════════════════════════════',
    );
  }

  /// Calculates the bounds (position and size) for the pro reference image box.
  ///
  /// Simple approach:
  /// 1. Box height = user's body height portion × container height × height multiplier
  /// 2. Box is centered at user's body center position
  /// 3. Image renders inside with BoxFit.contain - Flutter handles scaling
  _ProImageBounds _calculateBounds({
    required double containerWidth,
    required double containerHeight,
  }) {
    // Use the override userAlignment if provided, otherwise fall back to checkpoint's data.
    // This is important when viewing pro comparisons where the checkpoint comes from
    // a pro-specific comparison that doesn't have user alignment data.
    final UserAlignmentMetadata? effectiveUserAlignment =
        userAlignment ?? checkpoint.userAlignmentMetadata;

    // Get user's body height as portion of frame (0-1)
    final double userBodyPortion =
        effectiveUserAlignment?.userBodyHeightScreenPortion ?? 0.8;

    // Get user's body center position as portion of frame (0-1)
    final double userBodyCenterX =
        effectiveUserAlignment?.bodyCenterXScreenPortion ?? 0.5;
    final double userBodyCenterY =
        effectiveUserAlignment?.bodyCenterYScreenPortion ?? 0.5;

    // Get height multiplier - use passed value if available, otherwise look up from feature flags
    final double effectiveHeightMultiplier = heightMultiplier ??
        (cameraAngle == CameraAngle.rear
            ? locator.get<FeatureFlagService>().getDouble(
                FeatureFlag.proReferenceHeightMultiplierRear,
              )
            : locator.get<FeatureFlagService>().getDouble(
                FeatureFlag.proReferenceHeightMultiplierSide,
              ));

    // Calculate the "full" height for proportional calculations.
    // This accounts for any additional UI elements (like a selector) that are
    // part of the logical reference area but rendered separately.
    final double fullHeight = containerHeight + additionalVerticalSpace;

    // Calculate box dimensions using full height for proportions
    // Height matches user's body height portion, scaled by multiplier
    double boxHeight = userBodyPortion * fullHeight * effectiveHeightMultiplier;
    // Width is full container width (image will center itself with BoxFit.contain)
    final double boxWidth = containerWidth;

    // CONSTRAINT: Box height must never exceed actual container height
    if (boxHeight > containerHeight) {
      boxHeight = containerHeight;
    }

    // Position box so its center aligns with user's body center
    // Use full height for Y positioning to maintain correct proportions
    final double centerX = userBodyCenterX * containerWidth;
    final double centerY = userBodyCenterY * fullHeight;
    final double left = centerX - boxWidth / 2;
    double top = centerY - boxHeight / 2;

    // CONSTRAINT: Box must stay within container bounds vertically
    // Clamp top so image doesn't go above container
    if (top < 0) {
      top = 0;
    }
    // Clamp top so image doesn't go below container
    if (top + boxHeight > containerHeight) {
      top = containerHeight - boxHeight;
    }
    // Note: Horizontal clamping intentionally omitted to preserve alignment

    // Use override proPlayerId if provided, otherwise fall back to checkpoint's proPlayerId
    final String? activeProId =
        proPlayerId ?? checkpoint.proReferencePose?.proPlayerId;

    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint(
      '🎨 [Alignment] ${checkpoint.metadata.checkpointId} - PRO: $activeProId',
    );
    debugPrint('   Camera angle: $cameraAngle');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint(
      '   Container: ${containerWidth.toStringAsFixed(0)}x${containerHeight.toStringAsFixed(0)}',
    );
    if (additionalVerticalSpace > 0) {
      debugPrint(
        '   Full height (for proportions): ${fullHeight.toStringAsFixed(0)} (+${additionalVerticalSpace.toStringAsFixed(0)} for selector)',
      );
    }
    debugPrint(
      '   User body portion: ${(userBodyPortion * 100).toStringAsFixed(1)}%',
    );
    debugPrint(
      '   Height multiplier: ${effectiveHeightMultiplier.toStringAsFixed(2)}x',
    );
    debugPrint(
      '   User body center: (${(userBodyCenterX * 100).toStringAsFixed(1)}%, ${(userBodyCenterY * 100).toStringAsFixed(1)}%)',
    );
    debugPrint(
      '   Box size: ${boxWidth.toStringAsFixed(0)}x${boxHeight.toStringAsFixed(0)}',
    );
    debugPrint(
      '   Box position: (${left.toStringAsFixed(0)}, ${top.toStringAsFixed(0)})',
    );
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
    Widget image = Image(image: imageProvider, fit: BoxFit.fitHeight);

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
