import 'package:json_annotation/json_annotation.dart';

part 'analysis_warning.g.dart';

/// Type of analysis warning
@JsonEnum(valueField: 'value')
enum WarningType {
  /// Camera is too shaky
  @JsonValue('camera_stability')
  cameraStability('camera_stability'),

  /// Pose detection is jumpy/unreliable
  @JsonValue('pose_stability')
  poseStability('pose_stability'),

  /// Key landmarks not visible
  @JsonValue('low_visibility')
  lowVisibility('low_visibility'),

  /// Video too short for full analysis
  @JsonValue('short_video')
  shortVideo('short_video'),

  /// Consider using different model
  @JsonValue('model_recommendation')
  modelRecommendation('model_recommendation');

  const WarningType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case WarningType.cameraStability:
        return 'Camera stability';
      case WarningType.poseStability:
        return 'Pose stability';
      case WarningType.lowVisibility:
        return 'Low visibility';
      case WarningType.shortVideo:
        return 'Short video';
      case WarningType.modelRecommendation:
        return 'Model recommendation';
    }
  }
}

/// Severity level for warnings
@JsonEnum(valueField: 'value')
enum WarningSeverity {
  /// Informational, may not affect results
  @JsonValue('info')
  info('info'),

  /// May affect accuracy, consider re-recording
  @JsonValue('warning')
  warning('warning'),

  /// Significantly affects accuracy, strongly recommend re-analysis
  @JsonValue('critical')
  critical('critical');

  const WarningSeverity(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case WarningSeverity.info:
        return 'Info';
      case WarningSeverity.warning:
        return 'Warning';
      case WarningSeverity.critical:
        return 'Critical';
    }
  }

  /// Whether this severity level requires user attention
  bool get requiresAttention =>
      this == WarningSeverity.warning || this == WarningSeverity.critical;
}

/// A warning generated during analysis.
///
/// Warnings indicate issues that may affect analysis accuracy.
/// The frontend can display these to help users understand
/// potential limitations in the analysis results.
@JsonSerializable(explicitToJson: true)
class AnalysisWarning {
  const AnalysisWarning({
    required this.warningId,
    required this.warningType,
    required this.severity,
    required this.title,
    required this.message,
    this.recommendation,
    this.details,
  });

  /// Unique identifier for this warning type (e.g., 'camera_too_shaky')
  @JsonKey(name: 'warning_id')
  final String warningId;

  /// Category of warning
  @JsonKey(name: 'warning_type')
  final WarningType warningType;

  /// Severity level
  final WarningSeverity severity;

  /// Short title for display (e.g., 'Shaky camera detected')
  final String title;

  /// Human-readable explanation of the warning
  final String message;

  /// Suggested action to resolve the warning
  /// (e.g., 'Use a tripod or stabilize your phone')
  final String? recommendation;

  /// Additional data about the warning (e.g., stability scores, thresholds)
  final Map<String, dynamic>? details;

  factory AnalysisWarning.fromJson(Map<String, dynamic> json) =>
      _$AnalysisWarningFromJson(json);
  Map<String, dynamic> toJson() => _$AnalysisWarningToJson(this);
}
