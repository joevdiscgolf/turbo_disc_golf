import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

/// Represents a putt attempt with context about what the putt was for
class PuttAttempt {
  const PuttAttempt({
    required this.hole,
    required this.throwIndex,
    required this.distance,
    required this.made,
    required this.puttFor,
    this.isComeback = false,
  });

  final DGHole hole;
  final int throwIndex;
  final double distance;
  final bool made;
  final PuttFor puttFor;
  final bool isComeback;

  int get holeNumber => hole.number;
  int get par => hole.par;

  DiscThrow get discThrow => hole.throws[throwIndex];

  /// Which putt attempt this is on the hole (1st putt, 2nd putt, etc.)
  int get puttNumber {
    int count = 0;
    for (int i = 0; i <= throwIndex; i++) {
      if (hole.throws[i].purpose == ThrowPurpose.putt) {
        count++;
      }
    }
    return count;
  }

  String get puttNumberDisplay {
    final num = puttNumber;
    switch (num) {
      case 1:
        return '1st putt';
      case 2:
        return '2nd putt';
      case 3:
        return '3rd putt';
      default:
        return '${num}th putt';
    }
  }
}

/// What score making this putt would result in
enum PuttFor {
  eagle,
  birdie,
  par,
  bogey,
  doubleBogey,
  triplePlus;

  String get displayName {
    switch (this) {
      case PuttFor.eagle:
        return 'Eagle';
      case PuttFor.birdie:
        return 'Birdie';
      case PuttFor.par:
        return 'Par';
      case PuttFor.bogey:
        return 'Bogey';
      case PuttFor.doubleBogey:
        return 'Double';
      case PuttFor.triplePlus:
        return 'Triple+';
    }
  }

  String get shortName {
    switch (this) {
      case PuttFor.eagle:
        return 'Eag';
      case PuttFor.birdie:
        return 'Bir';
      case PuttFor.par:
        return 'Par';
      case PuttFor.bogey:
        return 'Bog';
      case PuttFor.doubleBogey:
        return 'Dbl';
      case PuttFor.triplePlus:
        return 'Tri+';
    }
  }

  String get puttDescription {
    switch (this) {
      case PuttFor.eagle:
        return 'eagle putt';
      case PuttFor.birdie:
        return 'birdie putt';
      case PuttFor.par:
        return 'par putt';
      case PuttFor.bogey:
        return 'bogey putt';
      case PuttFor.doubleBogey:
        return 'double bogey putt';
      case PuttFor.triplePlus:
        return 'triple+ putt';
    }
  }
}
