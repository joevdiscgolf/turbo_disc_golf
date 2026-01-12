import 'package:json_annotation/json_annotation.dart';

part 'form_analysis_result.g.dart';

/// Complete analysis result for a video form analysis session
@JsonSerializable(explicitToJson: true, anyMap: true)
class FormAnalysisResult {
  const FormAnalysisResult({
    required this.id,
    required this.sessionId,
    required this.createdAt,
    required this.checkpointResults,
    required this.overallScore,
    required this.overallFeedback,
    required this.prioritizedImprovements,
    this.rawGeminiResponse,
  });

  /// Unique identifier for this analysis result
  final String id;

  /// ID of the video analysis session this belongs to
  final String sessionId;

  /// When this analysis was created
  final String createdAt;

  /// Results for each checkpoint in the analysis
  final List<CheckpointAnalysisResult> checkpointResults;

  /// Overall form score (0-100)
  final int overallScore;

  /// AI-generated overall feedback summary
  final String overallFeedback;

  /// Prioritized list of improvements (most impactful first)
  final List<FormImprovement> prioritizedImprovements;

  /// Raw response from Gemini for debugging
  final String? rawGeminiResponse;

  factory FormAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$FormAnalysisResultFromJson(json);
  Map<String, dynamic> toJson() => _$FormAnalysisResultToJson(this);
}

/// Analysis result for a single checkpoint
@JsonSerializable(explicitToJson: true, anyMap: true)
class CheckpointAnalysisResult {
  const CheckpointAnalysisResult({
    required this.checkpointId,
    required this.checkpointName,
    required this.score,
    required this.feedback,
    required this.keyPointResults,
    this.timestampSeconds,
    this.comparisonToReference,
  });

  /// ID of the checkpoint being analyzed
  final String checkpointId;

  /// Name of the checkpoint
  final String checkpointName;

  /// Score for this checkpoint (0-100)
  final int score;

  /// Specific feedback for this checkpoint
  final String feedback;

  /// Results for each key point within this checkpoint
  final List<KeyPointResult> keyPointResults;

  /// Timestamp in the video where this checkpoint occurs
  final double? timestampSeconds;

  /// Comparison notes vs reference position
  final String? comparisonToReference;

  factory CheckpointAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$CheckpointAnalysisResultFromJson(json);
  Map<String, dynamic> toJson() => _$CheckpointAnalysisResultToJson(this);
}

/// Result for a single key point evaluation
@JsonSerializable(explicitToJson: true, anyMap: true)
class KeyPointResult {
  const KeyPointResult({
    required this.keyPointId,
    required this.keyPointName,
    required this.status,
    required this.observation,
    this.suggestion,
  });

  /// ID of the key point
  final String keyPointId;

  /// Name of the key point
  final String keyPointName;

  /// Status of this key point evaluation
  final KeyPointStatus status;

  /// What was observed in the video
  final String observation;

  /// Specific suggestion for improvement (if needed)
  final String? suggestion;

  factory KeyPointResult.fromJson(Map<String, dynamic> json) =>
      _$KeyPointResultFromJson(json);
  Map<String, dynamic> toJson() => _$KeyPointResultToJson(this);
}

/// Status of a key point evaluation
enum KeyPointStatus {
  @JsonValue('excellent')
  excellent,
  @JsonValue('good')
  good,
  @JsonValue('needs_improvement')
  needsImprovement,
  @JsonValue('poor')
  poor,
  @JsonValue('not_visible')
  notVisible,
}

/// A prioritized improvement suggestion
@JsonSerializable(explicitToJson: true, anyMap: true)
class FormImprovement {
  const FormImprovement({
    required this.priority,
    required this.checkpointId,
    required this.title,
    required this.description,
    required this.drillSuggestion,
  });

  /// Priority rank (1 = highest priority)
  final int priority;

  /// ID of the related checkpoint
  final String checkpointId;

  /// Short title for the improvement
  final String title;

  /// Detailed description of what to improve
  final String description;

  /// Specific drill or practice exercise
  final String drillSuggestion;

  factory FormImprovement.fromJson(Map<String, dynamic> json) =>
      _$FormImprovementFromJson(json);
  Map<String, dynamic> toJson() => _$FormImprovementToJson(this);
}
