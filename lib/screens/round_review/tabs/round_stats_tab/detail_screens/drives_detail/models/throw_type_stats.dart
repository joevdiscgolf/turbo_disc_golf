class ThrowTypeStats {
  const ThrowTypeStats({
    required this.throwType,
    required this.birdieRate,
    required this.birdieCount,
    required this.totalHoles,
    required this.c1InRegPct,
    required this.c1Count,
    required this.c1Total,
    required this.c2InRegPct,
    required this.c2Count,
    required this.c2Total,
    this.averageDistance,
    this.parkedPct = 0.0,
    this.parkedCount = 0,
    this.fairwayPct = 0.0,
    this.fairwayCount = 0,
    this.obPct = 0.0,
    this.obCount = 0,
    this.averageThrowDistance,
    this.shotShapeDistribution = const {},
  });

  final String throwType;
  final double birdieRate;
  final int birdieCount;
  final int totalHoles;
  final double c1InRegPct;
  final int c1Count;
  final int c1Total;
  final double c2InRegPct;
  final int c2Count;
  final int c2Total;
  final double? averageDistance; // Hole distance (deprecated, use averageThrowDistance)

  // NEW FIELDS FOR DRIVES DETAIL SCREEN V2
  final double parkedPct; // Percentage of tee shots that landed parked
  final int parkedCount; // Count of parked landings
  final double fairwayPct; // Percentage of tee shots that hit fairway
  final int fairwayCount; // Count of fairway hits
  final double obPct; // Percentage of out of bounds
  final int obCount; // Count of OB throws
  final double? averageThrowDistance; // Actual throw distance (not hole distance)
  final Map<String, int> shotShapeDistribution; // Map of shot shape name to count

  String get displayName {
    return throwType.substring(0, 1).toUpperCase() + throwType.substring(1);
  }

  bool get hasSufficientData => totalHoles >= 3;

  String get distanceDisplay {
    if (averageThrowDistance != null) {
      return '${averageThrowDistance!.round()} ft avg';
    }
    if (averageDistance != null) return '${averageDistance!.round()} ft avg';
    return 'N/A';
  }
}

class ShotShapeStats {
  const ShotShapeStats({
    required this.shapeName,
    required this.throwType,
    required this.birdieRate,
    required this.birdieCount,
    required this.totalAttempts,
    required this.c1InRegPct,
    required this.c1Count,
    required this.c1Total,
    required this.c2InRegPct,
    required this.c2Count,
    required this.c2Total,
    this.parkedPct = 0.0,
    this.parkedCount = 0,
    this.obPct = 0.0,
    this.obCount = 0,
  });

  final String shapeName;
  final String throwType;
  final double birdieRate;
  final int birdieCount;
  final int totalAttempts;
  final double c1InRegPct;
  final int c1Count;
  final int c1Total;
  final double c2InRegPct;
  final int c2Count;
  final int c2Total;
  final double parkedPct;
  final int parkedCount;
  final double obPct;
  final int obCount;

  String get displayName {
    String shape = shapeName.replaceAll(throwType, '').trim();
    // Remove leading underscore if present
    if (shape.startsWith('_')) {
      shape = shape.substring(1);
    }
    // Capitalize first letter
    if (shape.isEmpty) return shape;
    return shape.substring(0, 1).toUpperCase() + shape.substring(1);
  }

  bool get hasSufficientData => totalAttempts >= 1;
}
