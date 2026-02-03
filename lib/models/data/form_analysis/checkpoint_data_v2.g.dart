// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkpoint_data_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckpointDataV2 _$CheckpointDataV2FromJson(Map<String, dynamic> json) =>
    CheckpointDataV2(
      metadata: CheckpointMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      userPose: UserPoseData.fromJson(
        json['user_pose'] as Map<String, dynamic>,
      ),
      proReferencePose: json['pro_reference_pose'] == null
          ? null
          : ProReferencePoseData.fromJson(
              json['pro_reference_pose'] as Map<String, dynamic>,
            ),
      deviationAnalysis: DeviationAnalysis.fromJson(
        json['deviation_analysis'] as Map<String, dynamic>,
      ),
      userAlignmentMetadata: json['user_alignment_metadata'] == null
          ? null
          : UserAlignmentMetadata.fromJson(
              json['user_alignment_metadata'] as Map<String, dynamic>,
            ),
      coachingTips: (json['coaching_tips'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CheckpointDataV2ToJson(CheckpointDataV2 instance) =>
    <String, dynamic>{
      'metadata': instance.metadata.toJson(),
      'user_pose': instance.userPose.toJson(),
      'pro_reference_pose': instance.proReferencePose?.toJson(),
      'deviation_analysis': instance.deviationAnalysis.toJson(),
      'user_alignment_metadata': instance.userAlignmentMetadata?.toJson(),
      'coaching_tips': instance.coachingTips,
    };
