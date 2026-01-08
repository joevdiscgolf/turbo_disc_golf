import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pdga_metadata.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class PDGAMetadata extends Equatable {
  const PDGAMetadata({
    this.pdgaNum,
    this.pdgaRating,
    this.division,
  });

  final int? pdgaNum;
  final int? pdgaRating;
  final String? division;

  PDGAMetadata copyWith({
    int? pdgaNum,
    int? pdgaRating,
    String? division,
  }) {
    return PDGAMetadata(
      pdgaNum: pdgaNum ?? this.pdgaNum,
      pdgaRating: pdgaRating ?? this.pdgaRating,
      division: division ?? this.division,
    );
  }

  factory PDGAMetadata.fromJson(Map<String, dynamic> json) =>
      _$PDGAMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$PDGAMetadataToJson(this);

  @override
  List<Object?> get props => [pdgaNum, pdgaRating, division];
}
