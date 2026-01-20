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
  structuredContent: json['structuredContent'] == null
      ? null
      : StructuredStoryContent.fromJson(
          Map<String, dynamic>.from(json['structuredContent'] as Map),
        ),
  structuredContentV2: json['structuredContentV2'] == null
      ? null
      : RoundStoryV2Content.fromJson(
          Map<String, dynamic>.from(json['structuredContentV2'] as Map),
        ),
  structuredContentV3: json['structuredContentV3'] == null
      ? null
      : RoundStoryV3Content.fromJson(
          Map<String, dynamic>.from(json['structuredContentV3'] as Map),
        ),
  regenerateCount: (json['regenerateCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AIContentToJson(AIContent instance) => <String, dynamic>{
  'content': instance.content,
  'roundVersionId': instance.roundVersionId,
  'segments': instance.segments?.map((e) => e.toJson()).toList(),
  'structuredContent': instance.structuredContent?.toJson(),
  'structuredContentV2': instance.structuredContentV2?.toJson(),
  'structuredContentV3': instance.structuredContentV3?.toJson(),
  'regenerateCount': instance.regenerateCount,
};
