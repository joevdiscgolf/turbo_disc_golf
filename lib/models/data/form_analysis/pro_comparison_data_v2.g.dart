// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_comparison_data_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProComparisonDataV2 _$ProComparisonDataV2FromJson(Map<String, dynamic> json) =>
    ProComparisonDataV2(
      proPlayerId: json['pro_player_id'] as String,
      checkpoints: (json['checkpoints'] as List<dynamic>)
          .map((e) => CheckpointDataV2.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallFormScore: (json['overall_form_score'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProComparisonDataV2ToJson(
  ProComparisonDataV2 instance,
) => <String, dynamic>{
  'pro_player_id': instance.proPlayerId,
  'checkpoints': instance.checkpoints.map((e) => e.toJson()).toList(),
  'overall_form_score': instance.overallFormScore,
};
