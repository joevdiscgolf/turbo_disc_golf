import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';

part 'throw_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class DiscThrow {
  const DiscThrow({
    required this.index,
    this.purpose,
    this.technique,
    this.puttStyle,
    this.shotShape,
    this.stance,
    this.power,
    this.distanceFeetBeforeThrow,
    this.distanceFeetAfterThrow,
    this.elevationChangeFeet,
    this.windDirection,
    this.windStrength,
    this.resultRating,
    this.landingSpot,
    this.fairwayWidth,
    this.penaltyStrokes,
    this.notes,
    this.rawText,
    this.parseConfidence,
    this.discName,
    this.disc,
  });

  /// 0-based throw index within the hole (0 = tee throw, 1 = second throw, ...)
  final int index;

  final ThrowPurpose? purpose;
  final ThrowTechnique? technique;
  final PuttStyle? puttStyle;
  final ShotShape? shotShape;
  final StanceType? stance;
  final ThrowPower? power;

  /// Distances — store both when possible; LLM should parse numeric value and convert.
  final int? distanceFeetBeforeThrow;
  final int? distanceFeetAfterThrow;

  final double? elevationChangeFeet;

  final WindDirection? windDirection;
  final WindStrength? windStrength; // 1-5 scale (JSON as integer)

  final ThrowResultRating? resultRating; // 1-5
  final LandingSpot? landingSpot;
  final FairwayWidth? fairwayWidth;
  final int? penaltyStrokes;

  /// Free text & parser confidence (0.0 - 1.0)
  final String? notes; // short human-friendly note
  final String? rawText; // original sentence/snippet parsed
  final double? parseConfidence;
  final String? discName; //(to be matched to bag)
  final DGDisc? disc;

  factory DiscThrow.fromJson(Map<String, dynamic> json) =>
      _$DiscThrowFromJson(json);
  Map<String, dynamic> toJson() => _$DiscThrowToJson(this);
}

/* ============================
   Enums (LLM-friendly, minimal)
   ============================ */

/// What the throw was intended to be
enum ThrowPurpose {
  @JsonValue('tee_drive')
  teeDrive,
  @JsonValue('fairway_drive')
  fairwayDrive,
  @JsonValue('approach')
  approach,
  @JsonValue('putt')
  putt,
  @JsonValue('scramble')
  scramble,
  @JsonValue('penalty')
  penalty,
  @JsonValue('other')
  other,
}

/// Primary throwing technique
enum ThrowTechnique {
  @JsonValue('backhand')
  backhand,
  @JsonValue('forehand')
  forehand,
  @JsonValue('tomahawk')
  tomahawk,
  @JsonValue('thumber')
  thumber,
  @JsonValue('overhand')
  overhand,
  @JsonValue('backhand_roller')
  backhandRoller,
  @JsonValue('forehand_roller')
  forehandRoller,
  @JsonValue('grenade')
  grenade,
  @JsonValue('other')
  other,
}

/// Putt-specific styles (limited to the four you requested)
enum PuttStyle {
  @JsonValue('staggered')
  staggered,
  @JsonValue('straddle')
  straddle,
  @JsonValue('jump_putt')
  jumpPutt,
  @JsonValue('step_putt')
  stepPutt,
  @JsonValue('other')
  other,
}

/// Shot shape / release curve (includes rollers & short finesse shots)
enum ShotShape {
  @JsonValue('hyzer')
  hyzer,
  @JsonValue('anhyzer')
  anhyzer,
  @JsonValue('hyzer_flip')
  hyzerFlip,
  @JsonValue('turnover')
  turnover,
  @JsonValue('flat')
  flat,
  @JsonValue('flex_shot')
  flexShot,
  @JsonValue('spike_hyzer')
  spikeHyzer,
  @JsonValue('sky_anhyzer')
  skyAnhyzer,
  @JsonValue('roller')
  roller,
  @JsonValue('pitch')
  pitch,
  @JsonValue('skip')
  skip,
  @JsonValue('other')
  other,
}

/// Stance / footwork — per your instruction keep to these three (plus other)
enum StanceType {
  @JsonValue('standstill')
  standstill,
  @JsonValue('x_step')
  xStep,
  @JsonValue('patent_pending')
  patentPending,
  @JsonValue('other')
  other,
}

/// Thrower's dominant hand (helps disambiguate "lefty forehand" text)
enum ThrowHand {
  @JsonValue('right')
  right,
  @JsonValue('left')
  left,
  @JsonValue('ambidextrous')
  ambidextrous,
  @JsonValue('unknown')
  unknown,
  @JsonValue('other')
  other,
}

/// Power / effort of the throw (qualitative)
enum ThrowPower {
  @JsonValue('putt')
  putt,
  @JsonValue('soft')
  soft,
  @JsonValue('controlled')
  controlled,
  @JsonValue('full')
  full,
  @JsonValue('max')
  max,
  @JsonValue('other')
  other,
}

/// Grip type (generalized)
enum GripType {
  @JsonValue('power')
  power,
  @JsonValue('fan')
  fan,
  @JsonValue('modified')
  modified,
  @JsonValue('putt_grip')
  puttGrip,
  @JsonValue('other')
  other,
}

/// Wind direction (keep orthogonal to wind strength)
enum WindDirection {
  @JsonValue('none')
  none,
  @JsonValue('headwind')
  headwind,
  @JsonValue('tailwind')
  tailwind,
  @JsonValue('left_to_right')
  leftToRight,
  @JsonValue('right_to_left')
  rightToLeft,
  @JsonValue('swirling')
  swirling,
  @JsonValue('other')
  other,
}

/// Wind strength as an integer scale (JSON serializes as 1..5)
enum WindStrength {
  @JsonValue('calm')
  calm, // calm/negligible
  @JsonValue('light')
  light, // light
  @JsonValue('moderate')
  moderate, // moderate
  @JsonValue('strong')
  strong, // strong
  @JsonValue('extreme')
  extreme, // extreme / gale
}

/// Result quality rating (1-5 scale)
enum ThrowResultRating {
  @JsonValue('terrible')
  terrible,
  @JsonValue('poor')
  poor,
  @JsonValue('average')
  average,
  @JsonValue('good')
  good,
  @JsonValue('excellent')
  excellent,
}

/// High-level outcome of the throw (exact list you specified)
enum LandingSpot {
  @JsonValue('in_basket')
  inBasket,
  @JsonValue('parked')
  parked,
  @JsonValue('circle_1')
  circle1,
  @JsonValue('circle_2')
  circle2,
  @JsonValue('fairway')
  fairway,
  @JsonValue('off_fairway')
  offFairway,
  @JsonValue('out_of_bounds')
  outOfBounds,
  @JsonValue('other')
  other,
}

/// Fairway width / openness (hole-level attribute you requested)
enum FairwayWidth {
  @JsonValue('open')
  open,
  @JsonValue('moderate')
  moderate,
  @JsonValue('tight')
  tight,
  @JsonValue('very_tight')
  veryTight,
}

/// Hole type / terrain characteristics
enum HoleType {
  @JsonValue('open')
  open,
  @JsonValue('slightly_wooded')
  slightlyWooded,
  @JsonValue('wooded')
  wooded,
}

enum PuttingCircle {
  @JsonValue('circle_1')
  circle1,
  @JsonValue('circle_2')
  circle2,
}
