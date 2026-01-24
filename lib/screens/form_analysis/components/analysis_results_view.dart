import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_result.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/history_analysis_view.dart';

/// View displaying the complete form analysis results.
/// Converts PoseAnalysisResponse to FormAnalysisRecord format and uses HistoryAnalysisView for display.
class AnalysisResultsView extends StatelessWidget {
  const AnalysisResultsView({
    super.key,
    this.result,
    this.poseAnalysis,
    required this.topViewPadding,
  });

  final FormAnalysisResult? result;
  final PoseAnalysisResponse? poseAnalysis;
  final double topViewPadding;

  @override
  Widget build(BuildContext context) {
    if (poseAnalysis == null) {
      return const Center(child: Text('No pose analysis data available'));
    }

    // Extract top coaching tips from result if available
    final List<String>? topCoachingTips =
        result != null && result!.prioritizedImprovements.isNotEmpty
            ? result!.prioritizedImprovements
                  .map((imp) => imp.description)
                  .toList()
            : null;

    // Convert PoseAnalysisResponse to FormAnalysisRecord format
    final FormAnalysisRecord analysisRecord = poseAnalysis!.toFormAnalysisRecord(
      topCoachingTips: topCoachingTips,
    );

    // Use HistoryAnalysisView to display (no-op for onBack since we're in fresh analysis)
    // Add 48px for GenericAppBar height since FormAnalysisRecordingScreen uses extendBodyBehindAppBar
    const double appBarHeight = 48.0;
    return HistoryAnalysisView(
      analysis: analysisRecord,
      onBack: () {}, // No-op for fresh analysis
      topPadding: topViewPadding + appBarHeight,
      // Pass video data for video comparison feature
      videoUrl: poseAnalysis!.videoUrl,
      throwType: _parseThrowTechnique(poseAnalysis!.throwType),
      cameraAngle: poseAnalysis!.cameraAngle,
      videoAspectRatio: poseAnalysis!.videoAspectRatio,
      // Pass full pose analysis for video sync metadata
      poseAnalysisResponse: poseAnalysis,
    );
  }

  /// Parse throw technique string to enum (for video comparison feature)
  ThrowTechnique? _parseThrowTechnique(String throwTypeStr) {
    final String lowerCase = throwTypeStr.toLowerCase();
    switch (lowerCase) {
      case 'backhand':
        return ThrowTechnique.backhand;
      case 'forehand':
        return ThrowTechnique.forehand;
      case 'tomahawk':
        return ThrowTechnique.tomahawk;
      case 'thumber':
        return ThrowTechnique.thumber;
      case 'overhand':
        return ThrowTechnique.overhand;
      default:
        return null; // Unknown throw type
    }
  }
}
