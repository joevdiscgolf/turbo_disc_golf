import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_details_button.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_details_content.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_playback_controls.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_selector.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_timeline_scrubber.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_video_display.dart';
import 'package:turbo_disc_golf/components/form_analysis/floating_view_toggle.dart';
import 'package:turbo_disc_golf/components/form_analysis/fullscreen_comparison_dialog.dart';
import 'package:turbo_disc_golf/components/form_analysis/pro_reference_empty_state.dart';
import 'package:turbo_disc_golf/components/form_analysis/pro_reference_image_content.dart';
import 'package:turbo_disc_golf/components/form_analysis/v2_measurements_card.dart';
import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/form_analysis/form_reference_positions.dart';
import 'package:turbo_disc_golf/services/pro_reference_loader.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_cubit.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_state.dart';
import 'package:turbo_disc_golf/utils/checkpoint_helpers.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Testing constant: true = checkpoint selector above video, false = below controls
const bool _showCheckpointSelectorAboveVideo = false;

/// View for timeline player layout with checkpoint selector above video.
///
/// Wraps the entire tree in a [BlocProvider<CheckpointPlaybackCubit>] so all
/// child widgets share a single source of truth for playback state, selected
/// checkpoint, and skeleton toggle.
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
  final ProReferenceLoader _proRefLoader = ProReferenceLoader();

  // Cached pro reference image and transforms to prevent jitter during loading
  ImageProvider? _cachedProRefImage;
  double _cachedHorizontalOffset = 0;
  double _cachedScale = 1.0;
  int? _cachedCheckpointIndex;
  bool? _cachedShowSkeletonOnly;
  CameraAngle? _cachedCameraAngle;

  @override
  Widget build(BuildContext context) {
    final List<CheckpointRecord> checkpointsWithTimestamps =
        _getCheckpointsWithTimestamps();

    return BlocProvider<CheckpointPlaybackCubit>(
      create: (_) => CheckpointPlaybackCubit(
        checkpoints: checkpointsWithTimestamps,
        totalFrames: widget.poseAnalysisResponse?.totalFrames,
      ),
      child: BlocBuilder<CheckpointPlaybackCubit, CheckpointPlaybackState>(
        buildWhen: (prev, curr) =>
            prev.selectedCheckpointIndex != curr.selectedCheckpointIndex ||
            prev.lastSelectedCheckpointIndex != curr.lastSelectedCheckpointIndex ||
            prev.showSkeletonOnly != curr.showSkeletonOnly,
        builder: (context, state) {
          final int? selectedIndex = state.selectedCheckpointIndex;
          final int? lastSelectedIndex = state.lastSelectedCheckpointIndex;
          final bool showSkeletonOnly = state.showSkeletonOnly;
          final CheckpointPlaybackCubit cubit =
              BlocProvider.of<CheckpointPlaybackCubit>(context);
          final CheckpointRecord checkpoint =
              widget.analysis.checkpoints[selectedIndex ?? lastSelectedIndex ?? 0];

          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.only(top: widget.topPadding, bottom: 120),
                children: [
                  if (_showCheckpointSelectorAboveVideo)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: CheckpointSelector(
                        items: widget.analysis.checkpoints
                            .map(
                              (cp) => CheckpointSelectorItem(
                                id: cp.checkpointId,
                                label: cp.checkpointName,
                              ),
                            )
                            .toList(),
                        selectedIndex: selectedIndex ?? -1,
                        onChanged: (index) => cubit.jumpToCheckpoint(index),
                        formatLabel: formatCheckpointChipLabel,
                      ),
                    ),
                  CheckpointVideoDisplay(
                    videoUrl: widget.videoUrl!,
                    skeletonVideoUrl: widget.analysis.skeletonVideoUrl,
                    skeletonOnlyVideoUrl: widget.analysis.skeletonOnlyVideoUrl,
                    videoAspectRatio: widget.videoAspectRatio,
                    returnedVideoAspectRatio:
                        widget.analysis.returnedVideoAspectRatio,
                    videoOrientation: widget.analysis.videoOrientation,
                    checkpoints: widget.analysis.checkpoints,
                    proReferenceWidget: _buildProReferenceContent(
                      checkpoint,
                      selectedIndex,
                      lastSelectedIndex,
                      showSkeletonOnly,
                    ),
                  ),
                  _buildControlsAndDetailsSection(selectedIndex, cubit),
                  if (checkpoint.userV2Measurements != null)
                    V2MeasurementsCard(checkpoint: checkpoint),
                ],
              ),
              FloatingViewToggle(
                showSkeletonOnly: showSkeletonOnly,
                onChanged: (value) => cubit.setShowSkeletonOnly(value),
                colors: FloatingViewToggleColors.blue,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlsAndDetailsSection(
    int? selectedIndex,
    CheckpointPlaybackCubit cubit,
  ) {
    final CheckpointRecord checkpoint =
        widget.analysis.checkpoints[selectedIndex ?? 0];

    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SenseiColors.gray[100]!, Colors.white],
          stops: [0.0, 0.3],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const CheckpointTimelineScrubber(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const CheckpointPlaybackControls(),
          ),
          if (!_showCheckpointSelectorAboveVideo) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 0),
              child: CheckpointSelector(
                items: widget.analysis.checkpoints
                    .map(
                      (cp) => CheckpointSelectorItem(
                        id: cp.checkpointId,
                        label: cp.checkpointName,
                      ),
                    )
                    .toList(),
                selectedIndex: selectedIndex ?? -1,
                onChanged: (index) => cubit.jumpToCheckpoint(index),
                formatLabel: formatCheckpointChipLabel,
              ),
            ),
          ],
          Divider(
            color: SenseiColors.gray.shade100,
            indent: 16,
            endIndent: 16,
            height: _showCheckpointSelectorAboveVideo ? 40 : 32,
          ),
          CheckpointDetailsButton(
            checkpoint: checkpoint,
            onTap: () => _showCheckpointDetailsPanel(context, checkpoint),
          ),
        ],
      ),
    );
  }

  /// Pro reference content with badge and fullscreen tap.
  Widget _buildProReferenceContent(
    CheckpointRecord checkpoint,
    int? selectedIndex,
    int? lastSelectedIndex,
    bool showSkeletonOnly,
  ) {
    // Only show empty state if no checkpoint has ever been selected
    final bool showEmptyState =
        selectedIndex == null &&
        lastSelectedIndex == null &&
        locator.get<FeatureFlagService>().getBool(
          FeatureFlag.showProReferenceEmptyState,
        );

    if (showEmptyState) {
      return const ProReferenceEmptyState();
    }

    // Format the checkpoint name for the badge (remove " Position" suffix)
    final String badgeText = formatCheckpointChipLabel(checkpoint.checkpointName);

    return GestureDetector(
      onTap: () => _showFullscreenComparison(
        context,
        checkpoint,
        selectedIndex ?? lastSelectedIndex,
        showSkeletonOnly,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildProReferenceImageContent(
              checkpoint,
              selectedIndex ?? lastSelectedIndex,
              showSkeletonOnly,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProReferenceImageContent(
    CheckpointRecord checkpoint,
    int? selectedIndex,
    bool showSkeletonOnly,
  ) {
    final CameraAngle cameraAngle =
        widget.analysis.cameraAngle ?? CameraAngle.side;
    final bool isSameCheckpoint =
        _cachedCheckpointIndex == (selectedIndex ?? 0) &&
        _cachedShowSkeletonOnly == showSkeletonOnly &&
        _cachedCameraAngle == cameraAngle;

    return ProReferenceImageContent(
      checkpoint: checkpoint,
      throwType: widget.analysis.throwType,
      cameraAngle: cameraAngle,
      showSkeletonOnly: showSkeletonOnly,
      proRefLoader: _proRefLoader,
      detectedHandedness: widget.analysis.detectedHandedness,
      cachedImage: _cachedProRefImage,
      cachedHorizontalOffset: _cachedHorizontalOffset,
      cachedScale: _cachedScale,
      isCacheStale: !isSameCheckpoint,
      onImageLoaded: (image, horizontalOffset, scale) {
        _cachedProRefImage = image;
        _cachedCheckpointIndex = selectedIndex ?? 0;
        _cachedShowSkeletonOnly = showSkeletonOnly;
        _cachedCameraAngle = cameraAngle;
        _cachedHorizontalOffset = horizontalOffset;
        _cachedScale = scale;
      },
    );
  }

  List<CheckpointRecord> _getCheckpointsWithTimestamps() {
    final bool recordHasTimestampData = widget.analysis.checkpoints.any(
      (cp) => cp.timestampSeconds != null,
    );
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
              coachingTips: cp.coachingTips.isNotEmpty
                  ? cp.coachingTips
                  : FormReferencePositions.getCoachingTips(cp.checkpointId),
              timestampSeconds: cp.timestampSeconds,
            ),
          )
          .toList();
    }

    return widget.analysis.checkpoints;
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
      contentBuilder: (_) => CheckpointDetailsContent(checkpoint: checkpoint),
    );
  }

  void _showFullscreenComparison(
    BuildContext context,
    CheckpointRecord checkpoint,
    int? selectedIndex,
    bool showSkeletonOnly,
  ) {
    final CheckpointPlaybackCubit cubit =
        BlocProvider.of<CheckpointPlaybackCubit>(context);

    showDialog(
      context: context,
      barrierColor: Colors.black,
      useSafeArea: false,
      builder: (dialogContext) => FullscreenComparisonDialog(
        checkpoints: widget.analysis.checkpoints,
        throwType: widget.analysis.throwType,
        proRefLoader: _proRefLoader,
        initialIndex: selectedIndex ?? 0,
        showSkeletonOnly: showSkeletonOnly,
        cameraAngle: widget.analysis.cameraAngle ?? CameraAngle.side,
        videoOrientation: widget.analysis.videoOrientation,
        detectedHandedness: widget.analysis.detectedHandedness,
        onToggleMode: (bool newMode) {
          cubit.setShowSkeletonOnly(newMode);
        },
        onIndexChanged: (int newIndex) {
          cubit.jumpToCheckpoint(newIndex);
        },
      ),
    );
  }
}
