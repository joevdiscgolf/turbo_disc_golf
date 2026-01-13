// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_analysis_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormAnalysisRecord _$FormAnalysisRecordFromJson(Map<String, dynamic> json) =>
    FormAnalysisRecord(
      id: json['id'] as String,
      uid: json['uid'] as String,
      createdAt: json['created_at'] as String,
      throwType: json['throw_type'] as String,
      checkpoints: (json['checkpoints'] as List<dynamic>)
          .map((e) => CheckpointRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallFormScore: (json['overall_form_score'] as num?)?.toInt(),
      worstDeviationSeverity: json['worst_deviation_severity'] as String?,
      topCoachingTips: (json['top_coaching_tips'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$FormAnalysisRecordToJson(FormAnalysisRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uid': instance.uid,
      'created_at': instance.createdAt,
      'throw_type': instance.throwType,
      'overall_form_score': instance.overallFormScore,
      'worst_deviation_severity': instance.worstDeviationSeverity,
      'checkpoints': instance.checkpoints.map((e) => e.toJson()).toList(),
      'top_coaching_tips': instance.topCoachingTips,
    };

CheckpointRecord _$CheckpointRecordFromJson(Map<String, dynamic> json) =>
    CheckpointRecord(
      checkpointId: json['checkpoint_id'] as String,
      checkpointName: json['checkpoint_name'] as String,
      deviationSeverity: json['deviation_severity'] as String,
      coachingTips: (json['coaching_tips'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      angleDeviations: (json['angle_deviations'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      userImageUrl: json['user_image_url'] as String?,
      userSkeletonUrl: json['user_skeleton_url'] as String?,
      referenceImageUrl: json['reference_image_url'] as String?,
      referenceSkeletonUrl: json['reference_skeleton_url'] as String?,
    );

Map<String, dynamic> _$CheckpointRecordToJson(CheckpointRecord instance) =>
    <String, dynamic>{
      'checkpoint_id': instance.checkpointId,
      'checkpoint_name': instance.checkpointName,
      'deviation_severity': instance.deviationSeverity,
      'coaching_tips': instance.coachingTips,
      'angle_deviations': instance.angleDeviations,
      'user_image_url': instance.userImageUrl,
      'user_skeleton_url': instance.userSkeletonUrl,
      'reference_image_url': instance.referenceImageUrl,
      'reference_skeleton_url': instance.referenceSkeletonUrl,
    };
