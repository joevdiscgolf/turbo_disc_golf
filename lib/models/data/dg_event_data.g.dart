// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dg_event_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DGEvent _$DGEventFromJson(Map json) => DGEvent(
  eventName: json['eventName'] as String,
  rounds: (json['rounds'] as List<dynamic>)
      .map((e) => DGRound.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(),
);

Map<String, dynamic> _$DGEventToJson(DGEvent instance) => <String, dynamic>{
  'eventName': instance.eventName,
  'rounds': instance.rounds.map((e) => e.toJson()).toList(),
};
