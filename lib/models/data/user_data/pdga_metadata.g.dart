// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdga_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PDGAMetadata _$PDGAMetadataFromJson(Map json) => PDGAMetadata(
  pdgaNum: (json['pdgaNum'] as num?)?.toInt(),
  pdgaRating: (json['pdgaRating'] as num?)?.toInt(),
  division: json['division'] as String?,
);

Map<String, dynamic> _$PDGAMetadataToJson(PDGAMetadata instance) =>
    <String, dynamic>{
      'pdgaNum': instance.pdgaNum,
      'pdgaRating': instance.pdgaRating,
      'division': instance.division,
    };
