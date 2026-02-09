import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/user_data/pdga_metadata.dart';

part 'user_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class TurboUser extends Equatable {
  const TurboUser({
    required this.username,
    required this.keywords,
    required this.displayName,
    required this.uid,
    this.pdgaMetadata,
    this.eventIds,
    this.isAdmin,
    this.trebuchets,
    this.flags,
  });

  final String username;
  final List<String> keywords;
  final String displayName;
  final String uid;
  final PDGAMetadata? pdgaMetadata;
  final List<String>? eventIds;
  final bool? isAdmin;
  final List<String>? trebuchets;
  final List<String>? flags;

  TurboUser copyWith({
    String? username,
    List<String>? keywords,
    String? displayName,
    String? uid,
    PDGAMetadata? pdgaMetadata,
    List<String>? eventIds,
    bool? isAdmin,
    List<String>? trebuchets,
    List<String>? flags,
  }) {
    return TurboUser(
      username: username ?? this.username,
      keywords: keywords ?? this.keywords,
      displayName: displayName ?? this.displayName,
      uid: uid ?? this.uid,
      pdgaMetadata: pdgaMetadata ?? this.pdgaMetadata,
      eventIds: eventIds ?? this.eventIds,
      isAdmin: isAdmin ?? this.isAdmin,
      trebuchets: trebuchets ?? this.trebuchets,
      flags: flags ?? this.flags,
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
        pdgaMetadata,
        eventIds,
        isAdmin,
        trebuchets,
        flags,
      ];
}

@JsonSerializable(explicitToJson: true, anyMap: true)
class TurboUserMetadata {
  TurboUserMetadata({
    required this.username,
    required this.displayName,
    required this.uid,
    this.pdgaMetadata,
  });

  final String username;
  final String displayName;
  final String uid;
  final PDGAMetadata? pdgaMetadata;

  factory TurboUserMetadata.fromJson(Map<String, dynamic> json) =>
      _$TurboUserMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$TurboUserMetadataToJson(this);
}
