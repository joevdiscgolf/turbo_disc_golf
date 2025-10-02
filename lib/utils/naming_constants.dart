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
