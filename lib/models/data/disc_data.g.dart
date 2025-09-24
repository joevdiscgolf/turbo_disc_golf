// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disc_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DGDisc _$DGDiscFromJson(Map json) => DGDisc(
  name: json['name'] as String,
  id: json['id'] as String,
  speed: (json['speed'] as num?)?.toInt(),
  glide: (json['glide'] as num?)?.toInt(),
  turn: (json['turn'] as num?)?.toInt(),
  fade: (json['fade'] as num?)?.toInt(),
  brand: json['brand'] as String?,
  moldName: json['moldName'] as String?,
  plasticType: json['plasticType'] as String?,
);

Map<String, dynamic> _$DGDiscToJson(DGDisc instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'brand': instance.brand,
  'moldName': instance.moldName,
  'plasticType': instance.plasticType,
  'speed': instance.speed,
  'glide': instance.glide,
  'turn': instance.turn,
  'fade': instance.fade,
};
