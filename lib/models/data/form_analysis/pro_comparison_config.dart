import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_comparison_data_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/video_sync_metadata.dart';

part 'pro_comparison_config.g.dart';

/// Pro comparison configuration
@JsonSerializable(explicitToJson: true)
class ProComparisonConfig {
  const ProComparisonConfig({
    this.defaultProId,
    this.proComparisons,
    this.videoSyncMetadata,
  });

  /// Default pro player ID to show initially
  @JsonKey(name: 'default_pro_id')
  final String? defaultProId;

  /// Multi-pro comparison data: map of pro_player_id to comparison data
  @JsonKey(name: 'pro_comparisons')
  final Map<String, ProComparisonDataV2>? proComparisons;

  /// Video synchronization metadata for frame-perfect alignment
  @JsonKey(name: 'video_sync_metadata')
  final VideoSyncMetadata? videoSyncMetadata;

  factory ProComparisonConfig.fromJson(Map<String, dynamic> json) =>
      _$ProComparisonConfigFromJson(json);
  Map<String, dynamic> toJson() => _$ProComparisonConfigToJson(this);
}
