import 'package:turbo_disc_golf/models/data/throw_data.dart';

const Map<ThrowTechnique, String> throwTechniqueToName = {
  ThrowTechnique.backhand: 'Backhand',
  ThrowTechnique.forehand: 'Forehand',
  ThrowTechnique.tomahawk: 'Tomahawk',
  ThrowTechnique.thumber: 'Thumber',
  ThrowTechnique.overhand: 'Overhand',
  ThrowTechnique.backhandRoller: 'Backhand Roller',
  ThrowTechnique.forehandRoller: 'Forehand Roller',
  ThrowTechnique.grenade: 'Grenade',
  ThrowTechnique.other: 'Other',
};

const Map<ThrowPurpose, String> throwPurposeToName = {
  ThrowPurpose.teeDrive: 'Tee Drive',
  ThrowPurpose.fairwayDrive: 'Fairway Drive',
  ThrowPurpose.approach: 'Approach',
  ThrowPurpose.putt: 'Putt',
  ThrowPurpose.scramble: 'Scramble',
  ThrowPurpose.penalty: 'Penalty',
  ThrowPurpose.other: 'Other',
};

const Map<LandingSpot, String> landingSpotToName = {
  LandingSpot.inBasket: 'In Basket',
  LandingSpot.parked: 'Parked',
  LandingSpot.circle1: 'Circle 1',
  LandingSpot.circle2: 'Circle 2',
  LandingSpot.fairway: 'Fairway',
  LandingSpot.offFairway: 'Off Fairway',
  LandingSpot.outOfBounds: 'Out of Bounds',
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
  ShotShape.hyzerFlip: 'Hyzer Flip',
  ShotShape.turnover: 'Turnover',
  ShotShape.flat: 'Flat',
  ShotShape.flexShot: 'Flex Shot',
  ShotShape.spikeHyzer: 'Spike Hyzer',
  ShotShape.skyAnhyzer: 'Sky Anhyzer',
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
  StanceType.patentPending: 'Patent Pending',
  StanceType.other: 'Other',
};

final Map<PuttStyle, String> puttStyleToName = {
  PuttStyle.staggered: 'Staggered',
  PuttStyle.straddle: 'Straddle',
  PuttStyle.jumpPutt: 'Jump Putt',
  PuttStyle.stepPutt: 'Step Putt',
  PuttStyle.other: 'Other',
};

final Map<FairwayWidth, String> fairwayWidthToName = {
  FairwayWidth.open: 'Open',
  FairwayWidth.moderate: 'Moderate',
  FairwayWidth.tight: 'Tight',
  FairwayWidth.veryTight: 'Very Tight',
};

final Map<WindDirection, String> windDirectionToName = {
  WindDirection.none: 'None',
  WindDirection.headwind: 'Headwind',
  WindDirection.tailwind: 'Tailwind',
  WindDirection.leftToRight: 'Left to Right',
  WindDirection.rightToLeft: 'Right to Left',
};

final Map<WindStrength, String> windStrengthToName = {
  WindStrength.calm: 'Calm',
  WindStrength.light: 'Light',
  WindStrength.moderate: 'Moderate',
  WindStrength.strong: 'Strong',
  WindStrength.extreme: 'Extreme',
};
