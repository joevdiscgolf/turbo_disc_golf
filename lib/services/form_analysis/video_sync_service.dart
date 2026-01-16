import 'package:turbo_disc_golf/models/data/form_analysis/video_sync_metadata.dart';

/// Service for calculating synchronized video positions based on checkpoint metadata
class VideoSyncService {
  final VideoSyncMetadata syncMetadata;

  VideoSyncService(this.syncMetadata);

  /// Calculate pro video position for a given user video position
  Duration calculateProPosition(Duration userPosition) {
    switch (syncMetadata.syncStrategy) {
      case 'checkpoint_warp':
        return _multiPointSync(userPosition);
      case 'single_point':
        return _singlePointSync(userPosition);
      case 'linear':
      default:
        return _linearSync(userPosition);
    }
  }

  /// Single-point sync: Anchor at disc release checkpoint
  ///
  /// Uses the "pro" checkpoint (disc release) as the single alignment point.
  /// All other moments are offset by the same amount.
  Duration _singlePointSync(Duration userPosition) {
    // Find the "pro" checkpoint (disc release)
    final releaseSync = syncMetadata.checkpointSyncPoints.firstWhere(
      (cp) => cp.checkpointId == 'pro',
      orElse: () => syncMetadata.checkpointSyncPoints.first,
    );

    final userSeconds = userPosition.inMilliseconds / 1000.0;
    final offset = releaseSync.proTimestamp - releaseSync.userTimestamp;
    final proSeconds = userSeconds + offset;

    // Clamp to valid range
    final clampedSeconds = proSeconds.clamp(0.0, syncMetadata.proVideoDuration);
    return Duration(milliseconds: (clampedSeconds * 1000).toInt());
  }

  /// Multi-point sync: Interpolate between checkpoint pairs
  ///
  /// Finds the segment containing the current user time and interpolates
  /// linearly between the checkpoint pair to calculate the pro time.
  /// This allows for time-warping between checkpoints to maintain alignment.
  Duration _multiPointSync(Duration userPosition) {
    final userSeconds = userPosition.inMilliseconds / 1000.0;

    // Sort checkpoints by user timestamp
    final sortedPoints = List<CheckpointSyncPoint>.from(
      syncMetadata.checkpointSyncPoints,
    )..sort((a, b) => a.userTimestamp.compareTo(b.userTimestamp));

    // Handle edge cases
    if (sortedPoints.isEmpty) {
      return _linearSync(userPosition);
    }

    // Before first checkpoint: extrapolate backward
    if (userSeconds < sortedPoints.first.userTimestamp) {
      if (sortedPoints.length < 2) {
        return _linearSync(userPosition);
      }

      final cp1 = sortedPoints[0];
      final cp2 = sortedPoints[1];
      final proSeconds = _extrapolate(
        userSeconds,
        cp1.userTimestamp,
        cp2.userTimestamp,
        cp1.proTimestamp,
        cp2.proTimestamp,
      );

      final clampedSeconds = proSeconds.clamp(0.0, syncMetadata.proVideoDuration);
      return Duration(milliseconds: (clampedSeconds * 1000).toInt());
    }

    // After last checkpoint: extrapolate forward
    if (userSeconds > sortedPoints.last.userTimestamp) {
      if (sortedPoints.length < 2) {
        return _linearSync(userPosition);
      }

      final cp1 = sortedPoints[sortedPoints.length - 2];
      final cp2 = sortedPoints[sortedPoints.length - 1];
      final proSeconds = _extrapolate(
        userSeconds,
        cp1.userTimestamp,
        cp2.userTimestamp,
        cp1.proTimestamp,
        cp2.proTimestamp,
      );

      final clampedSeconds = proSeconds.clamp(0.0, syncMetadata.proVideoDuration);
      return Duration(milliseconds: (clampedSeconds * 1000).toInt());
    }

    // Find segment containing current user time
    for (int i = 0; i < sortedPoints.length - 1; i++) {
      final cp1 = sortedPoints[i];
      final cp2 = sortedPoints[i + 1];

      if (userSeconds >= cp1.userTimestamp && userSeconds <= cp2.userTimestamp) {
        // Interpolate within segment
        final progress = (userSeconds - cp1.userTimestamp) /
            (cp2.userTimestamp - cp1.userTimestamp);
        final proSeconds = cp1.proTimestamp +
            progress * (cp2.proTimestamp - cp1.proTimestamp);

        final clampedSeconds = proSeconds.clamp(0.0, syncMetadata.proVideoDuration);
        return Duration(milliseconds: (clampedSeconds * 1000).toInt());
      }
    }

    // Fallback (should not reach here)
    return _linearSync(userPosition);
  }

  /// Linear sync: Simple ratio-based synchronization
  ///
  /// Uses the time compression ratio to scale user time to pro time.
  /// No checkpoint alignment, just proportional playback.
  Duration _linearSync(Duration userPosition) {
    final userSeconds = userPosition.inMilliseconds / 1000.0;
    final proSeconds = userSeconds * syncMetadata.timeCompressionRatio;
    final clampedSeconds = proSeconds.clamp(0.0, syncMetadata.proVideoDuration);
    return Duration(milliseconds: (clampedSeconds * 1000).toInt());
  }

  /// Extrapolate a point outside the checkpoint range
  ///
  /// Uses the slope defined by two checkpoint pairs to extend the mapping
  /// beyond the checkpoint boundaries.
  double _extrapolate(
    double userTime,
    double user1,
    double user2,
    double pro1,
    double pro2,
  ) {
    final slope = (pro2 - pro1) / (user2 - user1);
    return pro1 + slope * (userTime - user1);
  }

  /// Get the checkpoint that the user position is closest to
  ///
  /// Useful for UI indicators showing which checkpoint is currently active.
  CheckpointSyncPoint? getClosestCheckpoint(Duration userPosition) {
    final userSeconds = userPosition.inMilliseconds / 1000.0;

    if (syncMetadata.checkpointSyncPoints.isEmpty) {
      return null;
    }

    CheckpointSyncPoint? closest;
    double minDistance = double.infinity;

    for (final checkpoint in syncMetadata.checkpointSyncPoints) {
      final distance = (checkpoint.userTimestamp - userSeconds).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closest = checkpoint;
      }
    }

    return closest;
  }

  /// Check if the current position is within threshold of a checkpoint
  ///
  /// Returns true if within 0.5 seconds of any checkpoint.
  bool isNearCheckpoint(Duration userPosition, {double thresholdSeconds = 0.5}) {
    final userSeconds = userPosition.inMilliseconds / 1000.0;

    return syncMetadata.checkpointSyncPoints.any((checkpoint) {
      final distance = (checkpoint.userTimestamp - userSeconds).abs();
      return distance <= thresholdSeconds;
    });
  }
}
