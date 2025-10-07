// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'throw_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscThrow _$DiscThrowFromJson(Map json) => DiscThrow(
  index: (json['index'] as num).toInt(),
  purpose: $enumDecodeNullable(_$ThrowPurposeEnumMap, json['purpose']),
  technique: $enumDecodeNullable(_$ThrowTechniqueEnumMap, json['technique']),
  puttStyle: $enumDecodeNullable(_$PuttStyleEnumMap, json['puttStyle']),
  shotShape: $enumDecodeNullable(_$ShotShapeEnumMap, json['shotShape']),
  stance: $enumDecodeNullable(_$StanceTypeEnumMap, json['stance']),
  power: $enumDecodeNullable(_$ThrowPowerEnumMap, json['power']),
  distanceFeet: (json['distanceFeet'] as num?)?.toInt(),
  elevationChangeFeet: (json['elevationChangeFeet'] as num?)?.toDouble(),
  windDirection: $enumDecodeNullable(
    _$WindDirectionEnumMap,
    json['windDirection'],
  ),
  windStrength: $enumDecodeNullable(
    _$WindStrengthEnumMap,
    json['windStrength'],
  ),
  resultRating: $enumDecodeNullable(
    _$ThrowResultRatingEnumMap,
    json['resultRating'],
  ),
  landingSpot: $enumDecodeNullable(_$LandingSpotEnumMap, json['landingSpot']),
  fairwayWidth: $enumDecodeNullable(
    _$FairwayWidthEnumMap,
    json['fairwayWidth'],
  ),
  penaltyStrokes: (json['penaltyStrokes'] as num?)?.toInt(),
  notes: json['notes'] as String?,
  rawText: json['rawText'] as String?,
  parseConfidence: (json['parseConfidence'] as num?)?.toDouble(),
  disc: json['disc'] == null
      ? null
      : DGDisc.fromJson(Map<String, dynamic>.from(json['disc'] as Map)),
);

Map<String, dynamic> _$DiscThrowToJson(DiscThrow instance) => <String, dynamic>{
  'index': instance.index,
  'purpose': _$ThrowPurposeEnumMap[instance.purpose],
  'technique': _$ThrowTechniqueEnumMap[instance.technique],
  'puttStyle': _$PuttStyleEnumMap[instance.puttStyle],
  'shotShape': _$ShotShapeEnumMap[instance.shotShape],
  'stance': _$StanceTypeEnumMap[instance.stance],
  'power': _$ThrowPowerEnumMap[instance.power],
  'distanceFeet': instance.distanceFeet,
  'elevationChangeFeet': instance.elevationChangeFeet,
  'windDirection': _$WindDirectionEnumMap[instance.windDirection],
  'windStrength': _$WindStrengthEnumMap[instance.windStrength],
  'resultRating': _$ThrowResultRatingEnumMap[instance.resultRating],
  'landingSpot': _$LandingSpotEnumMap[instance.landingSpot],
  'fairwayWidth': _$FairwayWidthEnumMap[instance.fairwayWidth],
  'penaltyStrokes': instance.penaltyStrokes,
  'notes': instance.notes,
  'rawText': instance.rawText,
  'parseConfidence': instance.parseConfidence,
  'disc': instance.disc?.toJson(),
};

const _$ThrowPurposeEnumMap = {
  ThrowPurpose.teeDrive: 'tee_drive',
  ThrowPurpose.fairwayDrive: 'fairway_drive',
  ThrowPurpose.approach: 'approach',
  ThrowPurpose.putt: 'putt',
  ThrowPurpose.scramble: 'scramble',
  ThrowPurpose.penalty: 'penalty',
  ThrowPurpose.other: 'other',
};

const _$ThrowTechniqueEnumMap = {
  ThrowTechnique.backhand: 'backhand',
  ThrowTechnique.forehand: 'forehand',
  ThrowTechnique.tomahawk: 'tomahawk',
  ThrowTechnique.thumber: 'thumber',
  ThrowTechnique.overhand: 'overhand',
  ThrowTechnique.backhandRoller: 'backhand_roller',
  ThrowTechnique.forehandRoller: 'forehand_roller',
  ThrowTechnique.grenade: 'grenade',
  ThrowTechnique.other: 'other',
};

const _$PuttStyleEnumMap = {
  PuttStyle.staggered: 'staggered',
  PuttStyle.straddle: 'straddle',
  PuttStyle.jumpPutt: 'jump_putt',
  PuttStyle.stepPutt: 'step_putt',
  PuttStyle.other: 'other',
};

const _$ShotShapeEnumMap = {
  ShotShape.hyzer: 'hyzer',
  ShotShape.anhyzer: 'anhyzer',
  ShotShape.hyzerFlip: 'hyzer_flip',
  ShotShape.turnover: 'turnover',
  ShotShape.flat: 'flat',
  ShotShape.flexShot: 'flex_shot',
  ShotShape.spikeHyzer: 'spike_hyzer',
  ShotShape.skyAnhyzer: 'sky_anhyzer',
  ShotShape.roller: 'roller',
  ShotShape.pitch: 'pitch',
  ShotShape.skip: 'skip',
  ShotShape.other: 'other',
};

const _$StanceTypeEnumMap = {
  StanceType.standstill: 'standstill',
  StanceType.xStep: 'x_step',
  StanceType.patentPending: 'patent_pending',
  StanceType.other: 'other',
};

const _$ThrowPowerEnumMap = {
  ThrowPower.putt: 'putt',
  ThrowPower.soft: 'soft',
  ThrowPower.controlled: 'controlled',
  ThrowPower.full: 'full',
  ThrowPower.max: 'max',
  ThrowPower.other: 'other',
};

const _$WindDirectionEnumMap = {
  WindDirection.none: 'none',
  WindDirection.headwind: 'headwind',
  WindDirection.tailwind: 'tailwind',
  WindDirection.leftToRight: 'left_to_right',
  WindDirection.rightToLeft: 'right_to_left',
  WindDirection.swirling: 'swirling',
  WindDirection.other: 'other',
};

const _$WindStrengthEnumMap = {
  WindStrength.calm: 'calm',
  WindStrength.light: 'light',
  WindStrength.moderate: 'moderate',
  WindStrength.strong: 'strong',
  WindStrength.extreme: 'extreme',
};

const _$ThrowResultRatingEnumMap = {
  ThrowResultRating.terrible: 'terrible',
  ThrowResultRating.poor: 'poor',
  ThrowResultRating.average: 'average',
  ThrowResultRating.good: 'good',
  ThrowResultRating.excellent: 'excellent',
};

const _$LandingSpotEnumMap = {
  LandingSpot.inBasket: 'in_basket',
  LandingSpot.parked: 'parked',
  LandingSpot.circle1: 'circle_1',
  LandingSpot.circle2: 'circle_2',
  LandingSpot.fairway: 'fairway',
  LandingSpot.offFairway: 'off_fairway',
  LandingSpot.outOfBounds: 'out_of_bounds',
  LandingSpot.other: 'other',
};

const _$FairwayWidthEnumMap = {
  FairwayWidth.open: 'open',
  FairwayWidth.moderate: 'moderate',
  FairwayWidth.tight: 'tight',
  FairwayWidth.veryTight: 'very_tight',
};
