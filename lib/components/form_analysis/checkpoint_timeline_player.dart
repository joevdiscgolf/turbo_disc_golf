import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Playback mode for checkpoint auto-pause behavior.
enum CheckpointPauseMode {
  /// Pause for 2 seconds at each checkpoint, then auto-resume
  timedPause,

  /// Pause indefinitely at each checkpoint until user resumes
  pauseIndefinitely,

  /// Play through without pausing at checkpoints
  continuous,
}

/// Video player with checkpoint timeline markers for form analysis.
///
/// Displays the user's form video with checkpoint markers (heisman, loaded, magic, pro)
/// on a timeline scrubber. Users can tap markers to jump to positions, and the player
/// auto-pauses at each checkpoint during playback at slow speed.
///
/// Features:
/// - Video playback with network URL loading
/// - Timeline scrubber with color-coded checkpoint markers
/// - Tap marker to jump to that checkpoint
/// - Auto-pause toggle (default: ON) - pauses at each checkpoint during playback
/// - Speed selector: 0.25x (default), 0.5x, 1.0x
/// - Timer-based playback simulation (~30fps)
/// - Two UI styles controlled by feature flag: darkSlateOverlay (default), cleanSportMinimal
class CheckpointTimelinePlayer extends StatefulWidget {
  const CheckpointTimelinePlayer({
    super.key,
    required this.videoUrl,
    required this.checkpoints,
    required this.videoDurationSeconds,
    this.skeletonVideoUrl,
    this.videoAspectRatio,
    this.initialSpeed = 0.25,
    this.onCheckpointTapped,
    this.selectedCheckpointIndex,
  });

  /// Network URL for user's form video
  final String videoUrl;

  /// Network URL for skeleton-only video (used when useSkeletonVideoInTimelinePlayer is enabled)
  final String? skeletonVideoUrl;

  /// Checkpoints with timestamp data
  final List<CheckpointRecord> checkpoints;

  /// Total video duration in seconds
  final double videoDurationSeconds;

  /// Video aspect ratio (width/height)
  final double? videoAspectRatio;

  /// Initial playback speed (default: 0.25x)
  final double initialSpeed;

  /// Callback when the checkpoint label is tapped (opens education panel)
  final void Function(CheckpointRecord checkpoint)? onCheckpointTapped;

  /// External checkpoint selection - when changed, player jumps to that checkpoint
  final int? selectedCheckpointIndex;

  @override
  State<CheckpointTimelinePlayer> createState() =>
      _CheckpointTimelinePlayerState();
}

class _CheckpointTimelinePlayerState extends State<CheckpointTimelinePlayer> {
  late VideoPlayerController _controller;

  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  String? _errorMessage;
  CheckpointPauseMode _pauseMode = CheckpointPauseMode.timedPause;

  Duration _currentPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  double _playbackSpeed = 0.25;

  Timer? _positionUpdateTimer;
  Timer? _playbackSimulationTimer;
  Timer? _autoResumeTimer;

  /// Index of the last checkpoint we auto-paused at (to avoid re-pausing)
  int _lastAutoPausedCheckpointIndex = -1;

  /// Index of checkpoint we're currently paused at (null if not at checkpoint)
  int? _currentPausedCheckpointIndex;

  // Frame interval for playback simulation (~30fps)
  static const Duration _playbackFrameInterval = Duration(milliseconds: 33);

  // Dark Slate Overlay colors
  static const Color _darkOverlayBg = Color(0xFF0F172A);
  static const Color _darkTrackInactive = Color(0xFF334155);
  static const Color _darkTrackActive = Color(0xFF06B6D4);
  static const Color _darkThumbColor = Colors.white;

  // Clean Sport Minimal colors
  static const Color _cleanTrackInactive = Color(0xFFE2E8F0);
  static const Color _cleanGradientStart = Color(0xFF3B82F6);
  static const Color _cleanGradientEnd = Color(0xFF8B5CF6);
  static const Color _cleanTextColor = Color(0xFF1E293B);

  // Checkpoint colors by ID
  static const Map<String, Color> _checkpointColors = {
    'heisman': Colors.blue,
    'loaded': Colors.green,
    'magic': Colors.amber,
    'pro': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _playbackSpeed = widget.initialSpeed;
    _initializeController();
  }

  @override
  void dispose() {
    _positionUpdateTimer?.cancel();
    _playbackSimulationTimer?.cancel();
    _autoResumeTimer?.cancel();
    _controller.removeListener(_onVideoPositionChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CheckpointTimelinePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jump to checkpoint when external selection changes
    if (widget.selectedCheckpointIndex != oldWidget.selectedCheckpointIndex &&
        widget.selectedCheckpointIndex != null &&
        _isInitialized) {
      _jumpToCheckpoint(widget.selectedCheckpointIndex!);
    }
  }

  Future<void> _initializeController() async {
    try {
      // Decide which video URL to use based on feature flag
      final FeatureFlagService featureFlags = locator.get<FeatureFlagService>();
      final bool useSkeletonVideo =
          featureFlags.useSkeletonVideoInTimelinePlayer &&
          widget.skeletonVideoUrl != null;
      debugPrint(
        'using skeleton video: $useSkeletonVideo, url: ${widget.skeletonVideoUrl}',
      );
      final String effectiveVideoUrl = useSkeletonVideo
          ? widget.skeletonVideoUrl!
          : widget.videoUrl;

      final Uri videoUri = Uri.parse(effectiveVideoUrl);
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[CheckpointTimelinePlayer] INITIALIZING VIDEO CONTROLLER');
      debugPrint(
        '[CheckpointTimelinePlayer] Using skeleton video: $useSkeletonVideo',
      );
      debugPrint('[CheckpointTimelinePlayer] URL scheme: ${videoUri.scheme}');
      debugPrint('[CheckpointTimelinePlayer] URL host: ${videoUri.host}');
      debugPrint('[CheckpointTimelinePlayer] URL path: ${videoUri.path}');
      debugPrint(
        '[CheckpointTimelinePlayer] URL query params: ${videoUri.queryParameters.keys.toList()}',
      );
      debugPrint('[CheckpointTimelinePlayer] FULL URL:');
      debugPrint(effectiveVideoUrl);
      debugPrint('═══════════════════════════════════════════════════════');

      _controller = VideoPlayerController.networkUrl(videoUri);

      debugPrint(
        '[CheckpointTimelinePlayer] Controller created, calling initialize()...',
      );
      await _controller.initialize();
      debugPrint('[CheckpointTimelinePlayer] Video initialized successfully');
      debugPrint(
        '[CheckpointTimelinePlayer] Duration: ${_controller.value.duration}',
      );
      debugPrint('[CheckpointTimelinePlayer] Size: ${_controller.value.size}');

      _controller.setVolume(0.0);

      _videoDuration = _controller.value.duration;
      _controller.addListener(_onVideoPositionChanged);

      _positionUpdateTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _updatePosition(),
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[CheckpointTimelinePlayer] FAILED TO LOAD VIDEO');
      debugPrint('[CheckpointTimelinePlayer] Error type: ${e.runtimeType}');
      debugPrint('[CheckpointTimelinePlayer] Error: $e');
      debugPrint('[CheckpointTimelinePlayer] Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: ${e.toString()}';
        });
      }
    }
  }

  void _onVideoPositionChanged() {
    // Listener for video controller state changes
  }

  void _updatePosition() {
    if (mounted && _isInitialized && !_isPlaying) {
      final Duration position = _controller.value.position;
      setState(() {
        _currentPosition = position;
      });
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause(cancelAutoResume: true);
    } else {
      _play();
    }
  }

  Future<void> _play() async {
    // If at or near end of video, reset to beginning
    const Duration endThreshold = Duration(milliseconds: 100);
    final bool isAtEnd = _currentPosition >= _videoDuration - endThreshold;

    final Duration startPosition = isAtEnd
        ? Duration.zero
        : _controller.value.position;

    await _controller.seekTo(startPosition);

    // Reset auto-pause tracking when starting fresh
    if (isAtEnd) {
      _lastAutoPausedCheckpointIndex = -1;
    }

    // Clear paused checkpoint when playing
    _currentPausedCheckpointIndex = null;

    setState(() {
      _currentPosition = startPosition;
      _isPlaying = true;
    });

    debugPrint(
      '[CheckpointTimelinePlayer] Play: ${(startPosition.inMilliseconds / 1000.0).toStringAsFixed(2)}s at ${_playbackSpeed}x speed',
    );

    _playbackSimulationTimer = Timer.periodic(_playbackFrameInterval, (_) {
      if (!_isPlaying || !mounted) {
        _playbackSimulationTimer?.cancel();
        return;
      }

      // Calculate next position based on playback speed
      final Duration nextPosition =
          _currentPosition +
          Duration(
            milliseconds:
                (_playbackFrameInterval.inMilliseconds * _playbackSpeed)
                    .round(),
          );

      // Check if reached end of video
      if (nextPosition >= _videoDuration) {
        _pause();
        return;
      }

      // Check for auto-pause at checkpoints (unless in continuous mode)
      if (_pauseMode != CheckpointPauseMode.continuous) {
        final int checkpointIndex = _findCheckpointAtPosition(nextPosition);
        if (checkpointIndex != -1 &&
            checkpointIndex != _lastAutoPausedCheckpointIndex) {
          _lastAutoPausedCheckpointIndex = checkpointIndex;
          _autoPauseAtCheckpoint(checkpointIndex, nextPosition);
          return;
        }
      }

      // Seek to next position
      final double normalizedValue =
          nextPosition.inMilliseconds / _videoDuration.inMilliseconds;
      _onSeek(normalizedValue);
    });
  }

  /// Find checkpoint index at or very close to the given position.
  /// Returns -1 if no checkpoint found within threshold.
  int _findCheckpointAtPosition(Duration position) {
    const double thresholdSeconds = 0.05; // 50ms threshold
    final double positionSeconds = position.inMilliseconds / 1000.0;

    for (int i = 0; i < widget.checkpoints.length; i++) {
      final CheckpointRecord cp = widget.checkpoints[i];
      if (cp.timestampSeconds != null) {
        final double diff = (cp.timestampSeconds! - positionSeconds).abs();
        if (diff <= thresholdSeconds) {
          return i;
        }
      }
    }
    return -1;
  }

  void _autoPauseAtCheckpoint(int checkpointIndex, Duration position) {
    HapticFeedback.mediumImpact();
    final CheckpointRecord cp = widget.checkpoints[checkpointIndex];

    debugPrint(
      '[CheckpointTimelinePlayer] Auto-pause at checkpoint: ${cp.checkpointName} (mode: $_pauseMode)',
    );

    // Seek to exact checkpoint position
    if (cp.timestampSeconds != null) {
      final Duration exactPosition = Duration(
        milliseconds: (cp.timestampSeconds! * 1000).toInt(),
      );
      _controller.seekTo(exactPosition);
      setState(() {
        _currentPosition = exactPosition;
        _currentPausedCheckpointIndex = checkpointIndex;
      });
    }

    _pause();

    // If timed pause mode, auto-resume after 2 seconds
    if (_pauseMode == CheckpointPauseMode.timedPause) {
      _autoResumeTimer?.cancel();
      _autoResumeTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && !_isPlaying) {
          debugPrint(
            '[CheckpointTimelinePlayer] Auto-resuming after 2s pause at ${cp.checkpointName}',
          );
          _play();
        }
      });
    }
  }

  void _pause({bool cancelAutoResume = false}) {
    _playbackSimulationTimer?.cancel();
    _playbackSimulationTimer = null;
    _controller.pause();

    // Cancel auto-resume if user manually pauses
    if (cancelAutoResume) {
      _autoResumeTimer?.cancel();
      _autoResumeTimer = null;
    }

    setState(() => _isPlaying = false);

    debugPrint(
      '[CheckpointTimelinePlayer] Pause: ${(_currentPosition.inMilliseconds / 1000.0).toStringAsFixed(2)}s',
    );
  }

  Future<void> _onSeek(double value) async {
    final Duration position = Duration(
      milliseconds: (value * _videoDuration.inMilliseconds).toInt(),
    );

    await _controller.seekTo(position);

    // Clear paused checkpoint on manual seek
    _currentPausedCheckpointIndex = null;

    setState(() {
      _currentPosition = position;
    });
  }

  void _jumpToCheckpoint(int index) {
    final CheckpointRecord cp = widget.checkpoints[index];
    if (cp.timestampSeconds == null) return;

    HapticFeedback.selectionClick();

    final Duration position = Duration(
      milliseconds: (cp.timestampSeconds! * 1000).toInt(),
    );

    // Reset auto-pause tracking so we can pause at this checkpoint again
    _lastAutoPausedCheckpointIndex = -1;

    _controller.seekTo(position);
    setState(() {
      _currentPosition = position;
      _currentPausedCheckpointIndex = index;
    });

    debugPrint(
      '[CheckpointTimelinePlayer] Jump to ${cp.checkpointName}: ${cp.timestampSeconds}s',
    );
  }

  Future<void> _changePlaybackSpeed(double speed) async {
    final bool wasPlaying = _isPlaying;

    if (wasPlaying) {
      _pause();
    }

    setState(() {
      _playbackSpeed = speed;
    });

    debugPrint('[CheckpointTimelinePlayer] Speed changed to ${speed}x');

    if (wasPlaying) {
      await _play();
    }
  }

  String _getCheckpointLabel(String checkpointId) {
    switch (checkpointId) {
      case 'heisman':
        return 'H';
      case 'loaded':
        return 'L';
      case 'magic':
        return 'M';
      case 'pro':
        return 'P';
      default:
        return checkpointId.substring(0, 1).toUpperCase();
    }
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState();
    }

    if (!_isInitialized) {
      return _buildLoadingState();
    }

    final FeatureFlagService featureFlags = locator.get<FeatureFlagService>();
    final String style = featureFlags.checkpointTimelinePlayerStyle;

    if (style == 'cleanSportMinimal') {
      return _buildCleanSportStyle();
    }

    return _buildDarkSlateStyle();
  }

  Widget _buildDarkSlateStyle() {
    return Column(
      children: [
        _buildVideoPlayer(),
        // Dark overlay controls container
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: _darkOverlayBg.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Checkpoint label (shows when paused at checkpoint)
              _buildCheckpointLabel(),
              // Timeline with markers
              _buildDarkSlateTimeline(),
              const SizedBox(height: 16),
              // Controls row
              _buildDarkSlateControls(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCleanSportStyle() {
    return Column(
      children: [
        // Video with overlaid checkpoint label (full width)
        Stack(
          children: [
            _buildVideoPlayerFullWidth(),
            // Checkpoint label overlaid on top right of video
            _buildCheckpointLabelOverlay(),
          ],
        ),
        // Controls area with gradient background (no spacing from video)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                SenseiColors.gray[50]!,
              ],
            ),
          ),
          child: Column(
            children: [
              // Timeline with tick marks
              _buildCleanSportTimeline(),
              const SizedBox(height: 8),
              // Controls row
              _buildCleanSportControlsRow(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: widget.videoAspectRatio ?? _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }

  Widget _buildVideoPlayerFullWidth() {
    return AspectRatio(
      aspectRatio: widget.videoAspectRatio ?? _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }

  Widget _buildCheckpointLabel() {
    final bool shouldShow = !_isPlaying && _currentPausedCheckpointIndex != null;
    final CheckpointRecord? checkpoint = _currentPausedCheckpointIndex != null
        ? widget.checkpoints[_currentPausedCheckpointIndex!]
        : null;

    return AnimatedOpacity(
      opacity: shouldShow ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: shouldShow ? 56 : 0,
        child: shouldShow && checkpoint != null
            ? GestureDetector(
                onTap: () => widget.onCheckpointTapped?.call(checkpoint),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        checkpoint.checkpointName.toUpperCase(),
                        style: const TextStyle(
                          color: _darkTrackActive,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to learn more',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCheckpointLabelOverlay() {
    // Show checkpoint label if paused at checkpoint OR if current position is at a checkpoint
    final int nearbyCheckpointIndex = _findCheckpointAtPosition(_currentPosition);
    final bool hasNearbyCheckpoint = nearbyCheckpointIndex != -1;
    final bool shouldShow = _currentPausedCheckpointIndex != null || hasNearbyCheckpoint;

    final CheckpointRecord? checkpoint = _currentPausedCheckpointIndex != null
        ? widget.checkpoints[_currentPausedCheckpointIndex!]
        : (hasNearbyCheckpoint ? widget.checkpoints[nearbyCheckpointIndex] : null);

    return Positioned(
      top: 12,
      right: 12,
      child: AnimatedOpacity(
        opacity: shouldShow ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: shouldShow && checkpoint != null
            ? GestureDetector(
                onTap: () => widget.onCheckpointTapped?.call(checkpoint),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _capitalizeFirst(checkpoint.checkpointName),
                        style: const TextStyle(
                          color: _cleanTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.help_outline,
                        size: 14,
                        color: _cleanTextColor.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildDarkSlateTimeline() {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double sliderWidth = constraints.maxWidth - 32;
              return Stack(
                children: [
                  // Custom slider track
                  Positioned.fill(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: _darkTrackActive,
                        inactiveTrackColor: _darkTrackInactive,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        thumbColor: _darkThumbColor,
                        overlayColor: _darkTrackActive.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: _videoDuration.inMilliseconds > 0
                            ? (_currentPosition.inMilliseconds /
                                      _videoDuration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                            : 0.0,
                        min: 0.0,
                        max: 1.0,
                        onChanged: _onSeek,
                      ),
                    ),
                  ),
                  // Diamond checkpoint markers
                  ...widget.checkpoints.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final CheckpointRecord cp = entry.value;
                    if (cp.timestampSeconds == null) {
                      return const SizedBox.shrink();
                    }
                    return _buildDarkSlateDiamondMarker(
                      index,
                      cp,
                      sliderWidth: sliderWidth,
                    );
                  }),
                ],
              );
            },
          ),
        ),
        // Time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                _formatDuration(_videoDuration),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDarkSlateDiamondMarker(
    int index,
    CheckpointRecord cp, {
    required double sliderWidth,
  }) {
    final double position = cp.timestampSeconds! / widget.videoDurationSeconds;
    final Color color = _checkpointColors[cp.checkpointId] ?? Colors.purple;
    final String label = _getCheckpointLabel(cp.checkpointId);

    // Calculate horizontal position (accounting for slider padding)
    final double markerX = 16 + (sliderWidth * position);

    return Positioned(
      left: markerX - 12,
      top: 4,
      child: GestureDetector(
        onTap: () => _jumpToCheckpoint(index),
        child: Column(
          children: [
            // Diamond shape
            Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Label
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanSportTimeline() {
    // Thumb radius for padding calculations
    const double thumbRadius = 8;

    return SizedBox(
      height: 56,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Full width minus padding for thumb on each side
          final double trackWidth = constraints.maxWidth - (thumbRadius * 2);
          final double progress = _videoDuration.inMilliseconds > 0
              ? (_currentPosition.inMilliseconds /
                      _videoDuration.inMilliseconds)
                  .clamp(0.0, 1.0)
              : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: thumbRadius),
            child: GestureDetector(
              onTapDown: (details) {
                final double tapPosition =
                    details.localPosition.dx / trackWidth;
                _onSeek(tapPosition.clamp(0.0, 1.0));
              },
              onHorizontalDragUpdate: (details) {
                final double tapPosition =
                    details.localPosition.dx / trackWidth;
                _onSeek(tapPosition.clamp(0.0, 1.0));
              },
              child: SizedBox(
                height: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Track background
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: _cleanTrackInactive,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    // Active track with gradient
                    Positioned(
                      left: 0,
                      child: Container(
                        height: 2,
                        width: trackWidth * progress,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              _cleanGradientStart,
                              _cleanGradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    // Checkpoint tick marks (sorted by z-index: H lowest, P on top)
                    ..._getSortedCheckpointsForStacking().map((entry) {
                      final int index = entry.key;
                      final CheckpointRecord cp = entry.value;
                      if (cp.timestampSeconds == null) {
                        return const SizedBox.shrink();
                      }
                      return _buildCleanSportTickMark(
                        index,
                        cp,
                        trackWidth: trackWidth,
                      );
                    }),
                    // Thumb with gradient
                    Positioned(
                      left: trackWidth * progress - thumbRadius,
                      child: Container(
                        width: thumbRadius * 2,
                        height: thumbRadius * 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _cleanGradientStart,
                              _cleanGradientEnd,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  _cleanGradientStart.withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCleanSportTickMark(
    int index,
    CheckpointRecord cp, {
    required double trackWidth,
  }) {
    final double position = cp.timestampSeconds! / widget.videoDurationSeconds;
    final String label = _getCheckpointLabel(cp.checkpointId);
    final double markerX = trackWidth * position;

    // Width of the tick tap area for easier tapping
    const double tickTapWidth = 32;

    // Position tick above the track (track is centered, so bottom: 28 puts tick above)
    return Positioned(
      left: markerX - (tickTapWidth / 2),
      bottom: 28, // Position above the centered track
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _jumpToCheckpoint(index),
        child: SizedBox(
          width: tickTapWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label (at top)
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _cleanTextColor.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              // Tick mark (extends down toward track)
              Container(
                width: 2,
                height: 12,
                decoration: BoxDecoration(
                  color: _cleanTextColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getCheckpointZIndex(String checkpointId) {
    switch (checkpointId) {
      case 'heisman':
        return 0;
      case 'loaded':
        return 1;
      case 'magic':
        return 2;
      case 'pro':
        return 3;
      default:
        return 0;
    }
  }

  /// Returns checkpoints sorted by z-index (H lowest, P on top)
  /// so that when rendered in a Stack, P appears on top when ticks overlap.
  List<MapEntry<int, CheckpointRecord>> _getSortedCheckpointsForStacking() {
    final List<MapEntry<int, CheckpointRecord>> entries =
        widget.checkpoints.asMap().entries.toList();
    entries.sort((a, b) {
      final int zIndexA = _getCheckpointZIndex(a.value.checkpointId);
      final int zIndexB = _getCheckpointZIndex(b.value.checkpointId);
      return zIndexA.compareTo(zIndexB);
    });
    return entries;
  }

  Widget _buildDarkSlateControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _darkTrackInactive.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Play/pause button
          IconButton(
            onPressed: _togglePlayPause,
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            iconSize: 28,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 8),
          // Pause mode pills
          Expanded(child: _buildPauseModePills(isDark: true)),
          const SizedBox(width: 8),
          // Speed dropdown
          _buildSpeedDropdown(isDark: true),
        ],
      ),
    );
  }

  Widget _buildCleanSportControlsRow() {
    const double controlHeight = 40.0;

    return Row(
      children: [
        // Play/pause button
        Container(
          width: controlHeight,
          height: controlHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cleanGradientStart, _cleanGradientEnd],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: _togglePlayPause,
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            iconSize: 22,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 12),
        // Pause mode pills
        Expanded(
          child: _buildPauseModePills(isDark: false, height: controlHeight),
        ),
        const SizedBox(width: 12),
        // Speed dropdown
        _buildSpeedDropdown(isDark: false, height: controlHeight),
      ],
    );
  }

  Widget _buildPauseModePills({required bool isDark, double? height}) {
    final Color selectedBg = isDark ? _darkTrackActive : _cleanGradientStart;
    final Color selectedText = Colors.white;
    final Color unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.1);
    final Color unselectedText = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : _cleanTextColor.withValues(alpha: 0.7);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPausePill(
          label: '2s',
          isSelected: _pauseMode == CheckpointPauseMode.timedPause,
          onTap: () {
            HapticFeedback.selectionClick();
            _autoResumeTimer?.cancel();
            setState(() => _pauseMode = CheckpointPauseMode.timedPause);
          },
          selectedBg: selectedBg,
          selectedText: selectedText,
          unselectedBg: unselectedBg,
          unselectedText: unselectedText,
          height: height,
        ),
        const SizedBox(width: 4),
        _buildPausePill(
          label: 'Hold',
          isSelected: _pauseMode == CheckpointPauseMode.pauseIndefinitely,
          onTap: () {
            HapticFeedback.selectionClick();
            _autoResumeTimer?.cancel();
            setState(() => _pauseMode = CheckpointPauseMode.pauseIndefinitely);
          },
          selectedBg: selectedBg,
          selectedText: selectedText,
          unselectedBg: unselectedBg,
          unselectedText: unselectedText,
          height: height,
        ),
        const SizedBox(width: 4),
        _buildPausePill(
          label: 'None',
          isSelected: _pauseMode == CheckpointPauseMode.continuous,
          onTap: () {
            HapticFeedback.selectionClick();
            _autoResumeTimer?.cancel();
            setState(() => _pauseMode = CheckpointPauseMode.continuous);
          },
          selectedBg: selectedBg,
          selectedText: selectedText,
          unselectedBg: unselectedBg,
          unselectedText: unselectedText,
          height: height,
        ),
      ],
    );
  }

  Widget _buildPausePill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color selectedBg,
    required Color selectedText,
    required Color unselectedBg,
    required Color unselectedText,
    double? height,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: height != null ? 0 : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(height != null ? 10 : 16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? selectedText : unselectedText,
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDropdown({required bool isDark, double? height}) {
    final Color textColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : _cleanTextColor;
    final Color dropdownBg = isDark
        ? _darkOverlayBg
        : Colors.white;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: height != null ? 0 : 4,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(height != null ? 10 : 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: _playbackSpeed,
          isDense: true,
          dropdownColor: dropdownBg,
          icon: Icon(
            Icons.arrow_drop_down,
            color: textColor,
            size: 20,
          ),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          items: [0.25, 0.5, 1.0].map((speed) {
            return DropdownMenuItem<double>(
              value: speed,
              child: Text(
                '${speed}x',
                style: TextStyle(color: textColor),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _changePlaybackSpeed(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final double loadingHeight = (widget.videoAspectRatio ?? 1.0) >= 1.0
        ? 200.0
        : 400.0;

    return Container(
          height: loadingHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[900],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.grey[800]!,
                  Colors.grey[700]!,
                  Colors.grey[800]!,
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading video...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1500),
          color: Colors.white.withValues(alpha: 0.3),
        );
  }

  Widget _buildErrorState() {
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
          if (_errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
