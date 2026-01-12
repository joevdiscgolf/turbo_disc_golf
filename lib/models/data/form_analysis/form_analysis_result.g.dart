// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_analysis_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormAnalysisResult _$FormAnalysisResultFromJson(Map json) => FormAnalysisResult(
  id: json['id'] as String,
  sessionId: json['sessionId'] as String,
  createdAt: json['createdAt'] as String,
  checkpointResults: (json['checkpointResults'] as List<dynamic>)
      .map(
        (e) => CheckpointAnalysisResult.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
      )
      .toList(),
  overallScore: (json['overallScore'] as num).toInt(),
  overallFeedback: json['overallFeedback'] as String,
  prioritizedImprovements: (json['prioritizedImprovements'] as List<dynamic>)
      .map((e) => FormImprovement.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
  rawGeminiResponse: json['rawGeminiResponse'] as String?,
);

Map<String, dynamic> _$FormAnalysisResultToJson(FormAnalysisResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'createdAt': instance.createdAt,
      'checkpointResults': instance.checkpointResults
          .map((e) => e.toJson())
          .toList(),
      'overallScore': instance.overallScore,
      'overallFeedback': instance.overallFeedback,
      'prioritizedImprovements': instance.prioritizedImprovements
          .map((e) => e.toJson())
          .toList(),
      'rawGeminiResponse': instance.rawGeminiResponse,
    };

CheckpointAnalysisResult _$CheckpointAnalysisResultFromJson(Map json) =>
    CheckpointAnalysisResult(
      checkpointId: json['checkpointId'] as String,
      checkpointName: json['checkpointName'] as String,
      score: (json['score'] as num).toInt(),
      feedback: json['feedback'] as String,
      keyPointResults: (json['keyPointResults'] as List<dynamic>)
          .map(
            (e) => KeyPointResult.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      timestampSeconds: (json['timestampSeconds'] as num?)?.toDouble(),
      comparisonToReference: json['comparisonToReference'] as String?,
    );

Map<String, dynamic> _$CheckpointAnalysisResultToJson(
  CheckpointAnalysisResult instance,
) => <String, dynamic>{
  'checkpointId': instance.checkpointId,
  'checkpointName': instance.checkpointName,
  'score': instance.score,
  'feedback': instance.feedback,
  'keyPointResults': instance.keyPointResults.map((e) => e.toJson()).toList(),
  'timestampSeconds': instance.timestampSeconds,
  'comparisonToReference': instance.comparisonToReference,
};

KeyPointResult _$KeyPointResultFromJson(Map json) => KeyPointResult(
  keyPointId: json['keyPointId'] as String,
  keyPointName: json['keyPointName'] as String,
  status: $enumDecode(_$KeyPointStatusEnumMap, json['status']),
  observation: json['observation'] as String,
  suggestion: json['suggestion'] as String?,
);

Map<String, dynamic> _$KeyPointResultToJson(KeyPointResult instance) =>
    <String, dynamic>{
      'keyPointId': instance.keyPointId,
      'keyPointName': instance.keyPointName,
      'status': _$KeyPointStatusEnumMap[instance.status]!,
      'observation': instance.observation,
      'suggestion': instance.suggestion,
    };

const _$KeyPointStatusEnumMap = {
  KeyPointStatus.excellent: 'excellent',
  KeyPointStatus.good: 'good',
  KeyPointStatus.needsImprovement: 'needs_improvement',
  KeyPointStatus.poor: 'poor',
  KeyPointStatus.notVisible: 'not_visible',
};

FormImprovement _$FormImprovementFromJson(Map json) => FormImprovement(
  priority: (json['priority'] as num).toInt(),
  checkpointId: json['checkpointId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  drillSuggestion: json['drillSuggestion'] as String,
);

Map<String, dynamic> _$FormImprovementToJson(FormImprovement instance) =>
    <String, dynamic>{
      'priority': instance.priority,
      'checkpointId': instance.checkpointId,
      'title': instance.title,
      'description': instance.description,
      'drillSuggestion': instance.drillSuggestion,
    };
