import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:intl/intl.dart';

import 'package:turbo_disc_golf/components/form_analysis/severity_badge.dart';
import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/components/form_analysis/synchronized_video_player.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/video_orientation.dart';
import 'package:turbo_disc_golf/services/pro_reference_loader.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/form_analysis_video_helper.dart';

/// View for displaying a historical form analysis from Firestore.
class HistoryAnalysisView extends StatefulWidget {
  const HistoryAnalysisView({
    super.key,
    required this.analysis,
    required this.onBack,
    this.topPadding = 0,
    this.videoUrl,
    this.throwType,
    this.cameraAngle,
    this.videoAspectRatio,
    this.poseAnalysisResponse,
  });

  final FormAnalysisRecord analysis;
  final VoidCallback onBack;
  final double topPadding;

  /// Optional: URL of user's form video for video comparison feature
  final String? videoUrl;

  /// Optional: Throw type for selecting correct pro reference video
  final ThrowTechnique? throwType;

  /// Optional: Camera angle for selecting correct pro reference video
  final CameraAngle? cameraAngle;

  /// Optional: Video aspect ratio for layout decisions (width/height)
  /// Examples: 0.5625 for 9:16 portrait, 1.778 for 16:9 landscape
  final double? videoAspectRatio;

  /// Optional: Full pose analysis response with video sync metadata
  /// Required for video synchronization to work properly
  final PoseAnalysisResponse? poseAnalysisResponse;

  @override
  State<HistoryAnalysisView> createState() => _HistoryAnalysisViewState();
}

class _HistoryAnalysisViewState extends State<HistoryAnalysisView> {
  int _selectedCheckpointIndex = 0;
  bool _showSkeletonOnly = false;
  final ProReferenceLoader _proRefLoader = ProReferenceLoader();

  @override
  void initState() {
    super.initState();

    // Debug log video sync metadata from both sources
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('[HistoryAnalysisView] 🎬 VIDEO SYNC METADATA DEBUG');
    debugPrint('[HistoryAnalysisView] Analysis ID: ${widget.analysis.id}');

    // Check FormAnalysisRecord (loaded from Firestore)
    debugPrint('[HistoryAnalysisView] From FormAnalysisRecord:');
    if (widget.analysis.videoSyncMetadata != null) {
      final metadata = widget.analysis.videoSyncMetadata!;
      debugPrint('[HistoryAnalysisView]   ✅ videoSyncMetadata EXISTS');
      debugPrint(
        '[HistoryAnalysisView]   - Pro speed multiplier: ${metadata.proPlaybackSpeedMultiplier}x',
      );
      debugPrint(
        '[HistoryAnalysisView]   - Checkpoint sync points: ${metadata.checkpointSyncPoints.length}',
      );
    } else {
      debugPrint(
        '[HistoryAnalysisView]   ❌ videoSyncMetadata is NULL (not saved to Firestore)',
      );
    }

    // Check PoseAnalysisResponse (if provided)
    debugPrint('[HistoryAnalysisView] From PoseAnalysisResponse:');
    if (widget.poseAnalysisResponse?.videoSyncMetadata != null) {
      final metadata = widget.poseAnalysisResponse!.videoSyncMetadata!;
      debugPrint('[HistoryAnalysisView]   ✅ videoSyncMetadata EXISTS');
      debugPrint(
        '[HistoryAnalysisView]   - Pro speed multiplier: ${metadata.proPlaybackSpeedMultiplier}x',
      );
      debugPrint(
        '[HistoryAnalysisView]   - Checkpoint sync points: ${metadata.checkpointSyncPoints.length}',
      );
    } else {
      debugPrint(
        '[HistoryAnalysisView]   ${widget.poseAnalysisResponse == null ? "⏭️  PoseAnalysisResponse not provided" : "❌ videoSyncMetadata is NULL"}',
      );
    }
    debugPrint('═══════════════════════════════════════════════════════');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverPadding(padding: EdgeInsets.only(top: widget.topPadding)),
            SliverToBoxAdapter(child: _buildHeader(context)),
            if (locator
                .get<FeatureFlagService>()
                .showFormAnalysisVideoComparison)
              _buildVideoComparisonSliver(),
            SliverToBoxAdapter(child: _buildCheckpointSelector(context)),
            SliverToBoxAdapter(child: _buildComparisonCard(context)),
            SliverToBoxAdapter(child: _buildAngleDeviations(context)),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
        _buildFloatingViewToggle(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final DateTime createdAt = DateTime.parse(widget.analysis.createdAt);
    final String formattedDateTime = DateFormat(
      'EEEE, MMM d \'at\' h:mm a',
    ).format(createdAt);
    final bool isBackhand =
        widget.analysis.throwType.toLowerCase() == 'backhand';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildThrowTypeBadge(isBackhand),
                    if (widget.analysis.cameraAngle != null) ...[
                      const SizedBox(width: 8),
                      _buildCameraAngleBadge(widget.analysis.cameraAngle!),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  formattedDateTime,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoComparisonSliver() {
    // Check if we have all required data for video comparison
    if (widget.videoUrl == null ||
        widget.videoUrl!.isEmpty ||
        widget.throwType == null ||
        widget.cameraAngle == null) {
      // Return empty sliver if data missing
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    try {
      // Get the correct pro reference video path
      final String proVideoPath = getProReferenceVideoPath(
        throwType: widget.throwType!,
        cameraAngle: widget.cameraAngle!,
      );

      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SynchronizedVideoPlayer(
            userVideoUrl: widget.videoUrl!,
            proVideoAssetPath: proVideoPath,
            videoSyncMetadata:
                widget.poseAnalysisResponse?.videoSyncMetadata ??
                widget.analysis.videoSyncMetadata,
            videoAspectRatio: widget.videoAspectRatio,
          ),
        ),
      );
    } catch (e) {
      // If pro video not supported (e.g., forehand), show informative message
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Video comparison not yet available for this throw type.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildThrowTypeBadge(bool isBackhand) {
    final Color color1 = isBackhand
        ? const Color(0xFF5E35B1)
        : const Color(0xFFFF6F00);
    final Color color2 = isBackhand
        ? const Color(0xFF7E57C2)
        : const Color(0xFFFF8F00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        isBackhand ? 'Backhand' : 'Forehand',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCameraAngleBadge(CameraAngle cameraAngle) {
    final bool isSideView = cameraAngle == CameraAngle.side;
    final Color color1 = isSideView
        ? const Color(0xFF1976D2)
        : const Color(0xFF00897B);
    final Color color2 = isSideView
        ? const Color(0xFF2196F3)
        : const Color(0xFF26A69A);
    final IconData icon = isSideView ? Icons.photo_camera : Icons.videocam;
    final String label = isSideView ? 'Side' : 'Rear';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingViewToggle() {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 112,
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD8B4FE), Color(0xFFC084FC)],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9333EA).withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Animated slider background
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: _showSkeletonOnly
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 52,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              // Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewToggleButton(
                    icon: Icons.videocam_outlined,
                    isSelected: !_showSkeletonOnly,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showSkeletonOnly = false);
                    },
                  ),
                  _buildViewToggleButton(
                    icon: Icons.accessibility_new,
                    isSelected: _showSkeletonOnly,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showSkeletonOnly = true);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 52,
        height: 44,
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: isSelected ? Colors.white : const Color(0xFF6B21B6),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckpointSelector(BuildContext context) {
    final int checkpointCount = widget.analysis.checkpoints.length;
    if (checkpointCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: List.generate(checkpointCount, (index) {
          return Expanded(
            child: _buildTabSegment(
              _formatChipLabel(
                widget.analysis.checkpoints[index].checkpointName,
              ),
              index == _selectedCheckpointIndex,
              () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCheckpointIndex = index);
              },
              isFirst: index == 0,
              isLast: index == checkpointCount - 1,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabSegment(
    String name,
    bool isSelected,
    VoidCallback onTap, {
    required bool isFirst,
    required bool isLast,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B5CF6), Color(0xFF6B4EFF)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(11) : Radius.zero,
            bottomLeft: isFirst ? const Radius.circular(11) : Radius.zero,
            topRight: isLast ? const Radius.circular(11) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(11) : Radius.zero,
          ),
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _formatChipLabel(String name) {
    return name.replaceAll(' Position', '').replaceAll(' position', '').trim();
  }

  Widget _buildComparisonCard(BuildContext context) {
    if (widget.analysis.checkpoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final CheckpointRecord checkpoint =
        widget.analysis.checkpoints[_selectedCheckpointIndex];

    // Use smaller horizontal padding for portrait mode
    final bool isPortrait =
        widget.analysis.videoOrientation == VideoOrientation.portrait;
    final double horizontalPadding = isPortrait ? 8.0 : 16.0;

    return GestureDetector(
      onTap: () => _showFullscreenComparison(checkpoint),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0.0), Colors.white],
            stops: const [0.0, 0.25],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _buildImageComparison(checkpoint),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[200]),
            _buildCheckpointDetailsButton(context, checkpoint),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckpointDetailsButton(
    BuildContext context,
    CheckpointRecord checkpoint,
  ) {
    // Get first 3 coaching tips
    final List<String> topTips = checkpoint.coachingTips.take(3).toList();

    return GestureDetector(
      onTap: () => _showCheckpointDetailsPanel(context, checkpoint),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checkpoint.checkpointName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (topTips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...topTips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(color: Color(0xFF137e66)),
                            ),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    checkpoint.coachingTips.length > 3
                        ? 'View all ${checkpoint.coachingTips.length} tips'
                        : 'View details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckpointDetailsPanel(
    BuildContext context,
    CheckpointRecord checkpoint,
  ) {
    EducationPanel.show(
      context,
      title: checkpoint.checkpointName,
      modalName: 'Checkpoint Details',
      accentColor: const Color(0xFF137e66),
      buttonLabel: 'Done',
      contentBuilder: (_) => _CheckpointDetailsContent(checkpoint: checkpoint),
    );
  }

  Widget _buildImageComparison(CheckpointRecord checkpoint) {
    // Select image URLs based on view mode
    final String? userImageUrl = _showSkeletonOnly
        ? checkpoint.userSkeletonUrl
        : checkpoint.userImageUrl;

    // Check if video is portrait orientation
    final bool isPortrait =
        widget.analysis.videoOrientation == VideoOrientation.portrait;

    // Portrait: side-by-side layout
    if (isPortrait) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildLabeledImage(
              label: 'Your Form',
              imageUrl: userImageUrl,
              showArrow: false,
              onTap: () => _showFullscreenComparison(checkpoint),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildProReferenceImage(
              checkpoint: checkpoint,
              onTap: () => _showFullscreenComparison(checkpoint),
            ),
          ),
        ],
      );
    }

    // Landscape: vertical stack layout (default)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledImage(
          label: 'Your Form',
          imageUrl: userImageUrl,
          showArrow: true,
          onTap: () => _showFullscreenComparison(checkpoint),
        ),
        const SizedBox(height: 12),
        _buildProReferenceImage(
          checkpoint: checkpoint,
          onTap: () => _showFullscreenComparison(checkpoint),
        ),
      ],
    );
  }

  Widget _buildProReferenceImage({
    required CheckpointRecord checkpoint,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Pro Reference',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SenseiColors.darkGray,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.black,
              child: _buildProReferenceImageContent(checkpoint),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProReferenceImageContent(CheckpointRecord checkpoint) {
    // New records with proPlayerId: Use hybrid asset loading
    if (checkpoint.proPlayerId != null) {
      return FutureBuilder<ImageProvider>(
        future: _proRefLoader.loadReferenceImage(
          proPlayerId: checkpoint.proPlayerId!,
          throwType: widget.analysis.throwType,
          checkpoint: checkpoint.checkpointId,
          isSkeleton: _showSkeletonOnly,
          cameraAngle: widget.analysis.cameraAngle ?? CameraAngle.side,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Failed to load pro reference: ${snapshot.error}');
            return const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            );
          }

          if (!snapshot.hasData) {
            return Container(
                  color: Colors.grey[900],
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey[800]!,
                          Colors.grey[700]!,
                          Colors.grey[800]!,
                        ],
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                );
          }

          // Apply alignment transformation (translate + scale)
          final double horizontalOffset =
              MediaQuery.of(context).size.width *
              (checkpoint.referenceHorizontalOffsetPercent ?? 0) /
              100;

          // WORKAROUND: Clamp scale to prevent backend bugs from making pro reference too small/large
          final double rawScale = checkpoint.referenceScale ?? 1.0;
          final double scale = rawScale.clamp(0.7, 1.5);

          if (rawScale != scale) {
            debugPrint('⚠️  [HistoryAnalysisView] Backend scale out of range!');
            debugPrint('   - Backend returned: $rawScale');
            debugPrint('   - Clamped to: $scale');
            debugPrint('   - Expected range: 0.7 - 1.3');
            debugPrint('   - THIS IS A BACKEND BUG - PLEASE FIX!');
          }

          debugPrint('🎯 [HistoryAnalysisView] Rendering pro reference:');
          debugPrint('   - Checkpoint: ${checkpoint.checkpointName}');
          debugPrint(
            '   - referenceScale from backend: ${checkpoint.referenceScale}',
          );
          debugPrint('   - Applied scale: $scale');
          debugPrint(
            '   - referenceHorizontalOffsetPercent: ${checkpoint.referenceHorizontalOffsetPercent}',
          );
          debugPrint(
            '   - Calculated horizontalOffset (pixels): $horizontalOffset',
          );
          debugPrint('   - Screen width: ${MediaQuery.of(context).size.width}');

          return Transform.translate(
            offset: Offset(horizontalOffset, 0),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: Image(image: snapshot.data!, fit: BoxFit.contain),
            ),
          );
        },
      );
    }

    // Legacy records with referenceImageUrl: Use CachedNetworkImage
    final String? refImageUrl = _showSkeletonOnly
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
            Container(
                  color: Colors.grey[900],
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey[800]!,
                          Colors.grey[700]!,
                          Colors.grey[800]!,
                        ],
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
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

  void _showFullscreenComparison(CheckpointRecord checkpoint) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      useSafeArea: false,
      builder: (dialogContext) => _FullscreenComparisonDialog(
        checkpoints: widget.analysis.checkpoints,
        throwType: widget.analysis.throwType,
        proRefLoader: _proRefLoader,
        initialIndex: _selectedCheckpointIndex,
        showSkeletonOnly: _showSkeletonOnly,
        cameraAngle: widget.analysis.cameraAngle ?? CameraAngle.side,
        videoOrientation: widget.analysis.videoOrientation,
        onToggleMode: (bool newMode) {
          setState(() => _showSkeletonOnly = newMode);
        },
        onIndexChanged: (int newIndex) {
          setState(() => _selectedCheckpointIndex = newIndex);
        },
      ),
    );
  }

  Widget _buildLabeledImage({
    required String label,
    required String? imageUrl,
    required bool showArrow,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SenseiColors.darkGray,
                ),
              ),
              const Spacer(),
              if (showArrow)
                Icon(
                  FlutterRemix.arrow_right_s_line,
                  size: 20,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.black,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? _buildImageWidget(imageUrl, BoxFit.cover)
                  : const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAngleDeviations(BuildContext context) {
    if (widget.analysis.checkpoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final CheckpointRecord checkpoint =
        widget.analysis.checkpoints[_selectedCheckpointIndex];

    // Convert angleDeviations map to List<AngleDeviation> format
    final List<AngleDeviation> deviations = _convertAngleDeviationsToList(
      checkpoint,
    );

    if (deviations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Angle Analysis',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...deviations.map((deviation) {
            // For knee_bend, add back leg detail if available
            if (deviation.angleName == 'knee_bend') {
              return _buildKneeDeviationWithBackLegDetail(
                context,
                deviation,
                checkpoint,
              );
            }
            // Other angles use existing row
            return _buildDeviationRow(context, deviation);
          }),
        ],
      ),
    );
  }

  List<AngleDeviation> _convertAngleDeviationsToList(
    CheckpointRecord checkpoint,
  ) {
    final List<AngleDeviation> deviations = [];
    final Map<String, double>? angleDeviations = checkpoint.angleDeviations;

    if (angleDeviations == null) return deviations;

    // For each angle deviation, we need to look up the user and reference values
    // Since we don't have them stored separately in the old format, we'll calculate them
    angleDeviations.forEach((angleName, deviationValue) {
      // We can't get the exact user and reference values from the old format
      // So we'll just show a simplified version
      deviations.add(
        AngleDeviation(
          angleName: angleName,
          userValue: 0, // Not available in old format
          referenceValue: 0, // Not available in old format
          deviation: deviationValue,
          withinTolerance: deviationValue.abs() < 10,
        ),
      );
    });

    return deviations;
  }

  Widget _buildDeviationRow(BuildContext context, AngleDeviation deviation) {
    final bool isGood = deviation.withinTolerance;
    final Color statusColor = isGood
        ? const Color(0xFF4CAF50)
        : (deviation.deviation != null && deviation.deviation!.abs() > 20)
        ? const Color(0xFFF44336)
        : const Color(0xFFFF9800);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isGood ? Icons.check : Icons.warning_amber,
              size: 18,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatAngleName(deviation.angleName),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (deviation.userValue != 0 && deviation.referenceValue != 0)
                  Text(
                    'You: ${deviation.userValue.toStringAsFixed(0)}° • '
                    'Pro: ${deviation.referenceValue?.toStringAsFixed(0) ?? '--'}°',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          if (deviation.deviation != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Text(
                '${deviation.deviation! >= 0 ? '+' : ''}${deviation.deviation!.toStringAsFixed(1)}°',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKneeDeviationWithBackLegDetail(
    BuildContext context,
    AngleDeviation deviation,
    CheckpointRecord checkpoint,
  ) {
    return Column(
      children: [
        // Existing aggregate knee bend row
        _buildDeviationRow(context, deviation),

        // Add back leg (left knee) detail if available
        if (checkpoint.userIndividualAngles?.leftKneeBendAngle != null) ...[
          const SizedBox(height: 6),
          _buildBackLegKneeDetail(context, checkpoint),
        ],
      ],
    );
  }

  Widget _buildBackLegKneeDetail(
    BuildContext context,
    CheckpointRecord checkpoint,
  ) {
    final double? userLeftKnee =
        checkpoint.userIndividualAngles?.leftKneeBendAngle;
    final double? refLeftKnee =
        checkpoint.referenceIndividualAngles?.leftKneeBendAngle;
    final double? deviation =
        checkpoint.individualDeviations?.leftKneeBendAngle;

    if (userLeftKnee == null) return const SizedBox.shrink();

    final Color deviationColor = _getDeviationColor(deviation?.abs());
    final String deviationText = deviation != null
        ? '${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(1)}°'
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(left: 16, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          // Back leg label
          Expanded(
            flex: 2,
            child: Text(
              'Back Leg (Left)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // User angle
          Text(
            '${userLeftKnee.toStringAsFixed(1)}°',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),

          // "vs" separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'vs',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),

          // Reference angle
          Text(
            refLeftKnee != null ? '${refLeftKnee.toStringAsFixed(1)}°' : 'N/A',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(width: 12),

          // Deviation badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: deviationColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: deviationColor, width: 1),
            ),
            child: Text(
              deviationText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: deviationColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDeviationColor(double? deviationAbs) {
    if (deviationAbs == null) return Colors.grey;

    if (deviationAbs < 5) return Colors.green; // Excellent
    if (deviationAbs < 15) return Colors.lightGreen; // Good
    if (deviationAbs < 20) return Colors.orange; // Moderate
    return Colors.red; // Significant
  }

  String _formatAngleName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : word,
        )
        .join(' ');
  }

  Widget _buildImageWidget(String imageUrl, BoxFit fit) {
    // Check if it's a data URL (base64)
    if (imageUrl.startsWith('data:image')) {
      try {
        // Extract base64 data from data URL
        final String base64String = imageUrl.split(',')[1];
        final Uint8List imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          fit: fit,
          width: double.infinity,
          height: 200,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            );
          },
        );
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        );
      }
    }

    // Otherwise use CachedNetworkImage for Cloud Storage URLs
    return CachedNetworkImage(
      key: ValueKey(imageUrl),
      imageUrl: imageUrl,
      fit: fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) =>
          Container(
                color: Colors.grey[900],
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[700]!,
                        Colors.grey[800]!,
                      ],
                    ),
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1500.ms,
                color: Colors.white.withValues(alpha: 0.3),
              ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }
}

/// Fullscreen dialog for comparing user form to pro reference with PageView.
class _FullscreenComparisonDialog extends StatefulWidget {
  const _FullscreenComparisonDialog({
    required this.checkpoints,
    required this.throwType,
    required this.proRefLoader,
    required this.initialIndex,
    required this.showSkeletonOnly,
    required this.onToggleMode,
    required this.onIndexChanged,
    required this.cameraAngle,
    this.videoOrientation,
  });

  final List<CheckpointRecord> checkpoints;
  final String throwType;
  final ProReferenceLoader proRefLoader;
  final int initialIndex;
  final bool showSkeletonOnly;
  final ValueChanged<bool> onToggleMode;
  final ValueChanged<int> onIndexChanged;
  final CameraAngle cameraAngle;
  final VideoOrientation? videoOrientation;

  @override
  State<_FullscreenComparisonDialog> createState() =>
      _FullscreenComparisonDialogState();
}

class _FullscreenComparisonDialogState
    extends State<_FullscreenComparisonDialog> {
  late PageController _pageController;
  late int _currentIndex;
  late bool _showSkeletonOnly;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _showSkeletonOnly = widget.showSkeletonOnly;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.checkpoints.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final CheckpointRecord currentCheckpoint =
        widget.checkpoints[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentCheckpoint.checkpointName,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        actions: [_buildToggleButton()],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.checkpoints.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                widget.onIndexChanged(index);
              },
              itemBuilder: (context, index) {
                return _buildCheckpointPage(widget.checkpoints[index]);
              },
            ),
            // Navigation arrows
            if (_currentIndex > 0)
              _buildNavigationArrow(isLeft: true, onTap: _goToPrevious),
            if (_currentIndex < widget.checkpoints.length - 1)
              _buildNavigationArrow(isLeft: false, onTap: _goToNext),
            // Page indicator
            if (widget.checkpoints.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: _buildPageIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _showSkeletonOnly
                ? () {
                    setState(() => _showSkeletonOnly = false);
                    widget.onToggleMode(false);
                  }
                : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: !_showSkeletonOnly
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Opacity(
                  opacity: !_showSkeletonOnly ? 1.0 : 0.5,
                  child: const Text('📹', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: !_showSkeletonOnly
                ? () {
                    setState(() => _showSkeletonOnly = true);
                    widget.onToggleMode(true);
                  }
                : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _showSkeletonOnly
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Opacity(
                  opacity: _showSkeletonOnly ? 1.0 : 0.5,
                  child: const Text('💀', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationArrow({
    required bool isLeft,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: isLeft ? 8 : null,
      right: isLeft ? null : 8,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLeft ? Icons.chevron_left : Icons.chevron_right,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.checkpoints.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentIndex
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckpointPage(CheckpointRecord checkpoint) {
    final String? userImageUrl = _showSkeletonOnly
        ? checkpoint.userSkeletonUrl
        : checkpoint.userImageUrl;

    // Check if video is portrait orientation
    final bool isPortrait =
        widget.videoOrientation == VideoOrientation.portrait;

    // Portrait: side-by-side layout
    if (isPortrait) {
      return Row(
        children: [
          Expanded(child: _buildFullscreenPanel('Your Form', userImageUrl)),
          const SizedBox(width: 4),
          Expanded(child: _buildFullscreenProReferencePanel(checkpoint)),
        ],
      );
    }

    // Landscape: vertical stack layout (default)
    return Column(
      children: [
        Expanded(child: _buildFullscreenPanel('Your Form', userImageUrl)),
        Container(height: 2, color: Colors.grey[800]),
        Expanded(child: _buildFullscreenProReferencePanel(checkpoint)),
      ],
    );
  }

  Widget _buildFullscreenProReferencePanel(CheckpointRecord checkpoint) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Pro Reference',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: _buildFullscreenProReferenceContent(checkpoint),
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenProReferenceContent(CheckpointRecord checkpoint) {
    // New records with proPlayerId: Use hybrid asset loading
    if (checkpoint.proPlayerId != null) {
      return FutureBuilder<ImageProvider>(
        future: widget.proRefLoader.loadReferenceImage(
          proPlayerId: checkpoint.proPlayerId!,
          throwType: widget.throwType,
          checkpoint: checkpoint.checkpointId,
          isSkeleton: _showSkeletonOnly,
          cameraAngle: widget.cameraAngle,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Failed to load pro reference: ${snapshot.error}');
            return const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            );
          }

          if (!snapshot.hasData) {
            return Container(
                  color: Colors.grey[900],
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey[800]!,
                          Colors.grey[700]!,
                          Colors.grey[800]!,
                        ],
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                );
          }

          // Apply alignment transformation (translate + scale)
          final double horizontalOffset =
              MediaQuery.of(context).size.width *
              (checkpoint.referenceHorizontalOffsetPercent ?? 0) /
              100;

          // WORKAROUND: Clamp scale to prevent backend bugs from making pro reference too small/large
          final double rawScale = checkpoint.referenceScale ?? 1.0;
          final double scale = rawScale.clamp(0.7, 1.5);

          if (rawScale != scale) {
            debugPrint('⚠️  [HistoryAnalysisView] Backend scale out of range!');
            debugPrint('   - Backend returned: $rawScale');
            debugPrint('   - Clamped to: $scale');
            debugPrint('   - Expected range: 0.7 - 1.3');
            debugPrint('   - THIS IS A BACKEND BUG - PLEASE FIX!');
          }

          debugPrint('🎯 [HistoryAnalysisView] Rendering pro reference:');
          debugPrint('   - Checkpoint: ${checkpoint.checkpointName}');
          debugPrint(
            '   - referenceScale from backend: ${checkpoint.referenceScale}',
          );
          debugPrint('   - Applied scale: $scale');
          debugPrint(
            '   - referenceHorizontalOffsetPercent: ${checkpoint.referenceHorizontalOffsetPercent}',
          );
          debugPrint(
            '   - Calculated horizontalOffset (pixels): $horizontalOffset',
          );
          debugPrint('   - Screen width: ${MediaQuery.of(context).size.width}');

          return Transform.translate(
            offset: Offset(horizontalOffset, 0),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: Image(image: snapshot.data!, fit: BoxFit.contain),
            ),
          );
        },
      );
    }

    // Legacy records with referenceImageUrl: Use CachedNetworkImage
    final String? refImageUrl = _showSkeletonOnly
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
            Container(
                  color: Colors.grey[900],
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey[800]!,
                          Colors.grey[700]!,
                          Colors.grey[800]!,
                        ],
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
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

  Widget _buildFullscreenPanel(String label, String? imageUrl) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? _buildFullscreenImageWidget(imageUrl)
                : const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenImageWidget(String imageUrl) {
    // Check if it's a data URL (base64)
    if (imageUrl.startsWith('data:image')) {
      try {
        // Extract base64 data from data URL
        final String base64String = imageUrl.split(',')[1];
        final Uint8List imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            );
          },
        );
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        );
      }
    }

    // Otherwise use CachedNetworkImage for Cloud Storage URLs
    return CachedNetworkImage(
      key: ValueKey(imageUrl),
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) =>
          Container(
                color: Colors.grey[900],
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[700]!,
                        Colors.grey[800]!,
                      ],
                    ),
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1500.ms,
                color: Colors.white.withValues(alpha: 0.3),
              ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }
}

/// Content widget for checkpoint details education panel.
class _CheckpointDetailsContent extends StatelessWidget {
  const _CheckpointDetailsContent({required this.checkpoint});

  final CheckpointRecord checkpoint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Severity indicator
        Row(
          children: [
            Text(
              'Form quality: ',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
            SeverityBadge(severity: checkpoint.deviationSeverity),
          ],
        ),
        if (checkpoint.coachingTips.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Coaching tips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF137e66).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF137e66).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: checkpoint.coachingTips
                  .map((tip) => _buildBulletPoint(context, tip))
                  .toList(),
            ),
          ),
        ],
        if (checkpoint.coachingTips.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'No specific coaching tips for this checkpoint.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(
              fontSize: 18,
              height: 1.35,
              color: Color(0xFF137e66),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
