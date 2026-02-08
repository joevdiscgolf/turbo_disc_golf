import 'package:json_annotation/json_annotation.dart';

/// Category of observation - what aspect of the throw it relates to
@JsonEnum(valueField: 'value')
enum ObservationCategory {
  @JsonValue('footwork')
  footwork('footwork'),
  @JsonValue('arm_mechanics')
  armMechanics('arm_mechanics'),
  @JsonValue('timing')
  timing('timing'),
  @JsonValue('balance')
  balance('balance'),
  @JsonValue('rotation')
  rotation('rotation');

  const ObservationCategory(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case ObservationCategory.footwork:
        return 'Footwork';
      case ObservationCategory.armMechanics:
        return 'Arm mechanics';
      case ObservationCategory.timing:
        return 'Timing';
      case ObservationCategory.balance:
        return 'Balance';
      case ObservationCategory.rotation:
        return 'Rotation';
    }
  }
}

/// Type of observation - whether it's positive, negative, or neutral
@JsonEnum(valueField: 'value')
enum ObservationType {
  @JsonValue('positive')
  positive('positive'),
  @JsonValue('negative')
  negative('negative'),
  @JsonValue('neutral')
  neutral('neutral');

  const ObservationType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case ObservationType.positive:
        return 'Strength';
      case ObservationType.negative:
        return 'Area to improve';
      case ObservationType.neutral:
        return 'Observation';
    }
  }
}

/// Severity of the observation - how much it affects performance
@JsonEnum(valueField: 'value')
enum ObservationSeverity {
  @JsonValue('none')
  none('none'),
  @JsonValue('minor')
  minor('minor'),
  @JsonValue('moderate')
  moderate('moderate'),
  @JsonValue('significant')
  significant('significant');

  const ObservationSeverity(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case ObservationSeverity.none:
        return 'None';
      case ObservationSeverity.minor:
        return 'Minor';
      case ObservationSeverity.moderate:
        return 'Moderate';
      case ObservationSeverity.significant:
        return 'Significant';
    }
  }

  /// Whether this severity level is considered severe (moderate or significant)
  bool get isSevere =>
      this == ObservationSeverity.moderate ||
      this == ObservationSeverity.significant;
}

/// Display mode for observation timing
@JsonEnum(valueField: 'value')
enum ObservationDisplayMode {
  @JsonValue('single_frame')
  singleFrame('single_frame'),
  @JsonValue('frame_range')
  frameRange('frame_range');

  const ObservationDisplayMode(this.value);
  final String value;
}
