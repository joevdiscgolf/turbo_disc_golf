// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disc_usage_stats_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscUsageStats _$DiscUsageStatsFromJson(Map json) => DiscUsageStats(
  discName: json['discName'] as String,
  usageByPurpose: Map<String, int>.from(json['usageByPurpose'] as Map),
  lastUsedAt: json['lastUsedAt'] as String,
  totalUses: (json['totalUses'] as num).toInt(),
);

Map<String, dynamic> _$DiscUsageStatsToJson(DiscUsageStats instance) =>
    <String, dynamic>{
      'discName': instance.discName,
      'usageByPurpose': instance.usageByPurpose,
      'lastUsedAt': instance.lastUsedAt,
      'totalUses': instance.totalUses,
    };

AllDiscUsageStats _$AllDiscUsageStatsFromJson(Map json) => AllDiscUsageStats(
  statsByDiscName: (json['statsByDiscName'] as Map).map(
    (k, e) => MapEntry(
      k as String,
      DiscUsageStats.fromJson(Map<String, dynamic>.from(e as Map)),
    ),
  ),
  lastComputedAt: json['lastComputedAt'] as String,
  totalRoundsProcessed: (json['totalRoundsProcessed'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AllDiscUsageStatsToJson(AllDiscUsageStats instance) =>
    <String, dynamic>{
      'statsByDiscName': instance.statsByDiscName.map(
        (k, e) => MapEntry(k, e.toJson()),
      ),
      'lastComputedAt': instance.lastComputedAt,
      'totalRoundsProcessed': instance.totalRoundsProcessed,
    };
