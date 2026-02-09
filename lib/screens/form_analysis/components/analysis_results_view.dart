import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/form_analysis/form_analysis_content.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_result.dart';

/// View displaying the complete form analysis results.
/// Uses FormAnalysisResponseV2 (unified model) and passes to FormAnalysisContent for display.
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

    // Add 48px for GenericAppBar height since FormAnalysisRecordingScreen uses extendBodyBehindAppBar
    const double appBarHeight = 48.0;

    return FormAnalysisContent(
      analysis: poseAnalysis!,
      onBack: () {}, // No-op for fresh analysis
      topPadding: topViewPadding + appBarHeight,
      poseAnalysisResponse: poseAnalysis,
    );
  }
}
