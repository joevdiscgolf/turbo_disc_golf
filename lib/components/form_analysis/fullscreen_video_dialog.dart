import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_playback_controls.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_selector.dart';
import 'package:turbo_disc_golf/components/form_analysis/checkpoint_timeline_scrubber.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/models/video_orientation.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_cubit.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_state.dart';
import 'package:turbo_disc_golf/utils/checkpoint_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';
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
  final List<CheckpointDataV2>? checkpoints;

  @override
  State<FullscreenVideoDialog> createState() => _FullscreenVideoDialogState();
}

class _FullscreenVideoDialogState extends State<FullscreenVideoDialog> {
  bool _showControls = false;

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
    // Force portrait orientation when dialog closes
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
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
                              showReplayOverlay
                                  ? Icons.replay
                                  : Icons.play_arrow,
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
                // Top row with checkpoint selector and buttons
                if (widget.checkpoints != null &&
                    widget.checkpoints!.isNotEmpty)
                  Positioned(
                    top: MediaQuery.of(context).viewPadding.top,
                    left: 0,
                    right: 8,
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: SizedBox(
                        height: 40,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _showControls
                                  ? CheckpointSelector(
                                      items: widget.checkpoints!
                                          .map(
                                            (cp) => CheckpointSelectorItem(
                                              id: cp.metadata.checkpointId,
                                              label: cp.metadata.checkpointName,
                                            ),
                                          )
                                          .toList(),
                                      selectedIndex:
                                          state.selectedCheckpointIndex ?? -1,
                                      onChanged: (index) =>
                                          cubit.jumpToCheckpoint(index),
                                      formatLabel: formatCheckpointChipLabel,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _showControls = !_showControls);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _showControls
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.tune,
                                  color: Colors.black,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.black,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Controls at bottom with blur and semi-transparent background
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: autoBottomPadding(context),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CheckpointTimelineScrubber(
                              useWhiteMarkers: true,
                              height: 32,
                            ),
                            if (_showControls) ...[
                              const SizedBox(height: 32),
                              const CheckpointPlaybackControls(
                                hideBorder: true,
                              ),
                            ],
                          ],
                        ),
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
