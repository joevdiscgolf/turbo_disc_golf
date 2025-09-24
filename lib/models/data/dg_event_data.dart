import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';

part 'dg_event_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class DGEvent {
  const DGEvent({required this.eventName, required this.rounds});

  final String eventName;
  final List<DGRound> rounds;

  factory DGEvent.fromJson(Map<String, dynamic> json) =>
      _$DGEventFromJson(json);

  Map<String, dynamic> toJson() => _$DGEventToJson(this);
}
