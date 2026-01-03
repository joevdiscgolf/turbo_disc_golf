import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';

part 'round_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class DGRound {
  const DGRound({
    required this.uid,
    required this.id,
    required this.courseName,
    required this.courseId,
    required this.course,
    required this.layoutId,
    required this.holes,
    this.analysis,
    this.aiSummary,
    this.aiCoachSuggestion,
    this.versionId = 1,
    required this.createdAt,
    required this.playedRoundAt,
  });

  final String uid;
  final String id;
  final String courseId;
  final String courseName;
  final Course course;
  final String layoutId;
  final List<DGHole> holes;
  final RoundAnalysis? analysis;
  final AIContent? aiSummary;
  final AIContent? aiCoachSuggestion;
  final int versionId;
  final String createdAt;
  final String playedRoundAt;

  factory DGRound.fromJson(Map<String, dynamic> json) =>
      _$DGRoundFromJson(json);

  Map<String, dynamic> toJson() => _$DGRoundToJson(this);

  /// Check if AI summary is out of date with the current round version
  bool get isAISummaryOutdated {
    if (aiSummary == null) return false;
    return aiSummary!.roundVersionId != versionId;
  }

  /// Check if AI coaching is out of date with the current round version
  bool get isAICoachingOutdated {
    if (aiCoachSuggestion == null) return false;
    return aiCoachSuggestion!.roundVersionId != versionId;
  }

  int getTotalScore() {
    return holes.fold(0, (total, hole) {
      // Only count holes that have throws
      if (hole.throws.isEmpty) return total;
      return total + hole.holeScore;
    });
  }

  int getTotalPar() {
    return holes.fold(0, (total, hole) {
      // Only count holes that have throws
      if (hole.throws.isEmpty) return total;
      return total + hole.par;
    });
  }

  int getRelativeToPar() {
    return getTotalScore() - getTotalPar();
  }

  /// Get the layout that was played in this round
  CourseLayout get playedLayout {
    return course.getLayoutById(layoutId) ?? course.defaultLayout;
  }

  /// Create a copy of this round with updated fields
  DGRound copyWith({
    String? id,
    String? courseName,
    String? courseId,
    Course? course,
    String? layoutId,
    List<DGHole>? holes,
    RoundAnalysis? analysis,
    AIContent? aiSummary,
    AIContent? aiCoachSuggestion,
    int? versionId,
    String? createdAt,
    String? playedRoundAt,
  }) {
    return DGRound(
      uid: uid,
      id: id ?? this.id,
      courseName: courseName ?? this.courseName,
      courseId: courseId ?? this.courseId,
      course: course ?? this.course,
      layoutId: layoutId ?? this.layoutId,
      holes: holes ?? this.holes,
      analysis: analysis ?? this.analysis,
      aiSummary: aiSummary ?? this.aiSummary,
      aiCoachSuggestion: aiCoachSuggestion ?? this.aiCoachSuggestion,
      versionId: versionId ?? this.versionId,
      createdAt: createdAt ?? this.createdAt,
      playedRoundAt: playedRoundAt ?? this.playedRoundAt,
    );
  }
}
