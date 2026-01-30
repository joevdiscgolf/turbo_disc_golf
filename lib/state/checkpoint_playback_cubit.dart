import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_state.dart';

/// Cubit managing all checkpoint video playback logic.
///
/// Owns timers (playback simulation, auto-resume, tap feedback),
/// checkpoint detection, auto-pause, and speed control. The video
/// widget is a dumb platform bridge that listens and seeks its
/// controller when this cubit emits position changes.
class CheckpointPlaybackCubit extends Cubit<CheckpointPlaybackState> {
  CheckpointPlaybackCubit({
    required List<CheckpointDataV2> checkpoints,
    double initialSpeed = 0.25,
    int? totalFrames,
  }) : super(
         CheckpointPlaybackState.initial(
           checkpoints: checkpoints,
           initialSpeed: initialSpeed,
           totalFrames: totalFrames,
         ),
       );

  // ─────────────────────────────────────────────
  // Timers
  // ─────────────────────────────────────────────

  Timer? _playbackSimulationTimer;
  Timer? _autoResumeTimer;
  Timer? _tapFeedbackTimer;

  /// Indices of checkpoints already auto-paused at during this playback segment.
  final Set<int> _autoPausedCheckpointIndices = {};

  /// Tracks the last active checkpoint index during continuous playback.
  int? _lastActiveCheckpointIndex;

  // Frame interval for playback simulation (~30fps)
  static const Duration _playbackFrameInterval = Duration(milliseconds: 33);

  // ─────────────────────────────────────────────
  // Video lifecycle (called by CheckpointVideoDisplay)
  // ─────────────────────────────────────────────

  /// Called by the video widget after its controller initializes successfully.
  void onVideoInitialized(Duration videoDuration) {
    emit(
      state.copyWith(
        videoInitStatus: VideoInitStatus.initialized,
        videoDuration: videoDuration,
      ),
    );
  }

  /// Called by the video widget if initialization fails.
  void onVideoInitError(String message) {
    emit(
      state.copyWith(
        videoInitStatus: VideoInitStatus.error,
        errorMessage: message,
      ),
    );
  }

  /// Called after the video widget swaps between skeleton/overlay controllers.
  void onControllerSwapComplete(Duration newDuration) {
    emit(state.copyWith(videoDuration: newDuration));
  }

  // ─────────────────────────────────────────────
  // Play / Pause
  // ─────────────────────────────────────────────

  void togglePlayPause() {
    HapticFeedback.lightImpact();
    if (state.isPlaying) {
      _pause(cancelAutoResume: true);
    } else {
      _play();
    }
  }

  /// Handle tap on video - toggles play/pause and shows feedback animation.
  void onVideoTap() {
    HapticFeedback.lightImpact();
    final bool willPlay = !state.isPlaying;

    if (state.isPlaying) {
      _pause(cancelAutoResume: true);
    } else {
      _play();
    }

    // Show tap feedback animation
    _tapFeedbackTimer?.cancel();
    emit(state.copyWith(showTapFeedback: true, tapFeedbackIsPlay: willPlay));

    _tapFeedbackTimer = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed) {
        emit(state.copyWith(showTapFeedback: false));
      }
    });
  }

  void _play() {
    final bool isAtEnd = state.isAtEnd;
    final Duration startPosition = isAtEnd
        ? Duration.zero
        : state.currentPosition;

    // Reset auto-pause tracking and selection when starting from beginning
    if (isAtEnd) {
      _autoPausedCheckpointIndices.clear();
    }

    // Find and set initial active checkpoint for the starting position
    final int initialActiveIndex = _findActiveCheckpointIndex(startPosition);
    _lastActiveCheckpointIndex = initialActiveIndex;

    // If there's an active checkpoint at start position, show it selected
    if (initialActiveIndex >= 0) {
      emit(
        state.copyWith(
          currentPosition: startPosition,
          isPlaying: true,
          selectedCheckpointIndex: initialActiveIndex,
          lastSelectedCheckpointIndex: initialActiveIndex,
        ),
      );
    } else {
      emit(
        state.copyWith(
          currentPosition: startPosition,
          isPlaying: true,
          clearSelectedCheckpointIndex: true,
        ),
      );
    }

    _playbackSimulationTimer?.cancel();
    _playbackSimulationTimer = Timer.periodic(_playbackFrameInterval, (_) {
      if (!state.isPlaying || isClosed) {
        _playbackSimulationTimer?.cancel();
        return;
      }

      // Calculate next position based on playback speed
      final Duration nextPosition =
          state.currentPosition +
          Duration(
            milliseconds:
                (_playbackFrameInterval.inMilliseconds * state.playbackSpeed)
                    .round(),
          );

      // Check if reached end of video
      if (nextPosition >= state.videoDuration) {
        _pause();
        return;
      }

      // Check for auto-pause at checkpoints (unless in continuous mode)
      if (state.pauseMode != CheckpointPauseMode.continuous) {
        final int checkpointIndex = _findCheckpointAtPosition(nextPosition);
        if (checkpointIndex != -1 &&
            !_autoPausedCheckpointIndices.contains(checkpointIndex)) {
          _autoPausedCheckpointIndices.add(checkpointIndex);
          _autoPauseAtCheckpoint(checkpointIndex);
          return;
        }
      }

      // Check for active checkpoint change during playback
      final int activeIndex = _findActiveCheckpointIndex(nextPosition);
      if (activeIndex >= 0 && activeIndex != _lastActiveCheckpointIndex) {
        _lastActiveCheckpointIndex = activeIndex;
        emit(
          state.copyWith(
            currentPosition: nextPosition,
            selectedCheckpointIndex: activeIndex,
            lastSelectedCheckpointIndex: activeIndex,
          ),
        );
        return;
      }

      // Simply advance position if no checkpoint change
      emit(state.copyWith(currentPosition: nextPosition));
    });
  }

  void _pause({bool cancelAutoResume = false}) {
    _playbackSimulationTimer?.cancel();
    _playbackSimulationTimer = null;
    _lastActiveCheckpointIndex = null;

    if (cancelAutoResume) {
      _autoResumeTimer?.cancel();
      _autoResumeTimer = null;
    }

    emit(state.copyWith(isPlaying: false));

    debugPrint(
      '[CheckpointPlaybackCubit] Pause: ${(state.currentPosition.inMilliseconds / 1000.0).toStringAsFixed(2)}s',
    );
  }

  // ─────────────────────────────────────────────
  // Seeking
  // ─────────────────────────────────────────────

  /// Called from scrubber drag/tap with a normalized [0..1] value.
  void seek(double normalized) {
    final Duration position = Duration(
      milliseconds: (normalized * state.videoDuration.inMilliseconds).toInt(),
    );

    // Check if we're exactly on a checkpoint for UI selection
    final int exactCheckpointIndex = _findExactCheckpointAtPosition(position);

    if (exactCheckpointIndex != -1) {
      _autoPausedCheckpointIndices.add(exactCheckpointIndex);
      emit(
        state.copyWith(
          currentPosition: position,
          selectedCheckpointIndex: exactCheckpointIndex,
          lastSelectedCheckpointIndex: exactCheckpointIndex,
        ),
      );
    } else {
      _autoPausedCheckpointIndices.clear();
      emit(
        state.copyWith(
          currentPosition: position,
          clearSelectedCheckpointIndex: true,
          // Don't update lastSelectedCheckpointIndex - keep showing the last one
        ),
      );
    }
  }

  /// Called when user starts dragging the scrubber.
  void onScrubStart() {
    HapticFeedback.lightImpact();
    if (state.isPlaying) {
      _pause(cancelAutoResume: true);
    }
  }

  /// Jump to a specific checkpoint by index.
  void jumpToCheckpoint(int index) {
    if (!state.isInitialized) return;
    if (index < 0 || index >= state.checkpoints.length) return;

    final CheckpointDataV2 cp = state.checkpoints[index];

    HapticFeedback.selectionClick();

    final Duration position = Duration(
      milliseconds: (cp.metadata.timestampSeconds * 1000).ceil(),
    );

    _autoPausedCheckpointIndices.add(index);
    emit(
      state.copyWith(
        currentPosition: position,
        selectedCheckpointIndex: index,
        lastSelectedCheckpointIndex: index,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Speed / Pause mode
  // ─────────────────────────────────────────────

  void changePlaybackSpeed(double speed) {
    final bool wasPlaying = state.isPlaying;

    if (wasPlaying) {
      _pause();
    }

    HapticFeedback.selectionClick();
    emit(state.copyWith(playbackSpeed: speed));

    debugPrint('[CheckpointPlaybackCubit] Speed changed to ${speed}x');

    if (wasPlaying) {
      _play();
    }
  }

  void changePauseMode(CheckpointPauseMode mode) {
    HapticFeedback.selectionClick();
    _autoResumeTimer?.cancel();
    emit(state.copyWith(pauseMode: mode));
  }

  // ─────────────────────────────────────────────
  // Skeleton toggle
  // ─────────────────────────────────────────────

  void setShowSkeletonOnly(bool value) {
    if (state.isPlaying) {
      _pause(cancelAutoResume: true);
    }
    emit(state.copyWith(showSkeletonOnly: value));
  }

  // ─────────────────────────────────────────────
  // Checkpoint detection (private)
  // ─────────────────────────────────────────────

  /// Find the active checkpoint at position (the last checkpoint crossed).
  /// Returns -1 if position is before all checkpoints.
  int _findActiveCheckpointIndex(Duration position) {
    final double positionSeconds = position.inMilliseconds / 1000.0;
    int activeIndex = -1;

    for (int i = 0; i < state.checkpoints.length; i++) {
      final CheckpointDataV2 cp = state.checkpoints[i];
      if (cp.metadata.timestampSeconds <= positionSeconds) {
        activeIndex = i;
      }
    }
    return activeIndex;
  }

  /// Find checkpoint index at or very close to the given position.
  /// Returns -1 if no checkpoint found within threshold.
  int _findCheckpointAtPosition(Duration position) {
    const double thresholdSeconds = 0.05; // 50ms threshold
    final double positionSeconds = position.inMilliseconds / 1000.0;

    for (int i = 0; i < state.checkpoints.length; i++) {
      final CheckpointDataV2 cp = state.checkpoints[i];

      final double diff = (cp.metadata.timestampSeconds - positionSeconds)
          .abs();
      if (diff <= thresholdSeconds) {
        return i;
      }
    }
    return -1;
  }

  /// Cached derived frame rate from checkpoint data.
  double? _derivedFrameRate;

  /// Find checkpoint at EXACT position (strict threshold for UI selection).
  /// Uses frame-based comparison, deriving frame rate from checkpoint data if needed.
  int _findExactCheckpointAtPosition(Duration position) {
    if (state.videoDuration.inMilliseconds == 0) return -1;

    // Get or derive total frames
    int? totalFrames = state.totalFrames;

    // If we don't have totalFrames, try to derive frame rate from checkpoint data
    if (totalFrames == null && _derivedFrameRate == null) {
      for (final CheckpointDataV2 cp in state.checkpoints) {
        if (cp.metadata.detectedFrameNumber != null &&
            cp.metadata.timestampSeconds > 0) {
          _derivedFrameRate =
              cp.metadata.detectedFrameNumber! / cp.metadata.timestampSeconds;
          break;
        }
      }
    }

    // Calculate totalFrames from derived frame rate if needed
    if (totalFrames == null && _derivedFrameRate != null) {
      final double videoDurationSeconds =
          state.videoDuration.inMilliseconds / 1000.0;
      totalFrames = (_derivedFrameRate! * videoDurationSeconds).round();
    }

    // If we have total frames (provided or derived), use frame-based comparison
    if (totalFrames != null && totalFrames > 0) {
      final double progress =
          position.inMilliseconds / state.videoDuration.inMilliseconds;
      final int currentFrame = (progress * totalFrames).round();

      for (int i = 0; i < state.checkpoints.length; i++) {
        final CheckpointDataV2 cp = state.checkpoints[i];
        if (cp.metadata.detectedFrameNumber != null) {
          if (currentFrame == cp.metadata.detectedFrameNumber) {
            return i;
          }
        }
      }
      return -1;
    }

    const double thresholdSeconds = 0.001;
    final double positionSeconds = position.inMilliseconds / 1000.0;

    for (int i = 0; i < state.checkpoints.length; i++) {
      final CheckpointDataV2 cp = state.checkpoints[i];

      final double diff = (cp.metadata.timestampSeconds - positionSeconds)
          .abs();
      if (diff <= thresholdSeconds) {
        return i;
      }
    }
    return -1;
  }

  void _autoPauseAtCheckpoint(int checkpointIndex) {
    HapticFeedback.mediumImpact();
    final CheckpointDataV2 cp = state.checkpoints[checkpointIndex];

    debugPrint(
      '[CheckpointPlaybackCubit] Auto-pause at checkpoint: ${cp.metadata.checkpointName} (mode: ${state.pauseMode})',
    );

    // Seek to exact checkpoint position
    Duration exactPosition = state.currentPosition;

    exactPosition = Duration(
      milliseconds: (cp.metadata.timestampSeconds * 1000).ceil(),
    );

    _playbackSimulationTimer?.cancel();
    _playbackSimulationTimer = null;

    emit(
      state.copyWith(
        currentPosition: exactPosition,
        isPlaying: false,
        selectedCheckpointIndex: checkpointIndex,
        lastSelectedCheckpointIndex: checkpointIndex,
      ),
    );

    // If timed pause mode, auto-resume after 2 seconds
    if (state.pauseMode == CheckpointPauseMode.timedPause) {
      _autoResumeTimer?.cancel();
      _autoResumeTimer = Timer(const Duration(seconds: 2), () {
        if (!isClosed && !state.isPlaying) {
          debugPrint(
            '[CheckpointPlaybackCubit] Auto-resuming after 2s pause at ${cp.metadata.checkpointName}',
          );
          _play();
        }
      });
    }
  }

  // ─────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────

  @override
  Future<void> close() {
    _playbackSimulationTimer?.cancel();
    _autoResumeTimer?.cancel();
    _tapFeedbackTimer?.cancel();
    return super.close();
  }
}
