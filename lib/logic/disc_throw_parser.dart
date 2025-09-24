// disc_throw_parser.dart
import 'package:turbo_disc_golf/models/data/throw_data.dart';

class DiscThrowParser {
  // ---------- public entry ----------
  static DiscThrow parseThrow(String raw, int index) {
    final text = raw.toLowerCase().trim();
    final fieldConfidence = <String, double>{};

    // distance (ft/meters)
    final feet = _extractFeet(text);
    final meters = _extractMeters(text);
    int? distanceFeet;
    if (feet != null) {
      distanceFeet = feet;
      fieldConfidence['distance'] = 0.95;
    } else if (meters != null) {
      distanceFeet = (meters / 0.3048).round();
      fieldConfidence['distance'] = 0.95;
    }

    // elevation
    final elevationFeet = _extractElevationFeet(text);
    if (elevationFeet != null) fieldConfidence['elevation'] = 0.9;

    // wind
    final windInfo = _extractWind(text);
    WindDirection? windDir = windInfo?['direction'];
    WindStrength? windStrength = windInfo?['strength'];
    if (windDir != null) fieldConfidence['windDirection'] = 0.85;
    if (windStrength != null) fieldConfidence['windStrength'] = 0.9;

    // enums
    final purpose = _matchPurpose(text);
    if (purpose != null) fieldConfidence['purpose'] = 0.9;

    final technique = _matchTechnique(text);
    if (technique != null) fieldConfidence['technique'] = 0.9;

    final puttStyle = _matchPuttStyle(text);
    if (puttStyle != null) fieldConfidence['puttStyle'] = 0.9;

    final shotShape = _matchShotShape(text);
    if (shotShape != null) fieldConfidence['shotShape'] = 0.9;

    final stance = _matchStance(text);
    if (stance != null) fieldConfidence['stance'] = 0.85;

    final hand = _matchHand(text);
    if (hand != null) fieldConfidence['hand'] = 0.9;

    final power = _matchPower(text);
    if (power != null) fieldConfidence['power'] = 0.7;

    final outcome = _matchOutcome(text);
    if (outcome != null) fieldConfidence['outcome'] = 0.95;

    final resultRating = _matchResultRating(text);
    if (resultRating != null) fieldConfidence['resultRating'] = 0.85;

    final fairwayWidth = _matchFairwayWidth(text);
    if (fairwayWidth != null) fieldConfidence['fairwayWidth'] = 0.75;

    return DiscThrow(
      index: index,
      purpose: purpose,
      technique: technique,
      puttStyle: puttStyle,
      shotShape: shotShape,
      stance: stance,
      power: power,
      distanceFeet: distanceFeet,
      elevationChangeFeet: elevationFeet,
      windDirection: windDir,
      windStrength: windStrength,
      resultRating: resultRating,
      fairwayWidth: fairwayWidth,
      notes: _briefNotes(text, purpose, technique, outcome),
      rawText: raw,
      parseConfidence: _computeOverallConfidence(fieldConfidence),
    );
  }

  // ---------- distance & wind extraction ----------
  static int? _extractFeet(String text) {
    final ftRegex = RegExp(r"(\d{2,4})\s*(?:ft|feet|foot|'|\bft\.)\b");
    final m = ftRegex.firstMatch(text);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  static double? _extractMeters(String text) {
    final mRegex = RegExp(r'(\d{2,4}(?:\.\d+)?)\s*(?:m|meters)\b');
    final m = mRegex.firstMatch(text);
    return m != null ? double.tryParse(m.group(1)!) : null;
  }

  static double? _extractElevationFeet(String text) {
    final reg = RegExp(
      r'(?:uphill|up|drops?|downhill|down)\s+(\d{1,3})\s*(?:ft|feet|m|meters)?',
    );
    final m = reg.firstMatch(text);
    if (m != null) return double.tryParse(m.group(1)!);
    return null;
  }

  static Map<String, dynamic>? _extractWind(String text) {
    final mph = RegExp(
      r'(\d{1,2}(?:\.\d+)?)\s*(?:mph|mi/h)\b',
    ).firstMatch(text);
    if (mph != null) {
      final sp = double.tryParse(mph.group(1)!)!;
      return {
        'direction': _matchWindDirection(text),
        'strength': _windSpeedToLevel(sp, 'mph'),
      };
    }
    final kmh = RegExp(
      r'(\d{2,3}(?:\.\d+)?)\s*(?:km/h|kph)\b',
    ).firstMatch(text);
    if (kmh != null) {
      final sp = double.tryParse(kmh.group(1)!)!;
      return {
        'direction': _matchWindDirection(text),
        'strength': _windSpeedToLevel(sp, 'kmh'),
      };
    }

    // spoken descriptions
    if (text.contains('headwind') || text.contains('head breeze')) {
      final lvl = text.contains('strong')
          ? WindStrength.strong
          : WindStrength.light;
      return {'direction': WindDirection.headwind, 'strength': lvl};
    }
    if (text.contains('tailwind') || text.contains('tail breeze')) {
      final lvl = text.contains('strong')
          ? WindStrength.strong
          : WindStrength.light;
      return {'direction': WindDirection.tailwind, 'strength': lvl};
    }
    if (text.contains('crosswind') ||
        text.contains('left to right') ||
        text.contains('right to left')) {
      final dir = _matchWindDirection(text);
      return {'direction': dir, 'strength': WindStrength.moderate};
    }
    if (text.contains('gust') || text.contains('swirl')) {
      return {
        'direction': WindDirection.swirling,
        'strength': WindStrength.strong,
      };
    }
    return null;
  }

  static WindStrength _windSpeedToLevel(double speed, String unit) {
    if (unit == 'kmh') speed = speed * 0.621371;
    if (speed <= 5) return WindStrength.calm;
    if (speed <= 10) return WindStrength.light;
    if (speed <= 20) return WindStrength.moderate;
    if (speed <= 30) return WindStrength.strong;
    return WindStrength.extreme;
  }

  // ---------- keyword mapping (expanded for voice/slang) ----------
  static ThrowPurpose? _matchPurpose(String t) {
    final map = <ThrowPurpose, List<String>>{
      ThrowPurpose.teeDrive: [
        'tee',
        'tee shot',
        'drive',
        'bomb',
        'crushed it',
        'rip',
        'opening shot',
      ],
      ThrowPurpose.fairwayDrive: [
        'fairway',
        'second shot',
        'layup drive',
        'long approach',
      ],
      ThrowPurpose.approach: [
        'approach',
        'upshot',
        'chip',
        'short approach',
        'layup',
        'attack the pin',
      ],
      ThrowPurpose.putt: ['putt', 'putted', 'tap in', 'drop in', 'knock in'],
      ThrowPurpose.scramble: [
        'scramble',
        'recovery',
        'pitch out',
        'escape',
        'save par',
        'get out of trouble',
      ],
      ThrowPurpose.penalty: [
        'penalty',
        'drop zone',
        'stroke',
        'mando drop',
        'rethrow',
      ],
    };
    return _firstMatchEnum(map, t);
  }

  static ThrowTechnique? _matchTechnique(String t) {
    final map = <ThrowTechnique, List<String>>{
      ThrowTechnique.backhand: ['backhand', 'bh', 'back hand', 'traditional'],
      ThrowTechnique.forehand: [
        'forehand',
        'fh',
        'sidearm',
        'flick',
        'flick shot',
      ],
      ThrowTechnique.tomahawk: ['tomahawk', 'hammer'],
      ThrowTechnique.thumber: ['thumber'],
      ThrowTechnique.overhand: ['overhand', 'overhead'],
      ThrowTechnique.backhandRoller: [
        'backhand roller',
        'bh roller',
        'cut roller',
      ],
      ThrowTechnique.forehandRoller: [
        'forehand roller',
        'fh roller',
        'sky roller',
      ],
      ThrowTechnique.grenade: ['grenade', 'pancake'],
    };
    return _firstMatchEnum(map, t, preferCompound: true);
  }

  static PuttStyle? _matchPuttStyle(String t) {
    final map = <PuttStyle, List<String>>{
      PuttStyle.staggered: ['staggered stance'],
      PuttStyle.straddle: ['straddle'],
      PuttStyle.jumpPutt: ['jump putt'],
      PuttStyle.stepPutt: ['step putt', 'step through'],
    };
    return _firstMatchEnum(map, t);
  }

  static ShotShape? _matchShotShape(String t) {
    final map = <ShotShape, List<String>>{
      ShotShape.hyzer: ['hyzer', 'dump', 'fade out'],
      ShotShape.hyzerFlip: ['hyzer flip', 'flip to flat', 'flip'],
      ShotShape.anhyzer: ['anhyzer', 'anny'],
      ShotShape.turnover: ['turnover', 'turn over'],
      ShotShape.flat: ['flat'],
      ShotShape.flexShot: ['flex', 's shot', 's curve'],
      ShotShape.spikeHyzer: ['spike hyzer', 'spike'],
      ShotShape.skyAnhyzer: ['sky anhyzer'],
      ShotShape.roller: ['roller', 'cut roller', 'sky roller'],
      ShotShape.pitch: ['pitch', 'touch', 'finesse'],
      ShotShape.skip: ['skip', 'big skip', 'skipped'],
    };
    return _firstMatchEnum(map, t, preferCompound: true);
  }

  static StanceType? _matchStance(String t) {
    final map = <StanceType, List<String>>{
      StanceType.xStep: ['x step', 'x-step'],
      StanceType.standstill: ['standstill', 'no run up', 'standing still'],
      StanceType.patentPending: [
        'patent pending',
        'weird stance',
        'back to basket',
      ],
    };
    return _firstMatchEnum(map, t);
  }

  static ThrowHand? _matchHand(String t) {
    final map = <ThrowHand, List<String>>{
      ThrowHand.left: ['lefty', 'left hand', 'left handed'],
      ThrowHand.right: ['righty', 'right hand', 'right handed'],
      ThrowHand.ambidextrous: ['both hands', 'switched', 'off hand'],
    };
    return _firstMatchEnum(map, t);
  }

  static ThrowPower? _matchPower(String t) {
    final map = <ThrowPower, List<String>>{
      ThrowPower.putt: ['tap in', 'putt'],
      ThrowPower.soft: ['soft', 'gentle', 'touch', 'finesse'],
      ThrowPower.controlled: ['controlled', 'smooth', 'easy', 'eighty percent'],
      ThrowPower.full: ['full', 'ripped', 'solid power'],
      ThrowPower.max: ['max', 'crushed', 'all out'],
    };
    return _firstMatchEnum(map, t);
  }

  static LandingSpot? _matchOutcome(String t) {
    final map = <LandingSpot, List<String>>{
      LandingSpot.inBasket: ['ace', 'in the basket', 'chains', 'dropped in'],
      LandingSpot.parked: ['parked', 'bullseye', 'drop in', 'under the basket'],
      LandingSpot.circle1: ['circle one', 'c1', 'inside the circle'],
      LandingSpot.circle2: ['circle two', 'c2', 'long putt look'],
      LandingSpot.fairway: ['fairway', 'in play', 'short grass', 'middle'],
      LandingSpot.offFairway: [
        'rough',
        'jail',
        'woods',
        'shule',
        'off fairway',
      ],
      LandingSpot.outOfBounds: [
        'ob',
        'out of bounds',
        'hazard',
        'stroke and distance',
      ],
    };
    return _firstMatchEnum(map, t, preferCompound: true);
  }

  static ThrowResultRating? _matchResultRating(String t) {
    if (t.contains('ace') || t.contains('parked') || t.contains('nailed it')) {
      return ThrowResultRating.excellent;
    }
    if (t.contains('good') || t.contains('solid') || t.contains('smooth')) {
      return ThrowResultRating.good;
    }
    if (t.contains('ok') || t.contains('decent') || t.contains('average')) {
      return ThrowResultRating.average;
    }
    if (t.contains('bad') || t.contains('poor')) return ThrowResultRating.poor;
    if (t.contains('lost') || t.contains('ob') || t.contains('out of bounds')) {
      return ThrowResultRating.terrible;
    }
    return null;
  }

  static FairwayWidth? _matchFairwayWidth(String t) {
    final map = <FairwayWidth, List<String>>{
      FairwayWidth.open: ['open', 'wide open', 'field'],
      FairwayWidth.moderate: ['moderate', 'semi open', 'some trees'],
      FairwayWidth.tight: ['tight', 'narrow', 'wooded'],
      FairwayWidth.veryTight: ['very tight', 'gap', 'tunnel', 'needle'],
    };
    return _firstMatchEnum(map, t);
  }

  static WindDirection? _matchWindDirection(String t) {
    if (t.contains('headwind') || t.contains('head breeze'))
      return WindDirection.headwind;
    if (t.contains('tailwind') || t.contains('tail breeze'))
      return WindDirection.tailwind;
    if (t.contains('left to right')) return WindDirection.leftToRight;
    if (t.contains('right to left')) return WindDirection.rightToLeft;
    if (t.contains('swirl') || t.contains('gust'))
      return WindDirection.swirling;
    return null;
  }

  // ---------- utils ----------
  static T? _firstMatchEnum<T>(
    Map<T, List<String>> map,
    String text, {
    bool preferCompound = false,
  }) {
    if (preferCompound) {
      for (var entry in map.entries) {
        for (var kw in entry.value) {
          if (kw.contains(' ') && text.contains(kw)) {
            return entry.key;
          }
        }
      }
    }
    for (var entry in map.entries) {
      for (var kw in entry.value) {
        if (text.contains(kw)) return entry.key;
      }
    }
    return null;
  }

  static String _briefNotes(
    String text,
    ThrowPurpose? purpose,
    ThrowTechnique? tech,
    LandingSpot? outcome,
  ) {
    final parts = <String>[];
    if (purpose != null) parts.add('purpose:${purpose.name}');
    if (tech != null) parts.add('tech:${tech.name}');
    if (outcome != null) parts.add('outcome:${outcome.name}');
    if (parts.isEmpty) {
      return text.length <= 120 ? text : text.substring(0, 120);
    }
    return parts.join(', ');
  }

  static double _computeOverallConfidence(Map<String, double> fieldConf) {
    if (fieldConf.isEmpty) return 0.0;
    const weights = <String, double>{
      'distance': 2.0,
      'outcome': 2.0,
      'technique': 1.0,
      'shotShape': 1.0,
      'puttStyle': 1.2,
      'stance': 0.5,
      'hand': 0.5,
      'intent': 0.5,
      'windDirection': 0.4,
      'windStrength': 0.4,
      'resultRating': 0.6,
      'fairwayWidth': 0.5,
      'elevation': 0.6,
      'purpose': 1.0,
      'power': 0.4,
    };
    double sumW = 0, sum = 0;
    fieldConf.forEach((k, v) {
      final w = weights[k] ?? 0.5;
      sumW += w;
      sum += v * w;
    });
    return sumW == 0 ? 0.0 : (sum / sumW).clamp(0.0, 1.0);
  }
}
