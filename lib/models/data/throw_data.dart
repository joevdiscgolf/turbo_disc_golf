import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

part 'throw_data.g.dart';

// Custom converter for ShotCondition list with logging
class ShotConditionListConverter implements JsonConverter<List<ShotCondition>?, List<dynamic>?> {
  const ShotConditionListConverter();

  @override
  List<ShotCondition>? fromJson(List<dynamic>? json) {
    if (json == null) return null;

    final List<ShotCondition> result = [];
    for (final value in json) {
      if (value is String) {
        try {
          // Try to find matching enum value
          final condition = ShotCondition.values.firstWhere(
            (e) => e.name == value ||
                   e.toString().split('.').last == value ||
                   _getJsonValue(e) == value,
            orElse: () {
              debugPrint('⚠️ WARNING: Invalid ShotCondition value "$value" - using "other"');
              return ShotCondition.other;
            },
          );
          result.add(condition);
        } catch (e) {
          debugPrint('⚠️ WARNING: Error parsing ShotCondition "$value" - using "other": $e');
          result.add(ShotCondition.other);
        }
      }
    }
    return result.isEmpty ? null : result;
  }

  @override
  List<String>? toJson(List<ShotCondition>? object) {
    return object?.map((e) => _getJsonValue(e) ?? e.name).toList();
  }

  static String? _getJsonValue(ShotCondition condition) {
    // Helper to get the JsonValue annotation value
    switch (condition) {
      case ShotCondition.tunnelShot: return 'tunnel_shot';
      case ShotCondition.gapShot: return 'gap_shot';
      case ShotCondition.lowCeiling: return 'low_ceiling';
      case ShotCondition.islandHole: return 'island_hole';
      case ShotCondition.waterCarry: return 'water_carry';
      case ShotCondition.obLeft: return 'ob_left';
      case ShotCondition.obRight: return 'ob_right';
      case ShotCondition.deathPutt: return 'death_putt';
      case ShotCondition.elevatedBasket: return 'elevated_basket';
      case ShotCondition.downhill: return 'downhill';
      case ShotCondition.uphill: return 'uphill';
      case ShotCondition.doglegLeft: return 'dogleg_left';
      case ShotCondition.doglegRight: return 'dogleg_right';
      case ShotCondition.other: return 'other';
    }
  }
}

// Basic throw classification
enum DiscThrowType {
  @JsonValue('drive')
  drive,
  @JsonValue('approach')
  approach,
  @JsonValue('putt')
  putt,
  @JsonValue('fairway')
  fairway,
  @JsonValue('upshot')
  upshot,
  @JsonValue('other')
  other,
}

// Throw technique/style
enum ThrowTechnique {
  @JsonValue('backhand')
  backhand,
  @JsonValue('forehand')
  forehand,
  @JsonValue('tomahawk')
  tomahawk,
  @JsonValue('thumber')
  thumber,
  @JsonValue('backhand_roller')
  backhandRoller,
  @JsonValue('forehand_roller')
  forehandRoller,
  @JsonValue('putt')
  putt,
  @JsonValue('jump_putt')
  jumpPutt,
  @JsonValue('step_putt')
  stepPutt,
  @JsonValue('turbo_putt')
  turboPutt,
  @JsonValue('straddle_putt')
  straddlePutt,
  @JsonValue('other')
  other,
}

// Shot shape/angle
enum ShotType {
  @JsonValue('hyzer')
  hyzer,
  @JsonValue('anhyzer')
  anhyzer,
  @JsonValue('hyzer_flip')
  hyzerFlip,
  @JsonValue('flex_shot')
  flexShot,
  @JsonValue('flat')
  flat,
  @JsonValue('spike_hyzer')
  spikeHyzer,
  @JsonValue('grenade')
  grenade,
  @JsonValue('sky_anhyzer')
  skyAnhyzer,
  @JsonValue('other')
  other,
}

// Stance type
enum StanceType {
  @JsonValue('standstill')
  standstill,
  @JsonValue('x_step')
  xStep,
  @JsonValue('run_up')
  runUp,
  @JsonValue('straddle')
  straddle,
  @JsonValue('jump')
  jump,
  @JsonValue('step_through')
  stepThrough,
  @JsonValue('other')
  other,
}

// Shot conditions/challenges
enum ShotCondition {
  @JsonValue('tunnel_shot')
  tunnelShot,
  @JsonValue('gap_shot')
  gapShot,
  @JsonValue('low_ceiling')
  lowCeiling,
  @JsonValue('island_hole')
  islandHole,
  @JsonValue('water_carry')
  waterCarry,
  @JsonValue('ob_left')
  obLeft,
  @JsonValue('ob_right')
  obRight,
  @JsonValue('death_putt')
  deathPutt,
  @JsonValue('elevated_basket')
  elevatedBasket,
  @JsonValue('downhill')
  downhill,
  @JsonValue('uphill')
  uphill,
  @JsonValue('dogleg_left')
  doglegLeft,
  @JsonValue('dogleg_right')
  doglegRight,
  @JsonValue('other')
  other,
}

// Wind conditions
enum WindCondition {
  @JsonValue('headwind')
  headwind,
  @JsonValue('tailwind')
  tailwind,
  @JsonValue('left_to_right_crosswind')
  leftToRightCrosswind,
  @JsonValue('right_to_left_crosswind')
  rightToLeftCrosswind,
  @JsonValue('other')
  other,
}

// Result quality rating (1-5 scale)
enum ThrowResultRating {
  @JsonValue(1)
  terrible, // 1 - Way off target, OB, lost disc
  @JsonValue(2)
  poor, // 2 - Bad position, recovery needed
  @JsonValue(3)
  average, // 3 - Acceptable, playable lie
  @JsonValue(4)
  good, // 4 - Good position, birdie opportunity
  @JsonValue(5)
  excellent, // 5 - Perfect shot, parked, ace
}

// Landing zone
enum LandingZone {
  @JsonValue('circle_1')
  circle1, // Within 10m/33ft
  @JsonValue('circle_2')
  circle2, // 10-20m/33-66ft
  @JsonValue('fairway')
  fairway,
  @JsonValue('rough')
  rough,
  @JsonValue('ob')
  ob,
  @JsonValue('water')
  water,
  @JsonValue('sand')
  sand,
  @JsonValue('basket')
  basket, // Made shot
  @JsonValue('pin_high')
  pinHigh,
  @JsonValue('short')
  short,
  @JsonValue('long')
  long,
  @JsonValue('left')
  left,
  @JsonValue('right')
  right,
  @JsonValue('other')
  other,
}

@JsonSerializable(explicitToJson: true, anyMap: true)
class DiscThrow {
  const DiscThrow({
    required this.distance,
    this.discName,
    this.discId,
    this.throwType,
    this.technique,
    this.shotType,
    this.stance,
    this.conditions,
    this.windCondition,
    this.resultRating,
    this.landingZone,
    this.distanceFromBasketBefore,
    this.distanceFromBasketAfter,
    this.description,
    this.result,
    this.madeShot,
    this.obPenalty,
    this.notes,
    // Add more optional fields here as needed
  });

  // Core fields
  final int distance; // Distance thrown
  final String? discName;
  final String? discId;

  // Throw classification
  @JsonKey(unknownEnumValue: DiscThrowType.other)
  final DiscThrowType? throwType;

  @JsonKey(unknownEnumValue: ThrowTechnique.other)
  final ThrowTechnique? technique;

  @JsonKey(unknownEnumValue: ShotType.other)
  final ShotType? shotType;

  @JsonKey(unknownEnumValue: StanceType.other)
  final StanceType? stance;

  // Conditions (can have multiple)
  @ShotConditionListConverter()
  final List<ShotCondition>? conditions;

  @JsonKey(unknownEnumValue: WindCondition.other)
  final WindCondition? windCondition;

  // Result data
  final ThrowResultRating? resultRating;

  @JsonKey(unknownEnumValue: LandingZone.other)
  final LandingZone? landingZone;
  final int? distanceFromBasketBefore; // Distance before throw (in feet)
  final int? distanceFromBasketAfter; // Distance after throw (in feet)
  final bool? madeShot; // Did it go in the basket?
  final bool? obPenalty; // Out of bounds penalty stroke?

  // Text descriptions
  final String? description; // Natural language description from voice input
  final String? result; // Legacy field: "parked", "OB", "C1", "C2", etc.
  final String? notes; // Additional notes

  // Add more optional fields below as needed
  // Example: final String? windSpeed;
  // Example: final double? throwAngle;
  // Example: final DateTime? throwTime;

  // Custom fromJson with logging for invalid enum values
  factory DiscThrow.fromJson(Map<String, dynamic> json) {
    // Log warnings for invalid enum values that will fallback to 'other'
    _logEnumWarnings(json);

    return _$DiscThrowFromJson(json);
  }

  Map<String, dynamic> toJson() => _$DiscThrowToJson(this);

  // Helper method to log warnings for invalid enum values
  static void _logEnumWarnings(Map<String, dynamic> json) {
    // Check throwType
    if (json['throwType'] != null && json['throwType'] is String) {
      final value = json['throwType'] as String;
      if (!_isValidEnumValue(DiscThrowType.values, value)) {
        debugPrint('⚠️ WARNING: Invalid throwType value "$value" - using "other"');
      }
    }

    // Check technique
    if (json['technique'] != null && json['technique'] is String) {
      final value = json['technique'] as String;
      if (!_isValidEnumValue(ThrowTechnique.values, value)) {
        debugPrint('⚠️ WARNING: Invalid technique value "$value" - using "other"');
      }
    }

    // Check shotType
    if (json['shotType'] != null && json['shotType'] is String) {
      final value = json['shotType'] as String;
      if (!_isValidEnumValue(ShotType.values, value)) {
        debugPrint('⚠️ WARNING: Invalid shotType value "$value" - using "other"');
      }
    }

    // Check stance
    if (json['stance'] != null && json['stance'] is String) {
      final value = json['stance'] as String;
      if (!_isValidEnumValue(StanceType.values, value)) {
        debugPrint('⚠️ WARNING: Invalid stance value "$value" - using "other"');
      }
    }

    // Check windCondition
    if (json['windCondition'] != null && json['windCondition'] is String) {
      final value = json['windCondition'] as String;
      if (!_isValidEnumValue(WindCondition.values, value)) {
        debugPrint('⚠️ WARNING: Invalid windCondition value "$value" - using "other"');
      }
    }

    // Check landingZone
    if (json['landingZone'] != null && json['landingZone'] is String) {
      final value = json['landingZone'] as String;
      if (!_isValidEnumValue(LandingZone.values, value)) {
        debugPrint('⚠️ WARNING: Invalid landingZone value "$value" - using "other"');
      }
    }

    // Check resultRating (should be 1-5)
    if (json['resultRating'] != null) {
      final value = json['resultRating'];
      if (value is! int || value < 1 || value > 5) {
        debugPrint('⚠️ WARNING: Invalid resultRating value "$value" - should be 1-5');
      }
    }
  }

  // Helper to check if a string value is valid for an enum
  static bool _isValidEnumValue<T extends Enum>(List<T> values, String value) {
    return values.any((e) =>
      e.name == value ||
      e.toString().split('.').last == value ||
      _toSnakeCase(e.name) == value
    );
  }

  // Convert camelCase to snake_case
  static String _toSnakeCase(String input) {
    return input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (Match m) => '_${m[0]!.toLowerCase()}',
    ).replaceAll(RegExp(r'^_'), '');
  }

  // Helper methods
  bool get isAce => madeShot == true && throwType == DiscThrowType.drive;
  bool get isParked => distanceFromBasketAfter != null && distanceFromBasketAfter! <= 10;
  bool get isCircle1 => landingZone == LandingZone.circle1;
  bool get isCircle2 => landingZone == LandingZone.circle2;
}
