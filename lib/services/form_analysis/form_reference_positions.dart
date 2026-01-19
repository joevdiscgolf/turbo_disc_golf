import 'package:turbo_disc_golf/models/data/form_analysis/form_checkpoint.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

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
      referenceDescription:
          'Step onto the ball of your back foot. Front leg should start '
          'drifting in front of your back leg. You are on your back leg but '
          'have not started to coil yet. Elbow is still roughly at 90 degrees '
          'and neutral. Target elbow angle: ~115°, hip rotation: ~80°.',
      keyPoints: [
        FormKeyPoint(
          id: 'heisman_foot_placement',
          name: 'Back Foot Placement',
          description: 'Position of the back foot during the x-step',
          idealState:
              'Stepped onto the ball of your back foot, weight centered, '
              'ready to begin the coil',
          commonMistakes: [
            'Stepping flat-footed instead of ball of foot',
            'Weight too far forward already',
            'Back foot pointed wrong direction',
          ],
        ),
        FormKeyPoint(
          id: 'heisman_front_leg',
          name: 'Front Leg Position',
          description: 'Position of the front leg as it drifts',
          idealState:
              'Front leg has started to drift in front of the back leg, '
              'preparing for the plant step',
          commonMistakes: [
            'Front leg too far behind',
            'Front leg stepping too wide',
            'Rushing the front leg forward',
          ],
        ),
        FormKeyPoint(
          id: 'heisman_elbow',
          name: 'Elbow Angle',
          description: 'Angle of the throwing elbow',
          idealState:
              'Elbow at roughly 90-115 degrees, neutral position, '
              'not yet loaded for the pull',
          commonMistakes: [
            'Elbow too straight (arm barring early)',
            'Elbow too bent (losing reach)',
            'Elbow dropped below disc plane',
          ],
        ),
        FormKeyPoint(
          id: 'heisman_coil',
          name: 'Body Coil',
          description: 'Amount of shoulder/hip separation',
          idealState:
              'Have not started to coil yet - shoulders and hips relatively '
              'aligned, saving the coil for the loaded position',
          commonMistakes: [
            'Coiling too early (losing timing)',
            'Already opening toward target',
            'Upper body ahead of lower body',
          ],
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
      referenceDescription:
          'Front (plant) foot is about to touch the ground. You should be '
          'fully coiled at this point. Back leg should be bowed out. '
          'Target elbow angle: ~143°, hip rotation: ~79°.',
      keyPoints: [
        FormKeyPoint(
          id: 'loaded_plant_foot',
          name: 'Plant Foot Timing',
          description: 'Position of the front foot as it plants',
          idealState:
              'Front (plant) foot is about to touch the ground, '
              'heel leading, preparing for weight transfer',
          commonMistakes: [
            'Planting too early (losing coil)',
            'Planting too late (rushing)',
            'Foot landing toe-first instead of heel',
          ],
        ),
        FormKeyPoint(
          id: 'loaded_coil',
          name: 'Full Coil',
          description: 'Maximum shoulder-hip separation',
          idealState:
              'Fully coiled - maximum separation between shoulders and hips, '
              'storing rotational energy for the pull',
          commonMistakes: [
            'Insufficient coil (losing power)',
            'Opening shoulders too early',
            'Coil in wrong direction',
          ],
        ),
        FormKeyPoint(
          id: 'loaded_back_leg',
          name: 'Back Leg Position',
          description: 'Shape of the back leg',
          idealState:
              'Back leg is bowed out, creating a stable base and '
              'allowing hip rotation to drive forward',
          commonMistakes: [
            'Back leg too straight',
            'Back knee collapsing inward',
            'Weight stuck on back leg',
          ],
        ),
        FormKeyPoint(
          id: 'loaded_disc_position',
          name: 'Disc Position',
          description: 'Where the disc is relative to the body',
          idealState:
              'Disc extended away from body, wrist-chest distance maximized, '
              'ready for the pull-through',
          commonMistakes: [
            'Disc too close to body',
            'Disc wrapped behind body (rounding)',
            'Disc too high or low',
          ],
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
      referenceDescription:
          'Disc is just starting to move forward. Both knees are bent inward. '
          'Position should be athletic. Target elbow angle: ~148°, '
          'hip rotation: ~77°, spine should be nearly vertical.',
      keyPoints: [
        FormKeyPoint(
          id: 'magic_disc_movement',
          name: 'Disc Movement',
          description: 'The disc beginning its forward motion',
          idealState:
              'Disc is just starting to move forward toward the target, '
              'initiated by hip rotation, not arm pulling',
          commonMistakes: [
            'Disc moving forward too early (arm throwing)',
            'Disc lagging behind hip rotation',
            'Disc path arcing around body',
          ],
        ),
        FormKeyPoint(
          id: 'magic_knees',
          name: 'Knee Position',
          description: 'Both knees bent and driving',
          idealState:
              'Both knees are bent inward, creating an athletic, powerful '
              'stance that drives rotation through the ground',
          commonMistakes: [
            'Knees too straight (losing power)',
            'Knees collapsing outward',
            'Front knee not bracing properly',
          ],
        ),
        FormKeyPoint(
          id: 'magic_athletic_position',
          name: 'Athletic Stance',
          description: 'Overall body position',
          idealState:
              'Athletic position - spine nearly vertical, balanced, '
              'weight transferring from back to front foot',
          commonMistakes: [
            'Spine tilted too far forward or back',
            'Off balance during weight transfer',
            'Rising up instead of staying low',
          ],
        ),
        FormKeyPoint(
          id: 'magic_hip_lead',
          name: 'Hip Lead',
          description: 'Hips leading the rotation',
          idealState:
              'Hips are driving the rotation, pulling the upper body '
              'and arm through the power pocket',
          commonMistakes: [
            'Upper body leading hips (arm throwing)',
            'Hips stalling out',
            'Hips spinning instead of driving forward',
          ],
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
          'angle, and the front leg is pretty straight.',
      orderIndex: 3,
      referenceDescription:
          'Pull-through is well in progress. Elbow is at a 90-degree angle '
          '(tightest point). Back leg is bent at almost a 90-degree angle. '
          'Front leg is pretty straight, bracing the rotation. '
          'Target elbow angle: ~50°.',
      keyPoints: [
        FormKeyPoint(
          id: 'pro_elbow',
          name: 'Elbow Angle',
          description: 'The tightest elbow position in the throw',
          idealState:
              'Elbow at approximately 90 degrees (actually ~50° measured), '
              'this is the tightest elbow angle in the entire throw',
          commonMistakes: [
            'Elbow too straight (arm barring)',
            'Elbow opening too early',
            'Elbow dropping below disc plane',
          ],
        ),
        FormKeyPoint(
          id: 'pro_back_leg',
          name: 'Back Leg',
          description: 'Back leg driving the rotation',
          idealState:
              'Back leg bent at almost a 90-degree angle, actively driving '
              'hip rotation and weight transfer',
          commonMistakes: [
            'Back leg too straight (not driving)',
            'Back leg collapsing',
            'Weight still stuck on back leg',
          ],
        ),
        FormKeyPoint(
          id: 'pro_front_leg',
          name: 'Front Leg',
          description: 'Front leg bracing',
          idealState:
              'Front leg is pretty straight, bracing against the ground '
              'to convert linear momentum into rotational power',
          commonMistakes: [
            'Front knee collapsing (leaking power)',
            'Front leg too bent (not bracing)',
            'Spinning around front leg instead of bracing',
          ],
        ),
        FormKeyPoint(
          id: 'pro_pull_through',
          name: 'Pull-Through Path',
          description: 'Disc path through the power pocket',
          idealState:
              'Pull-through is well in progress, disc moving on a straight '
              'line close to the chest toward the target',
          commonMistakes: [
            'Disc path rounding away from body',
            'Disc path too high or low',
            'Early release before full extension',
          ],
        ),
      ],
    ),
  ];
}
