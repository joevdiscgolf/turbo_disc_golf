import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';

part 'round_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class DGRound {
  const DGRound({required this.course, required this.holes, required this.id});

  final String? course;
  final List<DGHole> holes;
  final String id;

  factory DGRound.fromJson(Map<String, dynamic> json) =>
      _$DGRoundFromJson(json);

  Map<String, dynamic> toJson() => _$DGRoundToJson(this);
}
