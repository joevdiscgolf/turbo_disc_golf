import 'package:json_annotation/json_annotation.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/observation_measurement_component.dart';

part 'observation_measurement.g.dart';

/// Quantitative measurement data for an observation
@JsonSerializable(explicitToJson: true)
class ObservationMeasurement {
  const ObservationMeasurement({
    required this.measuredValue,
    this.idealValue,
    this.deviation,
    required this.unit,
    this.deviationDirection,
    this.components,
  });

  /// The actual measured value
  @JsonKey(name: 'measured_value')
  final double measuredValue;

  /// The ideal/target value (optional)
  @JsonKey(name: 'ideal_value')
  final double? idealValue;

  /// How far off from ideal (can be positive or negative, optional)
  final double? deviation;

  /// Unit of measurement (e.g., 'degrees', 'inches', 'percent')
  final String unit;

  /// Direction of deviation (e.g., 'too_high', 'too_low', 'too_early', 'too_late')
  @JsonKey(name: 'deviation_direction')
  final String? deviationDirection;

  /// Component breakdown for composite measurements (e.g., back_leg_drive factors)
  final List<ObservationMeasurementComponent>? components;

  /// Whether this measurement has component breakdown data
  bool get hasComponents => components != null && components!.isNotEmpty;

  /// Formatted string showing measured value with unit
  String get formattedMeasuredValue =>
      '${measuredValue.toStringAsFixed(1)}$unit';

  /// Formatted string showing ideal value with unit
  String get formattedIdealValue =>
      idealValue != null ? '${idealValue!.toStringAsFixed(1)}$unit' : '-';

  /// Formatted string showing deviation with unit
  String get formattedDeviation {
    if (deviation == null) return '-';
    final String sign = deviation! >= 0 ? '+' : '';
    return '$sign${deviation!.toStringAsFixed(1)}$unit';
  }

  factory ObservationMeasurement.fromJson(Map<String, dynamic> json) =>
      _$ObservationMeasurementFromJson(json);
  Map<String, dynamic> toJson() => _$ObservationMeasurementToJson(this);
}
