import 'package:json_annotation/json_annotation.dart';

part 'checkpoint_metadata.g.dart';

/// Checkpoint identification and timing information
@JsonSerializable(explicitToJson: true)
class CheckpointMetadata {
  const CheckpointMetadata({
    required this.checkpointId,
    required this.checkpointName,
    required this.frameNumber,
    required this.timestampSeconds,
    this.detectedFrameNumber,
  });

  /// Checkpoint identifier: "heisman", "loaded", "magic", "pro"
  @JsonKey(name: 'checkpoint_id')
  final String checkpointId;

  /// Display name: "Heisman Position", etc.
  @JsonKey(name: 'checkpoint_name')
  final String checkpointName;

  /// Frame number in the video
  @JsonKey(name: 'frame_number')
  final int frameNumber;

  /// Timestamp in seconds where this checkpoint occurs
  @JsonKey(name: 'timestamp_seconds')
  final double timestampSeconds;

  /// Frame number detected by the backend for this checkpoint
  @JsonKey(name: 'detected_frame_number')
  final int? detectedFrameNumber;

  factory CheckpointMetadata.fromJson(Map<String, dynamic> json) =>
      _$CheckpointMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$CheckpointMetadataToJson(this);
}
