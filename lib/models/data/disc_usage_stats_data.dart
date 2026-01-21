import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

part 'disc_usage_stats_data.g.dart';

/// Usage statistics for a single disc
@JsonSerializable(explicitToJson: true, anyMap: true)
class DiscUsageStats {
  const DiscUsageStats({
    required this.discId,
    required this.usageByPurpose,
    required this.lastUsedAt,
    required this.totalUses,
  });

  final String discId;

  /// Map of ThrowPurpose.name -> usage count
  final Map<String, int> usageByPurpose;

  /// ISO 8601 timestamp of last use
  final String lastUsedAt;

  /// Total number of times this disc was used
  final int totalUses;

  /// Get usage count for a specific purpose
  int getUsageForPurpose(ThrowPurpose purpose) {
    return usageByPurpose[purpose.name] ?? 0;
  }

  /// Create a new DiscUsageStats with incremented usage for a purpose
  DiscUsageStats incrementUsage(ThrowPurpose purpose) {
    final Map<String, int> updatedUsage = Map<String, int>.from(usageByPurpose);
    updatedUsage[purpose.name] = (updatedUsage[purpose.name] ?? 0) + 1;

    return DiscUsageStats(
      discId: discId,
      usageByPurpose: updatedUsage,
      lastUsedAt: DateTime.now().toIso8601String(),
      totalUses: totalUses + 1,
    );
  }

  factory DiscUsageStats.fromJson(Map<String, dynamic> json) =>
      _$DiscUsageStatsFromJson(json);

  Map<String, dynamic> toJson() => _$DiscUsageStatsToJson(this);

  /// Create empty stats for a new disc
  factory DiscUsageStats.empty(String discId) {
    return DiscUsageStats(
      discId: discId,
      usageByPurpose: const {},
      lastUsedAt: DateTime.now().toIso8601String(),
      totalUses: 0,
    );
  }
}

/// Container for all disc usage statistics
@JsonSerializable(explicitToJson: true, anyMap: true)
class AllDiscUsageStats {
  const AllDiscUsageStats({
    required this.statsByDiscId,
    required this.lastComputedAt,
    this.totalRoundsProcessed = 0,
  });

  /// Map of discId -> DiscUsageStats
  final Map<String, DiscUsageStats> statsByDiscId;

  /// ISO 8601 timestamp of when stats were last computed
  final String lastComputedAt;

  /// Total number of rounds processed to compute these stats (backend-computed)
  final int totalRoundsProcessed;

  factory AllDiscUsageStats.fromJson(Map<String, dynamic> json) =>
      _$AllDiscUsageStatsFromJson(json);

  Map<String, dynamic> toJson() => _$AllDiscUsageStatsToJson(this);

  /// Create empty stats container
  factory AllDiscUsageStats.empty() {
    return AllDiscUsageStats(
      statsByDiscId: const {},
      lastComputedAt: DateTime.now().toIso8601String(),
      totalRoundsProcessed: 0,
    );
  }

  /// Get stats for a specific disc, or null if not tracked
  DiscUsageStats? getStatsForDisc(String discId) {
    return statsByDiscId[discId];
  }

  /// Check if any stats exist
  bool get isEmpty => statsByDiscId.isEmpty;

  /// Check if stats exist
  bool get isNotEmpty => statsByDiscId.isNotEmpty;
}
