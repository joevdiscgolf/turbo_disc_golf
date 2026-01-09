// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseHole _$CourseHoleFromJson(Map json) => CourseHole(
  holeNumber: (json['holeNumber'] as num).toInt(),
  par: (json['par'] as num).toInt(),
  feet: (json['feet'] as num).toInt(),
  pins:
      (json['pins'] as List<dynamic>?)
          ?.map((e) => HolePin.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ??
      const [],
  holeType: $enumDecodeNullable(_$HoleTypeEnumMap, json['holeType']),
  holeShape: $enumDecodeNullable(_$HoleShapeEnumMap, json['holeShape']),
  defaultPinId: json['defaultPinId'] as String?,
);

Map<String, dynamic> _$CourseHoleToJson(CourseHole instance) =>
    <String, dynamic>{
      'holeNumber': instance.holeNumber,
      'par': instance.par,
      'feet': instance.feet,
      'pins': instance.pins.map((e) => e.toJson()).toList(),
      'holeType': _$HoleTypeEnumMap[instance.holeType],
      'holeShape': _$HoleShapeEnumMap[instance.holeShape],
      'defaultPinId': instance.defaultPinId,
    };

const _$HoleTypeEnumMap = {
  HoleType.open: 'open',
  HoleType.slightlyWooded: 'slightly_wooded',
  HoleType.wooded: 'wooded',
};

const _$HoleShapeEnumMap = {
  HoleShape.straight: 'straight',
  HoleShape.doglegLeft: 'dogleg_left',
  HoleShape.doglegRight: 'dogleg_right',
};

CourseLayout _$CourseLayoutFromJson(Map json) => CourseLayout(
  id: json['id'] as String,
  name: json['name'] as String,
  holes: (json['holes'] as List<dynamic>)
      .map((e) => CourseHole.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  description: json['description'] as String?,
  isDefault: json['isDefault'] as bool? ?? false,
);

Map<String, dynamic> _$CourseLayoutToJson(CourseLayout instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'holes': instance.holes.map((e) => e.toJson()).toList(),
      'description': instance.description,
      'isDefault': instance.isDefault,
    };

HolePin _$HolePinFromJson(Map json) => HolePin(
  id: json['id'] as String,
  par: (json['par'] as num).toInt(),
  feet: (json['feet'] as num).toInt(),
  label: json['label'] as String,
);

Map<String, dynamic> _$HolePinToJson(HolePin instance) => <String, dynamic>{
  'id': instance.id,
  'par': instance.par,
  'feet': instance.feet,
  'label': instance.label,
};

Course _$CourseFromJson(Map json) => Course(
  id: json['id'] as String,
  name: json['name'] as String,
  layouts: (json['layouts'] as List<dynamic>)
      .map((e) => CourseLayout.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  location: json['location'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  country: json['country'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  description: json['description'] as String?,
  uDiscId: json['uDiscId'] as String?,
  pdgaId: json['pdgaId'] as String?,
);

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'layouts': instance.layouts.map((e) => e.toJson()).toList(),
  'location': instance.location,
  'city': instance.city,
  'state': instance.state,
  'country': instance.country,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'description': instance.description,
  'uDiscId': instance.uDiscId,
  'pdgaId': instance.pdgaId,
};
