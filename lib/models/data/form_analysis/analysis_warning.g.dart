// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_warning.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalysisWarning _$AnalysisWarningFromJson(Map<String, dynamic> json) =>
    AnalysisWarning(
      warningId: json['warning_id'] as String,
      warningType: $enumDecode(_$WarningTypeEnumMap, json['warning_type']),
      severity: $enumDecode(_$WarningSeverityEnumMap, json['severity']),
      title: json['title'] as String,
      message: json['message'] as String,
      recommendation: json['recommendation'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AnalysisWarningToJson(AnalysisWarning instance) =>
    <String, dynamic>{
      'warning_id': instance.warningId,
      'warning_type': _$WarningTypeEnumMap[instance.warningType]!,
      'severity': _$WarningSeverityEnumMap[instance.severity]!,
      'title': instance.title,
      'message': instance.message,
      'recommendation': instance.recommendation,
      'details': instance.details,
    };

const _$WarningTypeEnumMap = {
  WarningType.cameraStability: 'camera_stability',
  WarningType.poseStability: 'pose_stability',
  WarningType.lowVisibility: 'low_visibility',
  WarningType.shortVideo: 'short_video',
  WarningType.modelRecommendation: 'model_recommendation',
};

const _$WarningSeverityEnumMap = {
  WarningSeverity.info: 'info',
  WarningSeverity.warning: 'warning',
  WarningSeverity.critical: 'critical',
};
