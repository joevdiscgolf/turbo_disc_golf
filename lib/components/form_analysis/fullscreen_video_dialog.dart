import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_playback_controls.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_selector.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_timeline_scrubber.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/video_orientation.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_cubit.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_state.dart';
import 'package:turbo_disc_golf/utils/checkpoint_helpers.dart';
import 'package:video_player/video_player.dart';

/// Fullscreen video dialog that displays the user's video with playback controls.
class FullscreenVideoDialog extends StatefulWidget {
  const FullscreenVideoDialog({
    super.key,
    required this.videoController,
    this.videoOrientation,
    this.checkpoints,
  });

  final VideoPlayerController videoController;
  final VideoOrientation? videoOrientation;
  final List<CheckpointRecord>? checkpoints;

  @override
  State<FullscreenVideoDialog> createState() => _FullscreenVideoDialogState();
}

class _FullscreenVideoDialogState extends State<FullscreenVideoDialog> {
  @override
  void initState() {
    super.initState();
    // Set orientation based on video orientation
    final bool isPortrait =
        widget.videoOrientation == VideoOrientation.portrait;
    if (isPortrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore orientation settings
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CheckpointPlaybackCubit cubit =
        BlocProvider.of<CheckpointPlaybackCubit>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<CheckpointPlaybackCubit, CheckpointPlaybackState>(
        builder: (context, state) {
          final bool showPlayOverlay =
              !state.isPlaying && state.isAtStart && !state.showTapFeedback;
          final bool showReplayOverlay =
              !state.isPlaying && state.isAtEnd && !state.showTapFeedback;
          final bool showPersistentOverlay =
              showPlayOverlay || showReplayOverlay;

          return GestureDetector(
            onTap: cubit.onVideoTap,
            child: Stack(
              children: [
                // Video player centered
                Center(
                  child: AspectRatio(
                    aspectRatio: widget.videoController.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(widget.videoController),
                        // Persistent play/replay overlay
                        if (showPersistentOverlay)
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              showReplayOverlay ? Icons.replay : Icons.play_arrow,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        // Tap feedback animation
                        if (state.showTapFeedback)
                          Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  state.tapFeedbackIsPlay
                                      ? Icons.play_arrow
                                      : Icons.pause,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              )
                              .animate()
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.2, 1.2),
                                duration: 200.ms,
                                curve: Curves.easeOut,
                              )
                              .fadeOut(
                                delay: 100.ms,
                                duration: 200.ms,
                                curve: Curves.easeOut,
                              ),
                      ],
                    ),
                  ),
                ),
                // Close button at top right (above checkpoint selector)
                Positioned(
                  top: 8,
                  right: 8,
                  child: SafeArea(
                    bottom: false,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                // Checkpoint selector below close button
                if (widget.checkpoints != null &&
                    widget.checkpoints!.isNotEmpty)
                  Positioned(
                    top: 120,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        child: CheckpointSelector(
                          items: widget.checkpoints!
                              .map(
                                (cp) => CheckpointSelectorItem(
                                  id: cp.checkpointId,
                                  label: cp.checkpointName,
                                ),
                              )
                              .toList(),
                          selectedIndex: state.selectedCheckpointIndex,
                          onChanged: (index) => cubit.jumpToCheckpoint(index),
                          formatLabel: formatCheckpointChipLabel,
                        ),
                      ),
                    ),
                  ),
                // Controls at bottom with semi-transparent background
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CheckpointTimelineScrubber(),
                          const SizedBox(height: 12),
                          const CheckpointPlaybackControls(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
