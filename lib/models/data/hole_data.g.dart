// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hole_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DGHole _$DGHoleFromJson(Map json) => DGHole(
  number: (json['number'] as num).toInt(),
  par: (json['par'] as num).toInt(),
  feet: (json['feet'] as num?)?.toInt(),
  throws: (json['throws'] as List<dynamic>)
      .map((e) => DiscThrow.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  holeType: $enumDecodeNullable(_$HoleTypeEnumMap, json['holeType']),
);

Map<String, dynamic> _$DGHoleToJson(DGHole instance) => <String, dynamic>{
  'number': instance.number,
  'par': instance.par,
  'feet': instance.feet,
  'throws': instance.throws.map((e) => e.toJson()).toList(),
  'holeType': _$HoleTypeEnumMap[instance.holeType],
};

const _$HoleTypeEnumMap = {
  HoleType.open: 'open',
  HoleType.slightlyWooded: 'slightly_wooded',
  HoleType.wooded: 'wooded',
};
