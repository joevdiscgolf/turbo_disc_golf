import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_cubit.dart';
import 'package:turbo_disc_golf/state/checkpoint_playback_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Timeline scrubber with checkpoint markers for form analysis video.
///
/// This is the ONLY widget that rebuilds at ~30fps (tracking position).
/// All other widgets in the player tree rebuild only on user interaction.
///
/// PERFORMANCE: Uses StatefulWidget to cache sorted checkpoint list,
/// avoiding O(n log n) sort operation every frame during playback.
class CheckpointTimelineScrubber extends StatefulWidget {
  const CheckpointTimelineScrubber({
    super.key,
    this.useWhiteMarkers = false,
    this.height = 48,
  });

  final bool useWhiteMarkers;
  final double height;

  @override
  State<CheckpointTimelineScrubber> createState() =>
      _CheckpointTimelineScrubberState();
}

class _CheckpointTimelineScrubberState extends State<CheckpointTimelineScrubber> {
  // Clean Sport Minimal colors
  static const Color _cleanTrackInactive = Color(0xFFE2E8F0);
  static const Color _cleanAccentColor = Color(0xFF3B82F6);
  static const Color _cleanAccentColorDark = Color(0xFF2563EB);
  static const Color _cleanTextColor = Color(0xFF1E293B);

  // Cached sorted checkpoints to avoid sorting every frame
  List<MapEntry<int, CheckpointDataV2>>? _cachedSortedCheckpoints;
  List<CheckpointDataV2>? _lastCheckpoints;

  /// Returns checkpoints sorted by z-index (H lowest, P on top).
  /// Caches result to avoid sorting on every frame during playback.
  List<MapEntry<int, CheckpointDataV2>> _getSortedCheckpoints(
    List<CheckpointDataV2> checkpoints,
  ) {
    // Only recompute if checkpoints list changed
    if (_cachedSortedCheckpoints != null && identical(_lastCheckpoints, checkpoints)) {
      return _cachedSortedCheckpoints!;
    }

    _lastCheckpoints = checkpoints;
    final List<MapEntry<int, CheckpointDataV2>> entries = checkpoints
        .asMap()
        .entries
        .toList();
    entries.sort((a, b) {
      final int zIndexA = _getCheckpointZIndex(a.value.metadata.checkpointId);
      final int zIndexB = _getCheckpointZIndex(b.value.metadata.checkpointId);
      return zIndexA.compareTo(zIndexB);
    });
    _cachedSortedCheckpoints = entries;
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckpointPlaybackCubit, CheckpointPlaybackState>(
      buildWhen: (prev, curr) =>
          prev.currentPosition != curr.currentPosition ||
          prev.videoDuration != curr.videoDuration ||
          prev.videoInitStatus != curr.videoInitStatus ||
          prev.checkpoints != curr.checkpoints,
      builder: (context, state) {
        return _buildTimeline(context, state);
      },
    );
  }

  Widget _buildTimeline(BuildContext context, CheckpointPlaybackState state) {
    const double thumbRadius = 8;

    final CheckpointPlaybackCubit cubit =
        BlocProvider.of<CheckpointPlaybackCubit>(context);

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double trackWidth = constraints.maxWidth - (thumbRadius * 2);
          final double progress = state.progress;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: thumbRadius),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final double tapPosition =
                    details.localPosition.dx / trackWidth;
                cubit.seek(tapPosition.clamp(0.0, 1.0));
              },
              onHorizontalDragStart: (_) => cubit.onScrubStart(),
              onHorizontalDragUpdate: (details) {
                final double tapPosition =
                    details.localPosition.dx / trackWidth;
                cubit.seek(tapPosition.clamp(0.0, 1.0));
              },
              child: SizedBox(
                height: widget.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Track background
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: _cleanTrackInactive,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    // Active track with gradient
                    Positioned(
                      left: 0,
                      child: Container(
                        height: 2,
                        width: trackWidth * progress,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_cleanAccentColor, _cleanAccentColorDark],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    // Checkpoint tick marks (using cached sorted list)
                    if (state.isInitialized)
                      ..._getSortedCheckpoints(state.checkpoints).map((entry) {
                        final int index = entry.key;
                        final CheckpointDataV2 cp = entry.value;

                        return _buildCleanSportTickMark(
                          context,
                          index,
                          cp,
                          trackWidth: trackWidth,
                          videoDurationMs: state.videoDuration.inMilliseconds,
                          useWhiteMarkers: widget.useWhiteMarkers,
                        );
                      }),
                    // Thumb with gradient
                    Positioned(
                      left: trackWidth * progress - thumbRadius,
                      child: Container(
                        width: thumbRadius * 2,
                        height: thumbRadius * 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_cleanAccentColor, _cleanAccentColorDark],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _cleanAccentColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCleanSportTickMark(
    BuildContext context,
    int index,
    CheckpointDataV2 cp, {
    required double trackWidth,
    required int videoDurationMs,
    required bool useWhiteMarkers,
  }) {
    final double videoDurationSecs = videoDurationMs / 1000.0;
    final double position = videoDurationSecs > 0
        ? cp.metadata.timestampSeconds / videoDurationSecs
        : 0.0;
    final String label = _getCheckpointLabel(cp.metadata.checkpointId);
    final double markerX = trackWidth * position;

    const double tickTapWidth = 32;
    const double dotSize = 6;

    final CheckpointPlaybackCubit cubit =
        BlocProvider.of<CheckpointPlaybackCubit>(context);

    return Positioned(
      left: markerX - (tickTapWidth / 2),
      top: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => cubit.jumpToCheckpoint(index),
        child: SizedBox(
          width: tickTapWidth,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: useWhiteMarkers
                      ? Colors.white.withValues(alpha: 0.7)
                      : SenseiColors.gray[400]!,
                  shape: BoxShape.circle,
                ),
              ),
              Positioned(
                top: 20 + (dotSize / 2) + 8,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: useWhiteMarkers
                        ? Colors.white.withValues(alpha: 0.8)
                        : _cleanTextColor.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCheckpointLabel(String checkpointId) {
    switch (checkpointId) {
      case 'heisman':
        return 'H';
      case 'loaded':
        return 'L';
      case 'magic':
        return 'M';
      case 'pro':
        return 'P';
      default:
        return checkpointId.substring(0, 1).toUpperCase();
    }
  }

  int _getCheckpointZIndex(String checkpointId) {
    switch (checkpointId) {
      case 'heisman':
        return 0;
      case 'loaded':
        return 1;
      case 'magic':
        return 2;
      case 'pro':
        return 3;
      default:
        return 0;
    }
  }
}
