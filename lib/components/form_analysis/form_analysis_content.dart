import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/history_analysis_view.dart';

/// Shared component for displaying form analysis content.
///
/// Used by both [AnalysisResultsView] (fresh analysis) and
/// [FormAnalysisDetailScreen] (historical analysis) to ensure consistent
/// display and reduce code duplication.
class FormAnalysisContent extends StatelessWidget {
  const FormAnalysisContent({
    super.key,
    required this.analysis,
    required this.onBack,
    this.topPadding = 0,
    this.poseAnalysisResponse,
  });

  /// The form analysis data to display.
  final FormAnalysisResponseV2 analysis;

  /// Callback when back navigation is triggered.
  final VoidCallback onBack;

  /// Top padding for the content (e.g., for app bar spacing).
  final double topPadding;

  /// Optional pose analysis response for fresh analyses.
  /// Contains video sync metadata for synchronized video playback.
  final FormAnalysisResponseV2? poseAnalysisResponse;

  @override
  Widget build(BuildContext context) {
    return HistoryAnalysisView(
      analysis: analysis,
      onBack: onBack,
      topPadding: topPadding,
      throwType: _parseThrowTechnique(analysis.analysisResults.throwType),
      cameraAngle: analysis.analysisResults.cameraAngle,
      videoAspectRatio: analysis.videoMetadata.videoAspectRatio,
      poseAnalysisResponse: poseAnalysisResponse,
    );
  }

  /// Parse throw technique string to enum.
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
        return null;
    }
  }
}
