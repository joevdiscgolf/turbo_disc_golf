import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_details_button.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_details_content.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_selector.dart';
import 'package:turbo_disc_golf/components/form_analysis/floating_view_toggle.dart';
import 'package:turbo_disc_golf/components/form_analysis/form_analysis_image.dart';
import 'package:turbo_disc_golf/components/form_analysis/fullscreen_comparison_dialog.dart';
import 'package:turbo_disc_golf/components/form_analysis/pro_reference_image_content.dart';
import 'package:turbo_disc_golf/components/form_analysis/v2_measurements_card.dart';
import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/video_orientation.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/timeline_analysis_view.dart';
import 'package:turbo_disc_golf/screens/form_analysis/form_analysis_detail/components/video_comparison_player.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/pro_reference_loader.dart';
import 'package:turbo_disc_golf/utils/checkpoint_helpers.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// View for displaying a historical form analysis in the detail screen.
///
/// Uses VideoComparisonPlayer (side-by-side user video + pro video) when
/// the video comparison feature flag is enabled.
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
  final String? videoUrl;
  final ThrowTechnique? throwType;
  final CameraAngle? cameraAngle;
  final double? videoAspectRatio;
  final PoseAnalysisResponse? poseAnalysisResponse;

  @override
  State<HistoryAnalysisView> createState() => _HistoryAnalysisViewState();
}

class _HistoryAnalysisViewState extends State<HistoryAnalysisView> {
  int _selectedCheckpointIndex = 0;
  bool _showSkeletonOnly = false;
  final ProReferenceLoader _proRefLoader = ProReferenceLoader();

  CameraAngle get _effectiveCameraAngle =>
      widget.cameraAngle ?? widget.analysis.cameraAngle ?? CameraAngle.side;

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
        cameraAngle: widget.cameraAngle,
        videoAspectRatio: widget.videoAspectRatio,
        poseAnalysisResponse: widget.poseAnalysisResponse,
      );
    }

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
                        id: cp.checkpointId,
                        label: cp.checkpointName,
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
    if (widget.videoUrl == null ||
        widget.videoUrl!.isEmpty ||
        widget.throwType == null ||
        widget.cameraAngle == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: VideoComparisonPlayer(
        videoUrl: widget.videoUrl!,
        skeletonVideoUrl: widget.analysis.skeletonVideoUrl,
        skeletonOnlyVideoUrl: widget.analysis.skeletonOnlyVideoUrl,
        showSkeletonOnly: _showSkeletonOnly,
        throwType: widget.throwType!,
        cameraAngle: widget.cameraAngle!,
        videoSyncMetadata:
            widget.poseAnalysisResponse?.videoSyncMetadata ??
            widget.analysis.videoSyncMetadata,
        videoAspectRatio: widget.videoAspectRatio,
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context) {
    if (widget.analysis.checkpoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final CheckpointRecord checkpoint =
        widget.analysis.checkpoints[_selectedCheckpointIndex];

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
              onTap: () =>
                  _showCheckpointDetailsPanel(context, checkpoint),
            ),
            if (checkpoint.userV2Measurements != null)
              V2MeasurementsCard(checkpoint: checkpoint),
            const SizedBox(height: 120),
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
      contentBuilder: (_) =>
          CheckpointDetailsContent(checkpoint: checkpoint),
    );
  }

  Widget _buildImageComparison(CheckpointRecord checkpoint) {
    final String? userImageUrl = _showSkeletonOnly
        ? checkpoint.userSkeletonUrl
        : checkpoint.userImageUrl;

    final bool isPortrait =
        widget.analysis.videoOrientation == VideoOrientation.portrait;

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
    required CheckpointRecord checkpoint,
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
                throwType: widget.analysis.throwType,
                cameraAngle: _effectiveCameraAngle,
                showSkeletonOnly: _showSkeletonOnly,
                proRefLoader: _proRefLoader,
                detectedHandedness: widget.analysis.detectedHandedness,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFullscreenComparison(CheckpointRecord checkpoint) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      useSafeArea: false,
      builder: (dialogContext) => FullscreenComparisonDialog(
        checkpoints: widget.analysis.checkpoints,
        throwType: widget.analysis.throwType,
        proRefLoader: _proRefLoader,
        initialIndex: _selectedCheckpointIndex,
        showSkeletonOnly: _showSkeletonOnly,
        cameraAngle: _effectiveCameraAngle,
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
