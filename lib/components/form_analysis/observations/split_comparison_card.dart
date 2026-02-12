import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/pro_comparison_placeholder.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/crop_metadata.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_reference.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Playback mode for video looping
enum PlaybackMode {
  /// Loop forward continuously
  loop,

  /// Play forward then backward (ping-pong)
  boomerang,
}

/// Controller for SplitComparisonCard to allow external video control
class SplitComparisonController {
  void Function(int frame)? _seekToFrame;
  VoidCallback? _pause;
  VoidCallback? _play;
  VoidCallback? _togglePlayPause;
  bool Function()? _getIsPlaying;
  void Function(PlaybackMode mode)? _setPlaybackMode;
  PlaybackMode Function()? _getPlaybackMode;
  void Function(double speed)? _setPlaybackSpeed;
  double Function()? _getPlaybackSpeed;
  void Function(int start, int end)? _updateFrameRange;

  /// Seek the user video to a specific frame
  void seekToFrame(int frame) => _seekToFrame?.call(frame);

  /// Pause video playback
  void pause() => _pause?.call();

  /// Resume video playback
  void play() => _play?.call();

  /// Toggle play/pause state
  void togglePlayPause() => _togglePlayPause?.call();

  /// Get current playing state
  bool get isPlaying => _getIsPlaying?.call() ?? false;

  /// Set the playback mode (loop or boomerang)
  void setPlaybackMode(PlaybackMode mode) => _setPlaybackMode?.call(mode);

  /// Get the current playback mode
  PlaybackMode get playbackMode =>
      _getPlaybackMode?.call() ?? PlaybackMode.boomerang;

  /// Set the playback speed (e.g., 0.25, 0.5, 1.0)
  void setPlaybackSpeed(double speed) => _setPlaybackSpeed?.call(speed);

  /// Get the current playback speed
  double get playbackSpeed => _getPlaybackSpeed?.call() ?? 0.25;

  /// Update the frame range for looping
  void updateFrameRange(int start, int end) =>
      _updateFrameRange?.call(start, end);
}

/// Split-screen video comparison showing user's form vs pro
/// - Portrait video: side by side
/// - Landscape video: stacked (you on top, pro below)
class SplitComparisonCard extends StatefulWidget {
  const SplitComparisonCard({
    super.key,
    required this.observation,
    required this.userVideoUrl,
    required this.fps,
    this.onFrameChanged,
    this.onPlayStateChanged,
    this.isScrubbingNotifier,
    this.controller,
    this.showProComparison = true,
    this.isLeftHanded = false,
    this.cropMetadata,
    this.initialPlaybackSpeed = 0.25,
    this.initialStartFrame,
    this.initialEndFrame,
    this.totalFrames,
  });

  final FormObservation observation;
  final String userVideoUrl;
  final double fps;

  /// Called when the current frame changes during playback
  final void Function(int currentFrame, int startFrame, int endFrame)?
      onFrameChanged;

  /// Called when play state changes
  final void Function(bool isPlaying)? onPlayStateChanged;

  /// Notifier to control whether auto-looping is paused (e.g., during scrubbing)
  final ValueNotifier<bool>? isScrubbingNotifier;

  /// Controller for external video control (seeking, pause, play)
  final SplitComparisonController? controller;

  /// Whether to show the pro comparison video/image (default: true)
  final bool showProComparison;

  /// Whether the user is left-handed (flips pro video/image horizontally)
  final bool isLeftHanded;

  /// Optional crop metadata for zooming into a specific region
  final CropMetadata? cropMetadata;

  /// Initial playback speed (default: 0.25x for slow motion)
  final double initialPlaybackSpeed;

  /// Initial start frame for the segment (overrides observation timing)
  final int? initialStartFrame;

  /// Initial end frame for the segment (overrides observation timing)
  final int? initialEndFrame;

  /// Total frames in the video (for clamping bounds)
  final int? totalFrames;

  @override
  State<SplitComparisonCard> createState() => _SplitComparisonCardState();
}

class _SplitComparisonCardState extends State<SplitComparisonCard> {
  VideoPlayerController? _userController;
  VideoPlayerController? _proController;
  Timer? _loopTimer;
  bool _isUserInitialized = false;
  bool _isProInitialized = false;
  String? _userError;
  String? _proError;

  /// Whether video is currently playing
  bool _isPlaying = true;

  /// Whether we've already paused at the key frame (for frame_range mode)
  bool _hasPausedAtKeyFrame = false;

  /// Whether to show tap feedback overlay
  bool _showTapFeedback = false;

  /// Whether the tap feedback shows play (true) or pause (false) icon
  bool _tapFeedbackIsPlay = false;

  /// Current playback speed for user video
  late double _playbackSpeed;

  /// Current start frame (can be updated dynamically)
  int? _dynamicStartFrame;

  /// Current end frame (can be updated dynamically)
  int? _dynamicEndFrame;

  /// Current playback mode (loop or boomerang)
  PlaybackMode _playbackMode = PlaybackMode.boomerang;

  /// Whether playing forward (true) or backward (false) in boomerang mode
  bool _isPlayingForward = true;

  /// Accumulated fractional frames for smooth reverse playback
  double _accumulatedReverseFrames = 0.0;

  int get _startFrame {
    // Use dynamic value if set, otherwise use widget override or observation timing
    if (_dynamicStartFrame != null) return _dynamicStartFrame!;
    if (widget.initialStartFrame != null) return widget.initialStartFrame!;
    return widget.observation.timing.startFrame ??
        widget.observation.timing.frameNumber;
  }

  int get _endFrame {
    // Use dynamic value if set, otherwise use widget override or observation timing
    if (_dynamicEndFrame != null) return _dynamicEndFrame!;
    if (widget.initialEndFrame != null) return widget.initialEndFrame!;
    return widget.observation.timing.endFrame ??
        widget.observation.timing.frameNumber;
  }

  /// The key frame to pause at (when in frame_range mode)
  int get _keyFrame => widget.observation.timing.frameNumber;

  /// Whether this observation uses frame_range display mode
  bool get _isFrameRangeMode => widget.observation.timing.isFrameRange;

  /// Seek the user video to a specific frame within the segment
  void seekToFrame(int frame) {
    if (_userController == null || !_userController!.value.isInitialized) {
      return;
    }
    final int clampedFrame = frame.clamp(_startFrame, _endFrame);
    final Duration position = Duration(
      milliseconds: ((clampedFrame / widget.fps) * 1000).round(),
    );
    _userController!.seekTo(position);
  }

  /// Pause video playback
  void pause() {
    _userController?.pause();
    _proController?.pause();
    if (_isPlaying) {
      setState(() => _isPlaying = false);
      widget.onPlayStateChanged?.call(false);
    }
  }

  /// Resume video playback
  void play() {
    // In boomerang mode when playing backward, don't call play() on controller
    // since we're manually stepping through frames
    if (_playbackMode == PlaybackMode.boomerang && !_isPlayingForward) {
      // Just set playing state - the loop timer will handle stepping
      if (!_isPlaying) {
        setState(() => _isPlaying = true);
        widget.onPlayStateChanged?.call(true);
      }
    } else {
      _userController?.play();
      _proController?.play();
      if (!_isPlaying) {
        setState(() => _isPlaying = true);
        widget.onPlayStateChanged?.call(true);
      }
    }
  }

  /// Toggle play/pause state with tap feedback
  void togglePlayPause() {
    HapticFeedback.lightImpact();
    if (_isPlaying) {
      pause();
      _showFeedback(isPlay: false);
    } else {
      play();
      _showFeedback(isPlay: true);
    }
  }

  /// Handle video tap
  void _onVideoTap() {
    togglePlayPause();
  }

  /// Show tap feedback overlay with animation
  void _showFeedback({required bool isPlay}) {
    setState(() {
      _showTapFeedback = true;
      _tapFeedbackIsPlay = isPlay;
    });
    // Hide feedback after animation completes
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _showTapFeedback = false);
      }
    });
  }

  Duration get _startPosition {
    return Duration(
      milliseconds: ((_startFrame / widget.fps) * 1000).round(),
    );
  }

  Duration get _endPosition {
    return Duration(
      milliseconds: ((_endFrame / widget.fps) * 1000).round(),
    );
  }

  ProReference? get _proRef => widget.observation.proReference;
  bool get _hasProVideo => _proRef?.proVideoUrl != null;
  bool get _hasProImage => _proRef?.proImageUrl != null;

  /// Whether the video is landscape (width > height)
  bool get _isLandscape {
    if (_userController == null || !_userController!.value.isInitialized) {
      return false;
    }
    return _userController!.value.aspectRatio > 1.0;
  }

  double get _videoAspectRatio {
    if (_userController == null || !_userController!.value.isInitialized) {
      return 9 / 16; // Default portrait
    }
    return _userController!.value.aspectRatio;
  }

  @override
  void initState() {
    super.initState();
    _playbackSpeed = widget.initialPlaybackSpeed;
    _bindController();
    _initializeVideos();
  }

  void _bindController() {
    final SplitComparisonController? controller = widget.controller;
    if (controller != null) {
      controller._seekToFrame = seekToFrame;
      controller._pause = pause;
      controller._play = play;
      controller._togglePlayPause = togglePlayPause;
      controller._getIsPlaying = () => _isPlaying;
      controller._setPlaybackMode = _setPlaybackMode;
      controller._getPlaybackMode = () => _playbackMode;
      controller._setPlaybackSpeed = _setPlaybackSpeed;
      controller._getPlaybackSpeed = () => _playbackSpeed;
      controller._updateFrameRange = _updateFrameRange;
    }
  }

  void _setPlaybackMode(PlaybackMode mode) {
    if (_playbackMode != mode) {
      _playbackMode = mode;
      // Reset to forward direction when switching modes
      _isPlayingForward = true;
    }
  }

  void _setPlaybackSpeed(double speed) {
    if (_playbackSpeed != speed) {
      setState(() {
        _playbackSpeed = speed;
      });
      _userController?.setPlaybackSpeed(speed);
    }
  }

  void _updateFrameRange(int start, int end) {
    // Clamp to video bounds if totalFrames is known
    final int maxFrame = widget.totalFrames ?? end;
    final int clampedStart = start.clamp(0, maxFrame);
    final int clampedEnd = end.clamp(0, maxFrame);

    if (_dynamicStartFrame != clampedStart || _dynamicEndFrame != clampedEnd) {
      setState(() {
        _dynamicStartFrame = clampedStart;
        _dynamicEndFrame = clampedEnd;
      });
    }
  }

  Future<void> _initializeVideos() async {
    await _initializeUserVideo();
    if (_hasProVideo) {
      await _initializeProVideo();
    }
    _startLoopTimer();
  }

  Future<void> _initializeUserVideo() async {
    try {
      _userController = VideoPlayerController.networkUrl(
        Uri.parse(widget.userVideoUrl),
      );
      await _userController!.initialize();
      await _userController!.setVolume(0);
      await _userController!.setPlaybackSpeed(_playbackSpeed);
      await _userController!.seekTo(_startPosition);
      await _userController!.play();

      if (mounted) {
        setState(() {
          _isUserInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userError = 'Unable to load video';
        });
      }
    }
  }

  Future<void> _initializeProVideo() async {
    if (_proRef?.proVideoUrl == null) return;

    try {
      _proController = VideoPlayerController.networkUrl(
        Uri.parse(_proRef!.proVideoUrl!),
      );
      await _proController!.initialize();
      await _proController!.setVolume(0);

      // Seek to pro's segment if available
      if (_proRef!.proVideoStartSeconds != null) {
        await _proController!.seekTo(
          Duration(
            milliseconds: (_proRef!.proVideoStartSeconds! * 1000).round(),
          ),
        );
      }
      await _proController!.play();

      if (mounted) {
        setState(() {
          _isProInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _proError = 'Unable to load pro video';
        });
      }
    }
  }

  /// Timer interval in milliseconds - ~30fps for smooth reverse playback
  static const int _timerIntervalMs = 33;

  void _startLoopTimer() {
    _loopTimer =
        Timer.periodic(const Duration(milliseconds: _timerIntervalMs), (_) {
      // Calculate ms per frame at current playback speed for boomerang reverse stepping
      // This must be inside the callback to use the current _playbackSpeed value
      final double msPerFrame = (1000 / widget.fps) / _playbackSpeed;

      // Skip looping while user is scrubbing
      final bool isScrubbing = widget.isScrubbingNotifier?.value ?? false;

      // Report current frame for slider
      if (_userController != null && _userController!.value.isInitialized) {
        final Duration position = _userController!.value.position;
        final int currentFrame =
            (position.inMilliseconds / 1000 * widget.fps).round();
        widget.onFrameChanged?.call(currentFrame, _startFrame, _endFrame);

        // In frame_range mode, pause at the key frame on first playthrough
        if (_isFrameRangeMode &&
            !_hasPausedAtKeyFrame &&
            !isScrubbing &&
            _isPlaying &&
            currentFrame >= _keyFrame) {
          _hasPausedAtKeyFrame = true;
          // Seek to exact key frame and pause
          seekToFrame(_keyFrame);
          pause();
        }

        // Handle looping based on playback mode (only if not scrubbing)
        if (!isScrubbing && _isPlaying) {
          if (_playbackMode == PlaybackMode.loop) {
            // Standard loop: jump back to start when reaching end
            if (position >= _endPosition) {
              _userController!.seekTo(_startPosition);
            }
          } else {
            // Boomerang mode: manually step backwards since video_player
            // doesn't support negative playback speeds
            if (_isPlayingForward) {
              // Playing forward - check if we reached the end
              if (position >= _endPosition) {
                _isPlayingForward = false;
                _accumulatedReverseFrames = 0.0; // Reset accumulator
                _userController!.pause();
              }
            } else {
              // Playing backward - accumulate fractional frames for smooth playback
              // This ensures reverse plays at the same speed as forward
              // framesToAccumulate = timerInterval / msPerFrame
              final double framesToAccumulate = _timerIntervalMs / msPerFrame;
              _accumulatedReverseFrames += framesToAccumulate;

              // Only step when we've accumulated at least 1 full frame
              if (_accumulatedReverseFrames >= 1.0) {
                final int framesToStep = _accumulatedReverseFrames.floor();
                _accumulatedReverseFrames -= framesToStep;

                final int targetFrame = currentFrame - framesToStep;

                if (targetFrame <= _startFrame) {
                  // Reached start - switch to forward playback
                  _isPlayingForward = true;
                  _accumulatedReverseFrames = 0.0;
                  _userController!.seekTo(_startPosition);
                  _userController!.play();
                } else {
                  // Step backwards
                  seekToFrame(targetFrame);
                }
              }
            }
          }
        }
      }

      // Loop pro video (only if not scrubbing)
      if (!isScrubbing &&
          _proController != null &&
          _proController!.value.isInitialized) {
        final Duration position = _proController!.value.position;
        final Duration endPos = _proRef?.proVideoEndSeconds != null
            ? Duration(
                milliseconds: (_proRef!.proVideoEndSeconds! * 1000).round())
            : _proController!.value.duration;
        final Duration startPos = _proRef?.proVideoStartSeconds != null
            ? Duration(
                milliseconds: (_proRef!.proVideoStartSeconds! * 1000).round())
            : Duration.zero;

        if (position >= endPos) {
          _proController!.seekTo(startPos);
        }
      }
    });
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _userController?.dispose();
    _proController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while user video initializes (to determine layout)
    if (!_isUserInitialized && _userError == null) {
      return _buildLoadingLayout();
    }

    // Use stacked layout for landscape, side-by-side for portrait
    if (_isLandscape) {
      return _buildStackedLayout();
    } else {
      return _buildSideBySideLayout();
    }
  }

  Widget _buildLoadingLayout() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: SenseiColors.gray[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Stacked layout for landscape videos (you on top, pro below)
  Widget _buildStackedLayout() {
    return Column(
      children: [
        // User video with label
        _buildVideoWithLabel(
          video: _buildUserVideo(),
          label: 'YOU',
          labelColor: SenseiColors.gray[700]!,
        ),
        // Pro video with label (conditionally shown)
        if (widget.showProComparison) ...[
          const SizedBox(height: 12),
          _buildVideoWithLabel(
            video: _buildProVideo(),
            label: _proRef?.proName ?? 'PRO',
            labelColor: const Color(0xFF10B981),
          ),
        ],
      ],
    );
  }

  /// Side-by-side layout for portrait videos
  Widget _buildSideBySideLayout() {
    // User video only (no pro comparison)
    if (!widget.showProComparison) {
      return Column(
        children: [
          _buildUserVideo(),
          const SizedBox(height: 8),
          _buildLabel('YOU', SenseiColors.gray[700]!),
        ],
      );
    }

    // Side-by-side with pro comparison
    return Column(
      children: [
        // Video comparison row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildUserVideo()),
            const SizedBox(width: 8),
            Expanded(child: _buildProVideo()),
          ],
        ),
        const SizedBox(height: 8),
        // Labels
        Row(
          children: [
            Expanded(
              child: _buildLabel('YOU', SenseiColors.gray[700]!),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLabel(
                _proRef?.proName ?? 'PRO',
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoWithLabel({
    required Widget video,
    required String label,
    required Color labelColor,
  }) {
    return Column(
      children: [
        video,
        const SizedBox(height: 6),
        _buildLabel(label, labelColor),
      ],
    );
  }

  Widget _buildUserVideo() {
    if (_userError != null) {
      return _buildErrorState(_userError!);
    }

    if (!_isUserInitialized) {
      return _buildLoadingState();
    }

    Widget videoPlayer = VideoPlayer(_userController!);

    // Apply crop transformation if metadata is provided
    final CropMetadata? crop = widget.cropMetadata;
    if (crop != null) {
      // Calculate the zoom level (inverse of scale, so 0.35 scale = ~2.86x zoom)
      final double zoomLevel = 1 / crop.scale;

      // Calculate alignment based on center coordinates
      // Convert 0-1 range to -1 to 1 range for Alignment
      final double alignX = (crop.centerX - 0.5) * 2;
      final double alignY = (crop.centerY - 0.5) * 2;

      videoPlayer = ClipRect(
        child: Transform.scale(
          scale: zoomLevel,
          alignment: Alignment(alignX, alignY),
          child: videoPlayer,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoAspectRatio,
      child: GestureDetector(
        onTap: _onVideoTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              videoPlayer,
              // Tap feedback overlay
              if (_showTapFeedback)
                Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _tapFeedbackIsPlay ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 28,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProVideo() {
    Widget content;

    // If pro video is available and initialized
    if (_hasProVideo && _isProInitialized && _proController != null) {
      content = AspectRatio(
        aspectRatio: _proController!.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: VideoPlayer(_proController!),
        ),
      );
    } else if (_hasProVideo && _proError != null) {
      // If pro video had an error
      return _buildErrorState(_proError!);
    } else if (_hasProVideo && !_isProInitialized) {
      // If pro video is loading
      return _buildLoadingState();
    } else if (_hasProImage) {
      // If pro has an image but no video
      content = AspectRatio(
        aspectRatio: _videoAspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: _proRef!.proImageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildLoadingState(),
            errorWidget: (context, url, error) => _buildProPlaceholder(),
          ),
        ),
      );
    } else {
      // No pro content available - show placeholder
      return _buildProPlaceholder();
    }

    // Flip horizontally for left-handed users
    if (widget.isLeftHanded) {
      return Transform.flip(flipX: true, child: content);
    }

    return content;
  }

  Widget _buildProPlaceholder() {
    return ProComparisonPlaceholder(
      proName: _proRef?.proName,
      proMeasurement: _proRef?.proMeasurement?.formatted,
      aspectRatio: _videoAspectRatio,
    );
  }

  Widget _buildLoadingState() {
    return AspectRatio(
      aspectRatio: _videoAspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: SenseiColors.gray[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return AspectRatio(
      aspectRatio: _videoAspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: SenseiColors.gray[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 24,
                color: SenseiColors.gray[400],
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  fontSize: 11,
                  color: SenseiColors.gray[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
