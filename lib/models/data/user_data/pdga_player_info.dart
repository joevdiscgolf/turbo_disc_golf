import 'package:json_annotation/json_annotation.dart';

part 'pdga_player_info.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class PDGAPlayerInfo {
  PDGAPlayerInfo({
    this.name,
    this.pdgaNum,
    this.location,
    this.classification,
    this.memberSince,
    this.rating,
    this.careerEarnings,
    this.careerEvents,
    this.nextEvent,
    this.careerWins,
  });

  final int? pdgaNum;
  final String? name;
  final String? location;
  final String? classification;
  final String? memberSince;
  final int? rating;
  final int? careerEvents;
  final double? careerEarnings;
  final int? careerWins;
  final String? nextEvent;

  factory PDGAPlayerInfo.fromJson(Map<String, dynamic> json) =>
      _$PDGAPlayerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PDGAPlayerInfoToJson(this);
}
