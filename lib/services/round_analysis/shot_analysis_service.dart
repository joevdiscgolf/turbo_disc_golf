import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

class ShotAnalysisService {
  /// Determine if a shot was successful based on outcome
  bool isSuccessfulShot(DiscThrow discThrow, DGHole hole) {
    // Made putt = success
    if (discThrow.landingSpot == LandingSpot.inBasket) return true;

    // Good landing spots = success
    if (discThrow.landingSpot == LandingSpot.parked) return true;
    if (discThrow.landingSpot == LandingSpot.circle1) return true;
    if (discThrow.landingSpot == LandingSpot.circle2) return true;
    if (discThrow.landingSpot == LandingSpot.fairway) return true;

    // Bad outcomes = failure
    if (discThrow.landingSpot == LandingSpot.outOfBounds) return false;
    if (discThrow.landingSpot == LandingSpot.offFairway) return false;
    if (discThrow.customPenaltyStrokes != null &&
        discThrow.customPenaltyStrokes! > 0) {
      return false;
    }

    // Hole resulted in birdie and this was tee shot or approach = success
    if (hole.relativeHoleScore < 0 &&
        (discThrow.purpose == ThrowPurpose.teeDrive ||
            discThrow.purpose == ThrowPurpose.fairwayDrive ||
            discThrow.purpose == ThrowPurpose.approach)) {
      return true;
    }

    // Use result rating as fallback if available
    if (discThrow.resultRating == ThrowResultRating.excellent ||
        discThrow.resultRating == ThrowResultRating.good) {
      return true;
    }

    // Default: not clearly successful
    return false;
  }
}
