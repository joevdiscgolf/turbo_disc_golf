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
        return forehandCheckpoints;
      default:
        return backhandCheckpoints;
    }
  }

  /// Backhand throw checkpoints (Slingshot methodology)
  /// TODO: Replace placeholder content with actual Slingshot rules
  static const List<FormCheckpoint> backhandCheckpoints = [
    // 1. Reachback Position
    FormCheckpoint(
      id: 'reachback',
      name: 'Reachback Position',
      description:
          'The moment of maximum extension before the pull-through begins',
      orderIndex: 0,
      referenceDescription:
          'Disc should be extended away from target, elbow slightly bent, '
          'shoulders turned away from target, weight on back foot',
      keyPoints: [
        FormKeyPoint(
          id: 'reachback_extension',
          name: 'Arm Extension',
          description: 'How far the disc is extended away from the body',
          idealState:
              'Disc at chest height, arm extended but not locked, '
              'elbow slightly bent for power loading',
          commonMistakes: [
            'Reaching too far behind (rounding)',
            'Disc too high or too low',
            'Elbow completely locked out',
          ],
        ),
        FormKeyPoint(
          id: 'reachback_shoulders',
          name: 'Shoulder Turn',
          description: 'Rotation of shoulders away from target',
          idealState:
              'Shoulders turned 90 degrees or more from target, '
              'creating coil for power generation',
          commonMistakes: [
            'Insufficient shoulder turn',
            'Opening shoulders too early',
            'Shoulders tilted instead of rotated',
          ],
        ),
        FormKeyPoint(
          id: 'reachback_weight',
          name: 'Weight Distribution',
          description: 'Where body weight is positioned',
          idealState:
              '60-70% of weight on back foot, '
              'knee bent and ready to drive forward',
          commonMistakes: [
            'Weight already shifted forward',
            'Standing too upright',
            'Weight on heels instead of balls of feet',
          ],
        ),
        FormKeyPoint(
          id: 'reachback_disc_angle',
          name: 'Disc Angle',
          description: 'Angle of the disc during reachback',
          idealState:
              'Disc nose slightly down, matching intended release angle',
          commonMistakes: [
            'Nose up (causes disc to fade early)',
            'Disc wobbling or unstable',
            'Wrist rolled over too much',
          ],
        ),
      ],
    ),

    // 2. Power Pocket Position
    FormCheckpoint(
      id: 'power_pocket',
      name: 'Power Pocket',
      description:
          'The critical moment when the disc passes close to the body, '
          'storing maximum rotational energy',
      orderIndex: 1,
      referenceDescription:
          'Elbow leads the hand, disc tight to chest/core, '
          'hips have fired and are opening toward target',
      keyPoints: [
        FormKeyPoint(
          id: 'power_pocket_elbow',
          name: 'Elbow Position',
          description: 'Position of the throwing elbow',
          idealState:
              'Elbow leading the hand, bent at approximately 90 degrees, '
              'driving forward before the disc',
          commonMistakes: [
            'Elbow too straight (arm barring)',
            'Elbow dropping below disc plane',
            'Elbow behind the body instead of leading',
          ],
        ),
        FormKeyPoint(
          id: 'power_pocket_disc_path',
          name: 'Disc Path',
          description: 'How close the disc travels to the body',
          idealState:
              'Disc passes within 6 inches of chest/core, '
              'on a straight line to target',
          commonMistakes: [
            'Disc arcing around body (rounding)',
            'Disc too far from body',
            'Inconsistent disc path',
          ],
        ),
        FormKeyPoint(
          id: 'power_pocket_hips',
          name: 'Hip Rotation',
          description: 'Timing and degree of hip opening',
          idealState:
              'Hips have begun opening toward target, '
              'leading the upper body rotation',
          commonMistakes: [
            'Hips open too late',
            'Hips open too early (leaking power)',
            'Hips not rotating at all (arm throwing)',
          ],
        ),
      ],
    ),

    // 3. Release Point
    FormCheckpoint(
      id: 'release_point',
      name: 'Release Point',
      description: 'The moment the disc leaves the hand',
      orderIndex: 2,
      referenceDescription:
          'Arm fully extended toward target, '
          'disc released at chest height with clean snap',
      keyPoints: [
        FormKeyPoint(
          id: 'release_timing',
          name: 'Release Timing',
          description:
              'When the disc leaves the hand relative to arm extension',
          idealState:
              'Disc releases as arm reaches full extension, '
              'not before or significantly after',
          commonMistakes: [
            'Early release (disc goes right for RHBH)',
            'Late release/grip lock (disc goes left for RHBH)',
            'Inconsistent release point',
          ],
        ),
        FormKeyPoint(
          id: 'release_angle',
          name: 'Release Angle',
          description: 'The angle of the disc at release',
          idealState:
              'Disc flat or with intended hyzer/anhyzer angle, '
              'nose angle appropriate for shot',
          commonMistakes: [
            'Off-axis torque (wobble)',
            'Unintended nose up release',
            'Inconsistent release angle',
          ],
        ),
        FormKeyPoint(
          id: 'release_height',
          name: 'Release Height',
          description: 'Height of the disc at release',
          idealState:
              'Release at chest height or slightly below, '
              'consistent with target line',
          commonMistakes: [
            'Release too high (causes nose up)',
            'Release too low (causes upward angle)',
            'Inconsistent release height',
          ],
        ),
      ],
    ),

    // 4. Follow Through
    FormCheckpoint(
      id: 'follow_through',
      name: 'Follow Through',
      description: 'The motion after the disc is released',
      orderIndex: 3,
      referenceDescription:
          'Arm continues naturally across body, '
          'body rotates fully, balanced finish',
      keyPoints: [
        FormKeyPoint(
          id: 'follow_through_arm',
          name: 'Arm Follow Through',
          description: 'Path of the arm after release',
          idealState:
              'Arm continues naturally across body and wraps around, '
              'not stopped abruptly',
          commonMistakes: [
            'Stopping arm abruptly after release',
            'Arm going too high or too low',
            'Follow through not on line with target',
          ],
        ),
        FormKeyPoint(
          id: 'follow_through_balance',
          name: 'Balance',
          description: 'Body balance after the throw',
          idealState:
              'Balanced on front foot, controlled finish, '
              'able to watch disc flight without stumbling',
          commonMistakes: [
            'Falling off to one side',
            'Spinning out uncontrolled',
            'Stepping forward after release',
          ],
        ),
        FormKeyPoint(
          id: 'follow_through_rotation',
          name: 'Body Rotation',
          description: 'Completion of body rotation',
          idealState:
              'Hips and shoulders complete full rotation toward target, '
              'chest facing target at finish',
          commonMistakes: [
            'Incomplete rotation',
            'Over-rotation',
            'Upper body ahead of lower body',
          ],
        ),
      ],
    ),
  ];

  /// Forehand/Sidearm throw checkpoints
  /// TODO: Replace placeholder content with actual Slingshot rules
  static const List<FormCheckpoint> forehandCheckpoints = [
    // 1. Setup Position
    FormCheckpoint(
      id: 'forehand_setup',
      name: 'Setup Position',
      description: 'Initial stance and grip before the throw',
      orderIndex: 0,
      referenceDescription:
          'Sideways stance, two-finger power grip, '
          'disc at waist height, elbow close to body',
      keyPoints: [
        FormKeyPoint(
          id: 'forehand_grip',
          name: 'Grip',
          description: 'How the disc is held',
          idealState:
              'Two-finger power grip (index and middle fingers on rim), '
              'thumb on top of flight plate',
          commonMistakes: [
            'Fingers too far from rim edge',
            'Grip too loose or too tight',
            'Thumb position incorrect',
          ],
        ),
        FormKeyPoint(
          id: 'forehand_stance',
          name: 'Stance',
          description: 'Body position and orientation',
          idealState:
              'Sideways to target, feet shoulder-width apart, '
              'slight knee bend',
          commonMistakes: [
            'Facing target too directly',
            'Feet too close together',
            'Standing too upright',
          ],
        ),
      ],
    ),

    // 2. Wind Up
    FormCheckpoint(
      id: 'forehand_wind_up',
      name: 'Wind Up',
      description: 'Bringing the disc back before the throw',
      orderIndex: 1,
      referenceDescription:
          'Disc brought back to hip/waist level, '
          'elbow stays close to body, wrist cocked',
      keyPoints: [
        FormKeyPoint(
          id: 'forehand_elbow_position',
          name: 'Elbow Position',
          description: 'Position of the elbow during wind up',
          idealState: 'Elbow tucked close to the body, not flared out',
          commonMistakes: [
            'Elbow flaring out (chicken wing)',
            'Elbow too far behind body',
            'Elbow dropping below disc plane',
          ],
        ),
        FormKeyPoint(
          id: 'forehand_wrist',
          name: 'Wrist Position',
          description: 'Wrist angle during wind up',
          idealState: 'Wrist cocked back, storing energy for snap',
          commonMistakes: [
            'Wrist not cocked back enough',
            'Wrist rolled over',
            'No power stored in wrist',
          ],
        ),
      ],
    ),

    // 3. Release
    FormCheckpoint(
      id: 'forehand_release',
      name: 'Release',
      description: 'The throwing motion and disc release',
      orderIndex: 2,
      referenceDescription:
          'Elbow drives forward, wrist snaps through, '
          'disc released with spin at appropriate angle',
      keyPoints: [
        FormKeyPoint(
          id: 'forehand_snap',
          name: 'Wrist Snap',
          description: 'The snapping motion that generates spin',
          idealState: 'Quick, powerful wrist snap generating high spin rate',
          commonMistakes: [
            'All arm, no wrist snap',
            'Snap too early or late',
            'Wrist rolling over instead of snapping',
          ],
        ),
        FormKeyPoint(
          id: 'forehand_release_angle',
          name: 'Release Angle',
          description: 'Angle of disc at release',
          idealState:
              'Disc flat or with intended angle, '
              'minimal off-axis torque',
          commonMistakes: [
            'Releasing with OAT (disc wobbles)',
            'Nose up release',
            'Releasing too high or low',
          ],
        ),
      ],
    ),

    // 4. Follow Through
    FormCheckpoint(
      id: 'forehand_follow_through',
      name: 'Follow Through',
      description: 'Motion after the disc is released',
      orderIndex: 3,
      referenceDescription:
          'Arm continues toward target, '
          'body stays balanced, smooth finish',
      keyPoints: [
        FormKeyPoint(
          id: 'forehand_arm_path',
          name: 'Arm Path',
          description: 'Direction of arm after release',
          idealState:
              'Arm follows through toward target, '
              'not across body or stopping short',
          commonMistakes: [
            'Cutting off follow through',
            'Arm going across body',
            'Follow through too high',
          ],
        ),
        FormKeyPoint(
          id: 'forehand_balance',
          name: 'Balance',
          description: 'Body balance at finish',
          idealState: 'Balanced, controlled finish',
          commonMistakes: [
            'Falling toward target',
            'Off balance to one side',
            'Spinning out',
          ],
        ),
      ],
    ),
  ];
}
