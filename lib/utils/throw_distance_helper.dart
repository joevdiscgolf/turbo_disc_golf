import 'package:turbo_disc_golf/models/data/throw_data.dart';

/// Helper for managing throw distance cascading.
///
/// When a throw's distance is edited, adjacent throws should be updated
/// to maintain consistency:
/// - If distanceFeetAfterThrow changes, the next throw's distanceFeetBeforeThrow
///   should match (where this throw landed is where the next throw starts)
/// - If distanceFeetBeforeThrow changes, the previous throw's distanceFeetAfterThrow
///   should match (where this throw starts is where the previous throw landed)
class ThrowDistanceHelper {
  /// Updates a throw in the list and cascades distance changes to adjacent throws.
  ///
  /// Returns the updated list of throws with cascaded distances.
  static List<DiscThrow> updateThrowWithCascade({
    required List<DiscThrow> throws,
    required int throwIndex,
    required DiscThrow updatedThrow,
  }) {
    if (throwIndex < 0 || throwIndex >= throws.length) {
      return throws;
    }

    final List<DiscThrow> updatedThrows = List<DiscThrow>.from(throws);
    final DiscThrow originalThrow = updatedThrows[throwIndex];

    // Update the current throw
    updatedThrows[throwIndex] = _copyThrow(updatedThrow);

    // Cascade distanceFeetAfterThrow to next throw's distanceFeetBeforeThrow
    if (updatedThrow.distanceFeetAfterThrow != null &&
        updatedThrow.distanceFeetAfterThrow !=
            originalThrow.distanceFeetAfterThrow &&
        throwIndex < updatedThrows.length - 1) {
      final DiscThrow nextThrow = updatedThrows[throwIndex + 1];
      updatedThrows[throwIndex + 1] = _copyThrowWithDistanceBefore(
        nextThrow,
        updatedThrow.distanceFeetAfterThrow,
      );
    }

    // Cascade distanceFeetBeforeThrow to previous throw's distanceFeetAfterThrow
    if (updatedThrow.distanceFeetBeforeThrow != null &&
        updatedThrow.distanceFeetBeforeThrow !=
            originalThrow.distanceFeetBeforeThrow &&
        throwIndex > 0) {
      final DiscThrow prevThrow = updatedThrows[throwIndex - 1];
      updatedThrows[throwIndex - 1] = _copyThrowWithDistanceAfter(
        prevThrow,
        updatedThrow.distanceFeetBeforeThrow,
      );
    }

    return updatedThrows;
  }

  /// Creates a copy of a throw with all its properties.
  static DiscThrow _copyThrow(DiscThrow throw_) {
    return DiscThrow(
      index: throw_.index,
      purpose: throw_.purpose,
      technique: throw_.technique,
      puttStyle: throw_.puttStyle,
      shotShape: throw_.shotShape,
      stance: throw_.stance,
      power: throw_.power,
      distanceFeetBeforeThrow: throw_.distanceFeetBeforeThrow,
      distanceFeetAfterThrow: throw_.distanceFeetAfterThrow,
      elevationChangeFeet: throw_.elevationChangeFeet,
      windDirection: throw_.windDirection,
      windStrength: throw_.windStrength,
      resultRating: throw_.resultRating,
      landingSpot: throw_.landingSpot,
      fairwayWidth: throw_.fairwayWidth,
      customPenaltyStrokes: throw_.customPenaltyStrokes,
      notes: throw_.notes,
      rawText: throw_.rawText,
      parseConfidence: throw_.parseConfidence,
      discName: throw_.discName,
      disc: throw_.disc,
    );
  }

  /// Creates a copy of a throw with a new distanceFeetBeforeThrow.
  static DiscThrow _copyThrowWithDistanceBefore(
    DiscThrow throw_,
    int? distanceBefore,
  ) {
    return DiscThrow(
      index: throw_.index,
      purpose: throw_.purpose,
      technique: throw_.technique,
      puttStyle: throw_.puttStyle,
      shotShape: throw_.shotShape,
      stance: throw_.stance,
      power: throw_.power,
      distanceFeetBeforeThrow: distanceBefore,
      distanceFeetAfterThrow: throw_.distanceFeetAfterThrow,
      elevationChangeFeet: throw_.elevationChangeFeet,
      windDirection: throw_.windDirection,
      windStrength: throw_.windStrength,
      resultRating: throw_.resultRating,
      landingSpot: throw_.landingSpot,
      fairwayWidth: throw_.fairwayWidth,
      customPenaltyStrokes: throw_.customPenaltyStrokes,
      notes: throw_.notes,
      rawText: throw_.rawText,
      parseConfidence: throw_.parseConfidence,
      discName: throw_.discName,
      disc: throw_.disc,
    );
  }

  /// Creates a copy of a throw with a new distanceFeetAfterThrow.
  static DiscThrow _copyThrowWithDistanceAfter(
    DiscThrow throw_,
    int? distanceAfter,
  ) {
    return DiscThrow(
      index: throw_.index,
      purpose: throw_.purpose,
      technique: throw_.technique,
      puttStyle: throw_.puttStyle,
      shotShape: throw_.shotShape,
      stance: throw_.stance,
      power: throw_.power,
      distanceFeetBeforeThrow: throw_.distanceFeetBeforeThrow,
      distanceFeetAfterThrow: distanceAfter,
      elevationChangeFeet: throw_.elevationChangeFeet,
      windDirection: throw_.windDirection,
      windStrength: throw_.windStrength,
      resultRating: throw_.resultRating,
      landingSpot: throw_.landingSpot,
      fairwayWidth: throw_.fairwayWidth,
      customPenaltyStrokes: throw_.customPenaltyStrokes,
      notes: throw_.notes,
      rawText: throw_.rawText,
      parseConfidence: throw_.parseConfidence,
      discName: throw_.discName,
      disc: throw_.disc,
    );
  }
}
