import 'dart:convert';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_checkpoint.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

/// Hardcoded reference positions based on Slingshot disc golf methodology.
///
/// To update with Slingshot rules:
/// 1. Edit the [backhandCheckpoints] list for backhand throws
/// 2. Edit the [forehandCheckpoints] list for forehand throws
/// 3. Each checkpoint has:
///    - id: unique identifier (e.g., 'reachback')
///    - name: display name (e.g., 'Reachback Position')
///    - description: what this checkpoint represents
///    - keyPoints: list of specific things to evaluate
///    - orderIndex: order in throwing sequence (0 = first)
///    - referenceDescription: ideal position description for AI prompt
///
/// Each keyPoint has:
///    - id: unique identifier
///    - name: display name
///    - description: what to look for
///    - idealState: description of perfect form
///    - commonMistakes: list of typical errors
class FormReferencePositions {
  FormReferencePositions._();

  /// Get checkpoints for a specific throw type
  static List<FormCheckpoint> getCheckpointsForThrowType(
    ThrowTechnique throwType,
  ) {
    switch (throwType) {
      case ThrowTechnique.backhand:
        return backhandCheckpoints;
      case ThrowTechnique.forehand:
      // return forehandCheckpoints;
      default:
        return backhandCheckpoints;
    }
  }

  /// Backhand throw checkpoints (Slingshot methodology)
  /// These checkpoints match the pose analysis backend detection system.
  static const List<FormCheckpoint> backhandCheckpoints = [
    // 1. Heisman Position
    FormCheckpoint(
      id: 'heisman',
      name: 'Heisman Position',
      description:
          'Player has just stepped onto their back leg on the ball of their '
          'foot. Front leg has started to drift in front of their back leg. '
          'They are on their back leg but have not started to coil yet, and '
          'their elbow is still roughly at 90 degrees and neutral.',
      orderIndex: 0,
      keyPoints: [
        FormKeyPoint(
          id: 'heisman_foot_placement',
          name: 'Back foot',
          description: 'Position of the back foot during the x-step',
          idealState:
              'Stepped onto the ball of your back foot, weight centered, '
              'ready to begin the coil',
        ),
        FormKeyPoint(
          id: 'heisman_front_leg',
          name: 'Front leg',
          description: 'Position of the front leg as it drifts',
          idealState: 'Front leg has started to drift in front of the back leg',
        ),
        FormKeyPoint(
          id: 'heisman_elbow',
          name: 'Elbow',
          description: 'Angle of the throwing elbow',
          idealState: 'Elbow ~90-115 degrees, neutral position',
        ),
        FormKeyPoint(
          id: 'heisman_coil',
          name: "Coil",
          description: 'Amount of shoulder/hip separation',
          idealState: 'Coil has not started yet',
        ),
      ],
    ),

    // 2. Loaded Position
    FormCheckpoint(
      id: 'loaded',
      name: 'Loaded Position',
      description:
          'The player\'s front (plant) foot is about to touch the ground, '
          'and they are fully coiled, and their back leg is bowed out.',
      orderIndex: 1,
      keyPoints: [
        FormKeyPoint(
          id: 'loaded_plant_foot',
          name: 'Plant foot timing',
          description: 'Position of the front foot as it plants',
          idealState: 'Front (plant) foot is about to touch the ground',
        ),
        FormKeyPoint(
          id: 'loaded_back_leg',
          name: 'Back leg',
          description: 'Shape of the back leg',
          idealState: 'Back leg is bowed out, in an athletic position',
        ),
        FormKeyPoint(
          id: 'loaded_disc_position',
          name: 'Disc position',
          description: 'Where the disc is relative to the body',
          idealState: 'Disc still not fully extended',
        ),
        FormKeyPoint(
          id: 'weight_not_falling',
          name: 'Weight',
          description: 'Where the disc is relative to the body',
          idealState:
              'Weight contained on the back leg - not falling over the front.',
        ),
      ],
    ),

    // 3. Magic Position
    FormCheckpoint(
      id: 'magic',
      name: 'Magic Position',
      description:
          'Disc is just starting to move forward, both knees are bent '
          'inward, in an athletic position.',
      orderIndex: 2,
      keyPoints: [
        FormKeyPoint(
          id: 'magic_disc_movement',
          name: 'Disc movement',
          description: 'The disc beginning its forward motion',
          idealState:
              'Disc has started moving forward'
              ' initiated by internal rotation, not arm pulling',
        ),
        FormKeyPoint(
          id: 'magic_knees',
          name: 'Knees',
          description: 'Both knees bent and driving',
          idealState:
              'Both knees are bent inward, creating an athletic, powerful '
              'stance that drives rotation through the ground',
        ),
        FormKeyPoint(
          id: 'magic_athletic_position',
          name: 'Athletic stance',
          description: 'Overall body position',
          idealState:
              'Athletic position - spine nearly vertical, balanced, '
              'weight transferring from back to front foot',
        ),
      ],
    ),

    // 4. Pro Position
    FormCheckpoint(
      id: 'pro',
      name: 'Pro Position',
      description:
          'The pull-through is well in progress, and the elbow is at a '
          '90-degree angle, and the back leg is bent at almost a 90-degree '
          'angle.',
      orderIndex: 3,
      keyPoints: [
        FormKeyPoint(
          id: 'pro_elbow',
          name: 'Elbow',
          description: 'The tightest elbow position in the throw',
          idealState: 'Elbow ~90 degrees',
        ),
        FormKeyPoint(
          id: 'pro_back_leg',
          name: 'Back leg',
          description: 'Back leg driving the rotation',
          idealState: 'Back leg has L-shape',
        ),
        FormKeyPoint(
          id: 'pro_about_to_release',
          name: 'Release',
          description: 'Disc path through the power pocket',
          idealState: 'Disc about to release',
        ),
      ],
    ),
  ];

  /// Default coaching tips per checkpoint.
  /// This is also the expected JSON structure for the Remote Config override.
  static const Map<String, List<String>> defaultCoachingTips = {
    'heisman': [
      'Balance and drift - front leg just past back leg',
      'Ball of the foot (air between heel and ground)',
      'Coil hasn\'t started yet',
    ],
    'loaded': [
      'Front foot about to plant',
      'On the ball of the back foot',
      'Back leg should be bowed out from coiling',
    ],
    'magic': [
      'Both knees bent inward (athletic)',
      'Disc has started to accelerate',
    ],
    'pro': [
      'Elbow ~90 degrees',
      'Back leg should be internally rotated (not straight)',
    ],
  };

  /// Get coaching tips for a checkpoint.
  /// Checks Remote Config for overrides, falls back to hardcoded defaults.
  static List<String> getCoachingTips(String checkpointId) {
    // Check Remote Config override
    final String remoteJson = locator
        .get<FeatureFlagService>()
        .formAnalysisCoachingTips;
    if (remoteJson.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed =
            json.decode(remoteJson) as Map<String, dynamic>;
        final List<dynamic>? tips = parsed[checkpointId] as List<dynamic>?;
        if (tips != null && tips.isNotEmpty) {
          return tips.cast<String>();
        }
      } catch (_) {
        // Invalid JSON — fall through to defaults
      }
    }

    // Fall back to hardcoded defaults
    return defaultCoachingTips[checkpointId] ?? [];
  }
}
