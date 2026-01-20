import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/round_story_v2_content.dart';

part 'round_story_v3_content.g.dart';

/// V3: Story section with hole range metadata
@JsonSerializable(explicitToJson: true, anyMap: true)
class StorySection {
  final String text;
  final List<StoryCallout> callouts;
  final HoleRange holeRange;

  const StorySection({
    required this.text,
    this.callouts = const [],
    required this.holeRange,
  });

  factory StorySection.fromJson(Map<String, dynamic> json) =>
      _$StorySectionFromJson(json);

  Map<String, dynamic> toJson() => _$StorySectionToJson(this);
}

@JsonSerializable(explicitToJson: true, anyMap: true)
class HoleRange {
  final int startHole;
  final int endHole;

  const HoleRange({
    required this.startHole,
    required this.endHole,
  });

  bool contains(int holeNumber) =>
      holeNumber >= startHole && holeNumber <= endHole;

  List<int> get holes =>
      List.generate(endHole - startHole + 1, (i) => startHole + i);

  String get displayString {
    if (startHole == endHole) return 'Hole $startHole';
    return 'Holes $startHole-$endHole';
  }

  factory HoleRange.fromJson(Map<String, dynamic> json) =>
      _$HoleRangeFromJson(json);

  Map<String, dynamic> toJson() => _$HoleRangeToJson(this);
}

/// Skills assessment with strengths and weaknesses
@JsonSerializable(explicitToJson: true, anyMap: true)
class SkillAssessment {
  final List<SkillHighlight> strengths;
  final List<SkillHighlight> weaknesses;
  final String keyInsight;

  const SkillAssessment({
    required this.strengths,
    required this.weaknesses,
    required this.keyInsight,
  });

  factory SkillAssessment.fromJson(Map<String, dynamic> json) =>
      _$SkillAssessmentFromJson(json);

  Map<String, dynamic> toJson() => _$SkillAssessmentToJson(this);
}

/// Individual skill highlight (strength or weakness)
@JsonSerializable(explicitToJson: true, anyMap: true)
class SkillHighlight {
  final String skill;
  final String description;
  final String statHighlight;

  const SkillHighlight({
    required this.skill,
    required this.description,
    required this.statHighlight,
  });

  factory SkillHighlight.fromJson(Map<String, dynamic> json) =>
      _$SkillHighlightFromJson(json);

  Map<String, dynamic> toJson() => _$SkillHighlightToJson(this);
}

@JsonSerializable(explicitToJson: true, anyMap: true)
class RoundStoryV3Content {
  final String roundTitle;
  final String overview;
  final List<StorySection> sections;
  final WhatCouldHaveBeenV2 whatCouldHaveBeen;
  final String? shareableHeadline;
  final List<String> practiceAdvice;
  final List<String> strategyTips;
  final SkillAssessment? skillsAssessment;

  const RoundStoryV3Content({
    required this.roundTitle,
    required this.overview,
    required this.sections,
    required this.whatCouldHaveBeen,
    this.shareableHeadline,
    this.practiceAdvice = const [],
    this.strategyTips = const [],
    this.skillsAssessment,
  });

  factory RoundStoryV3Content.fromJson(Map<String, dynamic> json) =>
      _$RoundStoryV3ContentFromJson(json);

  Map<String, dynamic> toJson() => _$RoundStoryV3ContentToJson(this);
}
