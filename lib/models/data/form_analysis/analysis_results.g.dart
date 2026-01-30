// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalysisResults _$AnalysisResultsFromJson(Map<String, dynamic> json) =>
    AnalysisResults(
      overallFormScore: (json['overall_form_score'] as num?)?.toInt(),
      throwType: json['throw_type'] as String,
      cameraAngle: $enumDecode(_$CameraAngleEnumMap, json['camera_angle']),
      detectedHandedness: _handednessFromJson(
        json['detected_handedness'] as String?,
      ),
      worstDeviationSeverity: json['worst_deviation_severity'] as String?,
    );

Map<String, dynamic> _$AnalysisResultsToJson(AnalysisResults instance) =>
    <String, dynamic>{
      'overall_form_score': instance.overallFormScore,
      'throw_type': instance.throwType,
      'camera_angle': _$CameraAngleEnumMap[instance.cameraAngle]!,
      'detected_handedness': _$HandednessEnumMap[instance.detectedHandedness],
      'worst_deviation_severity': instance.worstDeviationSeverity,
    };

const _$CameraAngleEnumMap = {
  CameraAngle.side: 'side',
  CameraAngle.rear: 'rear',
};

const _$HandednessEnumMap = {
  Handedness.left: 'left',
  Handedness.right: 'right',
};
