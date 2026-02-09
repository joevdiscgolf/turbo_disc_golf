import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/score_helpers.dart';

part 'hole_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class DGHole {
  const DGHole({
    required this.number,
    required this.par,
    required this.feet,
    required this.throws,
    this.holeType,
    this.explicitScore,
  });

  final int number;
  final int par;
  final int feet;
  final List<DiscThrow> throws;
  final HoleType? holeType;

  /// Explicit score for score-only entry. When null, calculated from throws.
  final int? explicitScore;

  /// Returns the hole score. Uses explicitScore if set, otherwise calculates from throws.
  int get holeScore => explicitScore ?? getScoreFromThrows(throws);

  /// True if this hole has detailed throw data (not score-only).
  bool get hasDetailedThrows => throws.isNotEmpty;

  int get relativeHoleScore => holeScore - par;

  factory DGHole.fromJson(Map<String, dynamic> json) => _$DGHoleFromJson(json);

  Map<String, dynamic> toJson() => _$DGHoleToJson(this);
}
