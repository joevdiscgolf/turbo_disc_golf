// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_analysis_response_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormAnalysisResponseV2 _$FormAnalysisResponseV2FromJson(
  Map<String, dynamic> json,
) => FormAnalysisResponseV2(
  version: json['version'] as String? ?? 'v2',
  sessionId: json['session_id'] as String?,
  status: json['status'] as String?,
  id: json['id'] as String?,
  uid: json['uid'] as String?,
  createdAt: json['created_at'] as String?,
  videoMetadata: VideoMetadata.fromJson(
    json['video_metadata'] as Map<String, dynamic>,
  ),
  analysisResults: AnalysisResults.fromJson(
    json['analysis_results'] as Map<String, dynamic>,
  ),
  checkpoints: (json['checkpoints'] as List<dynamic>)
      .map((e) => CheckpointDataV2.fromJson(e as Map<String, dynamic>))
      .toList(),
  proComparisonConfig: json['pro_comparison_config'] == null
      ? null
      : ProComparisonConfig.fromJson(
          json['pro_comparison_config'] as Map<String, dynamic>,
        ),
  framePoses: (json['frame_poses'] as List<dynamic>?)
      ?.map((e) => FramePoseDataV2.fromJson(e as Map<String, dynamic>))
      .toList(),
  formObservations: json['form_observations'] == null
      ? null
      : FormObservations.fromJson(
          json['form_observations'] as Map<String, dynamic>,
        ),
  formObservationsV2: json['form_observations_v2'] == null
      ? null
      : FormObservationsV2.fromJson(
          json['form_observations_v2'] as Map<String, dynamic>,
        ),
  armSpeed: json['arm_speed'] == null
      ? null
      : ArmSpeedData.fromJson(json['arm_speed'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FormAnalysisResponseV2ToJson(
  FormAnalysisResponseV2 instance,
) => <String, dynamic>{
  'version': instance.version,
  'session_id': instance.sessionId,
  'status': instance.status,
  'id': instance.id,
  'uid': instance.uid,
  'created_at': instance.createdAt,
  'video_metadata': instance.videoMetadata.toJson(),
  'analysis_results': instance.analysisResults.toJson(),
  'checkpoints': instance.checkpoints.map((e) => e.toJson()).toList(),
  'pro_comparison_config': instance.proComparisonConfig?.toJson(),
  'frame_poses': instance.framePoses?.map((e) => e.toJson()).toList(),
  'form_observations': instance.formObservations?.toJson(),
  'form_observations_v2': instance.formObservationsV2?.toJson(),
  'arm_speed': instance.armSpeed?.toJson(),
};
