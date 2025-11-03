import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

/// Represents detailed information about a specific shot on a hole
class ShotDetail {
  const ShotDetail({
    required this.hole,
    required this.throwIndex,
    required this.shotOutcome,
  });

  final DGHole hole;
  final int throwIndex;
  final ShotOutcome shotOutcome;

  DiscThrow get discThrow => hole.throws[throwIndex];

  int get holeNumber => hole.number;
  int get par => hole.par;
  int? get distance => hole.feet;
  int get score => hole.holeScore;
  int get relativeScore => hole.relativeHoleScore;
}

/// Tracks the outcome of a shot across multiple metrics
class ShotOutcome {
  const ShotOutcome({
    required this.wasBirdie,
    required this.wasC1InReg,
    required this.wasC2InReg,
  });

  final bool wasBirdie;
  final bool wasC1InReg;
  final bool wasC2InReg;

  /// Returns true if this shot was successful for the given metric
  bool isSuccessForMetric(ShotMetric metric) {
    switch (metric) {
      case ShotMetric.birdie:
        return wasBirdie;
      case ShotMetric.c1InReg:
        return wasC1InReg;
      case ShotMetric.c2InReg:
        return wasC2InReg;
    }
  }
}

/// Metrics we track for shot success
enum ShotMetric {
  birdie,
  c1InReg,
  c2InReg,
}

extension ShotMetricExtension on ShotMetric {
  String get displayName {
    switch (this) {
      case ShotMetric.birdie:
        return 'Birdie';
      case ShotMetric.c1InReg:
        return 'C1 in Reg';
      case ShotMetric.c2InReg:
        return 'C2 in Reg';
    }
  }
}
