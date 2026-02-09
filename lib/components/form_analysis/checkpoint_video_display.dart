import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/form_analysis/fullscreen_video_dialog.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_cubit.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_state.dart';
import 'package:video_player/video_player.dart';

/// Displays the video player and owns the VideoPlayerController lifecycle.
///
/// Accepts an optional [proReferenceWidget] and handles layout based on
/// video aspect ratio:
/// - Portrait (aspect < 1.0): video and pro ref side by side
/// - Landscape (aspect >= 1.0): video on top, pro ref below
///
/// The parent does not need to care about orientation.
class CheckpointVideoDisplay extends StatefulWidget {
  const CheckpointVideoDisplay({
    super.key,
    required this.analysis,
    this.videoAspectRatio,
    this.checkpoints,
    this.proReferenceWidget,
  });

  /// The full form analysis response containing video metadata, arm speed, etc.
  final FormAnalysisResponseV2 analysis;

  /// Video aspect ratio override (width/height). If not provided, uses
  /// the aspect ratio from the video controller.
  final double? videoAspectRatio;

  /// Checkpoints for the fullscreen video dialog selector.
  /// If not provided, uses analysis.checkpoints.
  final List<CheckpointDataV2>? checkpoints;

  /// Optional pro reference widget displayed alongside the video.
  /// Layout is handled automatically based on video aspect ratio.
  final Widget? proReferenceWidget;

  @override
  State<CheckpointVideoDisplay> createState() => _CheckpointVideoDisplayState();
}

class _CheckpointVideoDisplayState extends State<CheckpointVideoDisplay> {
  late VideoPlayerController _overlayController;
  VideoPlayerController? _skeletonOnlyController;
  bool _isOverlayInitialized = false;
  bool _isSkeletonOnlyInitialized = false;

  /// Whether we're currently showing skeleton-only video (local tracking).
  bool _showingSkeletonOnly = false;

  /// Tracks if we've reached max speed during this playback.
  /// Once true, the overlay will show max speed and not decrease.
  bool _hasReachedMax = false;

  /// The max speed value to display once reached.
  double? _lockedMaxSpeed;

  VideoPlayerController get _activeController =>
      _showingSkeletonOnly && _skeletonOnlyController != null
      ? _skeletonOnlyController!
      : _overlayController;

  bool get _isActiveInitialized =>
      _showingSkeletonOnly && _skeletonOnlyController != null
      ? _isSkeletonOnlyInitialized
      : _isOverlayInitialized;

  /// Last position we seeked to, to debounce rapid seeks.
  Duration? _lastSeekedPosition;

  // Convenience getters for analysis data
  String get _skeletonVideoUrl => widget.analysis.videoMetadata.skeletonVideoUrl!;
  String get _skeletonOnlyVideoUrl =>
      widget.analysis.videoMetadata.skeletonOnlyVideoUrl!;
  double? get _returnedVideoAspectRatio =>
      widget.analysis.videoMetadata.returnedVideoAspectRatio;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _skeletonOnlyController?.dispose();
    super.dispose();
  }

  Future<void> _initializeControllers() async {
    final CheckpointPlaybackCubit cubit =
        BlocProvider.of<CheckpointPlaybackCubit>(context);

    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[CheckpointVideoDisplay] INITIALIZING VIDEO CONTROLLERS');
      debugPrint('[CheckpointVideoDisplay] Overlay URL: $_skeletonVideoUrl');

      _overlayController = VideoPlayerController.networkUrl(
        Uri.parse(_skeletonVideoUrl),
      );
      await _overlayController.initialize();
      _overlayController.setVolume(0.0);

      debugPrint('[CheckpointVideoDisplay] Overlay controller initialized');

      if (mounted) {
        setState(() => _isOverlayInitialized = true);
      }

      // Initialize skeleton-only controller
      debugPrint(
        '[CheckpointVideoDisplay] Skeleton-only URL: $_skeletonOnlyVideoUrl',
      );
      _skeletonOnlyController = VideoPlayerController.networkUrl(
        Uri.parse(_skeletonOnlyVideoUrl),
      );
      await _skeletonOnlyController!.initialize();
      _skeletonOnlyController!.setVolume(0.0);

      debugPrint(
        '[CheckpointVideoDisplay] Skeleton-only controller initialized',
      );

      if (mounted) {
        setState(() => _isSkeletonOnlyInitialized = true);
      }

      debugPrint('═══════════════════════════════════════════════════════');

      cubit.onVideoInitialized(_activeController.value.duration);
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[CheckpointVideoDisplay] FAILED TO LOAD VIDEO');
      debugPrint('[CheckpointVideoDisplay] Error: $e');
      debugPrint('[CheckpointVideoDisplay] Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════');
      cubit.onVideoInitError('Failed to load video: $e');
    }
  }

  /// Swap to the newly active controller when showSkeletonOnly changes.
  Future<void> _swapActiveController(bool showSkeletonOnly) async {
    if (!_isActiveInitialized) return;

    _showingSkeletonOnly = showSkeletonOnly;

    // Seek newly active controller to current position
    final CheckpointPlaybackCubit cubit =
        BlocProvider.of<CheckpointPlaybackCubit>(context);
    await _activeController.seekTo(cubit.state.currentPosition);

    final Duration newDuration = _activeController.value.duration;
    cubit.onControllerSwapComplete(newDuration);

    if (mounted) {
      setState(() {});
    }
  }

  void _showFullscreenVideo() {
    if (!_isActiveInitialized) return;

    final CheckpointPlaybackCubit cubit =
        BlocProvider.of<CheckpointPlaybackCubit>(context);

    showDialog(
      context: context,
      barrierColor: Colors.black,
      useSafeArea: false,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: FullscreenVideoDialog(
          videoController: _activeController,
          videoOrientation: widget.analysis.videoMetadata.videoOrientation,
          checkpoints: widget.checkpoints ?? widget.analysis.checkpoints,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CheckpointPlaybackCubit, CheckpointPlaybackState>(
          listenWhen: (prev, curr) =>
              prev.currentPosition != curr.currentPosition,
          listener: (context, state) {
            if (!_isActiveInitialized) return;
            if (_lastSeekedPosition == state.currentPosition) return;

            // Reset max speed lock if seeking backward
            if (_lastSeekedPosition != null &&
                state.currentPosition < _lastSeekedPosition!) {
              _resetMaxSpeedLock();
            }

            _lastSeekedPosition = state.currentPosition;
            _activeController.seekTo(state.currentPosition);
          },
        ),
        BlocListener<CheckpointPlaybackCubit, CheckpointPlaybackState>(
          listenWhen: (prev, curr) =>
              prev.isPlaying != curr.isPlaying && !curr.isPlaying,
          listener: (context, state) {
            if (_isActiveInitialized) {
              _activeController.pause();
            }
          },
        ),
        // Reset max speed lock when video restarts from beginning
        BlocListener<CheckpointPlaybackCubit, CheckpointPlaybackState>(
          listenWhen: (prev, curr) =>
              !prev.isAtStart && curr.isAtStart,
          listener: (context, state) {
            _resetMaxSpeedLock();
          },
        ),
        BlocListener<CheckpointPlaybackCubit, CheckpointPlaybackState>(
          listenWhen: (prev, curr) =>
              prev.showSkeletonOnly != curr.showSkeletonOnly,
          listener: (context, state) {
            _swapActiveController(state.showSkeletonOnly);
          },
        ),
      ],
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<CheckpointPlaybackCubit, CheckpointPlaybackState>(
      buildWhen: (prev, curr) =>
          prev.videoInitStatus != curr.videoInitStatus ||
          prev.showTapFeedback != curr.showTapFeedback ||
          prev.tapFeedbackIsPlay != curr.tapFeedbackIsPlay ||
          prev.isPlaying != curr.isPlaying ||
          prev.isAtStart != curr.isAtStart ||
          prev.isAtEnd != curr.isAtEnd ||
          // Rebuild when position changes to update speed overlay
          (widget.analysis.armSpeed != null &&
              prev.currentPosition != curr.currentPosition),
      builder: (context, state) {
        if (state.hasError) {
          return _buildErrorState(state.errorMessage);
        }

        final Widget video = _isActiveInitialized
            ? _buildVideoPlayer(state)
            : _buildVideoShimmer();

        return _buildLayout(video);
      },
    );
  }

  /// Lays out video + optional pro reference based on aspect ratio.
  Widget _buildLayout(Widget video) {
    if (widget.proReferenceWidget == null) return video;

    final bool isPortrait = (widget.videoAspectRatio ?? 1.0) < 1.0;

    if (isPortrait) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: video),
          Expanded(
            child: AspectRatio(
              aspectRatio: widget.videoAspectRatio ?? 0.5625,
              child: Container(
                color: Colors.black,
                child: widget.proReferenceWidget!,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        video,
        Container(
          height: 200,
          width: double.infinity,
          color: Colors.black,
          child: widget.proReferenceWidget!,
        ),
      ],
    );
  }

  /// Calculate current frame from video position and total frames.
  int? _getCurrentFrame(CheckpointPlaybackState state) {
    if (state.totalFrames == null || state.videoDuration.inMilliseconds == 0) {
      return null;
    }
    final double progress =
        state.currentPosition.inMilliseconds / state.videoDuration.inMilliseconds;
    return (progress * state.totalFrames!).round().clamp(0, state.totalFrames!);
  }

  /// Get current arm speed for display overlay.
  /// Once max speed is reached, locks to that value and won't decrease.
  double? _getCurrentSpeed(CheckpointPlaybackState state) {
    final armSpeed = widget.analysis.armSpeed;
    if (armSpeed == null) return null;

    // If we've already locked to max, return the locked value
    if (_hasReachedMax && _lockedMaxSpeed != null) {
      return _lockedMaxSpeed;
    }

    final int? currentFrame = _getCurrentFrame(state);
    if (currentFrame == null) return null;

    final double? currentSpeed = armSpeed.getSpeedAtFrame(currentFrame);
    if (currentSpeed == null) return null;

    // Check if we've reached max speed (within small tolerance)
    final double maxSpeed = armSpeed.maxSpeedMph;
    if ((currentSpeed - maxSpeed).abs() < 0.1 ||
        currentFrame >= armSpeed.maxSpeedFrame) {
      _hasReachedMax = true;
      _lockedMaxSpeed = maxSpeed;
      return maxSpeed;
    }

    return currentSpeed;
  }

  /// Resets the max speed lock (call when video restarts or user seeks backward).
  void _resetMaxSpeedLock() {
    _hasReachedMax = false;
    _lockedMaxSpeed = null;
  }

  Widget _buildVideoPlayer(CheckpointPlaybackState state) {
    final bool showPlayOverlay =
        !state.isPlaying && state.isAtStart && !state.showTapFeedback;
    final bool showReplayOverlay =
        !state.isPlaying && state.isAtEnd && !state.showTapFeedback;
    final bool showPersistentOverlay = showPlayOverlay || showReplayOverlay;

    final CheckpointPlaybackCubit cubit =
        BlocProvider.of<CheckpointPlaybackCubit>(context);

    final bool showArmSpeed =
        locator.get<FeatureFlagService>().getBool(FeatureFlag.showArmSpeed);
    final double? currentSpeed = showArmSpeed ? _getCurrentSpeed(state) : null;
    final detectedHandedness = widget.analysis.analysisResults.detectedHandedness;

    return AspectRatio(
      aspectRatio:
          widget.videoAspectRatio ?? _activeController.value.aspectRatio,
      child: GestureDetector(
        onTap: cubit.onVideoTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_activeController),
            if (showPersistentOverlay)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  showReplayOverlay ? Icons.replay : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            if (state.showTapFeedback)
              Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      state.tapFeedbackIsPlay ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 36,
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    duration: 200.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeOut(
                    delay: 100.ms,
                    duration: 200.ms,
                    curve: Curves.easeOut,
                  ),
            // Arm speed overlay at top left (black text on white card)
            if (currentSpeed != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.speed,
                        color: Colors.black,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${currentSpeed.toStringAsFixed(1)} mph',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Handedness badge at top right
            if (detectedHandedness != null)
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
                    detectedHandedness.badgeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            // Fullscreen button at bottom right
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showFullscreenVideo();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoShimmer() {
    final double? effectiveAspectRatio =
        _returnedVideoAspectRatio ?? widget.videoAspectRatio;

    final Widget shimmer = Container(color: Colors.grey[900])
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.5));

    if (effectiveAspectRatio != null) {
      return AspectRatio(aspectRatio: effectiveAspectRatio, child: shimmer);
    }
    final double h = (widget.videoAspectRatio ?? 1.0) >= 1.0 ? 200.0 : 400.0;
    return SizedBox(height: h, child: shimmer);
  }

  Widget _buildErrorState(String? errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          const Text(
            'Failed to load video',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              errorMessage,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
