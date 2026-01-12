// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_analysis_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoAnalysisSession _$VideoAnalysisSessionFromJson(Map json) =>
    VideoAnalysisSession(
      id: json['id'] as String,
      uid: json['uid'] as String,
      createdAt: json['createdAt'] as String,
      videoPath: json['videoPath'] as String,
      videoSource: $enumDecode(_$VideoSourceEnumMap, json['videoSource']),
      throwType: $enumDecode(_$ThrowTechniqueEnumMap, json['throwType']),
      videoDurationSeconds: (json['videoDurationSeconds'] as num?)?.toDouble(),
      videoSizeBytes: (json['videoSizeBytes'] as num?)?.toInt(),
      analysisResult: json['analysisResult'] == null
          ? null
          : FormAnalysisResult.fromJson(
              Map<String, dynamic>.from(json['analysisResult'] as Map),
            ),
      status: $enumDecodeNullable(_$SessionStatusEnumMap, json['status']),
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$VideoAnalysisSessionToJson(
  VideoAnalysisSession instance,
) => <String, dynamic>{
  'id': instance.id,
  'uid': instance.uid,
  'createdAt': instance.createdAt,
  'videoPath': instance.videoPath,
  'videoSource': _$VideoSourceEnumMap[instance.videoSource]!,
  'throwType': _$ThrowTechniqueEnumMap[instance.throwType]!,
  'videoDurationSeconds': instance.videoDurationSeconds,
  'videoSizeBytes': instance.videoSizeBytes,
  'analysisResult': instance.analysisResult?.toJson(),
  'status': _$SessionStatusEnumMap[instance.status],
  'errorMessage': instance.errorMessage,
};

const _$VideoSourceEnumMap = {
  VideoSource.camera: 'camera',
  VideoSource.gallery: 'gallery',
};

const _$ThrowTechniqueEnumMap = {
  ThrowTechnique.backhand: 'backhand',
  ThrowTechnique.forehand: 'forehand',
  ThrowTechnique.tomahawk: 'tomahawk',
  ThrowTechnique.thumber: 'thumber',
  ThrowTechnique.overhand: 'overhand',
  ThrowTechnique.backhandRoller: 'backhand_roller',
  ThrowTechnique.forehandRoller: 'forehand_roller',
  ThrowTechnique.grenade: 'grenade',
  ThrowTechnique.other: 'other',
};

const _$SessionStatusEnumMap = {
  SessionStatus.created: 'created',
  SessionStatus.uploading: 'uploading',
  SessionStatus.analyzing: 'analyzing',
  SessionStatus.completed: 'completed',
  SessionStatus.failed: 'failed',
};
