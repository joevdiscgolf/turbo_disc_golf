// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoMetadata _$VideoMetadataFromJson(Map<String, dynamic> json) =>
    VideoMetadata(
      videoUrl: json['video_url'] as String?,
      videoStoragePath: json['video_storage_path'] as String?,
      skeletonVideoUrl: json['skeleton_video_url'] as String?,
      skeletonOnlyVideoUrl: json['skeleton_only_video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      videoDurationSeconds: (json['video_duration_seconds'] as num).toDouble(),
      totalFrames: (json['total_frames'] as num).toInt(),
      videoWidth: (json['video_width'] as num?)?.toInt(),
      videoHeight: (json['video_height'] as num?)?.toInt(),
      videoOrientation: $enumDecodeNullable(
        _$VideoOrientationEnumMap,
        json['video_orientation'],
      ),
      videoAspectRatio: (json['video_aspect_ratio'] as num?)?.toDouble(),
      returnedVideoAspectRatio: (json['returned_video_aspect_ratio'] as num?)
          ?.toDouble(),
    );

Map<String, dynamic> _$VideoMetadataToJson(VideoMetadata instance) =>
    <String, dynamic>{
      'video_url': instance.videoUrl,
      'video_storage_path': instance.videoStoragePath,
      'skeleton_video_url': instance.skeletonVideoUrl,
      'skeleton_only_video_url': instance.skeletonOnlyVideoUrl,
      'thumbnail_url': instance.thumbnailUrl,
      'video_duration_seconds': instance.videoDurationSeconds,
      'total_frames': instance.totalFrames,
      'video_width': instance.videoWidth,
      'video_height': instance.videoHeight,
      'video_orientation': _$VideoOrientationEnumMap[instance.videoOrientation],
      'video_aspect_ratio': instance.videoAspectRatio,
      'returned_video_aspect_ratio': instance.returnedVideoAspectRatio,
    };

const _$VideoOrientationEnumMap = {
  VideoOrientation.portrait: 'portrait',
  VideoOrientation.landscape: 'landscape',
};
