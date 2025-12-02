import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class TurboUser extends Equatable {
  const TurboUser({
    required this.username,
    required this.keywords,
    required this.displayName,
    required this.uid,
    this.pdgaNum,
    this.pdgaRating,
    this.eventIds,
    this.isAdmin,
    this.trebuchets,
  });
  final String username;
  final List<String> keywords;
  final String displayName;
  final String uid;
  final int? pdgaNum;
  final int? pdgaRating;
  final List<String>? eventIds;
  final bool? isAdmin;
  final List<String>? trebuchets;

  TurboUser copyWith({
    String? username,
    List<String>? keywords,
    String? displayName,
    String? uid,
    int? pdgaNum,
    int? pdgaRating,
    List<String>? eventIds,
    bool? isAdmin,
    List<String>? trebuchets,
  }) {
    return TurboUser(
      username: username ?? this.username,
      keywords: keywords ?? this.keywords,
      displayName: displayName ?? this.displayName,
      uid: uid ?? this.uid,
      pdgaNum: pdgaNum ?? this.pdgaNum,
      pdgaRating: pdgaRating ?? this.pdgaRating,

      eventIds: eventIds ?? this.eventIds,
      isAdmin: isAdmin ?? this.isAdmin,
      trebuchets: trebuchets ?? this.trebuchets,
    );
  }

  factory TurboUser.fromJson(Map<String, dynamic> json) =>
      _$TurboUserFromJson(json);

  Map<String, dynamic> toJson() => _$TurboUserToJson(this);

  @override
  List<Object?> get props => [
    username,
    keywords,
    displayName,
    uid,
    pdgaNum,
    pdgaRating,
    eventIds,
    isAdmin,
    trebuchets,
  ];
}

@JsonSerializable(explicitToJson: true, anyMap: true)
class TurboUserMetadata {
  TurboUserMetadata({
    required this.username,
    required this.displayName,
    required this.uid,
    this.pdgaNum,
    this.pdgaRating,
  });
  final String username;
  final String displayName;
  final String uid;
  int? pdgaNum;
  int? pdgaRating;

  factory TurboUserMetadata.fromJson(Map<String, dynamic> json) =>
      _$TurboUserMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$TurboUserMetadataToJson(this);
}
