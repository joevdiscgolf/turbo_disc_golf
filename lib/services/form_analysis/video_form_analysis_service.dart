import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_result.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_checkpoint.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/form_analysis/form_reference_positions.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

/// Service that orchestrates video form analysis.
/// Handles video validation, Gemini API calls, and result parsing.
class VideoFormAnalysisService implements ClearOnLogoutProtocol {
  VideoFormAnalysisService();

  // Video constraints
  static const int maxVideoSizeBytes = 20 * 1024 * 1024; // 20MB
  static const int maxVideoDurationSeconds = 30;
  static const int minVideoDurationSeconds = 2;
  static const List<String> supportedFormats = [
    'mp4',
    'mov',
    'avi',
    'webm',
    'm4v',
    '3gp',
  ];

  /// Validate video file before processing
  Future<VideoValidationResult> validateVideo(String videoPath) async {
    final File videoFile = File(videoPath);

    if (!await videoFile.exists()) {
      return const VideoValidationResult(
        isValid: false,
        errorMessage: 'Video file not found',
      );
    }

    final int fileSize = await videoFile.length();
    if (fileSize > maxVideoSizeBytes) {
      final int maxMb = maxVideoSizeBytes ~/ (1024 * 1024);
      return VideoValidationResult(
        isValid: false,
        errorMessage: 'Video is too large. Maximum size is ${maxMb}MB',
      );
    }

    final String extension = videoPath.split('.').last.toLowerCase();
    if (!supportedFormats.contains(extension)) {
      return VideoValidationResult(
        isValid: false,
        errorMessage:
            'Unsupported video format. Supported: ${supportedFormats.join(', ')}',
      );
    }

    return VideoValidationResult(isValid: true, fileSize: fileSize);
  }

  /// Analyze a video for throwing form
  ///
  /// If [poseAnalysis] is provided, the pose detection data (angles, deviations)
  /// will be included in the Gemini prompt for more accurate feedback.
  Future<FormAnalysisResult?> analyzeVideo({
    required String videoPath,
    required ThrowTechnique throwType,
    PoseAnalysisResponse? poseAnalysis,
    void Function(String)? onProgressUpdate,
  }) async {
    final GeminiService geminiService = locator.get<GeminiService>();

    try {
      onProgressUpdate?.call('Validating video...');

      // Validate video first
      final VideoValidationResult validation = await validateVideo(videoPath);
      if (!validation.isValid) {
        debugPrint('Video validation failed: ${validation.errorMessage}');
        return null;
      }

      onProgressUpdate?.call('Preparing analysis...');

      // Get reference positions for the throw type
      final List<FormCheckpoint> checkpoints =
          FormReferencePositions.getCheckpointsForThrowType(throwType);

      // Build the analysis prompt, including pose data if available
      final String prompt = _buildAnalysisPrompt(
        throwType,
        checkpoints,
        poseAnalysis: poseAnalysis,
      );

      onProgressUpdate?.call('Analyzing your form...');

      // Call Gemini with video
      final String? response = await geminiService.generateContentWithVideo(
        prompt: prompt,
        videoPath: videoPath,
      );

      if (response == null) {
        debugPrint('Gemini returned null response');
        return null;
      }

      onProgressUpdate?.call('Processing results...');

      // Parse the response into FormAnalysisResult
      return _parseAnalysisResponse(response, checkpoints);
    } catch (e, stackTrace) {
      debugPrint('Error analyzing video: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  String _buildAnalysisPrompt(
    ThrowTechnique throwType,
    List<FormCheckpoint> checkpoints, {
    PoseAnalysisResponse? poseAnalysis,
  }) {
    final String throwTypeName = _getThrowTypeName(throwType);
    final String checkpointsDescription = checkpoints.map((FormCheckpoint cp) {
      final String keyPointsText = cp.keyPoints.map((FormKeyPoint kp) {
        final String mistakes = kp.commonMistakes?.join(', ') ?? 'None';
        return '    - ${kp.name}: ${kp.description}\n'
            '      Ideal: ${kp.idealState}\n'
            '      Common mistakes: $mistakes';
      }).join('\n');
      return '''
Checkpoint: ${cp.name} (ID: ${cp.id})
  Description: ${cp.description}
  ${cp.referenceDescription != null ? 'Reference: ${cp.referenceDescription}' : ''}
  Key Points to Evaluate:
$keyPointsText''';
    }).join('\n\n');

    // Build pose analysis section if available
    final String poseDataSection = _buildPoseDataSection(poseAnalysis);

    return '''
You are an expert disc golf coach analyzing a player's $throwTypeName throwing form.

ANALYSIS FRAMEWORK (Slingshot Disc Golf Methodology):
$checkpointsDescription
$poseDataSection
INSTRUCTIONS:
1. Watch the entire throw sequence carefully
2. For each checkpoint, evaluate all key points
3. Identify the approximate timestamp where each checkpoint occurs
4. Compare the player's form to the ideal positions described
5. Provide specific, actionable feedback

OUTPUT FORMAT (YAML):
Return your analysis in this exact YAML format:

overall_score: [0-100 integer]
overall_feedback: |
  [2-3 sentence summary of the throw, highlighting main strengths and areas for improvement]

checkpoint_results:
  - checkpoint_id: [checkpoint id from the framework]
    checkpoint_name: [checkpoint name]
    score: [0-100 integer]
    timestamp_seconds: [approximate timestamp as float, e.g., 1.5]
    feedback: |
      [specific feedback for this checkpoint - what was good, what needs work]
    comparison_to_reference: |
      [how player compares to ideal position described in reference]
    key_point_results:
      - key_point_id: [key point id]
        key_point_name: [key point name]
        status: [excellent|good|needs_improvement|poor|not_visible]
        observation: |
          [what you observed in the video for this key point]
        suggestion: |
          [specific suggestion for improvement, or null if status is excellent/good]

prioritized_improvements:
  - priority: 1
    checkpoint_id: [related checkpoint id]
    title: [short 3-5 word title for the improvement]
    description: |
      [detailed description of what to improve and why it matters]
    drill_suggestion: |
      [specific drill or practice exercise to address this issue]
  - priority: 2
    checkpoint_id: [checkpoint id]
    title: [title]
    description: |
      [description]
    drill_suggestion: |
      [drill]
  - priority: 3
    checkpoint_id: [checkpoint id]
    title: [title]
    description: |
      [description]
    drill_suggestion: |
      [drill]

CRITICAL RULES:
- Be specific and constructive in feedback - avoid vague statements
- Base scores on observable technique, not throw outcome or distance
- Score breakdown: 90-100=excellent, 75-89=good, 50-74=needs_improvement, below 50=poor
- Prioritize improvements by IMPACT on overall form - fix the biggest issues first
- If a checkpoint or key point is not clearly visible in the video, mark status as "not_visible"
- Always provide 3 prioritized improvements, ordered by importance
- Return ONLY valid YAML - no markdown code blocks, no explanatory text before or after
- Start directly with "overall_score:" as the first line
''';
  }

  String _getThrowTypeName(ThrowTechnique throwType) {
    switch (throwType) {
      case ThrowTechnique.backhand:
        return 'backhand';
      case ThrowTechnique.forehand:
        return 'forehand/sidearm';
      case ThrowTechnique.tomahawk:
        return 'tomahawk';
      case ThrowTechnique.thumber:
        return 'thumber';
      case ThrowTechnique.backhandRoller:
        return 'backhand roller';
      case ThrowTechnique.forehandRoller:
        return 'forehand roller';
      default:
        return 'standard';
    }
  }

  /// Build a section describing pose analysis data for the Gemini prompt
  String _buildPoseDataSection(PoseAnalysisResponse? poseAnalysis) {
    if (poseAnalysis == null || poseAnalysis.checkpoints.isEmpty) {
      return '';
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('\n--- POSE MEASUREMENTS (objective data) ---');

    for (final CheckpointPoseData checkpoint in poseAnalysis.checkpoints) {
      buffer.write('${checkpoint.checkpointName}: ');

      // Compact angle display
      final List<String> angles = [];
      if (checkpoint.userAngles.elbowAngle != null) {
        angles.add('elbow ${checkpoint.userAngles.elbowAngle!.round()}°');
      }
      if (checkpoint.userAngles.hipRotation != null) {
        angles.add('hip ${checkpoint.userAngles.hipRotation!.round()}°');
      }
      buffer.writeln(angles.join(', '));

      // Compact deviations - only show issues
      final List<String> issues = [];
      for (final AngleDeviation dev in checkpoint.deviations) {
        if (!dev.withinTolerance && dev.deviation != null) {
          issues.add('${dev.angleName} ${dev.deviation!.round()}° off');
        }
      }
      if (issues.isNotEmpty) {
        buffer.writeln('  Issues: ${issues.join(', ')}');
      }
    }

    if (poseAnalysis.overallFormScore != null) {
      buffer.writeln('Pose score: ${poseAnalysis.overallFormScore}/100');
    }
    buffer.writeln('---');

    return buffer.toString();
  }

  FormAnalysisResult? _parseAnalysisResponse(
    String response,
    List<FormCheckpoint> checkpoints,
  ) {
    try {
      // Clean up the response - remove markdown code blocks if present
      String cleanedResponse = response.trim();
      if (cleanedResponse.startsWith('```yaml')) {
        cleanedResponse = cleanedResponse.substring(7);
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse =
            cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      // Parse YAML
      final dynamic yaml = loadYaml(cleanedResponse);
      if (yaml == null || yaml is! Map) {
        debugPrint('Failed to parse YAML response: not a valid map');
        return null;
      }

      final Map<dynamic, dynamic> yamlMap = yaml;

      // Extract overall score and feedback
      final int overallScore =
          _parseIntSafely(yamlMap['overall_score'], defaultValue: 0);
      final String overallFeedback =
          _parseStringSafely(yamlMap['overall_feedback']);

      // Parse checkpoint results
      final List<CheckpointAnalysisResult> checkpointResults = [];
      final dynamic checkpointResultsYaml = yamlMap['checkpoint_results'];
      if (checkpointResultsYaml is List) {
        for (final dynamic cpResult in checkpointResultsYaml) {
          if (cpResult is Map) {
            final CheckpointAnalysisResult? parsed =
                _parseCheckpointResult(cpResult);
            if (parsed != null) {
              checkpointResults.add(parsed);
            }
          }
        }
      }

      // Parse prioritized improvements
      final List<FormImprovement> improvements = [];
      final dynamic improvementsYaml = yamlMap['prioritized_improvements'];
      if (improvementsYaml is List) {
        for (final dynamic imp in improvementsYaml) {
          if (imp is Map) {
            final FormImprovement? parsed = _parseImprovement(imp);
            if (parsed != null) {
              improvements.add(parsed);
            }
          }
        }
      }

      // Sort improvements by priority
      improvements.sort((a, b) => a.priority.compareTo(b.priority));

      return FormAnalysisResult(
        id: const Uuid().v4(),
        sessionId: '', // Will be set by caller
        createdAt: DateTime.now().toIso8601String(),
        checkpointResults: checkpointResults,
        overallScore: overallScore,
        overallFeedback: overallFeedback,
        prioritizedImprovements: improvements,
        rawGeminiResponse: response,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing analysis response: $e');
      debugPrint(stackTrace.toString());
      debugPrint('Raw response: $response');
      return null;
    }
  }

  CheckpointAnalysisResult? _parseCheckpointResult(
    Map<dynamic, dynamic> cpResult,
  ) {
    try {
      final String checkpointId =
          _parseStringSafely(cpResult['checkpoint_id']);
      final String checkpointName =
          _parseStringSafely(cpResult['checkpoint_name']);
      final int score =
          _parseIntSafely(cpResult['score'], defaultValue: 0);
      final String feedback = _parseStringSafely(cpResult['feedback']);
      final double? timestampSeconds =
          _parseDoubleSafely(cpResult['timestamp_seconds']);
      final String? comparisonToReference =
          cpResult['comparison_to_reference']?.toString();

      // Parse key point results
      final List<KeyPointResult> keyPointResults = [];
      final dynamic keyPointsYaml = cpResult['key_point_results'];
      if (keyPointsYaml is List) {
        for (final dynamic kpResult in keyPointsYaml) {
          if (kpResult is Map) {
            final KeyPointResult? parsed = _parseKeyPointResult(kpResult);
            if (parsed != null) {
              keyPointResults.add(parsed);
            }
          }
        }
      }

      return CheckpointAnalysisResult(
        checkpointId: checkpointId,
        checkpointName: checkpointName,
        score: score,
        feedback: feedback,
        keyPointResults: keyPointResults,
        timestampSeconds: timestampSeconds,
        comparisonToReference: comparisonToReference,
      );
    } catch (e) {
      debugPrint('Error parsing checkpoint result: $e');
      return null;
    }
  }

  KeyPointResult? _parseKeyPointResult(Map<dynamic, dynamic> kpResult) {
    try {
      final String keyPointId = _parseStringSafely(kpResult['key_point_id']);
      final String keyPointName =
          _parseStringSafely(kpResult['key_point_name']);
      final String statusStr = _parseStringSafely(kpResult['status']);
      final String observation = _parseStringSafely(kpResult['observation']);
      final String? suggestion = kpResult['suggestion']?.toString();

      final KeyPointStatus status = _parseKeyPointStatus(statusStr);

      return KeyPointResult(
        keyPointId: keyPointId,
        keyPointName: keyPointName,
        status: status,
        observation: observation,
        suggestion: suggestion,
      );
    } catch (e) {
      debugPrint('Error parsing key point result: $e');
      return null;
    }
  }

  KeyPointStatus _parseKeyPointStatus(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'excellent':
        return KeyPointStatus.excellent;
      case 'good':
        return KeyPointStatus.good;
      case 'needs_improvement':
        return KeyPointStatus.needsImprovement;
      case 'poor':
        return KeyPointStatus.poor;
      case 'not_visible':
        return KeyPointStatus.notVisible;
      default:
        return KeyPointStatus.needsImprovement;
    }
  }

  FormImprovement? _parseImprovement(Map<dynamic, dynamic> imp) {
    try {
      final int priority =
          _parseIntSafely(imp['priority'], defaultValue: 99);
      final String checkpointId =
          _parseStringSafely(imp['checkpoint_id']);
      final String title = _parseStringSafely(imp['title']);
      final String description = _parseStringSafely(imp['description']);
      final String drillSuggestion =
          _parseStringSafely(imp['drill_suggestion']);

      return FormImprovement(
        priority: priority,
        checkpointId: checkpointId,
        title: title,
        description: description,
        drillSuggestion: drillSuggestion,
      );
    } catch (e) {
      debugPrint('Error parsing improvement: $e');
      return null;
    }
  }

  int _parseIntSafely(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  double? _parseDoubleSafely(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  String _parseStringSafely(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  @override
  Future<void> clearOnLogout() async {
    // Clear any cached analysis sessions if needed
  }
}

/// Result of video validation
class VideoValidationResult {
  const VideoValidationResult({
    required this.isValid,
    this.errorMessage,
    this.fileSize,
  });

  final bool isValid;
  final String? errorMessage;
  final int? fileSize;
}
