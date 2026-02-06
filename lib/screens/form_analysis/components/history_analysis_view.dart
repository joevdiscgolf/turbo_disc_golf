import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_details_button.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_details_content.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_selector.dart';
import 'package:turbo_disc_golf/components/form_analysis/floating_view_toggle.dart';
import 'package:turbo_disc_golf/components/form_analysis/form_analysis_image.dart';
import 'package:turbo_disc_golf/components/form_analysis/fullscreen_comparison_dialog.dart';
import 'package:turbo_disc_golf/components/form_analysis/pro_reference_image_content.dart';
import 'package:turbo_disc_golf/components/form_analysis/synchronized_video_player.dart';
import 'package:turbo_disc_golf/components/form_analysis/v2_measurements_card.dart';
import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/video_orientation.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/timeline_analysis_view.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/pro_reference_loader.dart';
import 'package:turbo_disc_golf/utils/checkpoint_helpers.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
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

  final FormAnalysisResponseV2 analysis;
  final VoidCallback onBack;
  final double topPadding;
  final String? videoUrl;
  final ThrowTechnique? throwType;
  final CameraAngle? cameraAngle;
  final double? videoAspectRatio;
  final FormAnalysisResponseV2? poseAnalysisResponse;

  @override
  State<HistoryAnalysisView> createState() => _HistoryAnalysisViewState();
}

class _HistoryAnalysisViewState extends State<HistoryAnalysisView> {
  int _selectedCheckpointIndex = 0;
  bool _showSkeletonOnly = false;
  final ProReferenceLoader _proRefLoader = ProReferenceLoader();

  /// Effective camera angle, prioritizing widget prop over analysis record
  CameraAngle get _effectiveCameraAngle =>
      widget.cameraAngle ?? widget.analysis.analysisResults.cameraAngle;

  @override
  void initState() {
    super.initState();

    // Debug log camera angle sources
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('[HistoryAnalysisView] 📷 CAMERA ANGLE DEBUG');
    debugPrint('[HistoryAnalysisView] Analysis ID: ${widget.analysis.id}');
    debugPrint(
      '[HistoryAnalysisView] widget.cameraAngle: ${widget.cameraAngle}',
    );
    debugPrint(
      '[HistoryAnalysisView] widget.analysis.cameraAngle: ${widget.analysis.analysisResults.cameraAngle}',
    );
    debugPrint(
      '[HistoryAnalysisView] _effectiveCameraAngle: $_effectiveCameraAngle',
    );
    debugPrint('═══════════════════════════════════════════════════════');

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('[HistoryAnalysisView] 🎬 VIDEO SYNC METADATA DEBUG');
    debugPrint('[HistoryAnalysisView] Analysis ID: ${widget.analysis.id}');
    debugPrint('[HistoryAnalysisView] From FormAnalysisResponseV2:');
    if (widget.analysis.proComparisonConfig?.videoSyncMetadata != null) {
      final metadata = widget.analysis.proComparisonConfig!.videoSyncMetadata!;
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
    debugPrint('[HistoryAnalysisView] From poseAnalysisResponse:');
    if (widget.poseAnalysisResponse?.proComparisonConfig?.videoSyncMetadata !=
        null) {
      final metadata =
          widget.poseAnalysisResponse!.proComparisonConfig!.videoSyncMetadata!;
      debugPrint('[HistoryAnalysisView]   ✅ videoSyncMetadata EXISTS');
      debugPrint(
        '[HistoryAnalysisView]   - Pro speed multiplier: ${metadata.proPlaybackSpeedMultiplier}x',
      );
      debugPrint(
        '[HistoryAnalysisView]   - Checkpoint sync points: ${metadata.checkpointSyncPoints.length}',
      );
    } else {
      debugPrint(
        '[HistoryAnalysisView]   ${widget.poseAnalysisResponse == null ? "⏭️  poseAnalysisResponse not provided" : "❌ videoSyncMetadata is NULL"}',
      );
    }
    debugPrint('═══════════════════════════════════════════════════════');
  }

  @override
  Widget build(BuildContext context) {
    // Delegate to TimelineAnalysisView when feature flag is enabled and video is available
    if (locator.get<FeatureFlagService>().showCheckpointTimelinePlayer &&
        widget.videoUrl != null &&
        widget.videoUrl!.isNotEmpty) {
      return TimelineAnalysisView(
        analysis: widget.analysis,
        onBack: widget.onBack,
        topPadding: widget.topPadding,
        videoUrl: widget.videoUrl,
        throwType: widget.throwType,
        cameraAngle: _effectiveCameraAngle,
        videoAspectRatio: widget.videoAspectRatio,
        poseAnalysisResponse: widget.poseAnalysisResponse,
      );
    }

    // Default layout (feature flag OFF or no video)
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverPadding(padding: EdgeInsets.only(top: widget.topPadding)),
            if (locator
                .get<FeatureFlagService>()
                .showFormAnalysisVideoComparison)
              _buildVideoComparisonSliver(),
            SliverToBoxAdapter(
              child: CheckpointSelector(
                items: widget.analysis.checkpoints
                    .map(
                      (cp) => CheckpointSelectorItem(
                        id: cp.metadata.checkpointId,
                        label: cp.metadata.checkpointName,
                      ),
                    )
                    .toList(),
                selectedIndex: _selectedCheckpointIndex,
                onChanged: (index) =>
                    setState(() => _selectedCheckpointIndex = index),
                formatLabel: formatCheckpointChipLabel,
              ),
            ),
            SliverToBoxAdapter(child: _buildComparisonCard(context)),
          ],
        ),
        FloatingViewToggle(
          showSkeletonOnly: _showSkeletonOnly,
          onChanged: (value) => setState(() => _showSkeletonOnly = value),
        ),
      ],
    );
  }

  Widget _buildVideoComparisonSliver() {
    // Check if we have all required data for video comparison
    if (widget.videoUrl == null ||
        widget.videoUrl!.isEmpty ||
        widget.throwType == null ||
        widget.cameraAngle == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    try {
      final String proVideoPath = getProReferenceVideoPath(
        throwType: widget.throwType!,
        cameraAngle: _effectiveCameraAngle,
      );

      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SynchronizedVideoPlayer(
            userVideoUrl: widget.videoUrl!,
            proVideoAssetPath: proVideoPath,
            videoSyncMetadata:
                widget
                    .poseAnalysisResponse
                    ?.proComparisonConfig
                    ?.videoSyncMetadata ??
                widget.analysis.proComparisonConfig?.videoSyncMetadata,
            videoAspectRatio: widget.videoAspectRatio,
          ),
        ),
      );
    } catch (e) {
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

  Widget _buildComparisonCard(BuildContext context) {
    if (widget.analysis.checkpoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final CheckpointDataV2 checkpoint =
        widget.analysis.checkpoints[_selectedCheckpointIndex];

    final bool isPortrait =
        widget.analysis.videoMetadata.videoOrientation ==
        VideoOrientation.portrait;
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
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: SenseiColors.gray.shade100,
              indent: 16,
              endIndent: 16,
            ),
            const SizedBox(height: 12),
            CheckpointDetailsButton(
              checkpoint: checkpoint,
              onTap: () => _showCheckpointDetailsPanel(context, checkpoint),
            ),
            if (locator.get<FeatureFlagService>().getBool(
                  FeatureFlag.showFormAnalysisMeasurementsCard,
                ))
              V2MeasurementsCard(
                checkpoint: checkpoint,
                cameraAngle: _effectiveCameraAngle,
              ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  void _showCheckpointDetailsPanel(
    BuildContext context,
    CheckpointDataV2 checkpoint,
  ) {
    EducationPanel.show(
      context,
      title: 'Key positions',
      modalName: 'Checkpoint Details',
      accentColor: const Color(0xFF137e66),
      buttonLabel: 'Done',
      contentBuilder: (_) => CheckpointDetailsContent(checkpoint: checkpoint),
    );
  }

  Widget _buildImageComparison(CheckpointDataV2 checkpoint) {
    // Note: In V2, individual checkpoint images are not stored
    // The UI now uses video-based display via TimelineAnalysisView
    // This code path is only for fallback when video is not available
    final String? userImageUrl = null; // No per-checkpoint images in V2

    final bool isPortrait =
        widget.analysis.videoMetadata.videoOrientation ==
        VideoOrientation.portrait;

    if (isPortrait) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildLabeledImage(
              label: 'You',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledImage(
          label: 'You',
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
    required CheckpointDataV2 checkpoint,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.black,
              child: ProReferenceImageContent(
                checkpoint: checkpoint,
                throwType: widget.analysis.analysisResults.throwType,
                cameraAngle: _effectiveCameraAngle,
                showSkeletonOnly: _showSkeletonOnly,
                proRefLoader: _proRefLoader,
                detectedHandedness:
                    widget.analysis.analysisResults.detectedHandedness,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFullscreenComparison(CheckpointDataV2 checkpoint) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      useSafeArea: false,
      builder: (dialogContext) => FullscreenComparisonDialog(
        checkpoints: widget.analysis.checkpoints,
        throwType: widget.analysis.analysisResults.throwType,
        proRefLoader: _proRefLoader,
        initialIndex: _selectedCheckpointIndex,
        showSkeletonOnly: _showSkeletonOnly,
        cameraAngle: _effectiveCameraAngle,
        videoOrientation: widget.analysis.videoMetadata.videoOrientation,
        detectedHandedness: widget.analysis.analysisResults.detectedHandedness,
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
                  color: SenseiColors.gray.shade400,
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
                  ? FormAnalysisImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                    )
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
}
