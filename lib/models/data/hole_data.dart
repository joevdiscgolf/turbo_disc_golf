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
  });

  final int number;
  final int par;
  final int feet;
  final List<DiscThrow> throws;
  final HoleType? holeType;

  int get holeScore => getScoreFromThrows(throws);

  int get relativeHoleScore => holeScore - par;

  factory DGHole.fromJson(Map<String, dynamic> json) => _$DGHoleFromJson(json);

  Map<String, dynamic> toJson() => _$DGHoleToJson(this);
}
