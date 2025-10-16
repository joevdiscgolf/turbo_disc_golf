// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_content_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIContentSegment _$AIContentSegmentFromJson(Map json) => AIContentSegment(
  type: $enumDecode(_$AISegmentTypeEnumMap, json['type']),
  content: json['content'] as String,
  params: (json['params'] as Map?)?.map((k, e) => MapEntry(k as String, e)),
);

Map<String, dynamic> _$AIContentSegmentToJson(AIContentSegment instance) =>
    <String, dynamic>{
      'type': _$AISegmentTypeEnumMap[instance.type]!,
      'content': instance.content,
      'params': instance.params,
    };

const _$AISegmentTypeEnumMap = {
  AISegmentType.markdown: 'markdown',
  AISegmentType.statCard: 'statCard',
};

AIContent _$AIContentFromJson(Map json) => AIContent(
  content: json['content'] as String,
  roundVersionId: (json['roundVersionId'] as num).toInt(),
  segments: (json['segments'] as List<dynamic>?)
      ?.map(
        (e) => AIContentSegment.fromJson(Map<String, dynamic>.from(e as Map)),
      )
      .toList(),
);

Map<String, dynamic> _$AIContentToJson(AIContent instance) => <String, dynamic>{
  'content': instance.content,
  'roundVersionId': instance.roundVersionId,
  'segments': instance.segments?.map((e) => e.toJson()).toList(),
};
