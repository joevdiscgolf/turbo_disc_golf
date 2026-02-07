// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'putt_practice_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PuttPracticeSession _$PuttPracticeSessionFromJson(Map json) =>
    PuttPracticeSession(
      id: json['id'] as String,
      uid: json['uid'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      status: $enumDecode(_$PuttPracticeSessionStatusEnumMap, json['status']),
      calibration: json['calibration'] == null
          ? null
          : BasketCalibration.fromJson(
              Map<String, dynamic>.from(json['calibration'] as Map),
            ),
      attempts: (json['attempts'] as List<dynamic>)
          .map(
            (e) => DetectedPuttAttempt.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      distanceRange: json['distanceRange'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$PuttPracticeSessionToJson(
  PuttPracticeSession instance,
) => <String, dynamic>{
  'id': instance.id,
  'uid': instance.uid,
  'createdAt': instance.createdAt.toIso8601String(),
  'endedAt': instance.endedAt?.toIso8601String(),
  'status': _$PuttPracticeSessionStatusEnumMap[instance.status]!,
  'calibration': instance.calibration?.toJson(),
  'attempts': instance.attempts.map((e) => e.toJson()).toList(),
  'distanceRange': instance.distanceRange,
  'notes': instance.notes,
};

const _$PuttPracticeSessionStatusEnumMap = {
  PuttPracticeSessionStatus.calibrating: 'calibrating',
  PuttPracticeSessionStatus.active: 'active',
  PuttPracticeSessionStatus.paused: 'paused',
  PuttPracticeSessionStatus.completed: 'completed',
};
