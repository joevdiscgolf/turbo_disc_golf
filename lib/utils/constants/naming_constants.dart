import 'package:turbo_disc_golf/models/data/throw_data.dart';

const Map<ThrowTechnique, String> throwTechniqueToName = {
  ThrowTechnique.backhand: 'Backhand',
  ThrowTechnique.forehand: 'Forehand',
  ThrowTechnique.tomahawk: 'Tomahawk',
  ThrowTechnique.thumber: 'Thumber',
  ThrowTechnique.overhand: 'Overhand',
  ThrowTechnique.backhandRoller: 'Backhand roller',
  ThrowTechnique.forehandRoller: 'Forehand roller',
  ThrowTechnique.grenade: 'Grenade',
  ThrowTechnique.other: 'Other',
};

/// Shortened names for compact displays (e.g., Blow-up breakdown)
const Map<ThrowTechnique, String> throwTechniqueToShortName = {
  ThrowTechnique.backhand: 'BH',
  ThrowTechnique.forehand: 'FH',
  ThrowTechnique.tomahawk: 'Tom',
  ThrowTechnique.thumber: 'Thum',
  ThrowTechnique.overhand: 'OH',
  ThrowTechnique.backhandRoller: 'BH Roller',
  ThrowTechnique.forehandRoller: 'FH Roller',
  ThrowTechnique.grenade: 'Gren',
  ThrowTechnique.other: 'Other',
};

const Map<ThrowPurpose, String> throwPurposeToName = {
  ThrowPurpose.teeDrive: 'Tee shot',
  ThrowPurpose.fairwayDrive: 'Fairway drive',
  ThrowPurpose.approach: 'Approach',
  ThrowPurpose.putt: 'Putt',
  ThrowPurpose.scramble: 'Scramble',
  ThrowPurpose.penalty: 'Penalty',
  ThrowPurpose.other: 'Other',
};

const Map<LandingSpot, String> landingSpotToName = {
  LandingSpot.inBasket: 'Basket',
  LandingSpot.parked: 'Parked',
  LandingSpot.circle1: 'Circle 1',
  LandingSpot.circle2: 'Circle 2',
  LandingSpot.fairway: 'Fairway',
  LandingSpot.offFairway: 'Off fairway',
  LandingSpot.outOfBounds: 'Out of bounds',
  LandingSpot.other: 'Other',
};

/// Shortened names for compact displays (e.g., Blow-up breakdown)
const Map<LandingSpot, String> landingSpotToShortName = {
  LandingSpot.inBasket: 'Basket',
  LandingSpot.parked: 'Parked',
  LandingSpot.circle1: 'C1',
  LandingSpot.circle2: 'C2',
  LandingSpot.fairway: 'FW',
  LandingSpot.offFairway: 'Off FW',
  LandingSpot.outOfBounds: 'OB',
  LandingSpot.other: 'Other',
};

final Map<ThrowResultRating, String> throwResultRatingToName = {
  ThrowResultRating.terrible: 'Terrible',
  ThrowResultRating.poor: 'Poor',
  ThrowResultRating.average: 'Average',
  ThrowResultRating.good: 'Good',
  ThrowResultRating.excellent: 'Excellent',
};

final Map<ShotShape, String> shotShapeToName = {
  ShotShape.hyzer: 'Hyzer',
  ShotShape.anhyzer: 'Anhyzer',
  ShotShape.hyzerFlip: 'Hyzer flip',
  ShotShape.turnover: 'Turnover',
  ShotShape.flat: 'Flat',
  ShotShape.flexShot: 'Flex shot',
  ShotShape.spikeHyzer: 'Spike hyzer',
  ShotShape.skyAnhyzer: 'Sky anhyzer',
  ShotShape.roller: 'Roller',
  ShotShape.pitch: 'Pitch',
  ShotShape.other: 'Other',
};

final Map<ThrowPower, String> throwPowerToName = {
  ThrowPower.putt: 'Putt',
  ThrowPower.soft: 'Soft',
  ThrowPower.controlled: 'Controlled',
  ThrowPower.full: 'Full',
  ThrowPower.max: 'Max',
};

final Map<StanceType, String> stanceTypeToName = {
  StanceType.standstill: 'Standstill',
  StanceType.xStep: 'X-Step',
  StanceType.patentPending: 'Patent pending',
  StanceType.other: 'Other',
};

final Map<PuttStyle, String> puttStyleToName = {
  PuttStyle.staggered: 'Staggered',
  PuttStyle.straddle: 'Straddle',
  PuttStyle.jumpPutt: 'Jump putt',
  PuttStyle.stepPutt: 'Step putt',
  PuttStyle.other: 'Other',
};

final Map<FairwayWidth, String> fairwayWidthToName = {
  FairwayWidth.open: 'Open',
  FairwayWidth.moderate: 'Moderate',
  FairwayWidth.tight: 'Tight',
  FairwayWidth.veryTight: 'Very tight',
};

final Map<WindDirection, String> windDirectionToName = {
  WindDirection.none: 'None',
  WindDirection.headwind: 'Headwind',
  WindDirection.tailwind: 'Tailwind',
  WindDirection.leftToRight: 'Left to right',
  WindDirection.rightToLeft: 'Right to left',
};

final Map<WindStrength, String> windStrengthToName = {
  WindStrength.calm: 'Calm',
  WindStrength.light: 'Light',
  WindStrength.moderate: 'Moderate',
  WindStrength.strong: 'Strong',
  WindStrength.extreme: 'Extreme',
};
