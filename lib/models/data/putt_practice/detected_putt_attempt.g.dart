// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detected_putt_attempt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DetectedPuttAttempt _$DetectedPuttAttemptFromJson(Map json) =>
    DetectedPuttAttempt(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      made: json['made'] as bool,
      relativeX: (json['relativeX'] as num).toDouble(),
      relativeY: (json['relativeY'] as num).toDouble(),
      estimatedDistanceFeet: (json['estimatedDistanceFeet'] as num?)
          ?.toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      frameNumber: (json['frameNumber'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DetectedPuttAttemptToJson(
  DetectedPuttAttempt instance,
) => <String, dynamic>{
  'id': instance.id,
  'timestamp': instance.timestamp.toIso8601String(),
  'made': instance.made,
  'relativeX': instance.relativeX,
  'relativeY': instance.relativeY,
  'estimatedDistanceFeet': instance.estimatedDistanceFeet,
  'confidence': instance.confidence,
  'frameNumber': instance.frameNumber,
};
