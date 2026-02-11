import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_coaching.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_measurement.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_timing.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_reference.dart';

part 'form_observation.g.dart';

/// A single form observation detected during analysis
@JsonSerializable(explicitToJson: true)
class FormObservation {
  const FormObservation({
    required this.observationId,
    required this.observationName,
    required this.category,
    required this.observationType,
    required this.severity,
    this.score,
    required this.confidence,
    required this.timing,
    this.measurement,
    required this.coaching,
    this.proReference,
  });

  /// Unique identifier for this observation
  @JsonKey(name: 'observation_id')
  final String observationId;

  /// Human-readable name for this observation
  @JsonKey(name: 'observation_name')
  final String observationName;

  /// Category of the observation (footwork, arm mechanics, etc.)
  final ObservationCategory category;

  /// Type of observation (positive, negative, neutral)
  @JsonKey(name: 'observation_type')
  final ObservationType observationType;

  /// Severity level (none, minor, moderate, significant)
  final ObservationSeverity severity;

  /// Score from 0.0 to 1.0 (1 = best performance)
  final double? score;

  /// Confidence score from 0.0 to 1.0
  final double confidence;

  /// Timing information including optional video segment
  final ObservationTiming timing;

  /// Optional quantitative measurement data
  final ObservationMeasurement? measurement;

  /// Coaching content for this observation
  final ObservationCoaching coaching;

  /// Optional pro reference for comparison
  /// Contains pro image/video URLs from Cloud Storage
  @JsonKey(name: 'pro_reference')
  final ProReference? proReference;

  /// Whether this observation has a severe severity level
  bool get isSevere => severity.isSevere;

  /// Whether this observation has a video segment to loop
  bool get hasVideoSegment => timing.hasSegment;

  /// Whether this observation has pro comparison data
  bool get hasProComparison => proReference != null;

  factory FormObservation.fromJson(Map<String, dynamic> json) =>
      _$FormObservationFromJson(json);
  Map<String, dynamic> toJson() => _$FormObservationToJson(this);
}
