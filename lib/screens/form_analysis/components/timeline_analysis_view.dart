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
import 'package:turbo_disc_golf/components/form_analysis/pro_player_selector.dart';
import 'package:turbo_disc_golf/components/form_analysis/pro_reference_empty_state.dart';
import 'package:turbo_disc_golf/components/form_analysis/pro_reference_image_content.dart';
import 'package:turbo_disc_golf/components/form_analysis/v2_measurements_card.dart';
import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_player_models.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_pro_players_loader.dart';
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

class _TimelineAnalysisViewState extends State<TimelineAnalysisView>
    with WidgetsBindingObserver {
  final ProReferenceLoader _proRefLoader = ProReferenceLoader();

  // Cached pro reference image and transforms to prevent jitter during loading
  ImageProvider? _cachedProRefImage;
  double _cachedHorizontalOffset = 0;
  double _cachedScale = 1.0;
  int? _cachedCheckpointIndex;
  bool? _cachedShowSkeletonOnly;
  CameraAngle? _cachedCameraAngle;

  // Selected pro player ID for multi-pro comparison feature
  String? _selectedProId;

  // Pro players config loaded from Firestore
  ProPlayersConfig? _proPlayersConfig;

  // Track loading state for retry capability
  bool _isLoadingConfig = false;
  bool _configLoadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProPlayersConfig();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Retry loading config when app resumes if previous load failed
    if (state == AppLifecycleState.resumed &&
        _configLoadFailed &&
        !_isLoadingConfig) {
      _loadProPlayersConfig();
    }
  }

  Future<void> _loadProPlayersConfig() async {
    if (_isLoadingConfig) return;

    setState(() {
      _isLoadingConfig = true;
      _configLoadFailed = false;
    });

    final ProPlayersConfig? config =
        await FBProPlayersLoader.getProPlayersConfig();

    if (!mounted) return;

    setState(() {
      _isLoadingConfig = false;
      if (config != null) {
        _proPlayersConfig = config;
        _configLoadFailed = false;
      } else {
        _configLoadFailed = true;
      }
    });
  }

  /// Whether multi-pro comparison feature is enabled and available
  bool get _isMultiProEnabled {
    final bool flagEnabled = locator.get<FeatureFlagService>().getBool(
      FeatureFlag.enableMultiProComparison,
    );
    final bool hasMultiplePros = (_proPlayersConfig?.pros.length ?? 0) > 1;
    return flagEnabled && hasMultiplePros;
  }

  /// Get list of available pros from config
  List<ProPlayerMetadata> get _availablePros {
    return _proPlayersConfig?.pros.values.toList() ?? [];
  }

  /// Get the currently selected pro ID (defaults to defaultProId or first available)
  String? get _activeProId {
    if (!_isMultiProEnabled) return null;
    return _selectedProId ??
        widget.analysis.defaultProId ??
        _proPlayersConfig?.defaultProId ??
        _availablePros.firstOrNull?.proPlayerId;
  }

  /// Get checkpoints for the currently selected pro player.
  /// Returns the default checkpoints if no pro comparison data is available.
  List<CheckpointRecord> get _activeCheckpoints {
    if (!_isMultiProEnabled || _activeProId == null) {
      return widget.analysis.checkpoints;
    }

    final ProComparisonData? proData =
        widget.analysis.proComparisons?[_activeProId];
    if (proData != null && proData.checkpoints.isNotEmpty) {
      return proData.checkpoints;
    }

    return widget.analysis.checkpoints;
  }

  void _onProSelected(String proId) {
    if (proId != _selectedProId) {
      setState(() {
        _selectedProId = proId;
        // Clear cached pro reference since we're switching pros
        _cachedProRefImage = null;
        _cachedCheckpointIndex = null;
      });
    }
  }

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
            prev.lastSelectedCheckpointIndex !=
                curr.lastSelectedCheckpointIndex ||
            prev.showSkeletonOnly != curr.showSkeletonOnly,
        builder: (context, state) {
          final int? selectedIndex = state.selectedCheckpointIndex;
          final int? lastSelectedIndex = state.lastSelectedCheckpointIndex;
          final bool showSkeletonOnly = state.showSkeletonOnly;
          final CheckpointPlaybackCubit cubit =
              BlocProvider.of<CheckpointPlaybackCubit>(context);
          final List<CheckpointRecord> activeCheckpoints = _activeCheckpoints;
          final CheckpointRecord checkpoint =
              activeCheckpoints[selectedIndex ?? lastSelectedIndex ?? 0];

          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.only(top: widget.topPadding, bottom: 120),
                children: [
                  if (_isMultiProEnabled && _proPlayersConfig != null)
                    ProPlayerSelector(
                      availablePros: _availablePros,
                      selectedProId: _activeProId!,
                      onProSelected: _onProSelected,
                    ),
                  if (_showCheckpointSelectorAboveVideo)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: CheckpointSelector(
                        items: activeCheckpoints
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
                    checkpoints: activeCheckpoints,
                    proReferenceWidget: _buildProReferenceContent(
                      checkpoint,
                      selectedIndex,
                      lastSelectedIndex,
                      showSkeletonOnly,
                    ),
                  ),
                  _buildControlsAndDetailsSection(
                    selectedIndex,
                    cubit,
                    activeCheckpoints,
                  ),
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
    List<CheckpointRecord> checkpoints,
  ) {
    final CheckpointRecord checkpoint = checkpoints[selectedIndex ?? 0];

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
                items: checkpoints
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
    final String badgeText = formatCheckpointChipLabel(
      checkpoint.checkpointName,
    );

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

    // Get user landmarks for alignment calculation
    final List<PoseLandmark>? userLandmarks =
        _getUserLandmarksForCheckpoint(checkpoint.checkpointId);

    return ProReferenceImageContent(
      checkpoint: checkpoint,
      throwType: widget.analysis.throwType,
      cameraAngle: cameraAngle,
      showSkeletonOnly: showSkeletonOnly,
      proRefLoader: _proRefLoader,
      proPlayerId: _activeProId,
      detectedHandedness: widget.analysis.detectedHandedness,
      userLandmarks: userLandmarks,
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

  /// Gets user landmarks for a specific checkpoint.
  /// First tries to get from CheckpointRecord (stored data), then falls back
  /// to PoseAnalysisResponse (fresh analysis that hasn't been saved yet).
  List<PoseLandmark>? _getUserLandmarksForCheckpoint(String checkpointId) {
    // First, try to get landmarks from the stored CheckpointRecord
    try {
      final CheckpointRecord checkpoint = _activeCheckpoints.firstWhere(
        (cp) => cp.checkpointId == checkpointId,
      );
      if (checkpoint.userLandmarks != null &&
          checkpoint.userLandmarks!.isNotEmpty) {
        return checkpoint.userLandmarks;
      }
    } catch (e) {
      // Checkpoint not found in active checkpoints, continue to fallback
    }

    // Fallback: try to get from PoseAnalysisResponse (for fresh analysis)
    if (widget.poseAnalysisResponse == null) return null;

    try {
      final CheckpointPoseData checkpointData =
          widget.poseAnalysisResponse!.checkpoints.firstWhere(
        (cp) => cp.checkpointId == checkpointId,
      );
      return checkpointData.userLandmarks;
    } catch (e) {
      debugPrint(
          'Failed to get user landmarks for checkpoint $checkpointId: $e');
      return null;
    }
  }

  List<CheckpointRecord> _getCheckpointsWithTimestamps() {
    final List<CheckpointRecord> checkpoints = _activeCheckpoints;

    final bool recordHasTimestampData = checkpoints.any(
      (cp) => cp.timestampSeconds != null,
    );
    final bool responseHasTimestampData =
        widget.poseAnalysisResponse?.checkpoints.isNotEmpty ?? false;

    if (recordHasTimestampData) {
      return checkpoints;
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

    return checkpoints;
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
        checkpoints: _activeCheckpoints,
        throwType: widget.analysis.throwType,
        proRefLoader: _proRefLoader,
        proPlayerId: _activeProId,
        initialIndex: selectedIndex ?? 0,
        showSkeletonOnly: showSkeletonOnly,
        cameraAngle: widget.analysis.cameraAngle ?? CameraAngle.side,
        videoOrientation: widget.analysis.videoOrientation,
        detectedHandedness: widget.analysis.detectedHandedness,
        poseAnalysisResponse: widget.poseAnalysisResponse,
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
