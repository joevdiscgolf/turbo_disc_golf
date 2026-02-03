import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/form_analysis/pill_button_group.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_cubit.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Playback controls: play/pause button, pause mode pills, speed pills.
///
/// Rebuilds infrequently — only on user interaction (play/pause, speed, mode).
class CheckpointPlaybackControls extends StatelessWidget {
  const CheckpointPlaybackControls({super.key, this.hideBorder = false});

  final bool hideBorder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckpointPlaybackCubit, CheckpointPlaybackState>(
      buildWhen: (prev, curr) =>
          prev.isPlaying != curr.isPlaying ||
          prev.isAtEnd != curr.isAtEnd ||
          prev.playbackSpeed != curr.playbackSpeed ||
          prev.pauseMode != curr.pauseMode,
      builder: (context, state) {
        return _buildControlsRow(context, state);
      },
    );
  }

  Widget _buildControlsRow(
    BuildContext context,
    CheckpointPlaybackState state,
  ) {
    const double controlHeight = 36.0;

    final CheckpointPlaybackCubit cubit =
        BlocProvider.of<CheckpointPlaybackCubit>(context);

    return Row(
      children: [
        // Play/pause button
        Container(
          width: controlHeight,
          height: controlHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SenseiColors.cleanAccentColor,
                SenseiColors.cleanAccentColorDark,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: defaultCardBoxShadow(),
          ),
          child: IconButton(
            onPressed: cubit.togglePlayPause,
            icon: Icon(
              state.isPlaying
                  ? Icons.pause
                  : (state.isAtEnd ? Icons.replay : Icons.play_arrow),
              color: Colors.white,
            ),
            iconSize: 22,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 12),
        // Pause mode pills
        Expanded(
          child: PillButtonGroup(
            height: controlHeight,
            isDark: false,
            hideBorder: hideBorder,
            buttons: [
              PillButtonData(
                label: '2s',
                isSelected:
                    state.pauseMode == CheckpointPauseMode.timedPause,
                onTap: () =>
                    cubit.changePauseMode(CheckpointPauseMode.timedPause),
              ),
              PillButtonData(
                label: 'Hold',
                isSelected:
                    state.pauseMode == CheckpointPauseMode.pauseIndefinitely,
                onTap: () => cubit
                    .changePauseMode(CheckpointPauseMode.pauseIndefinitely),
              ),
              PillButtonData(
                label: 'None',
                isSelected:
                    state.pauseMode == CheckpointPauseMode.continuous,
                onTap: () =>
                    cubit.changePauseMode(CheckpointPauseMode.continuous),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Speed pills
        Expanded(
          child: PillButtonGroup(
            height: controlHeight,
            isDark: false,
            hideBorder: hideBorder,
            buttons: [
              PillButtonData(
                label: '0.25',
                isSelected: state.playbackSpeed == 0.25,
                onTap: () => cubit.changePlaybackSpeed(0.25),
              ),
              PillButtonData(
                label: '0.5',
                isSelected: state.playbackSpeed == 0.5,
                onTap: () => cubit.changePlaybackSpeed(0.5),
              ),
              PillButtonData(
                label: '1x',
                isSelected: state.playbackSpeed == 1.0,
                onTap: () => cubit.changePlaybackSpeed(1.0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
