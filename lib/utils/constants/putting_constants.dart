// Constants for putting statistics and ranges
//
// These definitions follow PDGA standards for disc golf putting zones.

/// Circle 1 (C1): Putts from 0-33 feet
/// This represents putts inside Circle 1, which is regulation for scoring.
const double c1MaxDistance = 33.0;
const double c1MinDistance = 0.0;

/// Circle 1 Extended (C1X): Putts from 11-33 feet
/// This represents the outer portion of Circle 1, excluding gimme putts.
/// C1X is calculated by combining the '11-22 ft' and '22-33 ft' buckets.
const double c1xMinDistance = 11.0;
const double c1xMaxDistance = 33.0;
const List<String> c1xBuckets = ['11-22 ft', '22-33 ft'];

/// Circle 2 (C2): Putts from 33-66 feet
/// This represents putts inside Circle 2, the outer regulation circle.
const double c2MinDistance = 33.0;
const double c2MaxDistance = 66.0;
