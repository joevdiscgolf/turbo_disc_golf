import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/round_story_v2_content.dart';
import 'package:turbo_disc_golf/models/data/round_story_v3_content.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';

part 'ai_content_data.g.dart';

/// Type of AI content segment
enum AISegmentType {
  markdown, // Regular markdown text
  statCard, // Interactive stat card widget
}

/// A segment of AI content (either markdown text or a stat card widget)
@JsonSerializable(explicitToJson: true, anyMap: true)
class AIContentSegment {
  const AIContentSegment({
    required this.type,
    required this.content,
    this.params,
  });

  /// Type of segment (markdown or statCard)
  final AISegmentType type;

  /// For markdown: the markdown text
  /// For statCard: the widget ID (e.g., 'PUTTING_SUMMARY')
  final String content;

  /// Optional parameters for stat cards (e.g., {'range': '20-30'})
  final Map<String, dynamic>? params;

  factory AIContentSegment.fromJson(Map<String, dynamic> json) =>
      _$AIContentSegmentFromJson(json);

  Map<String, dynamic> toJson() => _$AIContentSegmentToJson(this);
}

@JsonSerializable(explicitToJson: true, anyMap: true)
class AIContent {
  const AIContent({
    required this.content,
    required this.roundVersionId,
    this.segments,
    this.structuredContent,
    this.structuredContentV2,
    this.structuredContentV3,
  });

  /// Raw markdown content (kept for backward compatibility)
  final String content;

  /// Version ID of the round this content was generated for
  final int roundVersionId;

  /// Structured segments (markdown + stat cards)
  /// If null, falls back to rendering raw content as markdown
  /// Used for old-format stories with {{PLACEHOLDERS}}
  final List<AIContentSegment>? segments;

  /// Structured story content with specific sections
  /// Used for V1 stories with organized coaching sections
  /// If present, this takes precedence over segments
  final StructuredStoryContent? structuredContent;

  /// V2 structured story content (narrative paragraphs with callouts)
  /// Null if this is a V1 story or old format
  final RoundStoryV2Content? structuredContentV2;

  /// V3 structured story content (sections with hole range metadata)
  /// Null if this is a V1/V2 story or old format
  final RoundStoryV3Content? structuredContentV3;

  factory AIContent.fromJson(Map<String, dynamic> json) =>
      _$AIContentFromJson(json);

  Map<String, dynamic> toJson() => _$AIContentToJson(this);
}
