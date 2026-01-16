# Video Synchronization Implementation Guide

## Overview

Implement dual-mode video synchronization with configurable playback speed:
- **Single-point sync**: Anchor at disc release only
- **Multi-point sync**: Time-warping across all checkpoints (Heisman → Loaded → Magic → Pro)
- **Playback speed**: Default 25% (slow motion), configurable

---

## Step 1: Create Sync Configuration Constants

**File:** `lib/config/video_sync_config_constants.dart` (NEW)

```dart
/// Configuration constants for video synchronization testing
///
/// These constants control how user and pro videos are synchronized during playback.
class VideoSyncConfigConstants {
  VideoSyncConfigConstants._(); // Private constructor

  /// Sync mode: Controls how videos are aligned
  ///
  /// - SINGLE_POINT: Anchor at disc release only (simpler, faster)
  /// - MULTI_POINT: Time-warp across all checkpoints for full-throw sync (more accurate)
  ///
  /// TESTING: Change this constant to test different sync modes
  static const VideoSyncMode syncMode = VideoSyncMode.SINGLE_POINT;

  /// Default playback speed for both videos (as percentage)
  ///
  /// - 1.0 = 100% (real-time)
  /// - 0.25 = 25% (slow motion) - DEFAULT
  /// - 0.5 = 50% (half speed)
  ///
  /// TESTING: Change this to adjust playback speed
  static const double defaultPlaybackSpeed = 0.25; // 25% slow motion

  /// Whether to allow user to change playback speed during playback
  static const bool allowPlaybackSpeedControl = true;

  /// Available playback speeds for user selection
  static const List<double> availablePlaybackSpeeds = [
    0.125, // 12.5% (very slow)
    0.25,  // 25% (slow)
    0.5,   // 50% (half)
    1.0,   // 100% (real-time)
  ];

  /// Whether to re-sync videos periodically to prevent drift
  static const bool enablePeriodicResync = true;

  /// How often to check and correct sync drift (in seconds)
  static const int resyncIntervalSeconds = 2;

  /// Maximum allowed sync drift before correction (in milliseconds)
  static const int maxSyncDriftMs = 100;

  /// Whether to show debug sync info overlay
  static const bool showSyncDebugInfo = false; // Set to true for debugging
}

/// Video synchronization mode
enum VideoSyncMode {
  /// Anchor videos at disc release only
  /// Simpler algorithm, faster to compute
  /// Good for comparing release form
  SINGLE_POINT,

  /// Time-warp videos across all checkpoints
  /// More complex algorithm, better full-throw sync
  /// Good for comparing entire throwing motion
  MULTI_POINT,
}
```

---

## Step 2: Update ProVideoLandmarks Model

**File:** `lib/services/form_analysis/pro_video_asset_service.dart`

Update the `ProVideoLandmarks` class to include FPS and speed metadata:

```dart
class ProVideoLandmarks {
  final String throwType;
  final String cameraAngle;
  final double videoDurationSeconds;
  final double realTimeDurationSeconds;
  final double fps;
  final double recordingSpeed;
  final double playbackSpeedMultiplier;
  final List<FramePoseData> framePoses;
  final List<CheckpointData> checkpoints;
  final Map<String, dynamic> metadata;

  ProVideoLandmarks({
    required this.throwType,
    required this.cameraAngle,
    required this.videoDurationSeconds,
    required this.realTimeDurationSeconds,
    required this.fps,
    required this.recordingSpeed,
    required this.playbackSpeedMultiplier,
    required this.framePoses,
    required this.checkpoints,
    required this.metadata,
  });

  factory ProVideoLandmarks.fromJson(Map<String, dynamic> json) {
    final videoDuration = (json['video_duration_seconds'] as num).toDouble();
    final playbackSpeed = (json['playback_speed_multiplier'] as num?)?.toDouble() ?? 1.0;

    return ProVideoLandmarks(
      throwType: json['throw_type'] as String,
      cameraAngle: json['camera_angle'] as String,
      videoDurationSeconds: videoDuration,
      realTimeDurationSeconds: (json['real_time_duration_seconds'] as num?)?.toDouble()
          ?? videoDuration / playbackSpeed,
      fps: (json['fps'] as num?)?.toDouble() ?? 30.0,
      recordingSpeed: (json['recording_speed'] as num?)?.toDouble() ?? 1.0,
      playbackSpeedMultiplier: playbackSpeed,
      framePoses: (json['frame_poses'] as List<dynamic>)
          .map((e) => FramePoseData.fromJson(e as Map<String, dynamic>))
          .toList(),
      checkpoints: (json['checkpoints'] as List<dynamic>)
          .map((e) => CheckpointData.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Get a human-readable description of the recording speed
  String get speedDescription {
    if (recordingSpeed >= 0.9) return 'Normal speed';
    if (recordingSpeed >= 0.2) return '25% speed (4x slow-mo)';
    if (recordingSpeed >= 0.1) return '12.5% speed (8x slow-mo)';
    return 'Custom speed';
  }
}
```

---

## Step 3: Update VideoSyncConfig Model

**File:** `lib/models/data/form_analysis/video_sync_config.dart`

Add support for both sync modes:

```dart
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/services/form_analysis/pro_video_asset_service.dart';
import 'package:turbo_disc_golf/config/video_sync_config_constants.dart';

/// Configuration for synchronizing user and pro videos
class VideoSyncConfig {
  final List<CheckpointTimestamp> checkpoints;
  final double userVideoDuration;
  final double proVideoDuration;
  final double proPlaybackSpeedMultiplier;
  final VideoSyncMode syncMode;
  final double defaultPlaybackSpeed;

  const VideoSyncConfig({
    required this.checkpoints,
    required this.userVideoDuration,
    required this.proVideoDuration,
    required this.proPlaybackSpeedMultiplier,
    required this.syncMode,
    this.defaultPlaybackSpeed = 1.0,
  });

  /// Create sync config from user analysis and pro landmarks
  factory VideoSyncConfig.fromAnalysis(
    PoseAnalysisResponse userAnalysis,
    ProVideoLandmarks proLandmarks, {
    VideoSyncMode? syncMode,
    double? playbackSpeed,
  }) {
    final mode = syncMode ?? VideoSyncConfigConstants.syncMode;

    // Create checkpoint mappings
    final checkpoints = _createCheckpointMappings(
      userAnalysis,
      proLandmarks,
      mode,
    );

    return VideoSyncConfig(
      checkpoints: checkpoints,
      userVideoDuration: userAnalysis.videoDurationSeconds,
      proVideoDuration: proLandmarks.videoDurationSeconds,
      proPlaybackSpeedMultiplier: proLandmarks.playbackSpeedMultiplier,
      syncMode: mode,
      defaultPlaybackSpeed: playbackSpeed ?? VideoSyncConfigConstants.defaultPlaybackSpeed,
    );
  }

  /// Create checkpoint mappings based on sync mode
  static List<CheckpointTimestamp> _createCheckpointMappings(
    PoseAnalysisResponse userAnalysis,
    ProVideoLandmarks proLandmarks,
    VideoSyncMode syncMode,
  ) {
    if (syncMode == VideoSyncMode.SINGLE_POINT) {
      // Only map disc release checkpoint
      return _createSinglePointMapping(userAnalysis, proLandmarks);
    } else {
      // Map all checkpoints for time-warping
      return _createMultiPointMapping(userAnalysis, proLandmarks);
    }
  }

  /// Single-point sync: Only map disc release (Pro checkpoint)
  static List<CheckpointTimestamp> _createSinglePointMapping(
    PoseAnalysisResponse userAnalysis,
    ProVideoLandmarks proLandmarks,
  ) {
    // Find disc release checkpoint in user analysis
    final userRelease = userAnalysis.checkpoints.firstWhere(
      (cp) => cp.checkpointId.toLowerCase() == 'pro',
      orElse: () => userAnalysis.checkpoints.last,
    );

    // Find disc release checkpoint in pro landmarks
    final proRelease = proLandmarks.checkpoints.firstWhere(
      (cp) => cp.checkpointId.toLowerCase() == 'pro',
      orElse: () => proLandmarks.checkpoints.last,
    );

    return [
      CheckpointTimestamp(
        checkpointId: 'pro',
        userTimestamp: userRelease.timestampSeconds,
        proTimestamp: proRelease.timestampSeconds,
      ),
    ];
  }

  /// Multi-point sync: Map all checkpoints for time-warping
  static List<CheckpointTimestamp> _createMultiPointMapping(
    PoseAnalysisResponse userAnalysis,
    ProVideoLandmarks proLandmarks,
  ) {
    final List<CheckpointTimestamp> mappings = [];

    // Map each user checkpoint to corresponding pro checkpoint
    for (final userCp in userAnalysis.checkpoints) {
      // Find matching pro checkpoint
      final proCp = proLandmarks.checkpoints.firstWhere(
        (cp) => cp.checkpointId.toLowerCase() == userCp.checkpointId.toLowerCase(),
        orElse: () {
          // If no exact match, estimate based on percentage through video
          final percentage = userCp.timestampSeconds / userAnalysis.videoDurationSeconds;
          return CheckpointData(
            checkpointId: userCp.checkpointId,
            timestampSeconds: percentage * proLandmarks.videoDurationSeconds,
          );
        },
      );

      mappings.add(CheckpointTimestamp(
        checkpointId: userCp.checkpointId,
        userTimestamp: userCp.timestampSeconds,
        proTimestamp: proCp.timestampSeconds,
      ));
    }

    // Sort by user timestamp
    mappings.sort((a, b) => a.userTimestamp.compareTo(b.userTimestamp));

    return mappings;
  }

  /// Map user video timestamp to pro video timestamp
  ///
  /// Algorithm varies based on sync mode:
  /// - SINGLE_POINT: Simple offset based on disc release
  /// - MULTI_POINT: Piecewise linear interpolation between checkpoints
  double mapUserTimeToPro(double userTime) {
    if (syncMode == VideoSyncMode.SINGLE_POINT) {
      return _mapSinglePoint(userTime);
    } else {
      return _mapMultiPoint(userTime);
    }
  }

  /// Single-point sync algorithm
  ///
  /// Simple offset calculation: proTime = userTime + offset
  /// where offset = proReleaseTime - userReleaseTime
  double _mapSinglePoint(double userTime) {
    if (checkpoints.isEmpty) return userTime;

    final releaseCheckpoint = checkpoints.first; // Should be disc release
    final offset = releaseCheckpoint.proTimestamp - releaseCheckpoint.userTimestamp;

    return userTime + offset;
  }

  /// Multi-point sync algorithm (time-warping)
  ///
  /// Piecewise linear interpolation between checkpoints
  double _mapMultiPoint(double userTime) {
    if (checkpoints.isEmpty) return userTime;

    // Sort checkpoints by user timestamp
    final sortedCheckpoints = List<CheckpointTimestamp>.from(checkpoints)
      ..sort((a, b) => a.userTimestamp.compareTo(b.userTimestamp));

    // Case 1: Before first checkpoint
    if (userTime <= sortedCheckpoints.first.userTimestamp) {
      if (sortedCheckpoints.first.userTimestamp == 0) {
        return sortedCheckpoints.first.proTimestamp;
      }
      final ratio = sortedCheckpoints.first.proTimestamp / sortedCheckpoints.first.userTimestamp;
      return userTime * ratio;
    }

    // Case 2: After last checkpoint
    if (userTime >= sortedCheckpoints.last.userTimestamp) {
      final lastCheckpoint = sortedCheckpoints.last;
      final userRemaining = userVideoDuration - lastCheckpoint.userTimestamp;
      final proRemaining = proVideoDuration - lastCheckpoint.proTimestamp;

      if (userRemaining == 0) return lastCheckpoint.proTimestamp;

      final ratio = proRemaining / userRemaining;
      return lastCheckpoint.proTimestamp + (userTime - lastCheckpoint.userTimestamp) * ratio;
    }

    // Case 3: Between checkpoints (piecewise linear interpolation)
    for (int i = 0; i < sortedCheckpoints.length - 1; i++) {
      final curr = sortedCheckpoints[i];
      final next = sortedCheckpoints[i + 1];

      if (userTime >= curr.userTimestamp && userTime <= next.userTimestamp) {
        final userSegment = next.userTimestamp - curr.userTimestamp;

        if (userSegment == 0) return curr.proTimestamp;

        final proSegment = next.proTimestamp - curr.proTimestamp;
        final progress = (userTime - curr.userTimestamp) / userSegment;
        return curr.proTimestamp + (progress * proSegment);
      }
    }

    // Fallback
    return userTime;
  }
}

/// Checkpoint timestamp mapping between user and pro videos
class CheckpointTimestamp {
  final String checkpointId;
  final double userTimestamp;
  final double proTimestamp;

  const CheckpointTimestamp({
    required this.checkpointId,
    required this.userTimestamp,
    required this.proTimestamp,
  });

  @override
  String toString() =>
      'CheckpointTimestamp($checkpointId: user=${userTimestamp}s, pro=${proTimestamp}s)';
}
```

---

## Step 4: Update SynchronizedVideoPlayerService

**File:** `lib/services/form_analysis/synchronized_video_player_service.dart`

Add support for both sync modes and playback speed:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/video_sync_config.dart';
import 'package:turbo_disc_golf/utils/video_sync_algorithm.dart';
import 'package:turbo_disc_golf/services/form_analysis/pro_video_asset_service.dart';
import 'package:turbo_disc_golf/config/video_sync_config_constants.dart';

class SynchronizedVideoPlayerService {
  // Video controllers
  VideoPlayerController? _userController;
  VideoPlayerController? _proController;

  // Sync configuration
  VideoSyncConfig? _syncConfig;

  // Sync management
  Timer? _syncTimer;
  bool _isSyncing = false;

  // Playback speed
  double _currentPlaybackSpeed = VideoSyncConfigConstants.defaultPlaybackSpeed;

  // Getters
  VideoPlayerController? get userController => _userController;
  VideoPlayerController? get proController => _proController;
  VideoSyncConfig? get syncConfig => _syncConfig;
  double get currentPlaybackSpeed => _currentPlaybackSpeed;

  bool get isInitialized =>
    _userController?.value.isInitialized == true &&
    _proController?.value.isInitialized == true;

  bool get isPlaying => _userController?.value.isPlaying ?? false;
  Duration get position => _userController?.value.position ?? Duration.zero;
  Duration get duration => _userController?.value.duration ?? Duration.zero;

  /// Initialize both video controllers with speed normalization
  Future<void> initialize({
    required String userVideoUrl,
    required String throwType,
    required String cameraAngle,
    required VideoSyncConfig syncConfig,
  }) async {
    _syncConfig = syncConfig;

    // Initialize user video (from network URL)
    _userController = VideoPlayerController.networkUrl(Uri.parse(userVideoUrl));
    await _userController!.initialize();

    // Get pro video asset path
    final proVideoPath = ProVideoAssetService.getProVideoPath(
      throwType: throwType,
      cameraAngle: cameraAngle,
    );

    // Initialize pro video (from assets)
    _proController = VideoPlayerController.asset(proVideoPath);
    await _proController!.initialize();

    // Apply default playback speed to both videos
    await setPlaybackSpeed(syncConfig.defaultPlaybackSpeed);

    // Set both videos to non-looping
    await _userController!.setLooping(false);
    await _proController!.setLooping(false);

    // Initial sync based on mode
    if (syncConfig.syncMode == VideoSyncMode.SINGLE_POINT) {
      // For single-point, start at disc release
      await syncToDiscRelease();
    } else {
      // For multi-point, start at beginning
      await seekUser(Duration.zero);
    }

    // Start periodic sync timer to prevent drift
    if (VideoSyncConfigConstants.enablePeriodicResync) {
      _startSyncTimer();
    }
  }

  /// Set playback speed for both videos
  Future<void> setPlaybackSpeed(double speed) async {
    if (!isInitialized) return;

    _currentPlaybackSpeed = speed;

    // Apply speed to user video
    await _userController!.setPlaybackSpeed(speed);

    // Apply normalized speed to pro video
    // Pro video needs additional multiplier to compensate for slow-motion recording
    final proSpeed = speed * _syncConfig!.proPlaybackSpeedMultiplier;
    await _proController!.setPlaybackSpeed(proSpeed);

    debugPrint('Playback speed set to ${(speed * 100).toStringAsFixed(0)}%');
    debugPrint('Pro video actual speed: ${proSpeed}x (normalized)');
  }

  /// Play both videos in sync
  Future<void> play() async {
    if (!isInitialized) return;

    await _userController!.play();
    await _proController!.play();
  }

  /// Pause both videos
  Future<void> pause() async {
    if (!isInitialized) return;

    await _userController!.pause();
    await _proController!.pause();
  }

  /// Toggle play/pause state
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Seek user video to a position and auto-sync pro video
  Future<void> seekUser(Duration position) async {
    if (!isInitialized || _syncConfig == null) return;

    final wasPlaying = isPlaying;
    if (wasPlaying) await pause();

    // Seek user video
    await _userController!.seekTo(position);

    // Calculate corresponding pro video position using sync algorithm
    final userTime = position.inMilliseconds / 1000.0;
    final proTime = _syncConfig!.mapUserTimeToPro(userTime);
    final proPosition = Duration(milliseconds: (proTime * 1000).round());

    // Seek pro video to synchronized position
    await _proController!.seekTo(proPosition);

    if (wasPlaying) {
      await Future.delayed(const Duration(milliseconds: 100));
      await play();
    }
  }

  /// Sync both videos to disc release moment (Pro checkpoint)
  Future<void> syncToDiscRelease() async {
    if (!isInitialized || _syncConfig == null) return;

    // Find disc release checkpoint
    final releaseCheckpoint = _syncConfig!.checkpoints.firstWhere(
      (cp) => cp.checkpointId.toLowerCase() == 'pro',
      orElse: () => _syncConfig!.checkpoints.last,
    );

    final wasPlaying = isPlaying;
    if (wasPlaying) await pause();

    // Seek to release point
    final userPosition = Duration(milliseconds: (releaseCheckpoint.userTimestamp * 1000).round());
    await _userController!.seekTo(userPosition);

    final proPosition = Duration(milliseconds: (releaseCheckpoint.proTimestamp * 1000).round());
    await _proController!.seekTo(proPosition);

    debugPrint('Synced to disc release: user=${releaseCheckpoint.userTimestamp}s, pro=${releaseCheckpoint.proTimestamp}s');

    if (wasPlaying) {
      await Future.delayed(const Duration(milliseconds: 100));
      await play();
    }
  }

  /// Jump to a specific checkpoint
  Future<void> syncToCheckpoint(String checkpointId) async {
    if (!isInitialized || _syncConfig == null) return;

    final checkpoint = _syncConfig!.checkpoints.firstWhere(
      (cp) => cp.checkpointId.toLowerCase() == checkpointId.toLowerCase(),
      orElse: () {
        debugPrint('Checkpoint $checkpointId not found, using first checkpoint');
        return _syncConfig!.checkpoints.first;
      },
    );

    final userPosition = Duration(milliseconds: (checkpoint.userTimestamp * 1000).round());
    await seekUser(userPosition);
  }

  /// Start periodic sync timer to prevent drift
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(seconds: VideoSyncConfigConstants.resyncIntervalSeconds),
      (_) => _performSync(),
    );
  }

  /// Check and correct video sync drift
  Future<void> _performSync() async {
    if (!isInitialized || !isPlaying || _isSyncing || _syncConfig == null) {
      return;
    }

    _isSyncing = true;

    try {
      final userTime = _userController!.value.position.inMilliseconds / 1000.0;
      final currentProTime = _proController!.value.position.inMilliseconds / 1000.0;

      // Calculate expected pro time using sync algorithm
      final expectedProTime = _syncConfig!.mapUserTimeToPro(userTime);
      final offset = expectedProTime - currentProTime;

      // If drift is more than threshold, re-sync
      if (offset.abs() > (VideoSyncConfigConstants.maxSyncDriftMs / 1000.0)) {
        debugPrint('Video drift detected: ${offset.toStringAsFixed(3)}s - re-syncing');

        final proPosition = Duration(milliseconds: (expectedProTime * 1000).round());
        await _proController!.seekTo(proPosition);
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Dispose resources and cleanup
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;

    _userController?.dispose();
    _userController = null;

    _proController?.dispose();
    _proController = null;

    _syncConfig = null;
  }
}
```

---

## Step 5: Add Playback Speed Controls to UI

**File:** `lib/screens/form_analysis/components/synchronized_video_playback_view.dart`

Add playback speed selector:

```dart
Widget _buildPlaybackSpeedControl() {
  if (!VideoSyncConfigConstants.allowPlaybackSpeedControl) {
    return SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Speed: ', style: TextStyle(fontSize: 14)),
        SizedBox(width: 8),
        ...VideoSyncConfigConstants.availablePlaybackSpeeds.map((speed) {
          final isSelected = (widget.playerService.currentPlaybackSpeed - speed).abs() < 0.01;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('${(speed * 100).toStringAsFixed(0)}%'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  widget.playerService.setPlaybackSpeed(speed);
                  setState(() {});
                }
              },
            ),
          );
        }).toList(),
      ],
    ),
  );
}

// Add to build method:
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildCheckpointChipSelector(),
      _buildPlaybackSpeedControl(),  // NEW
      Expanded(child: _buildVideoLayout()),
      _buildSyncedControls(),
    ],
  );
}
```

---

## Step 6: Add Sync Mode Debug Info (Optional)

**File:** `lib/widgets/form_analysis/video_sync_debug_overlay.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/services/form_analysis/synchronized_video_player_service.dart';
import 'package:turbo_disc_golf/config/video_sync_config_constants.dart';

/// Debug overlay showing sync information
class VideoSyncDebugOverlay extends StatelessWidget {
  final SynchronizedVideoPlayerService playerService;

  const VideoSyncDebugOverlay({
    Key? key,
    required this.playerService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!VideoSyncConfigConstants.showSyncDebugInfo) {
      return SizedBox.shrink();
    }

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: EdgeInsets.all(8),
        color: Colors.black.withOpacity(0.7),
        child: ValueListenableBuilder(
          valueListenable: playerService.userController!,
          builder: (context, userValue, _) {
            return ValueListenableBuilder(
              valueListenable: playerService.proController!,
              builder: (context, proValue, _) {
                final userTime = userValue.position.inMilliseconds / 1000.0;
                final proTime = proValue.position.inMilliseconds / 1000.0;
                final expectedProTime = playerService.syncConfig!.mapUserTimeToPro(userTime);
                final drift = (expectedProTime - proTime).abs();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sync Mode: ${playerService.syncConfig!.syncMode.name}',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      'User: ${userTime.toStringAsFixed(2)}s',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      'Pro: ${proTime.toStringAsFixed(2)}s',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      'Expected: ${expectedProTime.toStringAsFixed(2)}s',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      'Drift: ${(drift * 1000).toStringAsFixed(0)}ms',
                      style: TextStyle(
                        color: drift > 0.1 ? Colors.red : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Speed: ${(playerService.currentPlaybackSpeed * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```

---

## Step 7: Update VideoFormAnalysisCubit

**File:** `lib/state/video_form_analysis_cubit.dart`

Update to use new sync config:

```dart
Future<void> loadVideoPlayback(PoseAnalysisResponse analysis) async {
  if (analysis.videoUrl == null) {
    emit(VideoPlaybackError('No video URL available'));
    return;
  }

  emit(VideoPlaybackLoading());

  try {
    // Check if pro video exists
    final hasProVideo = await ProVideoAssetService.hasProVideo(
      throwType: analysis.throwType,
      cameraAngle: analysis.cameraAngle,
    );

    if (!hasProVideo) {
      emit(VideoPlaybackError(
        'No pro reference video available for ${analysis.throwType} ${analysis.cameraAngle}'
      ));
      return;
    }

    // Load pro landmarks
    final proLandmarks = await ProVideoAssetService.loadProLandmarks(
      throwType: analysis.throwType,
      cameraAngle: analysis.cameraAngle,
    );

    // Create sync configuration (uses config constants for mode and speed)
    final syncConfig = VideoSyncConfig.fromAnalysis(
      analysis,
      proLandmarks,
    );

    // Initialize video player service
    final service = SynchronizedVideoPlayerService();
    await service.initialize(
      userVideoUrl: analysis.videoUrl!,
      throwType: analysis.throwType,
      cameraAngle: analysis.cameraAngle,
      syncConfig: syncConfig,
    );

    emit(VideoPlaybackReady(service, analysis));
  } catch (e) {
    emit(VideoPlaybackError('Failed to load videos: $e'));
  }
}
```

---

## Summary: Implementation Checklist

- [ ] Create `lib/config/video_sync_config_constants.dart` with testing constants
- [ ] Update `ProVideoLandmarks` model to include FPS and speed metadata
- [ ] Update `VideoSyncConfig` with both sync algorithms
- [ ] Update `SynchronizedVideoPlayerService` with speed normalization
- [ ] Add playback speed controls to UI
- [ ] (Optional) Add debug overlay for testing
- [ ] Update `VideoFormAnalysisCubit` to use new config

---

## Testing Both Sync Modes

### Test Single-Point Sync

1. Set in config:
```dart
static const VideoSyncMode syncMode = VideoSyncMode.SINGLE_POINT;
```

2. Expected behavior:
   - Videos start at disc release
   - Simple offset-based sync
   - Faster to compute

### Test Multi-Point Sync

1. Set in config:
```dart
static const VideoSyncMode syncMode = VideoSyncMode.MULTI_POINT;
```

2. Expected behavior:
   - Videos start at beginning
   - Full throw is time-warped
   - All checkpoints aligned

### Test Playback Speeds

Try different speeds:
```dart
static const double defaultPlaybackSpeed = 0.125; // Very slow
static const double defaultPlaybackSpeed = 0.25;  // Slow (default)
static const double defaultPlaybackSpeed = 0.5;   // Half speed
static const double defaultPlaybackSpeed = 1.0;   // Real-time
```

### Debug Sync Issues

Enable debug overlay:
```dart
static const bool showSyncDebugInfo = true;
```

This shows real-time sync drift and timing information.

---

## Important Notes

- **Default playback speed**: 25% (slow motion)
- **Single-point sync**: Simpler, anchors at disc release only
- **Multi-point sync**: More accurate, but more complex
- **FPS detection**: Automatic based on video metadata
- **Speed normalization**: Pro slow-motion videos automatically adjusted
- **Testing**: Use constants to switch between modes without code changes
