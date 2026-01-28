import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/form_analysis/fullscreen_video_dialog.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/video_orientation.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_cubit.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_state.dart';
import 'package:video_player/video_player.dart';

/// Displays the video player and owns the VideoPlayerController lifecycle.
///
/// Accepts an optional [proReferenceWidget] and handles layout based on
/// [videoAspectRatio]:
/// - Portrait (aspect < 1.0): video and pro ref side by side
/// - Landscape (aspect >= 1.0): video on top, pro ref below
///
/// The parent does not need to care about orientation.
class CheckpointVideoDisplay extends StatefulWidget {
  const CheckpointVideoDisplay({
    super.key,
    required this.videoUrl,
    this.skeletonVideoUrl,
    this.skeletonOnlyVideoUrl,
    this.videoAspectRatio,
    this.returnedVideoAspectRatio,
    this.proReferenceWidget,
    this.videoOrientation,
    this.checkpoints,
  });

  /// Network URL for user's form video.
  final String videoUrl;

  /// Network URL for skeleton overlay video.
  final String? skeletonVideoUrl;

  /// Network URL for skeleton-only video.
  final String? skeletonOnlyVideoUrl;

  /// Video aspect ratio (width/height).
  final double? videoAspectRatio;

  /// Aspect ratio of the returned processed videos.
  final double? returnedVideoAspectRatio;

  /// Optional pro reference widget displayed alongside the video.
  /// Layout is handled automatically based on [videoAspectRatio].
  final Widget? proReferenceWidget;

  /// Video orientation (portrait or landscape).
  final VideoOrientation? videoOrientation;

  /// Checkpoints for the fullscreen video dialog selector.
  final List<CheckpointRecord>? checkpoints;

  @override
  State<CheckpointVideoDisplay> createState() =>
      _CheckpointVideoDisplayState();
}

class _CheckpointVideoDisplayState extends State<CheckpointVideoDisplay> {
  late VideoPlayerController _overlayController;
  VideoPlayerController? _skeletonOnlyController;
  bool _isOverlayInitialized = false;
  bool _isSkeletonOnlyInitialized = false;

  /// Whether we're currently showing skeleton-only video (local tracking).
  bool _showingSkeletonOnly = false;

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
      final String overlayUrl = widget.skeletonVideoUrl ?? widget.videoUrl;
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[CheckpointVideoDisplay] INITIALIZING VIDEO CONTROLLERS');
      debugPrint('[CheckpointVideoDisplay] Overlay URL: $overlayUrl');

      _overlayController = VideoPlayerController.networkUrl(
        Uri.parse(overlayUrl),
      );
      await _overlayController.initialize();
      _overlayController.setVolume(0.0);

      debugPrint('[CheckpointVideoDisplay] Overlay controller initialized');

      if (mounted) {
        setState(() => _isOverlayInitialized = true);
      }

      // Initialize skeleton-only controller if URL is available
      if (widget.skeletonOnlyVideoUrl != null) {
        debugPrint(
          '[CheckpointVideoDisplay] Skeleton-only URL: ${widget.skeletonOnlyVideoUrl}',
        );
        _skeletonOnlyController = VideoPlayerController.networkUrl(
          Uri.parse(widget.skeletonOnlyVideoUrl!),
        );
        await _skeletonOnlyController!.initialize();
        _skeletonOnlyController!.setVolume(0.0);

        debugPrint(
          '[CheckpointVideoDisplay] Skeleton-only controller initialized',
        );

        if (mounted) {
          setState(() => _isSkeletonOnlyInitialized = true);
        }
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
          videoOrientation: widget.videoOrientation,
          checkpoints: widget.checkpoints,
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
          prev.isAtEnd != curr.isAtEnd,
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

  Widget _buildVideoPlayer(CheckpointPlaybackState state) {
    final bool showPlayOverlay =
        !state.isPlaying && state.isAtStart && !state.showTapFeedback;
    final bool showReplayOverlay =
        !state.isPlaying && state.isAtEnd && !state.showTapFeedback;
    final bool showPersistentOverlay = showPlayOverlay || showReplayOverlay;

    final CheckpointPlaybackCubit cubit =
        BlocProvider.of<CheckpointPlaybackCubit>(context);

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
                      state.tapFeedbackIsPlay
                          ? Icons.play_arrow
                          : Icons.pause,
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
            // Fullscreen button at bottom right
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: _showFullscreenVideo,
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
        widget.returnedVideoAspectRatio ?? widget.videoAspectRatio;

    final Widget shimmer = Container(color: Colors.grey[900])
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
            duration: 1200.ms, color: Colors.white.withValues(alpha: 0.5));

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
