# Flutter Frontend Implementation Instructions for Claude

## Context

I need you to implement synchronized video playback with real-time skeleton overlays for the disc golf form analysis app. The backend has been updated to upload user videos to Google Cloud Storage and return a `video_url` field in the API response.

## What's Already Done

### Backend (✅ Complete):
- Added `google-cloud-storage` dependency
- Created `VideoStorageService` class
- Added `video_url` field to `FormAnalysisResponse` model
- Integrated Cloud Storage upload in both `/analyze` endpoints
- Videos are uploaded after analysis and signed URL (30-day expiry) is returned

### Flutter (✅ Foundation):
- Added `video_player: ^2.9.2` and `chewie: ^1.8.5` to `pubspec.yaml`
- Added `videoUrl` field to `PoseAnalysisResponse` model
- **NOTE**: You MUST run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate the model files after reading this

## Architecture Overview

**Goal**: Play user's uploaded video side-by-side with a pro reference video, with real-time skeleton overlays drawn on top of both videos. Videos automatically synchronize at the 4 checkpoints (Heisman, Loaded, Magic, Pro).

**Key Design Decisions**:
1. **Real-time skeleton overlay**: Use Flutter `CustomPainter` to draw skeletons on top of videos (NOT pre-rendered frames)
2. **Video source**: User videos loaded from Cloud Storage URL; pro videos bundled in app assets
3. **Synchronization**: Automatic time-warping based on checkpoint timestamps using piecewise linear interpolation
4. **Landmark interpolation**: Backend returns 15 sampled frames; interpolate between them for smooth 30fps skeleton animation
5. **UI placement**: Video playback integrated ABOVE the existing checkpoint comparison section in `AnalysisResultsView`

## Detailed Implementation Plan

### Phase 1: Install Dependencies & Regenerate Models

**Run these commands first**:
```bash
cd /Users/joevanderveen/Development/turbo_disc_golf_new
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

Verify `pose_analysis_response.g.dart` now includes the `videoUrl` field.

---

### Phase 2: Create Data Models

**File**: `lib/models/data/form_analysis/video_sync_config.dart` (NEW)

```dart
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

/// Configuration for synchronizing user and pro videos
class VideoSyncConfig {
  final List<CheckpointTimestamp> checkpoints;
  final double userVideoDuration;
  final double proVideoDuration;

  const VideoSyncConfig({
    required this.checkpoints,
    required this.userVideoDuration,
    required this.proVideoDuration,
  });

  /// Maps user video timestamp to pro video timestamp using piecewise linear interpolation
  double mapUserTimeToPro(double userTime) {
    if (checkpoints.isEmpty) return userTime;

    // Before first checkpoint: use linear scaling
    if (userTime <= checkpoints.first.userTimestamp) {
      final ratio = checkpoints.first.proTimestamp / checkpoints.first.userTimestamp;
      return userTime * ratio;
    }

    // After last checkpoint: use linear scaling
    if (userTime >= checkpoints.last.userTimestamp) {
      final lastCheckpoint = checkpoints.last;
      final userRemaining = userVideoDuration - lastCheckpoint.userTimestamp;
      final proRemaining = proVideoDuration - lastCheckpoint.proTimestamp;
      final ratio = proRemaining / userRemaining;
      return lastCheckpoint.proTimestamp + (userTime - lastCheckpoint.userTimestamp) * ratio;
    }

    // Between checkpoints: piecewise linear interpolation
    for (int i = 0; i < checkpoints.length - 1; i++) {
      final curr = checkpoints[i];
      final next = checkpoints[i + 1];

      if (userTime >= curr.userTimestamp && userTime <= next.userTimestamp) {
        final userSegment = next.userTimestamp - curr.userTimestamp;
        final proSegment = next.proTimestamp - curr.proTimestamp;
        final progress = (userTime - curr.userTimestamp) / userSegment;
        return curr.proTimestamp + (progress * proSegment);
      }
    }

    return userTime; // Fallback
  }

  /// Create from pose analysis response
  factory VideoSyncConfig.fromAnalysis(
    PoseAnalysisResponse userAnalysis,
    double proVideoDuration,
  ) {
    final checkpoints = userAnalysis.checkpoints.map((cp) {
      // For now, assume pro video checkpoints are at same percentage of video duration
      // In future, load actual pro checkpoint timestamps from landmarks.json
      final proTimestamp = (cp.timestampSeconds / userAnalysis.videoDurationSeconds) * proVideoDuration;

      return CheckpointTimestamp(
        checkpointId: cp.checkpointId,
        userTimestamp: cp.timestampSeconds,
        proTimestamp: proTimestamp,
      );
    }).toList();

    return VideoSyncConfig(
      checkpoints: checkpoints,
      userVideoDuration: userAnalysis.videoDurationSeconds,
      proVideoDuration: proVideoDuration,
    );
  }
}

/// Timestamp mapping for a checkpoint between user and pro videos
class CheckpointTimestamp {
  final String checkpointId;
  final double userTimestamp;
  final double proTimestamp;

  const CheckpointTimestamp({
    required this.checkpointId,
    required this.userTimestamp,
    required this.proTimestamp,
  });
}
```

---

### Phase 3: Create Utility Classes

#### File: `lib/utils/video_sync_algorithm.dart` (NEW)

```dart
import 'package:turbo_disc_golf/models/data/form_analysis/video_sync_config.dart';

/// Algorithms for video synchronization
class VideoSyncAlgorithm {
  /// Maps user video time to pro video time using time-warping
  static double mapUserTimeToPro(
    double userTime,
    VideoSyncConfig config,
  ) {
    return config.mapUserTimeToPro(userTime);
  }

  /// Calculate the sync offset needed at a given time
  static double calculateSyncOffset(
    double userTime,
    double currentProTime,
    VideoSyncConfig config,
  ) {
    final targetProTime = mapUserTimeToPro(userTime, config);
    return targetProTime - currentProTime;
  }
}
```

#### File: `lib/utils/landmark_interpolator.dart` (NEW)

```dart
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

/// Interpolates pose landmarks between sampled frames for smooth skeleton animation
class LandmarkInterpolator {
  /// Interpolate landmarks at a specific timestamp
  ///
  /// Given 15 sampled frames from the backend, calculate landmarks at any timestamp
  /// using linear interpolation between surrounding frames.
  static List<PoseLandmark> interpolateAtTime(
    double timestamp,
    List<FramePoseData> sampledFrames,
  ) {
    if (sampledFrames.isEmpty) return [];

    // Find surrounding frames
    FramePoseData? before;
    FramePoseData? after;

    for (int i = 0; i < sampledFrames.length; i++) {
      final frame = sampledFrames[i];

      if (frame.timestampSeconds <= timestamp) {
        before = frame;
      }

      if (frame.timestampSeconds >= timestamp && after == null) {
        after = frame;
        break;
      }
    }

    // Edge cases
    if (before == null) return after?.landmarks ?? [];
    if (after == null) return before.landmarks;
    if (before.timestampSeconds == after.timestampSeconds) return before.landmarks;

    // Interpolate between frames
    final progress = (timestamp - before.timestampSeconds) /
                     (after.timestampSeconds - before.timestampSeconds);

    final interpolated = <PoseLandmark>[];

    for (int i = 0; i < before.landmarks.length && i < after.landmarks.length; i++) {
      final landmarkBefore = before.landmarks[i];
      final landmarkAfter = after.landmarks[i];

      interpolated.add(PoseLandmark(
        name: landmarkBefore.name,
        x: _lerp(landmarkBefore.x, landmarkAfter.x, progress),
        y: _lerp(landmarkBefore.y, landmarkAfter.y, progress),
        z: _lerp(landmarkBefore.z, landmarkAfter.z, progress),
        visibility: _lerp(landmarkBefore.visibility, landmarkAfter.visibility, progress),
      ));
    }

    return interpolated;
  }

  /// Linear interpolation between two values
  static double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
}
```

---

### Phase 4: Create Skeleton Overlay Painter

**File**: `lib/widgets/form_analysis/skeleton_overlay_painter.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

/// CustomPainter that draws a skeleton overlay on top of a video frame
class SkeletonOverlayPainter extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final Color skeletonColor;
  final double lineWidth;
  final bool showJoints;

  SkeletonOverlayPainter({
    required this.landmarks,
    this.skeletonColor = Colors.greenAccent,
    this.lineWidth = 3.0,
    this.showJoints = true,
  });

  /// MediaPipe Pose connection definitions
  /// Each connection is a pair of landmark names to draw a line between
  static const List<List<String>> connections = [
    // Torso
    ['left_shoulder', 'right_shoulder'],
    ['left_shoulder', 'left_hip'],
    ['right_shoulder', 'right_hip'],
    ['left_hip', 'right_hip'],

    // Left arm
    ['left_shoulder', 'left_elbow'],
    ['left_elbow', 'left_wrist'],
    ['left_wrist', 'left_pinky'],
    ['left_wrist', 'left_index'],
    ['left_wrist', 'left_thumb'],

    // Right arm
    ['right_shoulder', 'right_elbow'],
    ['right_elbow', 'right_wrist'],
    ['right_wrist', 'right_pinky'],
    ['right_wrist', 'right_index'],
    ['right_wrist', 'right_thumb'],

    // Left leg
    ['left_hip', 'left_knee'],
    ['left_knee', 'left_ankle'],
    ['left_ankle', 'left_heel'],
    ['left_ankle', 'left_foot_index'],

    // Right leg
    ['right_hip', 'right_knee'],
    ['right_knee', 'right_ankle'],
    ['right_ankle', 'right_heel'],
    ['right_ankle', 'right_foot_index'],

    // Face (optional, can remove if cluttered)
    ['nose', 'left_eye_inner'],
    ['left_eye_inner', 'left_eye'],
    ['left_eye', 'left_eye_outer'],
    ['nose', 'right_eye_inner'],
    ['right_eye_inner', 'right_eye'],
    ['right_eye', 'right_eye_outer'],
    ['left_eye_outer', 'left_ear'],
    ['right_eye_outer', 'right_ear'],
    ['mouth_left', 'mouth_right'],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    // Create landmark map for quick lookup
    final landmarkMap = <String, PoseLandmark>{};
    for (final landmark in landmarks) {
      landmarkMap[landmark.name] = landmark;
    }

    final linePaint = Paint()
      ..color = skeletonColor
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = skeletonColor
      ..style = PaintingStyle.fill;

    // Draw connections
    for (final connection in connections) {
      final start = landmarkMap[connection[0]];
      final end = landmarkMap[connection[1]];

      if (start != null && end != null &&
          start.visibility > 0.5 && end.visibility > 0.5) {
        final startPos = _landmarkToOffset(start, size);
        final endPos = _landmarkToOffset(end, size);
        canvas.drawLine(startPos, endPos, linePaint);
      }
    }

    // Draw joints
    if (showJoints) {
      for (final landmark in landmarks) {
        if (landmark.visibility > 0.5) {
          final pos = _landmarkToOffset(landmark, size);
          canvas.drawCircle(pos, lineWidth * 1.5, jointPaint);
        }
      }
    }
  }

  /// Maps normalized landmark coordinates (0-1) to screen pixel coordinates
  Offset _landmarkToOffset(PoseLandmark landmark, Size size) {
    return Offset(
      landmark.x * size.width,
      landmark.y * size.height,
    );
  }

  @override
  bool shouldRepaint(SkeletonOverlayPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks ||
           oldDelegate.skeletonColor != skeletonColor ||
           oldDelegate.lineWidth != lineWidth;
  }
}
```

---

### Phase 5: Create Synchronized Video Player Service

**File**: `lib/services/form_analysis/synchronized_video_player_service.dart` (NEW)

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/video_sync_config.dart';
import 'package:turbo_disc_golf/utils/video_sync_algorithm.dart';

/// Service for managing synchronized playback of user and pro videos
class SynchronizedVideoPlayerService {
  VideoPlayerController? _userController;
  VideoPlayerController? _proController;
  VideoSyncConfig? _syncConfig;

  Timer? _syncTimer;
  bool _isSyncing = false;

  VideoPlayerController? get userController => _userController;
  VideoPlayerController? get proController => _proController;
  VideoSyncConfig? get syncConfig => _syncConfig;

  bool get isInitialized =>
    _userController?.value.isInitialized == true &&
    _proController?.value.isInitialized == true;

  bool get isPlaying => _userController?.value.isPlaying ?? false;

  /// Initialize both video controllers
  Future<void> initialize({
    required String userVideoUrl,
    required String proVideoPath,
    required VideoSyncConfig syncConfig,
  }) async {
    _syncConfig = syncConfig;

    // Initialize user video (from network URL)
    _userController = VideoPlayerController.networkUrl(Uri.parse(userVideoUrl));
    await _userController!.initialize();

    // Initialize pro video (from assets)
    _proController = VideoPlayerController.asset(proVideoPath);
    await _proController!.initialize();

    // Start sync timer to keep videos aligned
    _startSyncTimer();
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

  /// Seek user video to a position and auto-sync pro video
  Future<void> seekUser(Duration position) async {
    if (!isInitialized || _syncConfig == null) return;

    // Pause during seek
    final wasPlaying = isPlaying;
    if (wasPlaying) await pause();

    // Seek user video
    await _userController!.seekTo(position);

    // Calculate corresponding pro video position
    final userTime = position.inMilliseconds / 1000.0;
    final proTime = VideoSyncAlgorithm.mapUserTimeToPro(userTime, _syncConfig!);
    final proPosition = Duration(milliseconds: (proTime * 1000).round());

    // Seek pro video
    await _proController!.seekTo(proPosition);

    // Resume if was playing
    if (wasPlaying) await play();
  }

  /// Jump to a specific checkpoint
  Future<void> syncToCheckpoint(String checkpointId) async {
    if (!isInitialized || _syncConfig == null) return;

    final checkpoint = _syncConfig!.checkpoints.firstWhere(
      (cp) => cp.checkpointId == checkpointId,
      orElse: () => _syncConfig!.checkpoints.first,
    );

    await seekUser(Duration(milliseconds: (checkpoint.userTimestamp * 1000).round()));
  }

  /// Periodically re-sync videos to prevent drift
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _performSync();
    });
  }

  /// Check and correct sync drift
  Future<void> _performSync() async {
    if (!isInitialized || !isPlaying || _isSyncing || _syncConfig == null) return;

    _isSyncing = true;

    try {
      final userTime = _userController!.value.position.inMilliseconds / 1000.0;
      final currentProTime = _proController!.value.position.inMilliseconds / 1000.0;

      final offset = VideoSyncAlgorithm.calculateSyncOffset(
        userTime,
        currentProTime,
        _syncConfig!,
      );

      // If drift is more than 100ms, re-sync
      if (offset.abs() > 0.1) {
        final targetProTime = VideoSyncAlgorithm.mapUserTimeToPro(userTime, _syncConfig!);
        await _proController!.seekTo(
          Duration(milliseconds: (targetProTime * 1000).round()),
        );
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _userController?.dispose();
    _proController?.dispose();
  }
}
```

---

### Phase 6: Create Video Panel Widget

**File**: `lib/widgets/form_analysis/video_panel_with_skeleton.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/widgets/form_analysis/skeleton_overlay_painter.dart';
import 'package:turbo_disc_golf/utils/landmark_interpolator.dart';

/// A video panel with real-time skeleton overlay
class VideoPanelWithSkeleton extends StatelessWidget {
  final VideoPlayerController controller;
  final List<FramePoseData> framePoses;
  final String label;
  final Color skeletonColor;

  const VideoPanelWithSkeleton({
    super.key,
    required this.controller,
    required this.framePoses,
    required this.label,
    this.skeletonColor = Colors.greenAccent,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          VideoPlayer(controller),

          // Real-time skeleton overlay
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final timestamp = value.position.inMilliseconds / 1000.0;
              final landmarks = LandmarkInterpolator.interpolateAtTime(
                timestamp,
                framePoses,
              );

              return CustomPaint(
                painter: SkeletonOverlayPainter(
                  landmarks: landmarks,
                  skeletonColor: skeletonColor,
                  lineWidth: 3.0,
                  showJoints: true,
                ),
              );
            },
          ),

          // Label overlay
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Phase 7: Create Main Synchronized Video View

**File**: `lib/screens/form_analysis/components/synchronized_video_playback_view.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/services/form_analysis/synchronized_video_player_service.dart';
import 'package:turbo_disc_golf/widgets/form_analysis/video_panel_with_skeleton.dart';

/// Main UI for synchronized video playback with skeleton overlays
class SynchronizedVideoPlaybackView extends StatefulWidget {
  final SynchronizedVideoPlayerService service;
  final PoseAnalysisResponse analysis;

  const SynchronizedVideoPlaybackView({
    super.key,
    required this.service,
    required this.analysis,
  });

  @override
  State<SynchronizedVideoPlaybackView> createState() =>
      _SynchronizedVideoPlaybackViewState();
}

class _SynchronizedVideoPlaybackViewState
    extends State<SynchronizedVideoPlaybackView> {

  SynchronizedVideoPlayerService get _service => widget.service;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Checkpoint navigation chips
        _buildCheckpointChips(),

        const SizedBox(height: 16),

        // Video panels (side-by-side or stacked)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;
              return isLandscape ? _buildSideBySideLayout() : _buildStackedLayout();
            },
          ),
        ),

        const SizedBox(height: 16),

        // Playback controls
        _buildControls(),
      ],
    );
  }

  Widget _buildCheckpointChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.analysis.checkpoints.map((checkpoint) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(checkpoint.checkpointName),
              onPressed: () => _service.syncToCheckpoint(checkpoint.checkpointId),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSideBySideLayout() {
    return Row(
      children: [
        // User video
        Expanded(
          child: VideoPanelWithSkeleton(
            controller: _service.userController!,
            framePoses: widget.analysis.framePoses,
            label: 'Your Form',
            skeletonColor: Colors.greenAccent,
          ),
        ),

        const SizedBox(width: 8),

        // Pro video
        Expanded(
          child: VideoPanelWithSkeleton(
            controller: _service.proController!,
            framePoses: const [], // TODO: Load pro landmarks from assets
            label: 'Pro Reference',
            skeletonColor: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStackedLayout() {
    return Column(
      children: [
        // User video
        Expanded(
          child: VideoPanelWithSkeleton(
            controller: _service.userController!,
            framePoses: widget.analysis.framePoses,
            label: 'Your Form',
            skeletonColor: Colors.greenAccent,
          ),
        ),

        const SizedBox(height: 8),

        // Pro video
        Expanded(
          child: VideoPanelWithSkeleton(
            controller: _service.proController!,
            framePoses: const [], // TODO: Load pro landmarks from assets
            label: 'Pro Reference',
            skeletonColor: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _service.userController!,
      builder: (context, value, child) {
        return Column(
          children: [
            // Progress bar
            VideoProgressIndicator(
              _service.userController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.blue,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.black12,
              ),
            ),

            const SizedBox(height: 8),

            // Play/Pause button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    value.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 32,
                  ),
                  onPressed: () {
                    if (value.isPlaying) {
                      _service.pause();
                    } else {
                      _service.play();
                    }
                    setState(() {});
                  },
                ),

                const SizedBox(width: 16),

                // Time display
                Text(
                  '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
```

---

### Phase 8: Update VideoFormAnalysisCubit

**File**: `lib/state/video_form_analysis_cubit.dart`

Add new states and methods:

```dart
// Add these new states to the existing state classes

class VideoPlaybackLoading extends VideoFormAnalysisState {
  const VideoPlaybackLoading();
}

class VideoPlaybackReady extends VideoFormAnalysisState {
  final SynchronizedVideoPlayerService playerService;
  final PoseAnalysisResponse analysis;

  const VideoPlaybackReady({
    required this.playerService,
    required this.analysis,
  });

  @override
  List<Object?> get props => [playerService, analysis];
}

class VideoPlaybackError extends VideoFormAnalysisState {
  final String message;

  const VideoPlaybackError(this.message);

  @override
  List<Object?> get props => [message];
}

// Add these methods to VideoFormAnalysisCubit class

Future<void> loadVideoPlayback(PoseAnalysisResponse analysis) async {
  if (analysis.videoUrl == null) {
    emit(const VideoPlaybackError('No video URL available'));
    return;
  }

  emit(const VideoPlaybackLoading());

  try {
    // Initialize synchronized video player service
    final service = SynchronizedVideoPlayerService();

    // Determine pro video path based on throw type and camera angle
    final proVideoPath = _getProVideoPath(
      analysis.throwType,
      analysis.cameraAngle.name,
    );

    // For now, assume pro video has same duration as user video
    // TODO: Get actual pro video duration from assets
    final syncConfig = VideoSyncConfig.fromAnalysis(
      analysis,
      analysis.videoDurationSeconds, // Placeholder
    );

    await service.initialize(
      userVideoUrl: analysis.videoUrl!,
      proVideoPath: proVideoPath,
      syncConfig: syncConfig,
    );

    emit(VideoPlaybackReady(playerService: service, analysis: analysis));
  } catch (e) {
    emit(VideoPlaybackError('Failed to load video: $e'));
  }
}

String _getProVideoPath(String throwType, String cameraAngle) {
  // Adjust path based on your asset structure
  return 'assets/pro_references/paul_mcbeth/$throwType/$cameraAngle/reference.mp4';
}

@override
Future<void> close() {
  // Dispose video player service if exists
  final state = this.state;
  if (state is VideoPlaybackReady) {
    state.playerService.dispose();
  }
  return super.close();
}
```

---

### Phase 9: Integrate into AnalysisResultsView

**File**: `lib/screens/form_analysis/components/analysis_results_view.dart`

Add video playback section ABOVE the checkpoint comparison:

```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<VideoFormAnalysisCubit, VideoFormAnalysisState>(
    builder: (context, state) {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildScoreHeader(state),
            _buildOverallFeedbackSummary(state),

            // NEW: Synchronized video playback section
            _buildSynchronizedVideoSection(state),

            // Existing checkpoint comparison
            if (state is VideoFormAnalysisComplete &&
                state.poseAnalysis != null)
              PoseComparisonSection(
                poseData: state.poseAnalysis!,
                session: state.session,
              ),

            _buildCheckpointResultCards(state),
            _buildImprovementList(state),
          ],
        ),
      );
    },
  );
}

Widget _buildSynchronizedVideoSection(VideoFormAnalysisState state) {
  if (state is! VideoFormAnalysisComplete || state.poseAnalysis?.videoUrl == null) {
    return const SizedBox.shrink();
  }

  return BlocBuilder<VideoFormAnalysisCubit, VideoFormAnalysisState>(
    builder: (context, videoState) {
      // Auto-initialize video playback when analysis completes
      if (videoState is VideoFormAnalysisComplete &&
          videoState is! VideoPlaybackReady &&
          videoState is! VideoPlaybackLoading &&
          videoState is! VideoPlaybackError) {
        // Trigger video loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<VideoFormAnalysisCubit>().loadVideoPlayback(
            state.poseAnalysis!,
          );
        });
      }

      if (videoState is VideoPlaybackLoading) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          child: const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading video playback...'),
              ],
            ),
          ),
        );
      }

      if (videoState is VideoPlaybackError) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Video playback unavailable: ${videoState.message}',
            style: TextStyle(color: Colors.red.shade900),
          ),
        );
      }

      if (videoState is VideoPlaybackReady) {
        return Container(
          margin: const EdgeInsets.all(16),
          height: 400, // Adjust as needed
          child: SynchronizedVideoPlaybackView(
            service: videoState.playerService,
            analysis: videoState.analysis,
          ),
        );
      }

      return const SizedBox.shrink();
    },
  );
}
```

---

### Phase 10: Pro Reference Video Setup

**TODO**: You'll need to obtain actual pro throw videos. For now, you can:

1. **Option A - Use placeholder**:
   - Create a simple video or use one of the user's videos as a temporary pro reference
   - Place in: `assets/pro_references/paul_mcbeth/backhand/side/reference.mp4`

2. **Option B - Wait for actual pro videos**:
   - When you have them, place them in the assets structure as shown above
   - Pre-analyze them through the backend to get frame landmarks
   - Save landmarks as `landmarks.json` alongside each video

**Update pubspec.yaml** (already done):
```yaml
assets:
  - assets/pro_references/paul_mcbeth/backhand/side/
  - assets/pro_references/paul_mcbeth/backhand/rear/
  - assets/pro_references/paul_mcbeth/forehand/
```

---

## Testing Checklist

After implementation:

1. ✅ Run `flutter pub get`
2. ✅ Run `flutter pub run build_runner build --delete-conflicting-outputs`
3. ✅ Verify no compile errors
4. ✅ Upload a video and complete analysis
5. ✅ Verify `videoUrl` is present in API response
6. ✅ Check that video playback section appears above checkpoint comparison
7. ✅ Verify both videos load and play
8. ✅ Test checkpoint jump buttons
9. ✅ Verify skeleton overlays appear on both videos
10. ✅ Test play/pause/seek controls

## Key Points to Remember

1. **Model regeneration**: MUST run `flutter pub run build_runner build --delete-conflicting-outputs` after adding videoUrl field
2. **Video player initialization**: Always check `controller.value.isInitialized` before using
3. **Landmark interpolation**: Backend returns 15 frames, interpolate between them for smooth skeleton
4. **Sync drift**: Periodic re-sync every 2 seconds prevents videos from drifting apart
5. **Error handling**: Handle cases where videoUrl is null or video fails to load
6. **Disposal**: CRITICAL - dispose video controllers in cubit's close() method to prevent memory leaks

## Questions?

If you encounter issues:
- Check console for video loading errors
- Verify videoUrl is a valid signed URL (not expired)
- Ensure pro reference videos exist in assets at the correct paths
- Check that landmark interpolation is working (add debug prints)
- Verify sync config checkpoint timestamps are correct

Implement systematically following the phases above, and test each phase before moving to the next!
