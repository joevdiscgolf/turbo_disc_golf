import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';

part 'round_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class DGRound {
  const DGRound({
    required this.id,
    required this.courseName,
    this.courseId,
    required this.holes,
    this.analysis,
    this.aiSummary,
    this.aiCoachSuggestion,
  });

  final String id;
  final String? courseId;
  final String courseName;
  final List<DGHole> holes;
  final RoundAnalysis? analysis;
  final String? aiSummary;
  final String? aiCoachSuggestion;

  factory DGRound.fromJson(Map<String, dynamic> json) =>
      _$DGRoundFromJson(json);

  Map<String, dynamic> toJson() => _$DGRoundToJson(this);
}
