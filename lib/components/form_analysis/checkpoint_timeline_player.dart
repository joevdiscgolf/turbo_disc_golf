import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';
import 'package:video_player/video_player.dart';

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
    this.onCheckpointIndexChanged,
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

  /// Callback when the current checkpoint index changes (via auto-pause or timeline tap).
  /// This is called whenever the player reaches or pauses at a checkpoint, allowing
  /// the parent to sync the pro reference display.
  final ValueChanged<int>? onCheckpointIndexChanged;

  @override
  CheckpointTimelinePlayerState createState() => CheckpointTimelinePlayerState();
}

class CheckpointTimelinePlayerState extends State<CheckpointTimelinePlayer> {
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
  static const Color _darkTrackActive = Color(0xFF06B6D4);

  // Clean Sport Minimal colors
  static const Color _cleanTrackInactive = Color(0xFFE2E8F0);
  static const Color _cleanGradientStart = Color(0xFF3B82F6);
  static const Color _cleanGradientEnd = Color(0xFF8B5CF6);
  static const Color _cleanTextColor = Color(0xFF1E293B);

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

  /// Public method to jump to a checkpoint. Called via GlobalKey from parent.
  /// This avoids widget rebuilds and the associated performance overhead.
  void jumpToCheckpoint(int index) {
    if (!_isInitialized) return;
    final CheckpointRecord cp = widget.checkpoints[index];
    if (cp.timestampSeconds == null) return;

    HapticFeedback.selectionClick();

    final Duration position = Duration(
      milliseconds: (cp.timestampSeconds! * 1000).toInt(),
    );

    _lastAutoPausedCheckpointIndex = -1;
    _controller.seekTo(position);
    setState(() {
      _currentPosition = position;
      _currentPausedCheckpointIndex = index;
    });
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

    // Notify parent to sync pro reference display
    widget.onCheckpointIndexChanged?.call(checkpointIndex);

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

  /// Internal method for timeline marker taps - always notifies parent.
  void _jumpToCheckpoint(int index) {
    final CheckpointRecord cp = widget.checkpoints[index];
    if (cp.timestampSeconds == null) return;

    HapticFeedback.selectionClick();

    final Duration position = Duration(
      milliseconds: (cp.timestampSeconds! * 1000).toInt(),
    );

    _lastAutoPausedCheckpointIndex = -1;
    _controller.seekTo(position);
    setState(() {
      _currentPosition = position;
      _currentPausedCheckpointIndex = index;
    });

    // Notify parent to sync pro reference
    widget.onCheckpointIndexChanged?.call(index);
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

    return _buildCleanSportStyle();
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, SenseiColors.gray[50]!],
            ),
          ),
          child: Column(
            children: [
              // Timeline with tick marks
              _buildCleanSportTimeline(),
              // Controls row
              _buildCleanSportControlsRow(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayerFullWidth() {
    return AspectRatio(
      aspectRatio: widget.videoAspectRatio ?? _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }

  Widget _buildCheckpointLabelOverlay() {
    // Show checkpoint label if paused at checkpoint OR if current position is at a checkpoint
    final int nearbyCheckpointIndex = _findCheckpointAtPosition(
      _currentPosition,
    );
    final bool hasNearbyCheckpoint = nearbyCheckpointIndex != -1;
    final bool shouldShow =
        _currentPausedCheckpointIndex != null || hasNearbyCheckpoint;

    final CheckpointRecord? checkpoint = _currentPausedCheckpointIndex != null
        ? widget.checkpoints[_currentPausedCheckpointIndex!]
        : (hasNearbyCheckpoint
              ? widget.checkpoints[nearbyCheckpointIndex]
              : null);

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

  Widget _buildCleanSportTimeline() {
    // Thumb radius for padding calculations
    const double thumbRadius = 8;
    // Larger touch target for easier slider interaction
    const double touchTargetHeight = 72;

    return SizedBox(
      height: touchTargetHeight,
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
              behavior: HitTestBehavior.opaque,
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
                height: touchTargetHeight,
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
                            colors: [_cleanGradientStart, _cleanGradientEnd],
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
                            colors: [_cleanGradientStart, _cleanGradientEnd],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _cleanGradientStart.withValues(alpha: 0.4),
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
    final List<MapEntry<int, CheckpointRecord>> entries = widget.checkpoints
        .asMap()
        .entries
        .toList();
    entries.sort((a, b) {
      final int zIndexA = _getCheckpointZIndex(a.value.checkpointId);
      final int zIndexB = _getCheckpointZIndex(b.value.checkpointId);
      return zIndexA.compareTo(zIndexB);
    });
    return entries;
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
        const SizedBox(width: 8),
        // Speed pills
        Expanded(
          child: _buildSpeedPills(isDark: false, height: controlHeight),
        ),
      ],
    );
  }

  Widget _buildPauseModePills({required bool isDark, double? height}) {
    final Color selectedBg = isDark ? _darkTrackActive : _cleanGradientStart;
    final Color selectedText = Colors.white;
    final Color unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : SenseiColors.gray[100]!;
    final Color unselectedText = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : _cleanTextColor.withValues(alpha: 0.7);
    final double radius = height != null ? 10 : 16;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Row(
      children: [
        Expanded(
          child: _buildPausePill(
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
            isFirst: true,
          ),
        ),
        Expanded(
          child: _buildPausePill(
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
        ),
        Expanded(
          child: _buildPausePill(
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
            isLast: true,
          ),
        ),
        ],
      ),
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
    bool isFirst = false,
    bool isLast = false,
  }) {
    final double radius = height != null ? 10 : 16;
    final BorderRadius borderRadius = BorderRadius.horizontal(
      left: isFirst ? Radius.circular(radius) : Radius.zero,
      right: isLast ? Radius.circular(radius) : Radius.zero,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(
          horizontal: 4,
          vertical: height != null ? 0 : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: borderRadius,
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

  Widget _buildSpeedPills({required bool isDark, double? height}) {
    final Color selectedBg = isDark ? _darkTrackActive : _cleanGradientStart;
    final Color selectedText = Colors.white;
    final Color unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : SenseiColors.gray[100]!;
    final Color unselectedText = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : _cleanTextColor.withValues(alpha: 0.7);
    final double radius = height != null ? 10 : 16;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Row(
      children: [
        Expanded(
          child: _buildPausePill(
            label: '1/4',
            isSelected: _playbackSpeed == 0.25,
            onTap: () {
              HapticFeedback.selectionClick();
              _changePlaybackSpeed(0.25);
            },
            selectedBg: selectedBg,
            selectedText: selectedText,
            unselectedBg: unselectedBg,
            unselectedText: unselectedText,
            height: height,
            isFirst: true,
          ),
        ),
        Expanded(
          child: _buildPausePill(
            label: '1/2',
            isSelected: _playbackSpeed == 0.5,
            onTap: () {
              HapticFeedback.selectionClick();
              _changePlaybackSpeed(0.5);
            },
            selectedBg: selectedBg,
            selectedText: selectedText,
            unselectedBg: unselectedBg,
            unselectedText: unselectedText,
            height: height,
          ),
        ),
        Expanded(
          child: _buildPausePill(
            label: '1x',
            isSelected: _playbackSpeed == 1.0,
            onTap: () {
              HapticFeedback.selectionClick();
              _changePlaybackSpeed(1.0);
            },
            selectedBg: selectedBg,
            selectedText: selectedText,
            unselectedBg: unselectedBg,
            unselectedText: unselectedText,
            height: height,
            isLast: true,
          ),
        ),
        ],
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
