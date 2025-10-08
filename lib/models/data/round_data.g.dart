// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DGRound _$DGRoundFromJson(Map json) => DGRound(
  course: json['course'] as String?,
  holes: (json['holes'] as List<dynamic>)
      .map((e) => DGHole.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  id: json['id'] as String,
);

Map<String, dynamic> _$DGRoundToJson(DGRound instance) => <String, dynamic>{
  'course': instance.course,
  'holes': instance.holes.map((e) => e.toJson()).toList(),
  'id': instance.id,
};
