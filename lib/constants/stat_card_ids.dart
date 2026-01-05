/// Type-safe constants for all stat card IDs used in the story tab
///
/// These constants prevent typos and provide compile-time guarantees
/// when referencing card IDs throughout the codebase.
class StatCardIds {
  // Private constructor to prevent instantiation
  const StatCardIds._();

  // Driving Stats
  static const String fairwayHit = 'FAIRWAY_HIT';
  static const String c1InReg = 'C1_IN_REG';
  static const String obRate = 'OB_RATE';
  static const String parked = 'PARKED';

  // Putting Stats
  static const String c1Putting = 'C1_PUTTING';
  static const String c1xPutting = 'C1X_PUTTING';
  static const String c2Putting = 'C2_PUTTING';

  // Scoring Stats
  static const String birdieRate = 'BIRDIE_RATE';
  static const String bogeyRate = 'BOGEY_RATE';
  static const String parRate = 'PAR_RATE';

  // Mental Game Stats
  static const String bounceBack = 'BOUNCE_BACK';
  static const String hotStreak = 'HOT_STREAK';
  static const String flowState = 'FLOW_STATE';

  // Performance Stats
  static const String mistakes = 'MISTAKES';
  static const String skillsScore = 'SKILLS_SCORE';

  // Specialty Cards (existing widgets)
  static const String throwTypeComparison = 'THROW_TYPE_COMPARISON';
  static const String shotShapeBreakdown = 'SHOT_SHAPE_BREAKDOWN';

  // Parameterized Card ID Builders
  /// Builds a card ID for specific disc performance
  /// Example: `DISC_PERFORMANCE:Destroyer`
  static String discPerformance(String discName) =>
      'DISC_PERFORMANCE:$discName';

  /// Builds a card ID for specific hole type performance
  /// Example: `HOLE_TYPE:Par 3`, `HOLE_TYPE:Par 4`, `HOLE_TYPE:Par 5`
  static String holeType(String parType) => 'HOLE_TYPE:$parType';
}
