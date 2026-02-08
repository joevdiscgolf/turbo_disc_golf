import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';

part 'observation_timing.g.dart';

/// Timing information for an observation, including optional video segment
@JsonSerializable()
class ObservationTiming {
  const ObservationTiming({
    this.displayMode = ObservationDisplayMode.singleFrame,
    required this.frameNumber,
    required this.timestampSeconds,
    this.startFrame,
    this.endFrame,
    this.startTimestampSeconds,
    this.endTimestampSeconds,
    this.durationMs,
  });

  /// How to display this observation (single frame or frame range)
  @JsonKey(name: 'display_mode')
  final ObservationDisplayMode displayMode;

  /// Primary frame number where this observation occurs
  @JsonKey(name: 'frame_number')
  final int frameNumber;

  /// Timestamp in seconds for this observation
  @JsonKey(name: 'timestamp_seconds')
  final double timestampSeconds;

  /// Optional start frame for video segment (frame_range mode)
  @JsonKey(name: 'start_frame')
  final int? startFrame;

  /// Optional end frame for video segment (frame_range mode)
  @JsonKey(name: 'end_frame')
  final int? endFrame;

  /// Optional start timestamp in seconds (frame_range mode)
  @JsonKey(name: 'start_timestamp_seconds')
  final double? startTimestampSeconds;

  /// Optional end timestamp in seconds (frame_range mode)
  @JsonKey(name: 'end_timestamp_seconds')
  final double? endTimestampSeconds;

  /// Duration of the segment in milliseconds
  @JsonKey(name: 'duration_ms')
  final int? durationMs;

  /// Whether this observation has a video segment to loop
  bool get hasSegment => startFrame != null && endFrame != null;

  /// Whether this is a frame range display mode
  bool get isFrameRange => displayMode == ObservationDisplayMode.frameRange;

  factory ObservationTiming.fromJson(Map<String, dynamic> json) =>
      _$ObservationTimingFromJson(json);
  Map<String, dynamic> toJson() => _$ObservationTimingToJson(this);
}
