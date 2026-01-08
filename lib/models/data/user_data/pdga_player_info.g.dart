// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdga_player_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PDGAPlayerInfo _$PDGAPlayerInfoFromJson(Map json) => PDGAPlayerInfo(
  name: json['name'] as String?,
  pdgaNum: (json['pdgaNum'] as num?)?.toInt(),
  location: json['location'] as String?,
  classification: json['classification'] as String?,
  memberSince: json['memberSince'] as String?,
  rating: (json['rating'] as num?)?.toInt(),
  careerEarnings: (json['careerEarnings'] as num?)?.toDouble(),
  careerEvents: (json['careerEvents'] as num?)?.toInt(),
  nextEvent: json['nextEvent'] as String?,
  careerWins: (json['careerWins'] as num?)?.toInt(),
);

Map<String, dynamic> _$PDGAPlayerInfoToJson(PDGAPlayerInfo instance) =>
    <String, dynamic>{
      'pdgaNum': instance.pdgaNum,
      'name': instance.name,
      'location': instance.location,
      'classification': instance.classification,
      'memberSince': instance.memberSince,
      'rating': instance.rating,
      'careerEvents': instance.careerEvents,
      'careerEarnings': instance.careerEarnings,
      'careerWins': instance.careerWins,
      'nextEvent': instance.nextEvent,
    };
