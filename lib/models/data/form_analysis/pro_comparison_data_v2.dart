import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';

part 'pro_comparison_data_v2.g.dart';

/// Pro comparison data for multi-pro feature (V2 format)
@JsonSerializable(explicitToJson: true)
class ProComparisonDataV2 {
  const ProComparisonDataV2({
    required this.proPlayerId,
    required this.checkpoints,
    this.overallFormScore,
  });

  /// Pro player ID (e.g., "paul_mcbeth")
  @JsonKey(name: 'pro_player_id')
  final String proPlayerId;

  /// Checkpoints with this pro comparison
  final List<CheckpointDataV2> checkpoints;

  /// Overall form score for this pro comparison
  @JsonKey(name: 'overall_form_score')
  final int? overallFormScore;

  factory ProComparisonDataV2.fromJson(Map<String, dynamic> json) =>
      _$ProComparisonDataV2FromJson(json);
  Map<String, dynamic> toJson() => _$ProComparisonDataV2ToJson(this);
}
