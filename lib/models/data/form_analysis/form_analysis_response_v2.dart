import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/analysis_results.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/analysis_warning.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/arm_speed_data.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observations.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observations_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/frame_pose_data_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_comparison_config.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/video_metadata.dart';
import 'package:turbo_disc_golf/models/pose_model.dart';

part 'form_analysis_response_v2.g.dart';

/// Unified V2 model for form analysis
/// Works as both API response format AND Firestore storage format
/// Replaces PoseAnalysisResponse and FormAnalysisRecord
@JsonSerializable(explicitToJson: true)
class FormAnalysisResponseV2 {
  const FormAnalysisResponseV2({
    this.version = 'v2',
    this.sessionId,
    this.status,
    this.id,
    this.uid,
    this.createdAt,
    required this.videoMetadata,
    required this.analysisResults,
    required this.checkpoints,
    this.proComparisonConfig,
    this.framePoses,
    this.formObservations,
    this.formObservationsV2,
    this.armSpeed,
    this.poseModel,
    this.warnings = const [],
  });

  /// Version identifier (always "v2" for new format)
  final String version;

  // ==================== API-only fields ====================
  // These are null when loaded from Firestore

  /// Session ID from backend (API only)
  @JsonKey(name: 'session_id')
  final String? sessionId;

  /// Status from backend: "completed", "error", etc. (API only)
  final String? status;

  // ==================== Firestore-only fields ====================
  // These are null in API response, set during save

  /// Firestore document ID (Firestore only)
  final String? id;

  /// User ID (Firestore only)
  final String? uid;

  /// ISO 8601 timestamp when analysis was created (Firestore only)
  @JsonKey(name: 'created_at')
  final String? createdAt;

  // ==================== Shared fields ====================
  // Present in both API response and Firestore

  /// Video files and technical metadata
  @JsonKey(name: 'video_metadata')
  final VideoMetadata videoMetadata;

  /// Overall analysis results
  @JsonKey(name: 'analysis_results')
  final AnalysisResults analysisResults;

  /// Checkpoint data
  final List<CheckpointDataV2> checkpoints;

  /// Pro comparison configuration (optional)
  @JsonKey(name: 'pro_comparison_config')
  final ProComparisonConfig? proComparisonConfig;

  /// Compressed frame-by-frame pose data (optional)
  /// Stored in both API response and Firestore
  @JsonKey(name: 'frame_poses')
  final List<FramePoseDataV2>? framePoses;

  /// Form observations detected during analysis (optional)
  /// Contains AI-detected observations about the user's throwing form
  @JsonKey(name: 'form_observations')
  final FormObservations? formObservations;

  /// V2 form observations with named fields per observation type (optional)
  /// Provides typed access to each observation by its identifier
  /// Maps observation IDs to named fields for easier UI binding
  @JsonKey(name: 'form_observations_v2')
  final FormObservationsV2? formObservationsV2;

  /// Arm speed data from side-view video analysis (optional)
  /// Contains speed measurements over frames during the throwing motion
  @JsonKey(name: 'arm_speed')
  final ArmSpeedData? armSpeed;

  @JsonKey(name: 'pose_model')
  final PoseModel? poseModel;

  @JsonKey(name: 'warnings')
  final List<AnalysisWarning> warnings;

  /// Calculate worst deviation severity from checkpoints
  static String? calculateWorstSeverity(List<CheckpointDataV2> checkpoints) {
    if (checkpoints.isEmpty) return null;

    const List<String> severityOrder = [
      'good',
      'minor',
      'moderate',
      'significant',
    ];

    String? worstSeverity;
    int worstIndex = -1;

    for (final CheckpointDataV2 checkpoint in checkpoints) {
      final int index = severityOrder.indexOf(
        checkpoint.deviationAnalysis.severity.toLowerCase(),
      );
      if (index > worstIndex) {
        worstIndex = index;
        worstSeverity = checkpoint.deviationAnalysis.severity;
      }
    }

    return worstSeverity;
  }

  /// Aggregate top coaching tips from all checkpoints
  static List<String> aggregateTopTips(
    List<CheckpointDataV2> checkpoints, {
    int maxTips = 3,
  }) {
    final Map<String, int> tipFrequency = {};

    // Count tip occurrences across all checkpoints
    for (final CheckpointDataV2 checkpoint in checkpoints) {
      for (final String tip in checkpoint.coachingTips) {
        tipFrequency[tip] = (tipFrequency[tip] ?? 0) + 1;
      }
    }

    // Sort by frequency and take top N
    final List<MapEntry<String, int>> sortedTips = tipFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTips.take(maxTips).map((e) => e.key).toList();
  }

  factory FormAnalysisResponseV2.fromJson(Map<String, dynamic> json) =>
      _$FormAnalysisResponseV2FromJson(json);
  Map<String, dynamic> toJson() => _$FormAnalysisResponseV2ToJson(this);
}
