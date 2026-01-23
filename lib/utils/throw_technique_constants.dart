/// Metric types for throw statistics with semantic thresholds
enum MetricType {
  c1InReg,
  parked,
  ob,
  birdieRate,
}

/// Represents performance thresholds for a specific metric
class MetricThresholds {
  final double excellent; // Excellent performance threshold
  final double good; // Good performance threshold
  final double floor; // Worst reasonable performance
  final double ceiling; // Best reasonable performance
  final bool inverse; // true when lower is better

  const MetricThresholds({
    required this.excellent,
    required this.good,
    required this.floor,
    required this.ceiling,
    required this.inverse,
  });
}

/// Configuration of metric thresholds for all throw statistics
class MetricThresholdsConfig {
  static const Map<MetricType, MetricThresholds> thresholds = {
    /// C1 In Regulation: higher is better (65% excellent, 45% good)
    MetricType.c1InReg: MetricThresholds(
      excellent: 0.65,
      good: 0.45,
      floor: 0.20,
      ceiling: 0.85,
      inverse: false,
    ),

    /// Parked: higher is better (10% good, 20% excellent)
    MetricType.parked: MetricThresholds(
      excellent: 0.20,
      good: 0.10,
      floor: 0.0,
      ceiling: 0.35,
      inverse: false,
    ),

    /// Out of Bounds: lower is better (5% excellent, 15% good)
    MetricType.ob: MetricThresholds(
      excellent: 0.05,
      good: 0.15,
      floor: 0.0,
      ceiling: 0.30,
      inverse: true,
    ),

    /// Birdie Rate: higher is better (35% excellent, 20% good)
    MetricType.birdieRate: MetricThresholds(
      excellent: 0.35,
      good: 0.20,
      floor: 0.05,
      ceiling: 0.55,
      inverse: false,
    ),
  };

  static MetricThresholds getThresholds(MetricType type) {
    return thresholds[type]!;
  }
}

/// Abbreviations for disc golf throw techniques
class ThrowTechniqueAbbreviations {
  static const String backhand = 'BH';
  static const String forehand = 'FH';
  static const String tomahawk = 'TOM';
  static const String thumber = 'THM';
  static const String overhand = 'OH';
  static const String backhhandRoller = 'BH roll';
  static const String forehandRoller = 'FH roll';
  static const String grenade = 'GND';
  static const String other = 'Other';

  /// Get abbreviation for a throw technique
  static String getAbbreviation(String throwType) {
    final String lowerType = throwType.toLowerCase();
    switch (lowerType) {
      case 'backhand':
        return backhand;
      case 'forehand':
        return forehand;
      case 'tomahawk':
        return tomahawk;
      case 'thumber':
        return thumber;
      case 'overhand':
        return overhand;
      case 'backhand_roller':
        return backhhandRoller;
      case 'forehand_roller':
        return forehandRoller;
      case 'grenade':
        return grenade;
      case 'other':
        return other;
      default:
        return throwType;
    }
  }
}
