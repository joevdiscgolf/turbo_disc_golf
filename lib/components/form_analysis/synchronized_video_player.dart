import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Synchronized dual video player for comparing user's form with pro reference.
///
/// Displays two videos side-by-side (portrait) or stacked (landscape):
/// - User's form video (from network URL)
/// - Pro reference video (from app assets)
///
/// Features:
/// - Unified play/pause control
/// - Synchronized scrubbing
/// - Stops at shortest video duration to keep throws aligned
/// - Adaptive layout for portrait/landscape orientation
class SynchronizedVideoPlayer extends StatefulWidget {
  const SynchronizedVideoPlayer({
    super.key,
    required this.userVideoUrl,
    required this.proVideoAssetPath,
  });

  /// Network URL for user's form video
  final String userVideoUrl;

  /// Asset path for pro reference video
  final String proVideoAssetPath;

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
  Duration _shortestDuration = Duration.zero;

  Timer? _positionUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _positionUpdateTimer?.cancel();
    _userController.dispose();
    _proController.dispose();
    super.dispose();
  }

  Future<void> _initializeControllers() async {
    try {
      // Initialize user video from network URL
      _userController =
          VideoPlayerController.networkUrl(Uri.parse(widget.userVideoUrl));

      // Initialize pro video from assets
      _proController =
          VideoPlayerController.asset(widget.proVideoAssetPath);

      // Initialize both controllers
      await Future.wait([
        _userController.initialize(),
        _proController.initialize(),
      ]);

      // Calculate shortest duration to stop playback
      final Duration userDuration = _userController.value.duration;
      final Duration proDuration = _proController.value.duration;
      _shortestDuration =
          userDuration < proDuration ? userDuration : proDuration;

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
      setState(() {
        _currentPosition = _userController.value.position;
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

  void _play() {
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
    final Duration position = Duration(
      milliseconds: (value * _shortestDuration.inMilliseconds).toInt(),
    );
    _userController.seekTo(position);
    _proController.seekTo(position);
    setState(() {
      _currentPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState();
    }

    if (!_isUserVideoInitialized || !_isProVideoInitialized) {
      return _buildLoadingState();
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return _buildPortraitLayout();
        } else {
          return _buildLandscapeLayout();
        }
      },
    );
  }

  Widget _buildPortraitLayout() {
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

  Widget _buildLandscapeLayout() {
    return Column(
      children: [
        _buildUserVideo(),
        const SizedBox(height: 8),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildVideoContainer(_userController),
      ],
    );
  }

  Widget _buildProVideo() {
    return Column(
      children: [
        Text(
          'Pro Reference (Paul McBeth)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildVideoContainer(_proController),
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

  Widget _buildPlaybackControls() {
    return Column(
      children: [
        // Seek bar
        Slider(
          value: _shortestDuration.inMilliseconds > 0
              ? _currentPosition.inMilliseconds /
                  _shortestDuration.inMilliseconds
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
                _formatDuration(_currentPosition),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                _formatDuration(_shortestDuration),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading videos...'),
          ],
        ),
      ),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
    final String seconds =
        (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
