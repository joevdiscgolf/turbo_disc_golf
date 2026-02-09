// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TurboUser _$TurboUserFromJson(Map json) => TurboUser(
  username: json['username'] as String,
  keywords: (json['keywords'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  displayName: json['displayName'] as String,
  uid: json['uid'] as String,
  pdgaMetadata: json['pdgaMetadata'] == null
      ? null
      : PDGAMetadata.fromJson(
          Map<String, dynamic>.from(json['pdgaMetadata'] as Map),
        ),
  eventIds: (json['eventIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  isAdmin: json['isAdmin'] as bool?,
  trebuchets: (json['trebuchets'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  flags: (json['flags'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$TurboUserToJson(TurboUser instance) => <String, dynamic>{
  'username': instance.username,
  'keywords': instance.keywords,
  'displayName': instance.displayName,
  'uid': instance.uid,
  'pdgaMetadata': instance.pdgaMetadata?.toJson(),
  'eventIds': instance.eventIds,
  'isAdmin': instance.isAdmin,
  'trebuchets': instance.trebuchets,
  'flags': instance.flags,
};

TurboUserMetadata _$TurboUserMetadataFromJson(Map json) => TurboUserMetadata(
  username: json['username'] as String,
  displayName: json['displayName'] as String,
  uid: json['uid'] as String,
  pdgaMetadata: json['pdgaMetadata'] == null
      ? null
      : PDGAMetadata.fromJson(
          Map<String, dynamic>.from(json['pdgaMetadata'] as Map),
        ),
);

Map<String, dynamic> _$TurboUserMetadataToJson(TurboUserMetadata instance) =>
    <String, dynamic>{
      'username': instance.username,
      'displayName': instance.displayName,
      'uid': instance.uid,
      'pdgaMetadata': instance.pdgaMetadata?.toJson(),
    };
