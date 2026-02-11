import 'package:json_annotation/json_annotation.dart';

part 'observation_measurement_component.g.dart';

/// A single component of a composite measurement (e.g., knee angle, toe-down angle, slip)
@JsonSerializable()
class ObservationMeasurementComponent {
  const ObservationMeasurementComponent({
    required this.name,
    required this.label,
    required this.measuredValue,
    required this.score,
    required this.unit,
    this.idealValue,
  });

  /// Identifier for this component (e.g., 'knee_inward', 'toe_down', 'slip')
  final String name;

  /// Human-readable label (e.g., 'Knee inward angle')
  final String label;

  /// Raw measured value
  @JsonKey(name: 'measured_value')
  final double measuredValue;

  /// Component score (0-100)
  final double score;

  /// Unit of measurement (e.g., 'degrees', 'percent')
  final String unit;

  /// Ideal/target value (optional)
  @JsonKey(name: 'ideal_value')
  final double? idealValue;

  /// Formatted string showing measured value with unit
  String get formattedMeasuredValue {
    final String lowerUnit = unit.toLowerCase();

    // Handle degrees - use degree symbol
    if (lowerUnit == 'degrees' || lowerUnit == 'degree') {
      return '${measuredValue.toStringAsFixed(1)}°';
    }

    // Handle percent
    if (lowerUnit == 'percent' || lowerUnit == '%') {
      return '${measuredValue.toStringAsFixed(1)}%';
    }

    // Other units - format nicely
    return '${measuredValue.toStringAsFixed(1)} $unit';
  }

  /// Score as an integer percentage (0-100)
  int get scorePercent => score.round();

  factory ObservationMeasurementComponent.fromJson(Map<String, dynamic> json) =>
      _$ObservationMeasurementComponentFromJson(json);
  Map<String, dynamic> toJson() => _$ObservationMeasurementComponentToJson(this);
}
