# Instructions: Setting Up Pro Reference Video Assets

## Overview
You need to bundle pro reference videos in the Flutter app assets so they can be played alongside user videos for synchronized playback with skeleton overlays.

---

## Step 1: Create Asset Directory Structure

Create the following directory structure in your Flutter project:

```
/Users/joevanderveen/Development/turbo_disc_golf_new/assets/
└── pro_references/
    ├── backhand/
    │   ├── side/
    │   │   ├── reference.mp4
    │   │   └── landmarks.json
    │   └── rear/
    │       ├── reference.mp4
    │       └── landmarks.json
    └── forehand/
        ├── side/
        │   ├── reference.mp4
        │   └── landmarks.json
        └── rear/
            ├── reference.mp4
            └── landmarks.json
```

**Commands to create directories:**
```bash
cd /Users/joevanderveen/Development/turbo_disc_golf_new
mkdir -p assets/pro_references/backhand/side
mkdir -p assets/pro_references/backhand/rear
mkdir -p assets/pro_references/forehand/side
mkdir -p assets/pro_references/forehand/rear
```

---

## Step 2: Copy Pro Videos to Asset Folders

**IMPORTANT**: Ask the user where the pro reference videos are located, then copy them:

```bash
# Example - adjust paths based on where user's pro videos are stored:
cp /path/to/paul_mcbeth_backhand_side.mp4 assets/pro_references/backhand/side/reference.mp4
cp /path/to/paul_mcbeth_backhand_rear.mp4 assets/pro_references/backhand/rear/reference.mp4
cp /path/to/paul_mcbeth_forehand_side.mp4 assets/pro_references/forehand/side/reference.mp4
cp /path/to/paul_mcbeth_forehand_rear.mp4 assets/pro_references/forehand/rear/reference.mp4
```

**If user doesn't have pro videos yet:**
- Create placeholder files for now
- User can replace them later with actual pro videos

---

## Step 3: Generate Landmarks Data for Pro Videos

Each pro video needs to be analyzed by the backend to extract pose landmarks. These landmarks will be saved as `landmarks.json` files.

**Backend API endpoint to use:**
`POST /api/v1/form-analysis/analyze-file`

**You need to:**
1. Call the backend API for each pro video
2. Extract the `frame_poses` array from the response (this contains all landmark data)
3. Save it as `landmarks.json` in the corresponding directory

**Example Python script to generate landmarks** (save as `generate_pro_landmarks.py` in backend):

```python
#!/usr/bin/env python3
"""
Generate landmarks.json files for pro reference videos.
Run this from the backend directory after videos are copied to Flutter assets.
"""
import requests
import json
import os
from pathlib import Path

# Backend API endpoint
API_URL = "http://localhost:8080/api/v1/form-analysis/analyze-file"

# Pro video configurations
PRO_VIDEOS = [
    {
        "path": "/Users/joevanderveen/Development/turbo_disc_golf_new/assets/pro_references/backhand/side/reference.mp4",
        "landmarks_path": "/Users/joevanderveen/Development/turbo_disc_golf_new/assets/pro_references/backhand/side/landmarks.json",
        "throw_type": "backhand",
        "camera_angle": "side"
    },
    {
        "path": "/Users/joevanderveen/Development/turbo_disc_golf_new/assets/pro_references/backhand/rear/reference.mp4",
        "landmarks_path": "/Users/joevanderveen/Development/turbo_disc_golf_new/assets/pro_references/backhand/rear/landmarks.json",
        "throw_type": "backhand",
        "camera_angle": "rear"
    },
    {
        "path": "/Users/joevanderveen/Development/turbo_disc_golf_new/assets/pro_references/forehand/side/reference.mp4",
        "landmarks_path": "/Users/joevanderveen/Development/turbo_disc_golf_new/assets/pro_references/forehand/side/landmarks.json",
        "throw_type": "forehand",
        "camera_angle": "side"
    },
    {
        "path": "/Users/joevanderveen/Development/turbo_disc_golf_new/assets/pro_references/forehand/rear/reference.mp4",
        "landmarks_path": "/Users/joevanderveen/Development/turbo_disc_golf_new/assets/pro_references/forehand/rear/landmarks.json",
        "throw_type": "forehand",
        "camera_angle": "rear"
    }
]

def generate_landmarks(video_config):
    """Analyze a pro video and save landmarks."""
    video_path = video_config["path"]
    landmarks_path = video_config["landmarks_path"]

    if not os.path.exists(video_path):
        print(f"⊘ Skipping {video_path} (video not found)")
        return

    print(f"\n{'='*70}")
    print(f"Processing: {video_config['throw_type']} - {video_config['camera_angle']}")
    print(f"{'='*70}")

    # Prepare request
    files = {
        'video': open(video_path, 'rb')
    }
    data = {
        'throw_type': video_config['throw_type'],
        'camera_angle': video_config['camera_angle'],
        'user_id': 'pro_reference',
        'session_id': f"pro_{video_config['throw_type']}_{video_config['camera_angle']}"
    }

    print(f"Analyzing video with backend API...")
    response = requests.post(API_URL, files=files, data=data, timeout=120)

    if response.status_code != 200:
        print(f"✗ Error: {response.status_code}")
        print(response.text)
        return

    result = response.json()

    # Extract frame poses (all landmark data)
    frame_poses = result.get('frame_poses', [])
    checkpoints = result.get('checkpoints', [])
    video_duration = result.get('video_duration_seconds', 0)

    if not frame_poses:
        print("✗ No frame poses returned from API")
        return

    # Create landmarks data structure
    landmarks_data = {
        "throw_type": video_config['throw_type'],
        "camera_angle": video_config['camera_angle'],
        "video_duration_seconds": video_duration,
        "frame_poses": frame_poses,
        "checkpoints": checkpoints,
        "metadata": {
            "athlete": "Pro Reference",
            "analyzed_at": result.get('analyzed_at', ''),
            "total_frames": len(frame_poses)
        }
    }

    # Save to JSON file
    os.makedirs(os.path.dirname(landmarks_path), exist_ok=True)
    with open(landmarks_path, 'w') as f:
        json.dump(landmarks_data, f, indent=2)

    print(f"✓ Landmarks saved: {landmarks_path}")
    print(f"  - Total frames: {len(frame_poses)}")
    print(f"  - Checkpoints: {len(checkpoints)}")
    print(f"  - Duration: {video_duration:.2f}s")

if __name__ == "__main__":
    print("Generating landmarks for pro reference videos...")
    print("Make sure the backend server is running on http://localhost:8080")

    for config in PRO_VIDEOS:
        try:
            generate_landmarks(config)
        except Exception as e:
            print(f"✗ Error processing {config['path']}: {e}")

    print("\n" + "="*70)
    print("✓ Landmark generation complete!")
    print("="*70)
```

**To run the landmark generation script:**
```bash
# 1. Make sure backend server is running
cd /Users/joevanderveen/Development/score-sensei-backend
source venv/bin/activate
export GOOGLE_APPLICATION_CREDENTIALS="/Users/joevanderveen/gcp-keys/score-sensei-dev-key.json"
python main.py

# 2. In another terminal, run the landmark generation script
cd /Users/joevanderveen/Development/score-sensei-backend
source venv/bin/activate
python generate_pro_landmarks.py
```

**If you don't have pro videos yet**, create placeholder landmarks.json files:
```json
{
  "throw_type": "backhand",
  "camera_angle": "side",
  "video_duration_seconds": 3.0,
  "frame_poses": [],
  "checkpoints": [],
  "metadata": {
    "athlete": "Pro Reference",
    "analyzed_at": "",
    "total_frames": 0
  }
}
```

---

## Step 4: Update pubspec.yaml

Add the asset directories to `pubspec.yaml`:

```yaml
flutter:
  assets:
    # Pro reference videos and landmarks
    - assets/pro_references/backhand/side/
    - assets/pro_references/backhand/rear/
    - assets/pro_references/forehand/side/
    - assets/pro_references/forehand/rear/
```

**Run after updating pubspec.yaml:**
```bash
flutter pub get
```

---

## Step 5: Create Pro Video Asset Loader Service

Create a new service to load pro videos and their landmarks from assets.

**File:** `lib/services/form_analysis/pro_video_asset_service.dart` (NEW)

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

/// Service for loading pro reference videos and landmarks from app assets
class ProVideoAssetService {
  ProVideoAssetService._(); // Private constructor - singleton pattern

  /// Resolve the asset path for a pro reference video
  ///
  /// Returns the path to the video file in assets based on throw type and camera angle
  ///
  /// Example: 'assets/pro_references/backhand/side/reference.mp4'
  static String getProVideoPath({
    required String throwType,
    required String cameraAngle,
  }) {
    final normalizedThrowType = throwType.toLowerCase();
    final normalizedCameraAngle = cameraAngle.toLowerCase();

    return 'assets/pro_references/$normalizedThrowType/$normalizedCameraAngle/reference.mp4';
  }

  /// Load pre-analyzed landmarks for a pro reference video
  ///
  /// Returns the frame poses and checkpoints that were generated by analyzing
  /// the pro video through the backend API
  static Future<ProVideoLandmarks> loadProLandmarks({
    required String throwType,
    required String cameraAngle,
  }) async {
    final normalizedThrowType = throwType.toLowerCase();
    final normalizedCameraAngle = cameraAngle.toLowerCase();

    final landmarksPath =
        'assets/pro_references/$normalizedThrowType/$normalizedCameraAngle/landmarks.json';

    try {
      // Load JSON file from assets
      final jsonString = await rootBundle.loadString(landmarksPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      return ProVideoLandmarks.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load pro landmarks from $landmarksPath: $e');
    }
  }

  /// Check if a pro reference video exists for the given throw type and camera angle
  static Future<bool> hasProVideo({
    required String throwType,
    required String cameraAngle,
  }) async {
    try {
      final videoPath = getProVideoPath(
        throwType: throwType,
        cameraAngle: cameraAngle,
      );

      // Try to load the asset - if it fails, video doesn't exist
      await rootBundle.load(videoPath);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Data model for pro video landmarks loaded from assets
class ProVideoLandmarks {
  final String throwType;
  final String cameraAngle;
  final double videoDurationSeconds;
  final List<FramePoseData> framePoses;
  final List<CheckpointData> checkpoints;
  final Map<String, dynamic> metadata;

  ProVideoLandmarks({
    required this.throwType,
    required this.cameraAngle,
    required this.videoDurationSeconds,
    required this.framePoses,
    required this.checkpoints,
    required this.metadata,
  });

  factory ProVideoLandmarks.fromJson(Map<String, dynamic> json) {
    return ProVideoLandmarks(
      throwType: json['throw_type'] as String,
      cameraAngle: json['camera_angle'] as String,
      videoDurationSeconds: (json['video_duration_seconds'] as num).toDouble(),
      framePoses: (json['frame_poses'] as List<dynamic>)
          .map((e) => FramePoseData.fromJson(e as Map<String, dynamic>))
          .toList(),
      checkpoints: (json['checkpoints'] as List<dynamic>)
          .map((e) => CheckpointData.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}
```

---

## Step 6: Update SynchronizedVideoPlayerService

Update the service to use the pro video asset loader.

**File:** `lib/services/form_analysis/synchronized_video_player_service.dart`

Find the `initialize` method and update it:

```dart
/// Initialize both video controllers
///
/// [userVideoUrl] - Cloud Storage signed URL for user's video
/// [throwType] - "backhand" or "forehand"
/// [cameraAngle] - "side" or "rear"
/// [syncConfig] - Checkpoint-based synchronization configuration
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

  // Set both videos to looping (optional)
  await _userController!.setLooping(false);
  await _proController!.setLooping(false);

  // Start periodic sync timer to prevent drift
  _startSyncTimer();
}
```

---

## Step 7: Update Video Playback View

Update the view to load pro landmarks and pass them to the video panel.

**File:** `lib/screens/form_analysis/components/synchronized_video_playback_view.dart`

```dart
class SynchronizedVideoPlaybackView extends StatefulWidget {
  final PoseAnalysisResponse userAnalysis;
  final SynchronizedVideoPlayerService playerService;
  final bool compact;

  // ... existing code
}

class _SynchronizedVideoPlaybackViewState extends State<SynchronizedVideoPlaybackView> {
  ProVideoLandmarks? _proLandmarks;
  bool _isLoadingProLandmarks = true;

  @override
  void initState() {
    super.initState();
    _loadProLandmarks();
  }

  Future<void> _loadProLandmarks() async {
    try {
      final landmarks = await ProVideoAssetService.loadProLandmarks(
        throwType: widget.userAnalysis.throwType,
        cameraAngle: widget.userAnalysis.cameraAngle,
      );

      setState(() {
        _proLandmarks = landmarks;
        _isLoadingProLandmarks = false;
      });
    } catch (e) {
      debugPrint('Failed to load pro landmarks: $e');
      setState(() {
        _isLoadingProLandmarks = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProLandmarks) {
      return Center(child: CircularProgressIndicator());
    }

    // Now you can pass _proLandmarks.framePoses to the pro video panel
    return Column(
      children: [
        // User video panel
        VideoPanelWithSkeleton(
          controller: widget.playerService.userController!,
          framePoses: widget.userAnalysis.framePoses,
          label: 'Your Throw',
          skeletonColor: Colors.blue,
        ),

        // Pro video panel (if landmarks loaded successfully)
        if (_proLandmarks != null)
          VideoPanelWithSkeleton(
            controller: widget.playerService.proController!,
            framePoses: _proLandmarks!.framePoses,
            label: 'Pro reference',
            skeletonColor: Colors.green,
          ),

        // Controls
        _buildSyncedControls(),
      ],
    );
  }
}
```

---

## Step 8: Update VideoFormAnalysisCubit

Update the cubit to initialize with throw type and camera angle.

**File:** `lib/state/video_form_analysis_cubit.dart`

```dart
Future<void> loadVideoPlayback(PoseAnalysisResponse analysis) async {
  if (analysis.videoUrl == null) {
    emit(VideoPlaybackError('No video URL available'));
    return;
  }

  emit(VideoPlaybackLoading());

  try {
    // Check if pro video exists for this throw type and camera angle
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

    // Load pro landmarks to get pro video duration
    final proLandmarks = await ProVideoAssetService.loadProLandmarks(
      throwType: analysis.throwType,
      cameraAngle: analysis.cameraAngle,
    );

    // Create sync configuration
    final syncConfig = VideoSyncConfig.fromAnalysis(
      analysis,
      proLandmarks.videoDurationSeconds,
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

## Summary: What You Need to Do

1. **Create asset directories** (Step 1)
2. **Ask user where pro videos are** and copy them to assets (Step 2)
3. **Generate landmarks.json files** using the Python script (Step 3)
   - OR create placeholder JSON files if pro videos don't exist yet
4. **Update pubspec.yaml** with asset paths (Step 4)
5. **Create ProVideoAssetService** (Step 5)
6. **Update SynchronizedVideoPlayerService.initialize()** (Step 6)
7. **Update SynchronizedVideoPlaybackView** to load pro landmarks (Step 7)
8. **Update VideoFormAnalysisCubit.loadVideoPlayback()** (Step 8)

---

## Testing

After implementation, test with:

```dart
// Check if pro video exists
final hasVideo = await ProVideoAssetService.hasProVideo(
  throwType: 'backhand',
  cameraAngle: 'side',
);
print('Has backhand side video: $hasVideo');

// Load landmarks
final landmarks = await ProVideoAssetService.loadProLandmarks(
  throwType: 'backhand',
  cameraAngle: 'side',
);
print('Loaded ${landmarks.framePoses.length} frames');
```

---

## Important Notes

- **Asset paths are case-sensitive**: Use lowercase for throw_type and camera_angle
- **Video format**: Use H.264 MP4 for maximum compatibility
- **File size**: Each pro video should be 5-10MB for reasonable app size
- **Landmarks generation**: Must be done AFTER videos are copied to assets
- **If pro videos don't exist yet**: Create placeholder JSON files so app doesn't crash

---

## Questions to Ask User

Before proceeding, ask the user:

1. **Do you have pro reference videos available?**
   - If yes: Where are they located?
   - If no: We'll create placeholders for now

2. **What throw types and camera angles do you want to support?**
   - backhand + side ✓
   - backhand + rear ✓
   - forehand + side ✓
   - forehand + rear ✓
   - Other combinations?

3. **Who is the pro reference?**
   - For metadata purposes (e.g., "Paul McBeth", "Eagle McMahon")
