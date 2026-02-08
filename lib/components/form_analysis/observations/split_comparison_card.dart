import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/pro_comparison_placeholder.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_reference.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Controller for SplitComparisonCard to allow external video control
class SplitComparisonController {
  void Function(int frame)? _seekToFrame;
  VoidCallback? _pause;
  VoidCallback? _play;
  VoidCallback? _togglePlayPause;
  bool Function()? _getIsPlaying;

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

  /// Whether to show tap feedback overlay
  bool _showTapFeedback = false;

  /// Whether the tap feedback shows play (true) or pause (false) icon
  bool _tapFeedbackIsPlay = false;

  /// Playback speed for user video (0.25x for slow motion analysis)
  static const double _userPlaybackSpeed = 0.25;

  int get _startFrame =>
      widget.observation.timing.startFrame ??
      widget.observation.timing.frameNumber;

  int get _endFrame =>
      widget.observation.timing.endFrame ??
      widget.observation.timing.frameNumber;

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
    _userController?.play();
    _proController?.play();
    if (!_isPlaying) {
      setState(() => _isPlaying = true);
      widget.onPlayStateChanged?.call(true);
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
      await _userController!.setPlaybackSpeed(_userPlaybackSpeed);
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

  void _startLoopTimer() {
    _loopTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      // Skip looping while user is scrubbing
      final bool isScrubbing = widget.isScrubbingNotifier?.value ?? false;

      // Report current frame for slider
      if (_userController != null && _userController!.value.isInitialized) {
        final Duration position = _userController!.value.position;
        final int currentFrame = (position.inMilliseconds / 1000 * widget.fps).round();
        widget.onFrameChanged?.call(currentFrame, _startFrame, _endFrame);

        // Loop user video (only if not scrubbing)
        if (!isScrubbing && position >= _endPosition) {
          _userController!.seekTo(_startPosition);
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
        const SizedBox(height: 12),
        // Pro video with label
        _buildVideoWithLabel(
          video: _buildProVideo(),
          label: _proRef?.proName ?? 'PRO',
          labelColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  /// Side-by-side layout for portrait videos
  Widget _buildSideBySideLayout() {
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

    return AspectRatio(
      aspectRatio: _videoAspectRatio,
      child: GestureDetector(
        onTap: _onVideoTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_userController!),
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
    // If pro video is available and initialized
    if (_hasProVideo && _isProInitialized && _proController != null) {
      return AspectRatio(
        aspectRatio: _proController!.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: VideoPlayer(_proController!),
        ),
      );
    }

    // If pro video had an error
    if (_hasProVideo && _proError != null) {
      return _buildErrorState(_proError!);
    }

    // If pro video is loading
    if (_hasProVideo && !_isProInitialized) {
      return _buildLoadingState();
    }

    // If pro has an image but no video
    if (_hasProImage) {
      return AspectRatio(
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
    }

    // No pro content available - show placeholder
    return _buildProPlaceholder();
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
