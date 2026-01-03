// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_search_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseSearchHit _$CourseSearchHitFromJson(Map json) => CourseSearchHit(
  id: json['id'] as String,
  name: json['name'] as String,
  city: json['city'] as String?,
  state: json['state'] as String?,
  layouts: (json['layouts'] as List<dynamic>)
      .map(
        (e) =>
            CourseLayoutSummary.fromJson(Map<String, dynamic>.from(e as Map)),
      )
      .toList(),
);

Map<String, dynamic> _$CourseSearchHitToJson(CourseSearchHit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'city': instance.city,
      'state': instance.state,
      'layouts': instance.layouts.map((e) => e.toJson()).toList(),
    };

CourseLayoutSummary _$CourseLayoutSummaryFromJson(Map json) =>
    CourseLayoutSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      holeCount: (json['holeCount'] as num).toInt(),
      par: (json['par'] as num).toInt(),
      totalFeet: (json['totalFeet'] as num).toInt(),
      isDefault: json['isDefault'] as bool,
    );

Map<String, dynamic> _$CourseLayoutSummaryToJson(
  CourseLayoutSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'holeCount': instance.holeCount,
  'par': instance.par,
  'totalFeet': instance.totalFeet,
  'isDefault': instance.isDefault,
};
