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
import 'package:turbo_disc_golf/components/form_analysis/pro_reference_image_content.dart';
import 'package:turbo_disc_golf/components/form_analysis/v2_measurements_card.dart';
import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/form_analysis/form_reference_positions.dart';
import 'package:turbo_disc_golf/services/pro_reference_loader.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_cubit.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_state.dart';
import 'package:turbo_disc_golf/utils/checkpoint_helpers.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

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
    for (final CheckpointRecord checkpoint in widget.analysis.checkpoints) {
      debugPrint(
        'Checkpoint: ${checkpoint.checkpointName}, Detected frame: ${checkpoint.detectedFrameNumber}',
      );
    }
    final List<CheckpointRecord> checkpointsWithTimestamps =
        _getCheckpointsWithTimestamps();

    return BlocProvider<CheckpointPlaybackCubit>(
      create: (_) =>
          CheckpointPlaybackCubit(checkpoints: checkpointsWithTimestamps),
      child: BlocBuilder<CheckpointPlaybackCubit, CheckpointPlaybackState>(
        buildWhen: (prev, curr) =>
            prev.selectedCheckpointIndex != curr.selectedCheckpointIndex ||
            prev.showSkeletonOnly != curr.showSkeletonOnly,
        builder: (context, state) {
          final int selectedIndex = state.selectedCheckpointIndex;
          final bool showSkeletonOnly = state.showSkeletonOnly;
          final CheckpointPlaybackCubit cubit =
              BlocProvider.of<CheckpointPlaybackCubit>(context);
          final CheckpointRecord checkpoint =
              widget.analysis.checkpoints[selectedIndex];

          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.only(top: widget.topPadding, bottom: 120),
                children: [
                  CheckpointSelector(
                    items: widget.analysis.checkpoints
                        .map(
                          (cp) => CheckpointSelectorItem(
                            id: cp.checkpointId,
                            label: cp.checkpointName,
                          ),
                        )
                        .toList(),
                    selectedIndex: selectedIndex,
                    onChanged: (index) => cubit.jumpToCheckpoint(index),
                    formatLabel: formatCheckpointChipLabel,
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
                      showSkeletonOnly,
                    ),
                  ),
                  _buildControlsAndDetailsSection(selectedIndex),
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

  Widget _buildControlsAndDetailsSection(int selectedIndex) {
    final CheckpointRecord checkpoint =
        widget.analysis.checkpoints[selectedIndex];

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
          Divider(
            color: SenseiColors.gray.shade100,
            indent: 16,
            endIndent: 16,
            height: 40,
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
    int selectedIndex,
    bool showSkeletonOnly,
  ) {
    return GestureDetector(
      onTap: () => _showFullscreenComparison(
        context,
        checkpoint,
        selectedIndex,
        showSkeletonOnly,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildProReferenceImageContent(
              checkpoint,
              selectedIndex,
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
              child: const Text(
                'Pro reference',
                style: TextStyle(
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
    int selectedIndex,
    bool showSkeletonOnly,
  ) {
    final CameraAngle cameraAngle =
        widget.analysis.cameraAngle ?? CameraAngle.side;
    final bool isSameCheckpoint =
        _cachedCheckpointIndex == selectedIndex &&
        _cachedShowSkeletonOnly == showSkeletonOnly &&
        _cachedCameraAngle == cameraAngle;

    debugPrint(
      'ProRef Cache Check: checkpoint=$selectedIndex, skeleton=$showSkeletonOnly, '
      'camera=$cameraAngle, isSame=$isSameCheckpoint, '
      'cached=(idx:$_cachedCheckpointIndex, skel:$_cachedShowSkeletonOnly, cam:$_cachedCameraAngle)',
    );

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
        debugPrint(
          'ProRef Cache Updated: checkpoint=$selectedIndex, skeleton=$showSkeletonOnly, '
          'camera=$cameraAngle',
        );
        _cachedProRefImage = image;
        _cachedCheckpointIndex = selectedIndex;
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
    int selectedIndex,
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
        initialIndex: selectedIndex,
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
