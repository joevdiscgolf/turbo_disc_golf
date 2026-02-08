import 'package:json_annotation/json_annotation.dart';

part 'pro_reference.g.dart';

/// Pro comparison reference data for an observation
/// Images/videos are stored in Cloud Storage and URLs are provided by the backend
@JsonSerializable()
class ProReference {
  const ProReference({
    required this.proName,
    this.proImageUrl,
    this.proVideoUrl,
    this.proVideoStartSeconds,
    this.proVideoEndSeconds,
    this.proMeasurement,
    this.comparisonNote,
  });

  /// Name of the pro player (e.g., "Simon Lizotte")
  @JsonKey(name: 'pro_name')
  final String proName;

  /// URL to pro's image at this checkpoint (from Cloud Storage)
  /// Example: https://storage.googleapis.com/.../simon_lizotte/backhand/rear/reachback.jpg
  @JsonKey(name: 'pro_image_url')
  final String? proImageUrl;

  /// URL to pro's video clip for this observation (from Cloud Storage)
  @JsonKey(name: 'pro_video_url')
  final String? proVideoUrl;

  /// Start timestamp for pro video segment
  @JsonKey(name: 'pro_video_start_seconds')
  final double? proVideoStartSeconds;

  /// End timestamp for pro video segment
  @JsonKey(name: 'pro_video_end_seconds')
  final double? proVideoEndSeconds;

  /// Pro's measurement at the same moment
  @JsonKey(name: 'pro_measurement')
  final ProMeasurement? proMeasurement;

  /// Comparison note explaining the difference
  /// Example: "Simon's arm reaches back 25ms AFTER plant"
  @JsonKey(name: 'comparison_note')
  final String? comparisonNote;

  /// Whether this reference has an image
  bool get hasImage => proImageUrl != null;

  /// Whether this reference has a video
  bool get hasVideo => proVideoUrl != null;

  /// Whether this reference has any visual content
  bool get hasVisualContent => hasImage || hasVideo;

  factory ProReference.fromJson(Map<String, dynamic> json) =>
      _$ProReferenceFromJson(json);
  Map<String, dynamic> toJson() => _$ProReferenceToJson(this);
}

/// Pro's measurement value for comparison
@JsonSerializable()
class ProMeasurement {
  const ProMeasurement({
    required this.value,
    required this.unit,
  });

  /// The measurement value
  final double value;

  /// Unit of measurement (e.g., "degrees", "milliseconds")
  final String unit;

  /// Formatted string showing value with unit
  String get formatted => '${value.toStringAsFixed(1)}$unit';

  factory ProMeasurement.fromJson(Map<String, dynamic> json) =>
      _$ProMeasurementFromJson(json);
  Map<String, dynamic> toJson() => _$ProMeasurementToJson(this);
}
