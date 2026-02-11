import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';

part 'form_observations_v2.g.dart';

/// V2 container for form observations with a map of observation keys to observations.
/// This allows flexible addition of new observation types without model changes.
@JsonSerializable(explicitToJson: true)
class FormObservationsV2 {
  const FormObservationsV2({
    required this.observations,
    required this.overallScore,
  });

  /// Map of observation keys to their observation data.
  /// Keys are snake_case identifiers like 'back_toe_slip', 'max_arm_extension', etc.
  @JsonKey(name: 'observations')
  final Map<String, FormObservation> observations;

  /// Overall score from 0.0 to 1.0 (average of all observation scores)
  @JsonKey(name: 'overall_score')
  final double overallScore;

  /// Get all observations as a list
  List<FormObservation> get allObservations => observations.values.toList();

  /// Check if there are any observations
  bool get isNotEmpty => observations.isNotEmpty;

  /// Check if there are no observations
  bool get isEmpty => observations.isEmpty;

  /// Get observation by key (e.g., 'back_toe_slip')
  FormObservation? operator [](String key) => observations[key];

  /// Get all observation keys
  Iterable<String> get keys => observations.keys;

  /// Get observations grouped by category
  Map<ObservationCategory, List<FormObservation>> get byCategory {
    final Map<ObservationCategory, List<FormObservation>> grouped = {};
    for (final FormObservation observation in observations.values) {
      grouped.putIfAbsent(observation.category, () => []).add(observation);
    }
    return grouped;
  }

  /// Get all footwork observations
  List<FormObservation> get footworkObservations => observations.values
      .where((o) => o.category == ObservationCategory.footwork)
      .toList();

  /// Get all arm mechanics observations
  List<FormObservation> get armMechanicsObservations => observations.values
      .where((o) => o.category == ObservationCategory.armMechanics)
      .toList();

  /// Get all timing observations
  List<FormObservation> get timingObservations => observations.values
      .where((o) => o.category == ObservationCategory.timing)
      .toList();

  /// Get severe observations (moderate or significant)
  List<FormObservation> get severeObservations =>
      observations.values.where((o) => o.isSevere).toList();

  factory FormObservationsV2.fromJson(Map<String, dynamic> json) =>
      _$FormObservationsV2FromJson(json);
  Map<String, dynamic> toJson() => _$FormObservationsV2ToJson(this);
}
