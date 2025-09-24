import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

part 'hole_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class DGHole {
  const DGHole({
    required this.number,
    required this.par,
    required this.feet,
    required this.throws,
  });

  final int number;
  final int par;
  final int feet;
  final List<DiscThrow> throws;

  factory DGHole.fromJson(Map<String, dynamic> json) => _$DGHoleFromJson(json);

  Map<String, dynamic> toJson() => _$DGHoleToJson(this);
}
