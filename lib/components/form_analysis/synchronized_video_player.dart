import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

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
    this.analysisResult,
    this.videoAspectRatio,
  });

  /// Network URL for user's form video
  final String userVideoUrl;

  /// Asset path for pro reference video
  final String proVideoAssetPath;

  /// Analysis result containing video sync metadata (optional)
  /// When null, videos will use mechanical sync (same timeline positions)
  final PoseAnalysisResponse? analysisResult;

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
  double _timeOffset = 0.0; // Offset in seconds to align disc release
  double _proSpeedMultiplier = 1.0; // Speed multiplier for pro video

  @override
  void initState() {
    super.initState();

    // Calculate sync parameters from backend metadata
    if (widget.analysisResult?.videoSyncMetadata != null) {
      final metadata = widget.analysisResult!.videoSyncMetadata!;

      // Find the "pro" checkpoint (disc release)
      final releaseCheckpoint = metadata.checkpointSyncPoints.firstWhere(
        (cp) => cp.checkpointId == 'pro',
        orElse: () => metadata.checkpointSyncPoints.first,
      );

      // Get the speed multiplier from backend
      _proSpeedMultiplier = metadata.proPlaybackSpeedMultiplier;

      // Calculate offset constant using the sync formula:
      // pro_position = user_position * speed_multiplier + constant
      // At disc release: pro_release = user_release * multiplier + constant
      // Therefore: constant = pro_release - (user_release * multiplier)
      _timeOffset = releaseCheckpoint.proTimestamp -
                    (releaseCheckpoint.userTimestamp * _proSpeedMultiplier);

      debugPrint('🎬 Video sync: disc release alignment');
      debugPrint('   User release at: ${releaseCheckpoint.userTimestamp}s');
      debugPrint('   Pro release at: ${releaseCheckpoint.proTimestamp}s');
      debugPrint('   Pro speed multiplier: ${_proSpeedMultiplier}x');
      debugPrint('   Time offset constant: ${_timeOffset}s');
    } else {
      _timeOffset = 0.0;
      _proSpeedMultiplier = 1.0;
      debugPrint('🎬 Video sync: mechanical (no offset)');
    }

    _initializeControllers();
  }

  @override
  void dispose() {
    _positionUpdateTimer?.cancel();
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

      // Set initial playback speeds (1.0x for user, multiplier for pro)
      _userController.setPlaybackSpeed(1.0);
      _proController.setPlaybackSpeed(_proSpeedMultiplier);

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
    // Auto-pause when reaching end of shortest video
    if (_userController.value.position >= _shortestDuration && _isPlaying) {
      _pause();
    }
  }

  void _updatePosition() {
    if (mounted && _isUserVideoInitialized) {
      final userPosition = _userController.value.position;

      // Drift correction during playback when using speed multiplier
      if (_isPlaying && _proSpeedMultiplier != 1.0) {
        final double userSeconds = userPosition.inMilliseconds / 1000.0;

        // Calculate expected pro position using the sync formula:
        // pro_position = user_position * speed_multiplier + constant
        // where constant = pro_release - (user_release * speed_multiplier)
        final double expectedProSeconds = (userSeconds * _proSpeedMultiplier) + _timeOffset;
        final double actualProSeconds = _proController.value.position.inMilliseconds / 1000.0;
        final double drift = (actualProSeconds - expectedProSeconds).abs();

        // Re-sync if drift exceeds 150ms
        if (drift > 0.15) {
          // Clamp expected position to valid range
          final double clampedExpectedProSeconds = expectedProSeconds.clamp(0.0, _proDuration.inMilliseconds / 1000.0);
          final Duration expectedProPosition = Duration(
            milliseconds: (clampedExpectedProSeconds * 1000).toInt(),
          );
          _proController.seekTo(expectedProPosition);
          debugPrint('🔄 Re-sync: drift ${(drift * 1000).toInt()}ms, expected ${clampedExpectedProSeconds.toStringAsFixed(2)}s, actual ${actualProSeconds.toStringAsFixed(2)}s');
        }
      }

      setState(() {
        _currentPosition = userPosition;
      });
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  Future<void> _play() async {
    // Calculate correct pro video position using sync formula
    final double userSeconds = _userController.value.position.inMilliseconds / 1000.0;
    final double proSeconds = (userSeconds * _proSpeedMultiplier) + _timeOffset;

    // Clamp pro position to valid range [0, proDuration]
    final double clampedProSeconds = proSeconds.clamp(0.0, _proDuration.inMilliseconds / 1000.0);
    final Duration proPosition = Duration(
      milliseconds: (clampedProSeconds * 1000).toInt(),
    );

    debugPrint('▶️ Play: user=${userSeconds.toStringAsFixed(2)}s → pro=${clampedProSeconds.toStringAsFixed(2)}s');

    // Wait for pro video seek to complete before starting playback
    await _proController.seekTo(proPosition);

    // Start both videos simultaneously at their respective speeds
    _userController.play();
    _proController.play();
    setState(() => _isPlaying = true);
  }

  void _pause() {
    _userController.pause();
    _proController.pause();
    setState(() => _isPlaying = false);
  }

  void _onSeek(double value) {
    final Duration userPosition = Duration(
      milliseconds: (value * _shortestDuration.inMilliseconds).toInt(),
    );

    final double userSeconds = userPosition.inMilliseconds / 1000.0;

    // Calculate pro position using sync formula:
    // pro_position = user_position * speed_multiplier + constant
    final double proSeconds = (userSeconds * _proSpeedMultiplier) + _timeOffset;

    // Clamp pro position to valid range [0, proDuration]
    final double clampedProSeconds = proSeconds.clamp(0.0, _proDuration.inMilliseconds / 1000.0);
    final Duration proPosition = Duration(
      milliseconds: (clampedProSeconds * 1000).toInt(),
    );

    debugPrint('🔍 Seek: user=${userSeconds.toStringAsFixed(2)}s → pro=${clampedProSeconds.toStringAsFixed(2)}s');

    // Seek both videos
    _userController.seekTo(userPosition);
    _proController.seekTo(proPosition);

    setState(() {
      _currentPosition = userPosition;
    });
  }

  Future<void> _changePlaybackSpeed(double speed) async {
    final bool wasPlaying = _isPlaying;

    // Pause if playing
    if (wasPlaying) {
      _pause();
    }

    // Change speed: user video at selected speed, pro video at speed * multiplier
    await Future.wait([
      _userController.setPlaybackSpeed(speed),
      _proController.setPlaybackSpeed(speed * _proSpeedMultiplier),
    ]);

    debugPrint('🎬 Playback speed changed:');
    debugPrint('   User: ${speed}x');
    debugPrint('   Pro: ${speed * _proSpeedMultiplier}x (${speed}x * $_proSpeedMultiplier)');

    setState(() {
      _playbackSpeed = speed;
    });

    // Resume playback if it was playing
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
                    _shortestDuration.inMilliseconds).clamp(0.0, 1.0)
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
                _formatDuration(_currentPosition > _shortestDuration ? _shortestDuration : _currentPosition),
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
