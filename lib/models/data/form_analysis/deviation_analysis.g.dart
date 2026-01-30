// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deviation_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviationAnalysis _$DeviationAnalysisFromJson(Map<String, dynamic> json) =>
    DeviationAnalysis(
      angleDeviations: AngleDeviations.fromJson(
        json['angle_deviations'] as Map<String, dynamic>,
      ),
      severity: json['severity'] as String,
      individualDeviations: json['individual_deviations'] == null
          ? null
          : IndividualJointDeviations.fromJson(
              json['individual_deviations'] as Map<String, dynamic>,
            ),
      v2MeasurementDeviations: json['v2_measurement_deviations'] == null
          ? null
          : V2SideMeasurements.fromJson(
              json['v2_measurement_deviations'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$DeviationAnalysisToJson(DeviationAnalysis instance) =>
    <String, dynamic>{
      'angle_deviations': instance.angleDeviations.toJson(),
      'severity': instance.severity,
      'individual_deviations': instance.individualDeviations?.toJson(),
      'v2_measurement_deviations': instance.v2MeasurementDeviations?.toJson(),
    };
