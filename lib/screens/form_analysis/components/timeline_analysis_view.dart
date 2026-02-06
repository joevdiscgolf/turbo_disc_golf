import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_details_content.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_playback_controls.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_selector.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_timeline_scrubber.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_video_display.dart';
import 'package:turbo_disc_golf/components/form_analysis/fullscreen_comparison_dialog.dart';
import 'package:turbo_disc_golf/components/form_analysis/video_skeleton_toggle.dart';
import 'package:turbo_disc_golf/components/form_analysis/pro_player_selector.dart';
import 'package:turbo_disc_golf/components/form_analysis/pro_reference_empty_state.dart';
import 'package:turbo_disc_golf/components/panels/generic_selector_panel.dart';
import 'package:turbo_disc_golf/components/form_analysis/pro_reference_image_content.dart';
import 'package:turbo_disc_golf/components/form_analysis/v2_measurements_card.dart';
import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_comparison_data_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_player_models.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/user_alignment_metadata.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_pro_players_loader.dart';
import 'package:turbo_disc_golf/services/form_analysis/pro_player_constants.dart';
import 'package:turbo_disc_golf/services/pro_reference_loader.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_cubit.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_state.dart';
import 'package:turbo_disc_golf/utils/checkpoint_helpers.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Testing constant: true = checkpoint selector above video, false = below controls
const bool _showCheckpointSelectorAboveVideo = false;

/// Height of the pro player selector when shown below the pro reference image.
/// Calculated as: outer padding (10*2) + inner padding (8*2) + content (~16) = 52
const double _proSelectorHeight = 52.0;

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

  final FormAnalysisResponseV2 analysis;
  final VoidCallback onBack;
  final double topPadding;
  final String? videoUrl;
  final ThrowTechnique? throwType;
  final CameraAngle? cameraAngle;
  final double? videoAspectRatio;
  final FormAnalysisResponseV2? poseAnalysisResponse;

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

  // Pre-loaded images cache for instant checkpoint switching
  // Key format: "{checkpointId}_{skeleton|silhouette}"
  final Map<String, ImageProvider> _preloadedImages = {};

  // Selected pro player ID for multi-pro comparison feature
  String? _selectedProId;

  // Pro players config loaded from Firestore
  ProPlayersConfig? _proPlayersConfig;

  // Track loading state for retry capability
  bool _isLoadingConfig = false;
  bool _configLoadFailed = false;

  // Pre-computed lookup maps for O(1) access during playback
  // These are rebuilt when pro selection changes
  Map<String, List<PoseLandmark>?> _userLandmarksMap = {};
  Map<String, UserAlignmentMetadata?> _userAlignmentMap = {};

  // Cached values to avoid repeated lookups during rebuilds
  bool _cachedIsMultiProEnabled = false;
  String _cachedActiveProDisplayName = '';
  bool _cachedShowProReferenceEmptyState = false;
  double _cachedHeightMultiplier = 1.5;
  List<CheckpointDataV2> _cachedActiveCheckpoints = [];
  List<CheckpointSelectorItem> _cachedCheckpointSelectorItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize cached values first (uses defaults before config loads)
    _updateCachedDisplayValues();
    _buildLookupMaps();
    _loadProPlayersConfig();
    _preloadCheckpointImages();
  }

  /// Pre-computes lookup maps for user landmarks and alignment metadata.
  /// This avoids O(n) firstWhere lookups during playback rebuilds.
  void _buildLookupMaps() {
    // Build user alignment map from main analysis checkpoints
    _userAlignmentMap = {
      for (final cp in widget.analysis.checkpoints)
        cp.metadata.checkpointId: cp.userAlignmentMetadata,
    };

    // Build user landmarks map from active checkpoints
    _userLandmarksMap = {
      for (final cp in _activeCheckpoints)
        cp.metadata.checkpointId: cp.userPose.landmarks.isNotEmpty
            ? cp.userPose.landmarks
            : null,
    };

    // Also include landmarks from poseAnalysisResponse if available
    if (widget.poseAnalysisResponse != null) {
      for (final cp in widget.poseAnalysisResponse!.checkpoints) {
        // Only add if not already present or if current value is null
        if (!_userLandmarksMap.containsKey(cp.metadata.checkpointId) ||
            _userLandmarksMap[cp.metadata.checkpointId] == null) {
          if (cp.userPose.landmarks.isNotEmpty) {
            _userLandmarksMap[cp.metadata.checkpointId] = cp.userPose.landmarks;
          }
        }
      }
    }
  }

  /// Updates cached display values. Call after pro config loads or pro selection changes.
  void _updateCachedDisplayValues() {
    final FeatureFlagService featureFlagService = locator
        .get<FeatureFlagService>();
    _cachedIsMultiProEnabled = _computeIsMultiProEnabled();
    _cachedActiveProDisplayName = _computeActiveProDisplayName();
    _cachedShowProReferenceEmptyState = featureFlagService.getBool(
      FeatureFlag.showProReferenceEmptyState,
    );
    // Cache height multiplier based on camera angle
    final CameraAngle cameraAngle = widget.analysis.analysisResults.cameraAngle;
    _cachedHeightMultiplier = cameraAngle == CameraAngle.rear
        ? featureFlagService.getDouble(
            FeatureFlag.proReferenceHeightMultiplierRear,
          )
        : featureFlagService.getDouble(
            FeatureFlag.proReferenceHeightMultiplierSide,
          );
    _updateCachedCheckpoints();
  }

  /// Updates cached checkpoints and selector items.
  /// Call after pro selection changes.
  void _updateCachedCheckpoints() {
    _cachedActiveCheckpoints = _computeActiveCheckpoints();
    _cachedCheckpointSelectorItems = _cachedActiveCheckpoints
        .map(
          (cp) => CheckpointSelectorItem(
            id: cp.metadata.checkpointId,
            label: cp.metadata.checkpointName,
          ),
        )
        .toList();
  }

  /// Preloads all checkpoint images for instant switching.
  /// Stores images in _preloadedImages map for synchronous access.
  /// If [forProPlayerId] is provided, preloads for that specific pro player.
  Future<void> _preloadCheckpointImages({String? forProPlayerId}) async {
    final List<CheckpointDataV2> checkpoints = widget.analysis.checkpoints;
    final String throwType = widget.analysis.analysisResults.throwType;
    final CameraAngle cameraAngle = widget.analysis.analysisResults.cameraAngle;
    final String? proPlayerId =
        forProPlayerId ??
        checkpoints.firstOrNull?.proReferencePose?.proPlayerId;

    if (proPlayerId == null) return;

    // Preload both silhouette and skeleton versions for each checkpoint
    for (final checkpoint in checkpoints) {
      for (final isSkeleton in [true, false]) {
        try {
          final ImageProvider image = await _proRefLoader.loadReferenceImage(
            proPlayerId: proPlayerId,
            throwType: throwType,
            checkpoint: checkpoint.metadata.checkpointId,
            isSkeleton: isSkeleton,
            cameraAngle: cameraAngle,
          );

          if (!mounted) return;

          // Store in our map for synchronous access (keyed by pro + checkpoint + type)
          final String cacheKey = _getImageCacheKey(
            proPlayerId,
            checkpoint.metadata.checkpointId,
            isSkeleton,
          );
          _preloadedImages[cacheKey] = image;

          // Also precache into Flutter's image cache for rendering
          // ignore: use_build_context_synchronously
          precacheImage(image, context);
        } catch (e) {
          debugPrint(
            'Failed to preload checkpoint ${checkpoint.metadata.checkpointId}: $e',
          );
        }
      }
    }

    // Trigger rebuild so cached images are used
    if (mounted) {
      setState(() {});
    }
  }

  /// Gets cache key for preloaded images map (includes pro player ID)
  String _getImageCacheKey(
    String proPlayerId,
    String checkpointId,
    bool isSkeleton,
  ) {
    final String type = isSkeleton ? 'skeleton' : 'silhouette';
    return '${proPlayerId}_${checkpointId}_$type';
  }

  /// Gets a preloaded image if available
  ImageProvider? _getPreloadedImage(
    String checkpointId,
    bool showSkeletonOnly,
  ) {
    final String? proId = _activeProId;
    if (proId == null) return null;
    final String cacheKey = _getImageCacheKey(
      proId,
      checkpointId,
      showSkeletonOnly,
    );
    return _preloadedImages[cacheKey];
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
        // Update cached values now that config is loaded
        _updateCachedDisplayValues();
      } else {
        _configLoadFailed = true;
      }
    });
  }

  /// Whether multi-pro comparison feature is enabled and available (cached value).
  bool get _isMultiProEnabled => _cachedIsMultiProEnabled;

  /// Computes whether multi-pro comparison is enabled. Called when config changes.
  bool _computeIsMultiProEnabled() {
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

  /// Get the currently selected pro ID (defaults to paul_mcbeth)
  String? get _activeProId {
    if (!_isMultiProEnabled) return null;
    return _selectedProId ??
        widget.analysis.proComparisonConfig?.defaultProId ??
        _proPlayersConfig?.defaultProId ??
        kDefaultProPlayerId;
  }

  /// Get cached checkpoints for the currently selected pro player.
  List<CheckpointDataV2> get _activeCheckpoints =>
      _cachedActiveCheckpoints.isEmpty
      ? widget.analysis.checkpoints
      : _cachedActiveCheckpoints;

  /// Computes checkpoints for the currently selected pro player.
  /// Returns the default checkpoints if no pro comparison data is available.
  List<CheckpointDataV2> _computeActiveCheckpoints() {
    if (!_isMultiProEnabled || _activeProId == null) {
      return widget.analysis.checkpoints;
    }

    final ProComparisonDataV2? proData =
        widget.analysis.proComparisonConfig?.proComparisons?[_activeProId];
    if (proData != null && proData.checkpoints.isNotEmpty) {
      return proData.checkpoints;
    }

    return widget.analysis.checkpoints;
  }

  /// Get the display name for the currently selected pro player (cached value).
  String _getActiveProDisplayName() => _cachedActiveProDisplayName;

  /// Computes the display name for the active pro. Called when pro selection changes.
  String _computeActiveProDisplayName() {
    final String? proId = _activeProId;
    if (proId == null) return '';

    // Try to find the pro in available pros first
    final ProPlayerMetadata? pro = _availablePros
        .where((p) => p.proPlayerId == proId)
        .firstOrNull;

    if (pro != null && pro.displayName.isNotEmpty) {
      return pro.displayName;
    }

    // Fall back to constants
    return ProPlayerConstants.getDisplayName(proId);
  }

  /// Shows the pro player selector panel.
  void _showProSelectorPanel(BuildContext context) {
    if (!_isMultiProEnabled) return;

    HapticFeedback.selectionClick();

    final ProPlayerMetadata? currentSelection = _availablePros
        .where((pro) => pro.proPlayerId == _activeProId)
        .firstOrNull;

    showModalBottomSheet<ProPlayerMetadata>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.6,
          expand: false,
          builder: (context, scrollController) {
            return GenericSelectorPanel<ProPlayerMetadata>(
              items: _availablePros,
              selectedItem: currentSelection,
              getDisplayName: (pro) => pro.displayName.isNotEmpty
                  ? pro.displayName
                  : ProPlayerConstants.getDisplayName(pro.proPlayerId),
              getId: (pro) => pro.proPlayerId,
              title: 'Select pro player',
              enableSearch: false,
            );
          },
        );
      },
    ).then((selected) {
      if (selected != null) {
        _onProSelected(selected.proPlayerId);
      }
    });
  }

  void _onProSelected(String proId) {
    if (proId != _selectedProId) {
      setState(() {
        _selectedProId = proId;
        // Clear cached pro reference since we're switching pros
        _cachedProRefImage = null;
        _cachedCheckpointIndex = null;
        // Rebuild lookup maps for new pro's checkpoints
        _buildLookupMaps();
        // Update cached display values
        _updateCachedDisplayValues();
      });
      // Preload images for the newly selected pro (for instant switching later)
      _preloadCheckpointImages(forProPlayerId: proId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<CheckpointDataV2> checkpointsWithTimestamps =
        _getCheckpointsWithTimestamps();

    return BlocProvider<CheckpointPlaybackCubit>(
      create: (_) => CheckpointPlaybackCubit(
        checkpoints: checkpointsWithTimestamps,
        totalFrames: widget.poseAnalysisResponse?.videoMetadata.totalFrames,
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
          final List<CheckpointDataV2> activeCheckpoints = _activeCheckpoints;
          final CheckpointDataV2 checkpoint =
              activeCheckpoints[selectedIndex ?? lastSelectedIndex ?? 0];

          return ListView(
            padding: EdgeInsets.only(top: widget.topPadding, bottom: 120),
            children: [
              // if (_isMultiProEnabled && _proPlayersConfig != null)
              //   ProPlayerSelector(
              //     availablePros: _availablePros,
              //     selectedProId: _activeProId!,
              //     onProSelected: _onProSelected,
              //   ),
              if (_showCheckpointSelectorAboveVideo)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CheckpointSelector(
                    items: _cachedCheckpointSelectorItems,
                    selectedIndex: selectedIndex ?? -1,
                    onChanged: (index) => cubit.jumpToCheckpoint(index),
                    formatLabel: formatCheckpointChipLabel,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: VideoSkeletonToggle(
                  showSkeletonOnly: showSkeletonOnly,
                  onChanged: (value) => cubit.setShowSkeletonOnly(value),
                ),
              ),
              CheckpointVideoDisplay(
                videoUrl: widget.videoUrl!,
                skeletonVideoUrl:
                    widget.analysis.videoMetadata.skeletonVideoUrl,
                skeletonOnlyVideoUrl:
                    widget.analysis.videoMetadata.skeletonOnlyVideoUrl,
                videoAspectRatio: widget.videoAspectRatio,
                returnedVideoAspectRatio:
                    widget.analysis.videoMetadata.returnedVideoAspectRatio,
                videoOrientation:
                    widget.analysis.videoMetadata.videoOrientation,
                checkpoints: activeCheckpoints,
                detectedHandedness:
                    widget.analysis.analysisResults.detectedHandedness,
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
              if (locator.get<FeatureFlagService>().getBool(
                  FeatureFlag.showFormAnalysisMeasurementsCard,
                ))
              V2MeasurementsCard(
                checkpoint: checkpoint,
                cameraAngle: widget.analysis.analysisResults.cameraAngle,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPositionHeader(
    BuildContext context,
    CheckpointDataV2 checkpoint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _showCheckpointDetailsPanel(context, checkpoint);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: SenseiColors.gray.shade100.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Position details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SenseiColors.gray[600],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.help_outline_rounded,
                  size: 14,
                  color: SenseiColors.gray[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsAndDetailsSection(
    int? selectedIndex,
    CheckpointPlaybackCubit cubit,
    List<CheckpointDataV2> checkpoints,
  ) {
    final CheckpointDataV2 checkpoint = checkpoints[selectedIndex ?? 0];

    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SenseiColors.gray[100]!, Colors.white],
          stops: [0.0, 0.6],
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
            const SizedBox(height: 8),
            _buildPositionHeader(context, checkpoint),
            Padding(
              padding: const EdgeInsets.only(bottom: 0, left: 16, right: 16),
              child: CheckpointSelector(
                items: _cachedCheckpointSelectorItems,
                selectedIndex: selectedIndex ?? -1,
                onChanged: (index) => cubit.jumpToCheckpoint(index),
                formatLabel: formatCheckpointChipLabel,
              ),
            ),
          ],

          // Divider(
          //   color: SenseiColors.gray.shade100,
          //   indent: 16,
          //   endIndent: 16,
          //   height: _showCheckpointSelectorAboveVideo ? 40 : 32,
          // ),
          // CheckpointDetailsButton(
          //   checkpoint: checkpoint,
          //   onTap: () => _showCheckpointDetailsPanel(context, checkpoint),
          // ),
        ],
      ),
    );
  }

  /// Pro reference content with badge and fullscreen tap.
  /// Uses Column layout to ensure pro selector never overlaps the pro reference image.
  Widget _buildProReferenceContent(
    CheckpointDataV2 checkpoint,
    int? selectedIndex,
    int? lastSelectedIndex,
    bool showSkeletonOnly,
  ) {
    // Only show empty state if no checkpoint has ever been selected
    final bool showEmptyState =
        selectedIndex == null &&
        lastSelectedIndex == null &&
        _cachedShowProReferenceEmptyState;

    if (showEmptyState) {
      return const ProReferenceEmptyState();
    }

    // Format the checkpoint name for the badge (remove " Position" suffix)
    final String badgeText = formatCheckpointChipLabel(
      checkpoint.metadata.checkpointName,
    );

    // Use Column layout: pro reference image on top, selector below (never overlapping)
    return Column(
      children: [
        // Pro reference image with top-right badge (fills available space)
        Expanded(
          child: GestureDetector(
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
                // Top-right checkpoint badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
          ),
        ),
        // Pro player selector below the image (only when multi-pro is enabled)
        if (_isMultiProEnabled)
          GestureDetector(
            onTap: () => _showProSelectorPanel(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(color: Colors.black),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getActiveProDisplayName(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProReferenceImageContent(
    CheckpointDataV2 checkpoint,
    int? selectedIndex,
    bool showSkeletonOnly,
  ) {
    final CameraAngle cameraAngle = widget.analysis.analysisResults.cameraAngle;
    final bool isSameCheckpoint =
        _cachedCheckpointIndex == (selectedIndex ?? 0) &&
        _cachedShowSkeletonOnly == showSkeletonOnly &&
        _cachedCameraAngle == cameraAngle;

    // Get user landmarks for alignment calculation
    final List<PoseLandmark>? userLandmarks = _getUserLandmarksForCheckpoint(
      checkpoint.metadata.checkpointId,
    );

    // Always get userAlignmentMetadata from the main analysis checkpoints,
    // not from the pro-specific checkpoints. This ensures proper sizing
    // regardless of which pro is selected.
    final UserAlignmentMetadata? userAlignment =
        _getUserAlignmentMetadataForCheckpoint(
          checkpoint.metadata.checkpointId,
        );

    // Get preloaded image for instant rendering (avoids FutureBuilder async delay)
    final ImageProvider? preloadedImage = _getPreloadedImage(
      checkpoint.metadata.checkpointId,
      showSkeletonOnly,
    );

    return ProReferenceImageContent(
      checkpoint: checkpoint,
      throwType: widget.analysis.analysisResults.throwType,
      cameraAngle: cameraAngle,
      showSkeletonOnly: showSkeletonOnly,
      proRefLoader: _proRefLoader,
      proPlayerId: _activeProId,
      detectedHandedness: widget.analysis.analysisResults.detectedHandedness,
      userLandmarks: userLandmarks,
      userAlignment: userAlignment,
      heightMultiplier: _cachedHeightMultiplier,
      // When multi-pro is enabled, selector takes space below - account for this in scaling
      additionalVerticalSpace: _isMultiProEnabled ? _proSelectorHeight : 0,
      cachedImage: _cachedProRefImage,
      cachedHorizontalOffset: _cachedHorizontalOffset,
      cachedScale: _cachedScale,
      isCacheStale: !isSameCheckpoint,
      preloadedImage: preloadedImage,
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

  /// Gets user landmarks for a specific checkpoint using pre-computed map.
  /// O(1) lookup for smooth playback performance.
  List<PoseLandmark>? _getUserLandmarksForCheckpoint(String checkpointId) {
    return _userLandmarksMap[checkpointId];
  }

  /// Gets user alignment metadata for a specific checkpoint using pre-computed map.
  /// O(1) lookup for smooth playback performance.
  UserAlignmentMetadata? _getUserAlignmentMetadataForCheckpoint(
    String checkpointId,
  ) {
    return _userAlignmentMap[checkpointId];
  }

  List<CheckpointDataV2> _getCheckpointsWithTimestamps() {
    final List<CheckpointDataV2> checkpoints = _activeCheckpoints;

    return checkpoints;
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
      buttonLabel: 'Got it!',
      contentBuilder: (_) => CheckpointDetailsContent(checkpoint: checkpoint),
    );
  }

  void _showFullscreenComparison(
    BuildContext context,
    CheckpointDataV2 checkpoint,
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
        throwType: widget.analysis.analysisResults.throwType,
        proRefLoader: _proRefLoader,
        proPlayerId: _activeProId,
        initialIndex: selectedIndex ?? 0,
        showSkeletonOnly: showSkeletonOnly,
        cameraAngle: widget.analysis.analysisResults.cameraAngle,
        videoOrientation: widget.analysis.videoMetadata.videoOrientation,
        detectedHandedness: widget.analysis.analysisResults.detectedHandedness,
        poseAnalysisResponse: widget.poseAnalysisResponse,
        // Reuse pre-computed user alignment map
        userAlignmentByCheckpointId: _userAlignmentMap,
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
