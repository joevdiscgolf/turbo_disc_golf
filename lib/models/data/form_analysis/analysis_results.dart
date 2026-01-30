import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/handedness.dart';

part 'analysis_results.g.dart';

Handedness? _handednessFromJson(String? value) => Handedness.fromApiString(value);

/// Overall analysis results
@JsonSerializable(explicitToJson: true)
class AnalysisResults {
  const AnalysisResults({
    this.overallFormScore,
    required this.throwType,
    required this.cameraAngle,
    this.detectedHandedness,
    this.worstDeviationSeverity,
    this.topCoachingTips,
  });

  /// Overall form score (0-100)
  @JsonKey(name: 'overall_form_score')
  final int? overallFormScore;

  /// Type of throw: "backhand" or "forehand"
  @JsonKey(name: 'throw_type')
  final String throwType;

  /// Camera angle: side or rear
  @JsonKey(name: 'camera_angle')
  final CameraAngle cameraAngle;

  /// Detected handedness: left or right
  @JsonKey(name: 'detected_handedness', fromJson: _handednessFromJson)
  final Handedness? detectedHandedness;

  /// Worst deviation severity across all checkpoints
  /// Values: "good", "minor", "moderate", "significant"
  @JsonKey(name: 'worst_deviation_severity')
  final String? worstDeviationSeverity;

  /// Top coaching tips aggregated from all checkpoints
  @JsonKey(name: 'top_coaching_tips')
  final List<String>? topCoachingTips;

  /// Create a copy with updated fields
  AnalysisResults copyWith({
    int? overallFormScore,
    String? throwType,
    CameraAngle? cameraAngle,
    Handedness? detectedHandedness,
    String? worstDeviationSeverity,
    List<String>? topCoachingTips,
  }) {
    return AnalysisResults(
      overallFormScore: overallFormScore ?? this.overallFormScore,
      throwType: throwType ?? this.throwType,
      cameraAngle: cameraAngle ?? this.cameraAngle,
      detectedHandedness: detectedHandedness ?? this.detectedHandedness,
      worstDeviationSeverity: worstDeviationSeverity ?? this.worstDeviationSeverity,
      topCoachingTips: topCoachingTips ?? this.topCoachingTips,
    );
  }

  factory AnalysisResults.fromJson(Map<String, dynamic> json) =>
      _$AnalysisResultsFromJson(json);
  Map<String, dynamic> toJson() => _$AnalysisResultsToJson(this);
}
