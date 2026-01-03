import 'package:json_annotation/json_annotation.dart';

part 'course_search_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class CourseSearchHit {
  final String id;
  final String name;
  final String? city;
  final String? state;
  final List<CourseLayoutSummary> layouts;

  CourseSearchHit({
    required this.id,
    required this.name,
    this.city,
    this.state,
    required this.layouts,
  });

  factory CourseSearchHit.fromJson(Map<String, dynamic> json) =>
      _$CourseSearchHitFromJson(json);

  Map<String, dynamic> toJson() => _$CourseSearchHitToJson(this);
}

@JsonSerializable(explicitToJson: true, anyMap: true)
class CourseLayoutSummary {
  final String id;
  final String name;
  final int holeCount;
  final int par;
  final int totalFeet;
  final bool isDefault;
  final String? description;

  CourseLayoutSummary({
    required this.id,
    required this.name,
    required this.holeCount,
    required this.par,
    required this.totalFeet,
    required this.isDefault,
    this.description,
  });

  factory CourseLayoutSummary.fromJson(Map<String, dynamic> json) =>
      _$CourseLayoutSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$CourseLayoutSummaryToJson(this);
}
