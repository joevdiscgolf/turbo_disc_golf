// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_content_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIContent _$AIContentFromJson(Map json) => AIContent(
  content: json['content'] as String,
  roundVersionId: (json['roundVersionId'] as num).toInt(),
);

Map<String, dynamic> _$AIContentToJson(AIContent instance) => <String, dynamic>{
  'content': instance.content,
  'roundVersionId': instance.roundVersionId,
};
