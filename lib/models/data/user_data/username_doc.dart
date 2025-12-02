import 'package:json_annotation/json_annotation.dart';
part 'username_doc.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class UsernameDocument {
  const UsernameDocument({required this.username, required this.uid});
  final String username;
  final String uid;

  factory UsernameDocument.fromJson(Map<String, dynamic> json) =>
      _$UsernameDocFromJson(json);

  Map<String, dynamic> toJson() => _$UsernameDocToJson(this);
}
