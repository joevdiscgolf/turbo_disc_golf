import 'package:equatable/equatable.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';

/// Playback mode for checkpoint auto-pause behavior.
enum CheckpointPauseMode {
  /// Pause for 2 seconds at each checkpoint, then auto-resume
  timedPause,

  /// Pause indefinitely at each checkpoint until user resumes
  pauseIndefinitely,

  /// Play through without pausing at checkpoints
  continuous,
}

/// Video initialization status.
enum VideoInitStatus {
  uninitialized,
  initializing,
  initialized,
  error,
}

/// State for the checkpoint playback cubit.
///
/// Single concrete state class with [copyWith] for immutable updates.
/// All widgets in the checkpoint player tree select from this state.
class CheckpointPlaybackState extends Equatable {
  const CheckpointPlaybackState({
    required this.currentPosition,
    required this.videoDuration,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.pauseMode,
    required this.selectedCheckpointIndex,
    required this.lastSelectedCheckpointIndex,
    required this.showSkeletonOnly,
    required this.videoInitStatus,
    required this.checkpoints,
    required this.showTapFeedback,
    required this.tapFeedbackIsPlay,
    this.totalFrames,
    this.errorMessage,
  });

  // ─────────────────────────────────────────────
  // Initial
  // ─────────────────────────────────────────────

  factory CheckpointPlaybackState.initial({
    List<CheckpointRecord> checkpoints = const [],
    double initialSpeed = 0.25,
    int? totalFrames,
  }) {
    return CheckpointPlaybackState(
      currentPosition: Duration.zero,
      videoDuration: Duration.zero,
      isPlaying: false,
      playbackSpeed: initialSpeed,
      pauseMode: CheckpointPauseMode.timedPause,
      selectedCheckpointIndex: null,
      lastSelectedCheckpointIndex: null,
      showSkeletonOnly: false,
      videoInitStatus: VideoInitStatus.uninitialized,
      checkpoints: checkpoints,
      showTapFeedback: false,
      tapFeedbackIsPlay: true,
      totalFrames: totalFrames,
    );
  }

  // ─────────────────────────────────────────────
  // Core fields
  // ─────────────────────────────────────────────

  final Duration currentPosition;
  final Duration videoDuration;
  final bool isPlaying;
  final double playbackSpeed;
  final CheckpointPauseMode pauseMode;
  final int? selectedCheckpointIndex;
  final int? lastSelectedCheckpointIndex;
  final bool showSkeletonOnly;
  final VideoInitStatus videoInitStatus;
  final List<CheckpointRecord> checkpoints;
  final bool showTapFeedback;
  final bool tapFeedbackIsPlay;
  final int? totalFrames;
  final String? errorMessage;

  // ─────────────────────────────────────────────
  // Derived
  // ─────────────────────────────────────────────

  /// Threshold for detecting end of video.
  static const Duration _endThreshold = Duration(milliseconds: 100);

  bool get isAtEnd =>
      videoDuration > Duration.zero &&
      currentPosition >= videoDuration - _endThreshold;

  bool get isAtStart => currentPosition <= const Duration(milliseconds: 100);

  bool get isInitialized => videoInitStatus == VideoInitStatus.initialized;

  bool get hasError => videoInitStatus == VideoInitStatus.error;

  double get progress => videoDuration.inMilliseconds > 0
      ? (currentPosition.inMilliseconds / videoDuration.inMilliseconds)
          .clamp(0.0, 1.0)
      : 0.0;

  // ─────────────────────────────────────────────
  // Copy
  // ─────────────────────────────────────────────

  CheckpointPlaybackState copyWith({
    Duration? currentPosition,
    Duration? videoDuration,
    bool? isPlaying,
    double? playbackSpeed,
    CheckpointPauseMode? pauseMode,
    int? selectedCheckpointIndex,
    bool clearSelectedCheckpointIndex = false,
    int? lastSelectedCheckpointIndex,
    bool? showSkeletonOnly,
    VideoInitStatus? videoInitStatus,
    List<CheckpointRecord>? checkpoints,
    bool? showTapFeedback,
    bool? tapFeedbackIsPlay,
    int? totalFrames,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CheckpointPlaybackState(
      currentPosition: currentPosition ?? this.currentPosition,
      videoDuration: videoDuration ?? this.videoDuration,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      pauseMode: pauseMode ?? this.pauseMode,
      selectedCheckpointIndex: clearSelectedCheckpointIndex
          ? null
          : (selectedCheckpointIndex ?? this.selectedCheckpointIndex),
      lastSelectedCheckpointIndex:
          lastSelectedCheckpointIndex ?? this.lastSelectedCheckpointIndex,
      showSkeletonOnly: showSkeletonOnly ?? this.showSkeletonOnly,
      videoInitStatus: videoInitStatus ?? this.videoInitStatus,
      checkpoints: checkpoints ?? this.checkpoints,
      showTapFeedback: showTapFeedback ?? this.showTapFeedback,
      tapFeedbackIsPlay: tapFeedbackIsPlay ?? this.tapFeedbackIsPlay,
      totalFrames: totalFrames ?? this.totalFrames,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        currentPosition,
        videoDuration,
        isPlaying,
        playbackSpeed,
        pauseMode,
        selectedCheckpointIndex,
        lastSelectedCheckpointIndex,
        showSkeletonOnly,
        videoInitStatus,
        checkpoints,
        showTapFeedback,
        tapFeedbackIsPlay,
        totalFrames,
        errorMessage,
      ];
}
