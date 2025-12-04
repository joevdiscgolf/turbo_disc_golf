import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';

part 'potential_round_data.g.dart';

/// Intermediate representation of a hole with all optional fields.
/// Used during parsing to handle incomplete data from Gemini without exceptions.
@JsonSerializable(explicitToJson: true, anyMap: true)
class PotentialDGHole {
  const PotentialDGHole({
    this.number,
    this.par,
    this.feet,
    this.throws,
    this.holeType,
  });

  final int? number;
  final int? par;
  final int? feet;
  final List<DiscThrow>? throws;
  final HoleType? holeType;

  factory PotentialDGHole.fromJson(Map<String, dynamic> json) =>
      _$PotentialDGHoleFromJson(json);

  Map<String, dynamic> toJson() => _$PotentialDGHoleToJson(this);

  /// Check if this hole has all required fields for conversion to DGHole
  bool get hasRequiredFields {
    if (number == null ||
        (number ?? 0) < 1 ||
        par == null ||
        par == 0 ||
        feet == null ||
        feet == 0 ||
        !lastThrowInBasket) {
      return false;
    }

    return true;
  }

  bool get lastThrowInBasket {
    if (throws == null) {
      return false;
    } else if (throws!.isEmpty) {
      return false;
    } else {
      return throws![throws!.length - 1].landingSpot == LandingSpot.inBasket;
    }
  }

  /// Get list of missing required field names
  List<String> getMissingFields() {
    final List<String> missing = [];
    if (number == null) missing.add('number');
    if (par == null) missing.add('par');
    if (throws == null) {
      missing.add('throws');
    }
    return missing;
  }

  /// Convert to final DGHole if all required fields are present
  /// Throws ArgumentError if required fields are missing
  DGHole toDGHole() {
    if (!hasRequiredFields) {
      throw ArgumentError(
        'Cannot convert to DGHole: missing required fields: ${getMissingFields().join(', ')}',
      );
    }

    return DGHole(
      number: number!,
      par: par!,
      feet: feet!,
      throws: throws!,
      holeType: holeType,
    );
  }
}

/// Intermediate representation of a round with all optional fields (except id).
/// Used during parsing to handle incomplete data from Gemini without exceptions.
@JsonSerializable(explicitToJson: true, anyMap: true)
class PotentialDGRound {
  const PotentialDGRound({
    required this.uid,
    required this.id,
    this.courseId,
    this.courseName,
    this.holes,
    this.analysis,
    this.aiSummary,
    this.aiCoachSuggestion,
    this.versionId = 1,
    this.createdAt,
    this.playedRoundAt,
  });

  final String uid;
  final String id;
  final String? courseId;
  final String? courseName;
  final List<PotentialDGHole>? holes;
  final RoundAnalysis? analysis;
  final AIContent? aiSummary;
  final AIContent? aiCoachSuggestion;
  final int versionId;
  final String? createdAt;
  final String? playedRoundAt;

  factory PotentialDGRound.fromJson(Map<String, dynamic> json) =>
      _$PotentialDGRoundFromJson(json);

  Map<String, dynamic> toJson() => _$PotentialDGRoundToJson(this);

  /// Check if this round has all required fields for conversion to DGRound
  bool get hasRequiredFields {
    if (courseName == null || holes == null || holes!.isEmpty) return false;

    // Also check that all holes have required fields
    for (final potentialHole in holes!) {
      if (!potentialHole.hasRequiredFields) return false;
    }

    return true;
  }

  /// Get list of missing required field names
  List<String> getMissingFields() {
    final List<String> missing = [];
    if (courseName == null) missing.add('courseName');
    if (holes == null || holes!.isEmpty) {
      missing.add('holes');
    } else {
      // Check holes for missing fields
      for (int i = 0; i < holes!.length; i++) {
        final holeMissing = holes![i].getMissingFields();
        if (holeMissing.isNotEmpty) {
          missing.add(
            'hole ${holes![i].number ?? i}: ${holeMissing.join(', ')}',
          );
        }
      }
    }
    return missing;
  }

  /// Get summary of validation issues for display
  Map<String, dynamic> getValidationSummary() {
    final Map<String, dynamic> summary = {
      'isValid': hasRequiredFields,
      'missingFields': getMissingFields(),
      'holesCount': holes?.length ?? 0,
      'invalidHoles': <Map<String, dynamic>>[],
    };

    if (holes != null) {
      for (final hole in holes!) {
        if (!hole.hasRequiredFields) {
          summary['invalidHoles'].add({
            'holeNumber': hole.number,
            'missingFields': hole.getMissingFields(),
          });
        }
      }
    }

    return summary;
  }

  /// Convert to final DGRound if all required fields are present
  /// Throws ArgumentError if required fields are missing
  DGRound toDGRound() {
    if (!hasRequiredFields) {
      throw ArgumentError(
        'Cannot convert to DGRound: missing required fields: ${getMissingFields().join(', ')}',
      );
    }

    return DGRound(
      uid: uid,
      id: id,
      courseId: courseId,
      courseName: courseName!,
      holes: holes!.map((h) => h.toDGHole()).toList(),
      analysis: analysis,
      aiSummary: aiSummary,
      aiCoachSuggestion: aiCoachSuggestion,
      versionId: versionId,
      createdAt: DateTime.now().toIso8601String(),
      playedRoundAt: DateTime.now().toIso8601String(),
    );
  }
}
