// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_player_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportedConfiguration _$SupportedConfigurationFromJson(Map json) =>
    SupportedConfiguration(
      throwType: json['throw_type'] as String,
      cameraAngle: json['camera_angle'] as String,
    );

Map<String, dynamic> _$SupportedConfigurationToJson(
  SupportedConfiguration instance,
) => <String, dynamic>{
  'throw_type': instance.throwType,
  'camera_angle': instance.cameraAngle,
};

ProV2Measurements _$ProV2MeasurementsFromJson(Map json) => ProV2Measurements(
  frontKneeAngle: (json['front_knee_angle'] as num?)?.toDouble(),
  backKneeAngle: (json['back_knee_angle'] as num?)?.toDouble(),
  frontElbowAngle: (json['front_elbow_angle'] as num?)?.toDouble(),
  frontFootDirectionAngle: (json['front_foot_direction_angle'] as num?)
      ?.toDouble(),
  backFootDirectionAngle: (json['back_foot_direction_angle'] as num?)
      ?.toDouble(),
  hipRotationAngle: (json['hip_rotation_angle'] as num?)?.toDouble(),
  shoulderRotationAngle: (json['shoulder_rotation_angle'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ProV2MeasurementsToJson(ProV2Measurements instance) =>
    <String, dynamic>{
      'front_knee_angle': instance.frontKneeAngle,
      'back_knee_angle': instance.backKneeAngle,
      'front_elbow_angle': instance.frontElbowAngle,
      'front_foot_direction_angle': instance.frontFootDirectionAngle,
      'back_foot_direction_angle': instance.backFootDirectionAngle,
      'hip_rotation_angle': instance.hipRotationAngle,
      'shoulder_rotation_angle': instance.shoulderRotationAngle,
    };

ReferencePoseCheckpoint _$ReferencePoseCheckpointFromJson(Map json) =>
    ReferencePoseCheckpoint(
      checkpointId: json['checkpoint_id'] as String,
      checkpointName: json['checkpoint_name'] as String,
      description: json['description'] as String?,
      v2Measurements: json['v2_measurements'] == null
          ? null
          : ProV2Measurements.fromJson(
              Map<String, dynamic>.from(json['v2_measurements'] as Map),
            ),
    );

Map<String, dynamic> _$ReferencePoseCheckpointToJson(
  ReferencePoseCheckpoint instance,
) => <String, dynamic>{
  'checkpoint_id': instance.checkpointId,
  'checkpoint_name': instance.checkpointName,
  'description': instance.description,
  'v2_measurements': instance.v2Measurements?.toJson(),
};

ProPlayerMetadata _$ProPlayerMetadataFromJson(Map json) => ProPlayerMetadata(
  proPlayerId: json['pro_player_id'] as String,
  displayName: json['display_name'] as String,
  description: json['description'] as String?,
  assetBaseUrl: json['asset_base_url'] as String?,
  isBundled: json['is_bundled'] as bool?,
  isActive: json['is_active'] as bool?,
  supportedConfigurations: (json['supported_configurations'] as List<dynamic>?)
      ?.map(
        (e) => SupportedConfiguration.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
      )
      .toList(),
  referencePoses: (json['reference_poses'] as Map?)?.map(
    (k, e) => MapEntry(
      k as String,
      (e as Map).map(
        (k, e) => MapEntry(
          k as String,
          (e as Map).map(
            (k, e) => MapEntry(
              k as String,
              ReferencePoseCheckpoint.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

Map<String, dynamic> _$ProPlayerMetadataToJson(
  ProPlayerMetadata instance,
) => <String, dynamic>{
  'pro_player_id': instance.proPlayerId,
  'display_name': instance.displayName,
  'description': instance.description,
  'asset_base_url': instance.assetBaseUrl,
  'is_bundled': instance.isBundled,
  'is_active': instance.isActive,
  'supported_configurations': instance.supportedConfigurations
      ?.map((e) => e.toJson())
      .toList(),
  'reference_poses': instance.referencePoses?.map(
    (k, e) => MapEntry(
      k,
      e.map((k, e) => MapEntry(k, e.map((k, e) => MapEntry(k, e.toJson())))),
    ),
  ),
};

ProComparisonPoseData _$ProComparisonPoseDataFromJson(Map json) =>
    ProComparisonPoseData(
      proPlayerId: json['pro_player_id'] as String,
      checkpoints: (json['checkpoints'] as List<dynamic>)
          .map(
            (e) => CheckpointPoseData.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      overallFormScore: (json['overall_form_score'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProComparisonPoseDataToJson(
  ProComparisonPoseData instance,
) => <String, dynamic>{
  'pro_player_id': instance.proPlayerId,
  'checkpoints': instance.checkpoints.map((e) => e.toJson()).toList(),
  'overall_form_score': instance.overallFormScore,
};

ProComparisonData _$ProComparisonDataFromJson(Map json) => ProComparisonData(
  proPlayerId: json['pro_player_id'] as String,
  checkpoints: (json['checkpoints'] as List<dynamic>)
      .map(
        (e) => CheckpointRecord.fromJson(Map<String, dynamic>.from(e as Map)),
      )
      .toList(),
  overallFormScore: (json['overall_form_score'] as num?)?.toInt(),
);

Map<String, dynamic> _$ProComparisonDataToJson(ProComparisonData instance) =>
    <String, dynamic>{
      'pro_player_id': instance.proPlayerId,
      'checkpoints': instance.checkpoints.map((e) => e.toJson()).toList(),
      'overall_form_score': instance.overallFormScore,
    };

ProPlayersConfig _$ProPlayersConfigFromJson(Map json) => ProPlayersConfig(
  pros: (json['pros'] as Map).map(
    (k, e) => MapEntry(
      k as String,
      ProPlayerMetadata.fromJson(Map<String, dynamic>.from(e as Map)),
    ),
  ),
  defaultProId: json['default_pro_id'] as String,
);

Map<String, dynamic> _$ProPlayersConfigToJson(ProPlayersConfig instance) =>
    <String, dynamic>{
      'pros': instance.pros.map((k, e) => MapEntry(k, e.toJson())),
      'default_pro_id': instance.defaultProId,
    };
