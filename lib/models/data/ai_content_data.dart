import 'package:json_annotation/json_annotation.dart';

part 'ai_content_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class AIContent {
  const AIContent({
    required this.content,
    required this.roundVersionId,
  });

  final String content;
  final int roundVersionId;

  factory AIContent.fromJson(Map<String, dynamic> json) =>
      _$AIContentFromJson(json);

  Map<String, dynamic> toJson() => _$AIContentToJson(this);
}
