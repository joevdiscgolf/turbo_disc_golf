import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/video_sync_metadata.dart';

/// Synchronized dual video player for comparing user's form with pro reference.
///
/// Displays two videos:
/// - User's form video (from network URL)
/// - Pro reference video (from app assets)
///
/// Layout adapts based on video aspect ratio:
/// - Portrait videos (9:16, <1.0): Side-by-side
/// - Landscape videos (16:9, >1.0): Stacked vertically
///
/// Features:
/// - Unified play/pause control
/// - Synchronized scrubbing
/// - Stops at shortest video duration to keep throws aligned
/// - Pro video cropped to match user video aspect ratio (16:9)
class SynchronizedVideoPlayer extends StatefulWidget {
  const SynchronizedVideoPlayer({
    super.key,
    required this.userVideoUrl,
    required this.proVideoAssetPath,
    this.videoSyncMetadata,
    this.videoAspectRatio,
  });

  /// Network URL for user's form video
  final String userVideoUrl;

  /// Asset path for pro reference video
  final String proVideoAssetPath;

  /// Video sync metadata for synchronization (optional)
  /// When null, videos will use mechanical sync (same timeline positions)
  final VideoSyncMetadata? videoSyncMetadata;

  /// Aspect ratio of user's video (width/height)
  /// Used to determine layout: <1.0 = portrait (side-by-side), >1.0 = landscape (stacked)
  final double? videoAspectRatio;

  @override
  State<SynchronizedVideoPlayer> createState() =>
      _SynchronizedVideoPlayerState();
}

class _SynchronizedVideoPlayerState extends State<SynchronizedVideoPlayer> {
  late VideoPlayerController _userController;
  late VideoPlayerController _proController;

  bool _isUserVideoInitialized = false;
  bool _isProVideoInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  String? _errorMessage;

  Duration _currentPosition = Duration.zero;
  Duration _userDuration = Duration.zero;
  Duration _proDuration = Duration.zero;
  Duration _shortestDuration = Duration.zero;
  double _playbackSpeed = 1.0;

  Timer? _positionUpdateTimer;
  Timer? _playbackSimulationTimer;
  double _syncOffsetSeconds = 0.0;

  // Frame interval for playback simulation (~30fps)
  static const Duration _playbackFrameInterval = Duration(milliseconds: 33);

  @override
  void initState() {
    super.initState();

    // Calculate simple sync offset based on disc release checkpoint
    if (widget.videoSyncMetadata != null) {
      final VideoSyncMetadata metadata = widget.videoSyncMetadata!;

      // Find disc release checkpoint (ID: 'pro')
      final releaseCheckpoint = metadata.checkpointSyncPoints.firstWhere(
        (cp) => cp.checkpointId == 'pro',
        orElse: () => metadata.checkpointSyncPoints.first,
      );

      // Calculate constant offset: proPosition = userPosition + offset
      _syncOffsetSeconds =
          releaseCheckpoint.proTimestamp - releaseCheckpoint.userTimestamp;

      debugPrint('🎬 Video sync: simple constant offset');
      debugPrint('   Disc release: user=${releaseCheckpoint.userTimestamp}s, pro=${releaseCheckpoint.proTimestamp}s');
      debugPrint('   Sync offset: ${_syncOffsetSeconds}s');

      // Log all checkpoints for debugging
      debugPrint('📍 All checkpoints:');
      for (final checkpoint in metadata.checkpointSyncPoints) {
        final double proCalc = checkpoint.userTimestamp + _syncOffsetSeconds;
        final double diff = (checkpoint.proTimestamp - proCalc).abs();
        debugPrint('   ${checkpoint.checkpointId}: user=${checkpoint.userTimestamp.toStringAsFixed(3)}s, pro=${checkpoint.proTimestamp.toStringAsFixed(3)}s, calculated=${proCalc.toStringAsFixed(3)}s, diff=${diff.toStringAsFixed(3)}s');
      }
    } else {
      _syncOffsetSeconds = 0.0;
      debugPrint('🎬 Video sync: mechanical (no offset)');
    }

    _initializeControllers();
  }

  @override
  void dispose() {
    _positionUpdateTimer?.cancel();
    _playbackSimulationTimer?.cancel();
    _userController.removeListener(_onVideoPositionChanged);
    _userController.dispose();
    _proController.dispose();
    super.dispose();
  }

  Future<void> _initializeControllers() async {
    try {
      // Initialize user video from network URL
      _userController = VideoPlayerController.networkUrl(
        Uri.parse(widget.userVideoUrl),
      );

      // Initialize pro video from assets
      _proController = VideoPlayerController.asset(widget.proVideoAssetPath);

      // Initialize both controllers
      await Future.wait([
        _userController.initialize(),
        _proController.initialize(),
      ]);

      // Mute both videos
      _userController.setVolume(0.0);
      _proController.setVolume(0.0);

      // Store video durations
      _userDuration = _userController.value.duration;
      _proDuration = _proController.value.duration;
      _shortestDuration = _userDuration;

      debugPrint('🎬 Video durations:');
      debugPrint('   User: ${_userDuration.inSeconds}s');
      debugPrint('   Pro: ${_proDuration.inSeconds}s');

      // Add listener to track playback position
      _userController.addListener(_onVideoPositionChanged);

      // Start position update timer
      _positionUpdateTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _updatePosition(),
      );

      if (mounted) {
        setState(() {
          _isUserVideoInitialized = true;
          _isProVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load videos: ${e.toString()}');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load videos: ${e.toString()}';
        });
      }
    }
  }

  void _onVideoPositionChanged() {
    // Listener for video controller state changes
    // Note: End-of-video detection is now handled by playback simulation timer
  }

  void _updatePosition() {
    // During playback simulation, _currentPosition is updated by _onSeek()
    // This timer only updates position when not playing (for paused state display)
    if (mounted && _isUserVideoInitialized && !_isPlaying) {
      final Duration userPosition = _userController.value.position;

      setState(() {
        _currentPosition = userPosition;
      });
    }
  }

  /// Calculate pro video position using simple constant offset formula.
  ///
  /// Formula: proPosition = userPosition + offset
  /// where: offset = proReleaseTime - userReleaseTime
  ///
  /// This ensures both videos advance at the same rate (1.0x speed),
  /// with perfect sync at the disc release moment.
  Duration _calculateProPosition(Duration userPosition) {
    if (widget.videoSyncMetadata == null) {
      // No sync metadata, play in parallel
      return userPosition;
    }

    // Apply constant offset (in seconds)
    final double userSeconds = userPosition.inMilliseconds / 1000.0;
    final double proSeconds = userSeconds + _syncOffsetSeconds;

    // Clamp to valid range [0, proDuration]
    final double clampedProSeconds = proSeconds.clamp(
      0.0,
      _proDuration.inMilliseconds / 1000.0,
    );

    final bool wasClamped = proSeconds != clampedProSeconds;
    if (wasClamped && userSeconds == 0.0) {
      debugPrint('🎬 Sync calculation (at start):');
      debugPrint('   User: ${userSeconds.toStringAsFixed(2)}s');
      debugPrint('   Pro (calculated): ${proSeconds.toStringAsFixed(2)}s');
      debugPrint('   Pro (clamped): ${clampedProSeconds.toStringAsFixed(2)}s');
      debugPrint('   Status: Pro video clamped to 0 (will start when user reaches ${(-_syncOffsetSeconds).toStringAsFixed(2)}s)');
    }

    return Duration(milliseconds: (clampedProSeconds * 1000).toInt());
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  Future<void> _play() async {
    // If at or near end of video (within 100ms), reset to beginning
    const Duration endThreshold = Duration(milliseconds: 100);
    final bool isAtEnd = _currentPosition >= _shortestDuration - endThreshold;

    final Duration userPosition = isAtEnd
        ? Duration.zero
        : _userController.value.position;

    // Sync both videos to starting position
    final Duration proPosition = _calculateProPosition(userPosition);
    await Future.wait([
      _userController.seekTo(userPosition),
      _proController.seekTo(proPosition),
    ]);

    // Update current position
    setState(() {
      _currentPosition = userPosition;
      _isPlaying = true;
    });

    debugPrint('▶️ Play: user=${(userPosition.inMilliseconds / 1000.0).toStringAsFixed(2)}s, pro=${(proPosition.inMilliseconds / 1000.0).toStringAsFixed(2)}s at ${_playbackSpeed}x speed');
    debugPrint('   Sync verification: offset=${_syncOffsetSeconds.toStringAsFixed(3)}s, calculated correctly: ${((userPosition.inMilliseconds / 1000.0) + _syncOffsetSeconds - (proPosition.inMilliseconds / 1000.0)).abs() < 0.001}');

    // Start playback simulation timer
    _playbackSimulationTimer = Timer.periodic(_playbackFrameInterval, (_) {
      if (!_isPlaying || !mounted) {
        _playbackSimulationTimer?.cancel();
        return;
      }

      // Calculate next position based on playback speed
      final Duration nextPosition = _currentPosition +
          Duration(
            milliseconds: (_playbackFrameInterval.inMilliseconds * _playbackSpeed).round(),
          );

      // Check if reached end of video
      if (nextPosition >= _shortestDuration) {
        _pause();
        return;
      }

      // Seek to next position (triggers VideoSyncService calculation)
      final double normalizedValue = nextPosition.inMilliseconds / _shortestDuration.inMilliseconds;
      _onSeek(normalizedValue);
    });
  }

  // NOTE: Checkpoint jump methods below are preserved but commented out.
  // They were removed from _play() to fix unwanted jumping behavior, but may be useful in the future.
  // The original issue: pressing play from position 0 would jump to ~40% instead of playing from start.

  // bool _shouldJumpToFirstCheckpoint(Duration userPosition) {
  //   if (_videoSyncService == null) return false;

  //   final checkpoints = _videoSyncService!.syncMetadata.checkpointSyncPoints;
  //   if (checkpoints.isEmpty) return false;

  //   // Get first checkpoint
  //   final firstCheckpoint = checkpoints.first;
  //   final Duration firstCheckpointUserTime = Duration(
  //     milliseconds: (firstCheckpoint.userTimestamp * 1000).toInt(),
  //   );

  //   // Jump to checkpoint if we're before it (or very close to start)
  //   // Use a small threshold (e.g., 100ms) to handle play from position 0
  //   const Duration threshold = Duration(milliseconds: 100);

  //   return userPosition < firstCheckpointUserTime || userPosition < threshold;
  // }

  // Future<void> _jumpToFirstCheckpoint() async {
  //   if (_videoSyncService == null) return;

  //   final checkpoints = _videoSyncService!.syncMetadata.checkpointSyncPoints;
  //   if (checkpoints.isEmpty) return;

  //   final firstCheckpoint = checkpoints.first;

  //   // Convert timestamps to Duration
  //   final Duration userCheckpointTime = Duration(
  //     milliseconds: (firstCheckpoint.userTimestamp * 1000).toInt(),
  //   );
  //   final Duration proCheckpointTime = Duration(
  //     milliseconds: (firstCheckpoint.proTimestamp * 1000).toInt(),
  //   );

  //   // Safety: don't jump beyond video duration
  //   if (userCheckpointTime >= _userDuration || proCheckpointTime >= _proDuration) {
  //     debugPrint('⚠️ First checkpoint beyond video duration, skipping jump');
  //     return;
  //   }

  //   debugPrint('🎯 Jumping to first checkpoint (${firstCheckpoint.checkpointId}):');
  //   debugPrint('   User: ${firstCheckpoint.userTimestamp.toStringAsFixed(2)}s');
  //   debugPrint('   Pro: ${firstCheckpoint.proTimestamp.toStringAsFixed(2)}s');

  //   // Seek both videos to checkpoint positions
  //   await Future.wait([
  //     _userController.seekTo(userCheckpointTime),
  //     _proController.seekTo(proCheckpointTime),
  //   ]);

  //   // Update current position to reflect the jump
  //   setState(() {
  //     _currentPosition = userCheckpointTime;
  //   });
  // }

  void _pause() {
    // Cancel playback simulation timer
    _playbackSimulationTimer?.cancel();
    _playbackSimulationTimer = null;

    // Pause both controllers to save resources
    _userController.pause();
    _proController.pause();

    setState(() => _isPlaying = false);

    debugPrint('⏸️ Pause: user=${(_currentPosition.inMilliseconds / 1000.0).toStringAsFixed(2)}s');
  }

  Future<void> _onSeek(double value) async {
    final Duration userPosition = Duration(
      milliseconds: (value * _shortestDuration.inMilliseconds).toInt(),
    );

    // Calculate pro position using simple constant offset
    final Duration proPosition = _calculateProPosition(userPosition);

    // Seek both videos and wait for completion
    await Future.wait([
      _userController.seekTo(userPosition),
      _proController.seekTo(proPosition),
    ]);

    setState(() {
      _currentPosition = userPosition;
    });

    // Log sync status at key moments (every 0.5s for debugging)
    final double userSec = userPosition.inMilliseconds / 1000.0;
    final double proSec = proPosition.inMilliseconds / 1000.0;
    if ((userSec * 2).round() == userSec * 2) {
      // Log at 0.0s, 0.5s, 1.0s, 1.5s, etc.
      debugPrint('🎬 Seek: user=${userSec.toStringAsFixed(2)}s → pro=${proSec.toStringAsFixed(2)}s (offset=${_syncOffsetSeconds.toStringAsFixed(3)}s)');
    }
  }

  Future<void> _changePlaybackSpeed(double speed) async {
    final bool wasPlaying = _isPlaying;

    // Pause if playing (cancels simulation timer)
    if (wasPlaying) {
      _pause();
    }

    // Update playback speed
    setState(() {
      _playbackSpeed = speed;
    });

    debugPrint('🎬 Playback speed changed to ${speed}x');

    // Resume playback if it was playing (restarts simulation with new speed)
    if (wasPlaying) {
      await _play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState();
    }

    if (!_isUserVideoInitialized || !_isProVideoInitialized) {
      return _buildLoadingState();
    }

    // Determine layout based on video aspect ratio
    // Portrait videos (<1.0): side-by-side
    // Landscape videos (>=1.0): stacked vertically
    final bool isLandscapeVideo = (widget.videoAspectRatio ?? 1.0) >= 1.0;

    if (isLandscapeVideo) {
      return _buildStackedLayout();
    } else {
      return _buildSideBySideLayout();
    }
  }

  Widget _buildSideBySideLayout() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildUserVideo()),
            const SizedBox(width: 8),
            Expanded(child: _buildProVideo()),
          ],
        ),
        const SizedBox(height: 16),
        _buildPlaybackControls(),
      ],
    );
  }

  Widget _buildStackedLayout() {
    return Column(
      children: [
        _buildUserVideo(),
        const SizedBox(height: 16),
        _buildProVideo(),
        const SizedBox(height: 16),
        _buildPlaybackControls(),
      ],
    );
  }

  Widget _buildUserVideo() {
    return Column(
      children: [
        Text(
          'Your Form',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildVideoContainer(_userController),
      ],
    );
  }

  Widget _buildProVideo() {
    return Column(
      children: [
        const Text(
          'Pro Reference',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildProVideoContainer(),
      ],
    );
  }

  Widget _buildVideoContainer(VideoPlayerController controller) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildProVideoContainer() {
    // For landscape videos (16:9), crop pro video to match user's aspect ratio
    final bool isLandscapeVideo = (widget.videoAspectRatio ?? 1.0) >= 1.0;
    final double targetAspectRatio = isLandscapeVideo
        ? (widget.videoAspectRatio ?? 16 / 9)
        : _proController.value.aspectRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: targetAspectRatio,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _proController.value.size.width,
            height: _proController.value.size.height,
            child: VideoPlayer(_proController),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Column(
      children: [
        // Seek bar
        Slider(
          value: _shortestDuration.inMilliseconds > 0
              ? (_currentPosition.inMilliseconds /
                        _shortestDuration.inMilliseconds)
                    .clamp(0.0, 1.0)
              : 0.0,
          min: 0.0,
          max: 1.0,
          onChanged: _onSeek,
        ),
        // Time display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(
                  _currentPosition > _shortestDuration
                      ? _shortestDuration
                      : _currentPosition,
                ),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                _formatDuration(_shortestDuration),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Playback speed selector
        _buildSpeedSelector(),
        const SizedBox(height: 12),
        // Play/pause button
        IconButton(
          onPressed: _togglePlayPause,
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          iconSize: 48,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedSelector() {
    const List<double> speeds = [0.25, 0.5, 1.0];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Speed:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        ...speeds.map((speed) {
          final bool isSelected = _playbackSpeed == speed;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => _changePlaybackSpeed(speed),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '${speed}x',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLoadingState() {
    // Determine if videos are landscape based on aspect ratio
    final bool isLandscapeVideo = (widget.videoAspectRatio ?? 1.0) >= 1.0;

    // Calculate constant height to prevent content shifting
    // For landscape: use aspect ratio to maintain proper dimensions
    // For portrait: use a reasonable fixed height
    final double loadingHeight = isLandscapeVideo ? 200.0 : 400.0;

    return Container(
          height: loadingHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[900],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
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
                    'Loading videos...',
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          const Text(
            'Failed to load videos',
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

  String _formatDuration(Duration duration) {
    final String minutes = duration.inMinutes.toString().padLeft(2, '0');
    final String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
