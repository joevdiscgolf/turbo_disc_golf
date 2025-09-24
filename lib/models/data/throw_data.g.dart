// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'throw_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscThrow _$DiscThrowFromJson(Map json) => DiscThrow(
  distance: (json['distance'] as num).toInt(),
  discName: json['discName'] as String?,
  discId: json['discId'] as String?,
  throwType: $enumDecodeNullable(
    _$DiscThrowTypeEnumMap,
    json['throwType'],
    unknownValue: DiscThrowType.other,
  ),
  technique: $enumDecodeNullable(
    _$ThrowTechniqueEnumMap,
    json['technique'],
    unknownValue: ThrowTechnique.other,
  ),
  shotType: $enumDecodeNullable(
    _$ShotTypeEnumMap,
    json['shotType'],
    unknownValue: ShotType.other,
  ),
  stance: $enumDecodeNullable(
    _$StanceTypeEnumMap,
    json['stance'],
    unknownValue: StanceType.other,
  ),
  conditions: const ShotConditionListConverter().fromJson(
    json['conditions'] as List?,
  ),
  windCondition: $enumDecodeNullable(
    _$WindConditionEnumMap,
    json['windCondition'],
    unknownValue: WindCondition.other,
  ),
  resultRating: $enumDecodeNullable(
    _$ThrowResultRatingEnumMap,
    json['resultRating'],
  ),
  landingZone: $enumDecodeNullable(
    _$LandingZoneEnumMap,
    json['landingZone'],
    unknownValue: LandingZone.other,
  ),
  distanceFromBasketBefore: (json['distanceFromBasketBefore'] as num?)?.toInt(),
  distanceFromBasketAfter: (json['distanceFromBasketAfter'] as num?)?.toInt(),
  description: json['description'] as String?,
  result: json['result'] as String?,
  madeShot: json['madeShot'] as bool?,
  obPenalty: json['obPenalty'] as bool?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$DiscThrowToJson(DiscThrow instance) => <String, dynamic>{
  'distance': instance.distance,
  'discName': instance.discName,
  'discId': instance.discId,
  'throwType': _$DiscThrowTypeEnumMap[instance.throwType],
  'technique': _$ThrowTechniqueEnumMap[instance.technique],
  'shotType': _$ShotTypeEnumMap[instance.shotType],
  'stance': _$StanceTypeEnumMap[instance.stance],
  'conditions': const ShotConditionListConverter().toJson(instance.conditions),
  'windCondition': _$WindConditionEnumMap[instance.windCondition],
  'resultRating': _$ThrowResultRatingEnumMap[instance.resultRating],
  'landingZone': _$LandingZoneEnumMap[instance.landingZone],
  'distanceFromBasketBefore': instance.distanceFromBasketBefore,
  'distanceFromBasketAfter': instance.distanceFromBasketAfter,
  'madeShot': instance.madeShot,
  'obPenalty': instance.obPenalty,
  'description': instance.description,
  'result': instance.result,
  'notes': instance.notes,
};

const _$DiscThrowTypeEnumMap = {
  DiscThrowType.drive: 'drive',
  DiscThrowType.approach: 'approach',
  DiscThrowType.putt: 'putt',
  DiscThrowType.fairway: 'fairway',
  DiscThrowType.upshot: 'upshot',
  DiscThrowType.other: 'other',
};

const _$ThrowTechniqueEnumMap = {
  ThrowTechnique.backhand: 'backhand',
  ThrowTechnique.forehand: 'forehand',
  ThrowTechnique.tomahawk: 'tomahawk',
  ThrowTechnique.thumber: 'thumber',
  ThrowTechnique.backhandRoller: 'backhand_roller',
  ThrowTechnique.forehandRoller: 'forehand_roller',
  ThrowTechnique.putt: 'putt',
  ThrowTechnique.jumpPutt: 'jump_putt',
  ThrowTechnique.stepPutt: 'step_putt',
  ThrowTechnique.turboPutt: 'turbo_putt',
  ThrowTechnique.straddlePutt: 'straddle_putt',
  ThrowTechnique.other: 'other',
};

const _$ShotTypeEnumMap = {
  ShotType.hyzer: 'hyzer',
  ShotType.anhyzer: 'anhyzer',
  ShotType.hyzerFlip: 'hyzer_flip',
  ShotType.flexShot: 'flex_shot',
  ShotType.flat: 'flat',
  ShotType.spikeHyzer: 'spike_hyzer',
  ShotType.grenade: 'grenade',
  ShotType.skyAnhyzer: 'sky_anhyzer',
  ShotType.other: 'other',
};

const _$StanceTypeEnumMap = {
  StanceType.standstill: 'standstill',
  StanceType.xStep: 'x_step',
  StanceType.runUp: 'run_up',
  StanceType.straddle: 'straddle',
  StanceType.jump: 'jump',
  StanceType.stepThrough: 'step_through',
  StanceType.other: 'other',
};

const _$WindConditionEnumMap = {
  WindCondition.headwind: 'headwind',
  WindCondition.tailwind: 'tailwind',
  WindCondition.leftToRightCrosswind: 'left_to_right_crosswind',
  WindCondition.rightToLeftCrosswind: 'right_to_left_crosswind',
  WindCondition.other: 'other',
};

const _$ThrowResultRatingEnumMap = {
  ThrowResultRating.terrible: 1,
  ThrowResultRating.poor: 2,
  ThrowResultRating.average: 3,
  ThrowResultRating.good: 4,
  ThrowResultRating.excellent: 5,
};

const _$LandingZoneEnumMap = {
  LandingZone.circle1: 'circle_1',
  LandingZone.circle2: 'circle_2',
  LandingZone.fairway: 'fairway',
  LandingZone.rough: 'rough',
  LandingZone.ob: 'ob',
  LandingZone.water: 'water',
  LandingZone.sand: 'sand',
  LandingZone.basket: 'basket',
  LandingZone.pinHigh: 'pin_high',
  LandingZone.short: 'short',
  LandingZone.long: 'long',
  LandingZone.left: 'left',
  LandingZone.right: 'right',
  LandingZone.other: 'other',
};
