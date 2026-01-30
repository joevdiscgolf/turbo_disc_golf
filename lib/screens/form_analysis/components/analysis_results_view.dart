import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_result.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/history_analysis_view.dart';

/// View displaying the complete form analysis results.
/// Uses FormAnalysisResponseV2 (unified model) and passes to HistoryAnalysisView for display.
class AnalysisResultsView extends StatelessWidget {
  const AnalysisResultsView({
    super.key,
    this.result,
    this.poseAnalysis,
    required this.topViewPadding,
  });

  final FormAnalysisResult? result;
  final FormAnalysisResponseV2? poseAnalysis;
  final double topViewPadding;

  @override
  Widget build(BuildContext context) {
    if (poseAnalysis == null) {
      return const Center(child: Text('No pose analysis data available'));
    }

    // FormAnalysisResponseV2 is the unified model - use it directly
    // Use HistoryAnalysisView to display (no-op for onBack since we're in fresh analysis)
    // Add 48px for GenericAppBar height since FormAnalysisRecordingScreen uses extendBodyBehindAppBar
    const double appBarHeight = 48.0;
    return HistoryAnalysisView(
      analysis: poseAnalysis!,
      onBack: () {}, // No-op for fresh analysis
      topPadding: topViewPadding + appBarHeight,
      // Pass video data for video comparison feature
      videoUrl: poseAnalysis!.videoMetadata.videoUrl,
      throwType: _parseThrowTechnique(poseAnalysis!.analysisResults.throwType),
      cameraAngle: poseAnalysis!.analysisResults.cameraAngle,
      videoAspectRatio: poseAnalysis!.videoMetadata.videoAspectRatio,
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
