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

    // Convert PoseAnalysisResponse to FormAnalysisRecord format
    final FormAnalysisRecord analysisRecord = _convertToRecord(poseAnalysis!);

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

  FormAnalysisRecord _convertToRecord(PoseAnalysisResponse poseAnalysis) {
    // Convert checkpoints from CheckpointPoseData to CheckpointRecord
    final List<CheckpointRecord> checkpoints = poseAnalysis.checkpoints.map((
      cp,
    ) {
      // Use base64 as data URLs (they'll be converted inline by the display code)
      final String? userImageUrl = cp.userImageBase64 != null
          ? 'data:image/jpeg;base64,${cp.userImageBase64}'
          : null;
      final String? userSkeletonUrl = cp.userSkeletonOnlyBase64 != null
          ? 'data:image/jpeg;base64,${cp.userSkeletonOnlyBase64}'
          : null;
      final String? referenceImageUrl =
          cp.referenceSilhouetteWithSkeletonBase64 != null
          ? 'data:image/jpeg;base64,${cp.referenceSilhouetteWithSkeletonBase64}'
          : (cp.referenceImageBase64 != null
                ? 'data:image/jpeg;base64,${cp.referenceImageBase64}'
                : null);
      final String? referenceSkeletonUrl =
          cp.referenceSkeletonOnlyBase64 != null
          ? 'data:image/jpeg;base64,${cp.referenceSkeletonOnlyBase64}'
          : null;

      // Convert angle deviations from AngleDeviations object to Map
      final Map<String, double> angleDeviations = {};
      if (cp.deviationsRaw.shoulderRotation != null) {
        angleDeviations['shoulder_rotation'] =
            cp.deviationsRaw.shoulderRotation!;
      }
      if (cp.deviationsRaw.elbowAngle != null) {
        angleDeviations['elbow_angle'] = cp.deviationsRaw.elbowAngle!;
      }
      if (cp.deviationsRaw.hipRotation != null) {
        angleDeviations['hip_rotation'] = cp.deviationsRaw.hipRotation!;
      }
      if (cp.deviationsRaw.kneeBend != null) {
        angleDeviations['knee_bend'] = cp.deviationsRaw.kneeBend!;
      }
      if (cp.deviationsRaw.spineTilt != null) {
        angleDeviations['spine_tilt'] = cp.deviationsRaw.spineTilt!;
      }

      return CheckpointRecord(
        checkpointId: cp.checkpointId,
        checkpointName: cp.checkpointName,
        deviationSeverity: cp.deviationSeverity,
        coachingTips: cp.coachingTips,
        angleDeviations: angleDeviations.isNotEmpty ? angleDeviations : null,
        userImageUrl: userImageUrl,
        userSkeletonUrl: userSkeletonUrl,
        referenceImageUrl: referenceImageUrl,
        referenceSkeletonUrl: referenceSkeletonUrl,
        proPlayerId: cp.proPlayerId,
        referenceHorizontalOffsetPercent: cp.referenceHorizontalOffsetPercent,
        referenceScale: cp.referenceScale,
        // Individual joint angles - User
        userLeftKneeBendAngle: cp.userIndividualAngles?.leftKneeBendAngle,
        userRightKneeBendAngle: cp.userIndividualAngles?.rightKneeBendAngle,
        userLeftElbowFlexionAngle:
            cp.userIndividualAngles?.leftElbowFlexionAngle,
        userRightElbowFlexionAngle:
            cp.userIndividualAngles?.rightElbowFlexionAngle,
        userLeftShoulderAbductionAngle:
            cp.userIndividualAngles?.leftShoulderAbductionAngle,
        userRightShoulderAbductionAngle:
            cp.userIndividualAngles?.rightShoulderAbductionAngle,
        userLeftWristExtensionAngle:
            cp.userIndividualAngles?.leftWristExtensionAngle,
        userRightWristExtensionAngle:
            cp.userIndividualAngles?.rightWristExtensionAngle,
        userLeftHipFlexionAngle: cp.userIndividualAngles?.leftHipFlexionAngle,
        userRightHipFlexionAngle: cp.userIndividualAngles?.rightHipFlexionAngle,
        userLeftAnkleAngle: cp.userIndividualAngles?.leftAnkleAngle,
        userRightAnkleAngle: cp.userIndividualAngles?.rightAnkleAngle,
        // Individual joint angles - Reference
        refLeftKneeBendAngle: cp.referenceIndividualAngles?.leftKneeBendAngle,
        refRightKneeBendAngle: cp.referenceIndividualAngles?.rightKneeBendAngle,
        refLeftElbowFlexionAngle:
            cp.referenceIndividualAngles?.leftElbowFlexionAngle,
        refRightElbowFlexionAngle:
            cp.referenceIndividualAngles?.rightElbowFlexionAngle,
        refLeftShoulderAbductionAngle:
            cp.referenceIndividualAngles?.leftShoulderAbductionAngle,
        refRightShoulderAbductionAngle:
            cp.referenceIndividualAngles?.rightShoulderAbductionAngle,
        refLeftWristExtensionAngle:
            cp.referenceIndividualAngles?.leftWristExtensionAngle,
        refRightWristExtensionAngle:
            cp.referenceIndividualAngles?.rightWristExtensionAngle,
        refLeftHipFlexionAngle:
            cp.referenceIndividualAngles?.leftHipFlexionAngle,
        refRightHipFlexionAngle:
            cp.referenceIndividualAngles?.rightHipFlexionAngle,
        refLeftAnkleAngle: cp.referenceIndividualAngles?.leftAnkleAngle,
        refRightAnkleAngle: cp.referenceIndividualAngles?.rightAnkleAngle,
        // Individual joint angle deviations
        devLeftKneeBendAngle: cp.individualDeviations?.leftKneeBendAngle,
        devRightKneeBendAngle: cp.individualDeviations?.rightKneeBendAngle,
        devLeftElbowFlexionAngle:
            cp.individualDeviations?.leftElbowFlexionAngle,
        devRightElbowFlexionAngle:
            cp.individualDeviations?.rightElbowFlexionAngle,
        devLeftShoulderAbductionAngle:
            cp.individualDeviations?.leftShoulderAbductionAngle,
        devRightShoulderAbductionAngle:
            cp.individualDeviations?.rightShoulderAbductionAngle,
        devLeftWristExtensionAngle:
            cp.individualDeviations?.leftWristExtensionAngle,
        devRightWristExtensionAngle:
            cp.individualDeviations?.rightWristExtensionAngle,
        devLeftHipFlexionAngle: cp.individualDeviations?.leftHipFlexionAngle,
        devRightHipFlexionAngle: cp.individualDeviations?.rightHipFlexionAngle,
        devLeftAnkleAngle: cp.individualDeviations?.leftAnkleAngle,
        devRightAnkleAngle: cp.individualDeviations?.rightAnkleAngle,
      );
    }).toList();

    // Calculate worst deviation severity from checkpoints
    final String? worstSeverity = _calculateWorstSeverity(checkpoints);

    return FormAnalysisRecord(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      uid: 'temp',
      createdAt: DateTime.now().toIso8601String(),
      throwType: poseAnalysis.throwType,
      overallFormScore: poseAnalysis.overallFormScore,
      worstDeviationSeverity: worstSeverity,
      checkpoints: checkpoints,
      topCoachingTips:
          result != null && result!.prioritizedImprovements.isNotEmpty
          ? result!.prioritizedImprovements
                .map((imp) => imp.description)
                .toList()
          : null,
      cameraAngle: poseAnalysis.cameraAngle,
      videoOrientation: poseAnalysis.videoOrientation,
      videoAspectRatio: poseAnalysis.videoAspectRatio,
      videoUrl: poseAnalysis.videoUrl,
    );
  }

  String? _calculateWorstSeverity(List<CheckpointRecord> checkpoints) {
    if (checkpoints.isEmpty) return null;

    const List<String> severityOrder = [
      'good',
      'minor',
      'moderate',
      'significant',
    ];

    String? worstSeverity;
    int worstIndex = -1;

    for (final checkpoint in checkpoints) {
      final int index = severityOrder.indexOf(
        checkpoint.deviationSeverity.toLowerCase(),
      );
      if (index > worstIndex) {
        worstIndex = index;
        worstSeverity = checkpoint.deviationSeverity;
      }
    }

    return worstSeverity;
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
