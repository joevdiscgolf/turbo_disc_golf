// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_checkpoint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormCheckpoint _$FormCheckpointFromJson(Map json) => FormCheckpoint(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  keyPoints: (json['keyPoints'] as List<dynamic>)
      .map((e) => FormKeyPoint.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  orderIndex: (json['orderIndex'] as num).toInt(),
  referenceImagePath: json['referenceImagePath'] as String?,
  referenceDescription: json['referenceDescription'] as String?,
);

Map<String, dynamic> _$FormCheckpointToJson(FormCheckpoint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'keyPoints': instance.keyPoints.map((e) => e.toJson()).toList(),
      'orderIndex': instance.orderIndex,
      'referenceImagePath': instance.referenceImagePath,
      'referenceDescription': instance.referenceDescription,
    };

FormKeyPoint _$FormKeyPointFromJson(Map json) => FormKeyPoint(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  idealState: json['idealState'] as String,
  commonMistakes: (json['commonMistakes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$FormKeyPointToJson(FormKeyPoint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'idealState': instance.idealState,
      'commonMistakes': instance.commonMistakes,
    };
