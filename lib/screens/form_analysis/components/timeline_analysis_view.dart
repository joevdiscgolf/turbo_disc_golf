import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_selector.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_timeline_player.dart';
import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_checkpoint.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/models/video_orientation.dart';
import 'package:turbo_disc_golf/services/form_analysis/form_reference_positions.dart';
import 'package:turbo_disc_golf/services/pro_reference_loader.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// View for timeline player layout with checkpoint selector above video.
///
/// This view is used when the `showCheckpointTimelinePlayer` feature flag is enabled
/// and a video URL is available. It provides a different layout than the default
/// `HistoryAnalysisView`:
/// - CheckpointSelector at top (above video)
/// - CheckpointTimelinePlayer (video with timeline)
/// - Pro reference section (full width, no horizontal margins)
class TimelineAnalysisView extends StatefulWidget {
  const TimelineAnalysisView({
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
  final String? videoUrl;
  final ThrowTechnique? throwType;
  final CameraAngle? cameraAngle;
  final double? videoAspectRatio;
  final PoseAnalysisResponse? poseAnalysisResponse;

  @override
  State<TimelineAnalysisView> createState() => _TimelineAnalysisViewState();
}

class _TimelineAnalysisViewState extends State<TimelineAnalysisView> {
  int _selectedCheckpointIndex = 0;
  bool _showSkeletonOnly = false;
  final ProReferenceLoader _proRefLoader = ProReferenceLoader();
  final GlobalKey<CheckpointTimelinePlayerState> _playerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final List<CheckpointRecord> checkpointsWithTimestamps =
        _getCheckpointsWithTimestamps();
    final double videoDuration =
        widget.poseAnalysisResponse?.videoDurationSeconds ??
        widget.analysis.videoSyncMetadata?.userVideoDuration ??
        3.0;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverPadding(padding: EdgeInsets.only(top: widget.topPadding)),
            // CheckpointSelector at top (above video)
            SliverToBoxAdapter(
              child: CheckpointSelector(
                items: widget.analysis.checkpoints
                    .map(
                      (cp) => CheckpointSelectorItem(
                        id: cp.checkpointId,
                        label: cp.checkpointName,
                      ),
                    )
                    .toList(),
                selectedIndex: _selectedCheckpointIndex,
                onChanged: (index) {
                  setState(() => _selectedCheckpointIndex = index);
                  // Directly tell player to jump - no rebuild cycle
                  _playerKey.currentState?.jumpToCheckpoint(index);
                },
                formatLabel: _formatChipLabel,
              ),
            ),
            // CheckpointTimelinePlayer
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: CheckpointTimelinePlayer(
                  key: _playerKey,
                  videoUrl: widget.videoUrl!,
                  skeletonVideoUrl: widget.analysis.skeletonVideoUrl,
                  checkpoints: checkpointsWithTimestamps,
                  videoDurationSeconds: videoDuration,
                  videoAspectRatio: widget.videoAspectRatio,
                  onCheckpointTapped: (checkpoint) =>
                      _showCheckpointDetailsPanel(context, checkpoint),
                  onCheckpointIndexChanged: (index) =>
                      setState(() => _selectedCheckpointIndex = index),
                ),
              ),
            ),
            // Pro reference section (full width, no horizontal margins)
            SliverToBoxAdapter(child: _buildProReferenceSection()),
            // Checkpoint details button
            SliverToBoxAdapter(
              child: _buildCheckpointDetailsButton(
                context,
                widget.analysis.checkpoints[_selectedCheckpointIndex],
              ),
            ),
            // Bottom spacing for floating button
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        _buildFloatingViewToggle(),
      ],
    );
  }

  List<CheckpointRecord> _getCheckpointsWithTimestamps() {
    // Check if FormAnalysisRecord has timestamp data
    final bool recordHasTimestampData = widget.analysis.checkpoints.any(
      (cp) => cp.timestampSeconds != null,
    );

    // Check if PoseAnalysisResponse has timestamp data
    final bool responseHasTimestampData =
        widget.poseAnalysisResponse?.checkpoints.isNotEmpty ?? false;

    if (recordHasTimestampData) {
      return widget.analysis.checkpoints;
    } else if (responseHasTimestampData) {
      return widget.poseAnalysisResponse!.checkpoints
          .map(
            (cp) => CheckpointRecord(
              checkpointId: cp.checkpointId,
              checkpointName: cp.checkpointName,
              deviationSeverity: cp.deviationSeverity,
              coachingTips: cp.coachingTips,
              timestampSeconds: cp.timestampSeconds,
            ),
          )
          .toList();
    }

    return widget.analysis.checkpoints;
  }

  String _formatChipLabel(String name) {
    return name.replaceAll(' Position', '').replaceAll(' position', '').trim();
  }

  Widget _buildProReferenceSection() {
    if (widget.analysis.checkpoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final CheckpointRecord checkpoint =
        widget.analysis.checkpoints[_selectedCheckpointIndex];

    return GestureDetector(
      onTap: () => _showFullscreenComparison(checkpoint),
      child: _buildProReferenceImage(
        checkpoint: checkpoint,
        onTap: () => _showFullscreenComparison(checkpoint),
      ),
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
          padding: EdgeInsets.only(left: 16, bottom: 6),
          child: Text(
            'Pro reference',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SenseiColors.darkGray,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 200,
            width: double.infinity,
            color: Colors.black,
            child: _buildProReferenceImageContent(checkpoint),
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
            return _buildShimmerPlaceholder();
          }

          return _buildProReferenceTransformedImage(
            checkpoint: checkpoint,
            imageProvider: snapshot.data!,
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
        placeholder: (context, url) => _buildShimmerPlaceholder(),
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

  Widget _buildProReferenceTransformedImage({
    required CheckpointRecord checkpoint,
    required ImageProvider imageProvider,
  }) {
    // Apply alignment transformation (translate + scale)
    final double horizontalOffset =
        MediaQuery.of(context).size.width *
        (checkpoint.referenceHorizontalOffsetPercent ?? 0) /
        100;

    // WORKAROUND: Clamp scale to prevent backend bugs
    final double rawScale = checkpoint.referenceScale ?? 1.0;
    final double scale = rawScale.clamp(0.7, 1.5);

    // Check if user is left-handed to flip pro reference
    final bool isLeftHanded =
        widget.analysis.detectedHandedness == Handedness.left;
    final Widget image = Image(
      image: imageProvider,
      fit: BoxFit.contain,
    );

    return Transform.translate(
      offset: Offset(horizontalOffset, 0),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: isLeftHanded ? Transform.flip(flipX: true, child: image) : image,
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
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

  Widget _buildCheckpointDetailsButton(
    BuildContext context,
    CheckpointRecord checkpoint,
  ) {
    // Get first 3 coaching tips
    final List<String> topTips = checkpoint.coachingTips.take(3).toList();

    return GestureDetector(
      onTap: () => _showCheckpointDetailsPanel(context, checkpoint),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.only(left: 8, right: 0, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
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
                      color: Colors.grey[800],
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
                    'View details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF137e66),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: const Color(0xFF137e66), size: 28),
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
      title: 'Key positions',
      modalName: 'Checkpoint Details',
      accentColor: const Color(0xFF137e66),
      buttonLabel: 'Done',
      contentBuilder: (_) => _CheckpointDetailsContent(checkpoint: checkpoint),
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
        detectedHandedness: widget.analysis.detectedHandedness,
        onToggleMode: (bool newMode) {
          setState(() => _showSkeletonOnly = newMode);
        },
        onIndexChanged: (int newIndex) {
          setState(() => _selectedCheckpointIndex = newIndex);
        },
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
    this.detectedHandedness,
  });

  final List<CheckpointRecord> checkpoints;
  final String throwType;
  final ProReferenceLoader proRefLoader;
  final int initialIndex;
  final Handedness? detectedHandedness;
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
          Expanded(child: _buildFullscreenPanel('You', userImageUrl)),
          const SizedBox(width: 4),
          Expanded(child: _buildFullscreenProReferencePanel(checkpoint)),
        ],
      );
    }

    // Landscape: vertical stack layout (default)
    return Column(
      children: [
        Expanded(child: _buildFullscreenPanel('You', userImageUrl)),
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
            'Pro reference',
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
            return const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            );
          }

          if (!snapshot.hasData) {
            return _buildShimmerPlaceholder();
          }

          // Apply alignment transformation (translate + scale)
          final double horizontalOffset =
              MediaQuery.of(context).size.width *
              (checkpoint.referenceHorizontalOffsetPercent ?? 0) /
              100;

          // WORKAROUND: Clamp scale to prevent backend bugs
          final double rawScale = checkpoint.referenceScale ?? 1.0;
          final double scale = rawScale.clamp(0.7, 1.5);

          // Check if user is left-handed to flip pro reference
          final bool isLeftHanded =
              widget.detectedHandedness == Handedness.left;
          final Widget image = Image(
            image: snapshot.data!,
            fit: BoxFit.contain,
          );

          return Transform.translate(
            offset: Offset(horizontalOffset, 0),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: isLeftHanded
                  ? Transform.flip(flipX: true, child: image)
                  : image,
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
        placeholder: (context, url) => _buildShimmerPlaceholder(),
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

  Widget _buildShimmerPlaceholder() {
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
      placeholder: (context, url) => _buildShimmerPlaceholder(),
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
    final List<FormCheckpoint> allPositions =
        FormReferencePositions.backhandCheckpoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allPositions
          .map((position) => _buildPositionCard(context, position))
          .toList(),
    );
  }

  Widget _buildPositionCard(BuildContext context, FormCheckpoint position) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${position.orderIndex + 1}. ${position.name}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            position.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          if (position.keyPoints.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...position.keyPoints.map(
              (keyPoint) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${keyPoint.name}: ${keyPoint.idealState}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
