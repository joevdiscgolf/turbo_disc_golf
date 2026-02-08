import 'package:json_annotation/json_annotation.dart';

part 'observation_coaching.g.dart';

/// Coaching content for an observation
@JsonSerializable()
class ObservationCoaching {
  const ObservationCoaching({
    required this.summary,
    required this.explanation,
    this.fixSuggestion,
    this.drillSuggestion,
  });

  /// Short summary of the observation (1-2 sentences)
  final String summary;

  /// Detailed explanation of why this matters
  final String explanation;

  /// Suggestion for how to fix/improve (for negative observations)
  @JsonKey(name: 'fix_suggestion')
  final String? fixSuggestion;

  /// Suggested drill to practice this aspect
  @JsonKey(name: 'drill_suggestion')
  final String? drillSuggestion;

  factory ObservationCoaching.fromJson(Map<String, dynamic> json) =>
      _$ObservationCoachingFromJson(json);
  Map<String, dynamic> toJson() => _$ObservationCoachingToJson(this);
}
