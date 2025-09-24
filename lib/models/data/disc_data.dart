import 'package:json_annotation/json_annotation.dart';

part 'disc_data.g.dart';

enum DGDiscType {
  @JsonValue('putter')
  putter,
  @JsonValue('approach')
  approach,
  @JsonValue('midrange')
  midrange,
  @JsonValue('fairway')
  fairway,
  @JsonValue('distance')
  distance,
}

@JsonSerializable(explicitToJson: true, anyMap: true)
class DGDisc {
  const DGDisc({
    required this.name,
    required this.id,
    required this.speed,
    required this.glide,
    required this.turn,
    required this.fade,
    required this.brand,
    required this.moldName,
    required this.plasticType,
  });

  final String id;

  final String name;
  final String? brand;
  final String? moldName;
  final String? plasticType;

  // flight numbers
  final int? speed;
  final int? glide;
  final int? turn;
  final int? fade;

  factory DGDisc.fromJson(Map<String, dynamic> json) => _$DGDiscFromJson(json);

  Map<String, dynamic> toJson() => _$DGDiscToJson(this);
}
