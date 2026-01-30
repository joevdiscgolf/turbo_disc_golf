import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

part 'deviation_analysis.g.dart';

/// Deviation analysis comparing user pose to pro reference
@JsonSerializable(explicitToJson: true)
class DeviationAnalysis {
  const DeviationAnalysis({
    required this.angleDeviations,
    required this.severity,
    this.individualDeviations,
    this.v2MeasurementDeviations,
  });

  /// Angle deviations from reference
  @JsonKey(name: 'angle_deviations')
  final AngleDeviations angleDeviations;

  /// Deviation severity: "good", "minor", "moderate", "significant"
  final String severity;

  /// Individual joint deviations (user - reference)
  @JsonKey(name: 'individual_deviations')
  final IndividualJointDeviations? individualDeviations;

  /// V2 side-view measurement deviations (user - reference)
  @JsonKey(name: 'v2_measurement_deviations')
  final V2SideMeasurements? v2MeasurementDeviations;

  factory DeviationAnalysis.fromJson(Map<String, dynamic> json) =>
      _$DeviationAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$DeviationAnalysisToJson(this);
}
