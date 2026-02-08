import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';

part 'form_observations.g.dart';

/// Container for all form observations from an analysis
@JsonSerializable(explicitToJson: true)
class FormObservations {
  const FormObservations({
    required this.observations,
    required this.observationsCount,
    this.worstSeverity,
    required this.hasSignificantObservations,
  });

  /// List of all observations
  final List<FormObservation> observations;

  /// Total number of observations
  @JsonKey(name: 'observations_count')
  final int observationsCount;

  /// The worst severity level found in all observations
  @JsonKey(name: 'worst_severity')
  final ObservationSeverity? worstSeverity;

  /// Whether there are any significant severity observations
  @JsonKey(name: 'has_significant_observations')
  final bool hasSignificantObservations;

  /// Get all severe observations (moderate or significant)
  List<FormObservation> get severeObservations =>
      observations.where((o) => o.isSevere).toList();

  /// Get observations grouped by category
  Map<ObservationCategory, List<FormObservation>> get byCategory {
    final Map<ObservationCategory, List<FormObservation>> grouped = {};
    for (final FormObservation observation in observations) {
      grouped.putIfAbsent(observation.category, () => []).add(observation);
    }
    return grouped;
  }

  /// Get observations by type
  List<FormObservation> getByType(ObservationType type) =>
      observations.where((o) => o.observationType == type).toList();

  /// Get positive observations (strengths)
  List<FormObservation> get positiveObservations =>
      getByType(ObservationType.positive);

  /// Get negative observations (areas to improve)
  List<FormObservation> get negativeObservations =>
      getByType(ObservationType.negative);

  /// Get neutral observations
  List<FormObservation> get neutralObservations =>
      getByType(ObservationType.neutral);

  /// Check if there are any observations
  bool get isEmpty => observations.isEmpty;

  /// Check if there are any observations
  bool get isNotEmpty => observations.isNotEmpty;

  factory FormObservations.fromJson(Map<String, dynamic> json) =>
      _$FormObservationsFromJson(json);
  Map<String, dynamic> toJson() => _$FormObservationsToJson(this);
}
