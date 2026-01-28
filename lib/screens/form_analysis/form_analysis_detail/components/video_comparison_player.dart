import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/synchronized_video_player.dart';

import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/video_sync_metadata.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/form_analysis_video_helper.dart';

/// Reusable video comparison player that shows the user's form video
/// side-by-side with a pro reference video using [SynchronizedVideoPlayer].
///
/// Handles:
/// - Selecting the correct user video URL based on skeleton toggle
/// - Resolving the pro reference video asset path
/// - Displaying an info message when throw type is not supported
class VideoComparisonPlayer extends StatelessWidget {
  const VideoComparisonPlayer({
    super.key,
    required this.videoUrl,
    required this.showSkeletonOnly,
    required this.throwType,
    required this.cameraAngle,
    this.skeletonVideoUrl,
    this.skeletonOnlyVideoUrl,
    this.videoSyncMetadata,
    this.videoAspectRatio,
  });

  /// Network URL for the user's original form video
  final String videoUrl;

  /// URL for the skeleton overlay video (skeleton drawn on top of video)
  final String? skeletonVideoUrl;

  /// URL for the skeleton-only video (skeleton on black background)
  final String? skeletonOnlyVideoUrl;

  /// Whether to show skeleton-only view instead of skeleton overlay
  final bool showSkeletonOnly;

  /// Throw technique for selecting correct pro reference video
  final ThrowTechnique throwType;

  /// Camera angle for selecting correct pro reference video
  final CameraAngle cameraAngle;

  /// Video sync metadata for synchronization between user and pro videos
  final VideoSyncMetadata? videoSyncMetadata;

  /// Aspect ratio of user's video (width/height)
  final double? videoAspectRatio;

  @override
  Widget build(BuildContext context) {
    try {
      final String proVideoPath = getProReferenceVideoPath(
        throwType: throwType,
        cameraAngle: cameraAngle,
      );

      // Always pass the overlay URL as the primary user video
      final String userOverlayUrl = skeletonVideoUrl ?? videoUrl;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SynchronizedVideoPlayer(
          userVideoUrl: userOverlayUrl,
          userSkeletonOnlyVideoUrl: skeletonOnlyVideoUrl,
          showSkeletonOnly: showSkeletonOnly,
          proVideoAssetPath: proVideoPath,
          videoSyncMetadata: videoSyncMetadata,
          videoAspectRatio: videoAspectRatio,
        ),
      );
    } catch (e) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Video comparison not yet available for this throw type.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
