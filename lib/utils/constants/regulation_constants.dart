import 'package:turbo_disc_golf/models/data/throw_data.dart';

/// Checks if a throw at the given index is eligible to count toward C1/C2 in regulation.
/// Only throws that could realistically reach C1 for a birdie opportunity should count.
///
/// - Par 3: throwIndex >= 0 (tee shot should try for C1)
/// - Par 4: throwIndex >= 1 (second shot should try for C1)
/// - Par 5: throwIndex >= 2 (third shot should try for C1)
bool isThrowEligibleForCircleInReg(int throwIndex, int par) {
  return throwIndex >= (par - 3);
}

/// Checks if the landing spot qualifies as C1 in regulation
bool isC1Landing(LandingSpot? landing) {
  return landing == LandingSpot.circle1 || landing == LandingSpot.parked;
}

/// Checks if the landing spot qualifies as C2 in regulation (includes C1)
bool isC2Landing(LandingSpot? landing) {
  return landing == LandingSpot.circle1 ||
      landing == LandingSpot.circle2 ||
      landing == LandingSpot.parked;
}
