// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_comparison_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProComparisonConfig _$ProComparisonConfigFromJson(Map<String, dynamic> json) =>
    ProComparisonConfig(
      defaultProId: json['default_pro_id'] as String?,
      proComparisons: (json['pro_comparisons'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          ProComparisonDataV2.fromJson(e as Map<String, dynamic>),
        ),
      ),
      videoSyncMetadata: json['video_sync_metadata'] == null
          ? null
          : VideoSyncMetadata.fromJson(
              json['video_sync_metadata'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ProComparisonConfigToJson(
  ProComparisonConfig instance,
) => <String, dynamic>{
  'default_pro_id': instance.defaultProId,
  'pro_comparisons': instance.proComparisons?.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'video_sync_metadata': instance.videoSyncMetadata?.toJson(),
};
