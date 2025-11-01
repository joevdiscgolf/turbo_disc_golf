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

  String get displayName {
    return throwType.substring(0, 1).toUpperCase() + throwType.substring(1);
  }

  bool get hasSufficientData => totalHoles >= 3;
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

  String get displayName {
    final shape = shapeName.replaceAll(throwType, '').trim();
    return shape.substring(0, 1).toUpperCase() + shape.substring(1);
  }

  bool get hasSufficientData => totalAttempts >= 1;
}
